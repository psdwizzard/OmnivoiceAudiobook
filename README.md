# OmniVoice — Forge Edition

A patched deployment of OmniVoice (the `omnivoice` Gradio TTS / voice-cloning /
long-form audiobook app) set up to run as a multi-user app behind Cloudflare
Access, sharing a single GPU with other tools (e.g. ComfyUI).

This repo does **not** vendor the upstream `omnivoice` Python package. The
package is installed normally into `venv/` (gitignored). What lives here is:

- **`site-packages-patches/`** — the canonical edited copies of the files we
  patch in the installed package. Edit here, then copy into
  `venv/Lib/site-packages/omnivoice/...` (and restart). They are kept
  byte-identical to what runs.
- **Launchers** (`run_omnivoice_*.bat`).
- **`integrations/comfyui/`** — a ComfyUI custom node for cross-app VRAM
  coordination.

> Upstream app: OmniVoice (k2-fsa). This is a hosting/integration layer on top.

---

## What the Forge edition adds

1. **Network / hosted launch** — binds `0.0.0.0:8001` so the app is reachable
   over LAN / Tailscale / a Cloudflare tunnel (`run_omnivoice_network.bat`,
   `run_omnivoice_forge.bat`).
2. **Per-user generation libraries** — behind Cloudflare Access, each user's
   long-form generations are stored under `generations/<user-email>/`, keyed off
   the `Cf-Access-Authenticated-User-Email` header. Saved **voices are shared**
   across everyone; only the long-form library is split.
3. **Download button** — a `⬇ Download Selected` button in the Long Form tab:
   pick a past generation and download its final audio in one click.
4. **Saved-voice settings in Long Form** — selecting a saved voice loads that
   voice's saved generation settings into the Long Form sliders (matches the
   Voice Cloning tab).
5. **GPU VRAM coordination** with a co-resident ComfyUI (see below).

---

## Running

### Local only
```
run_omnivoice_demo.bat        # 127.0.0.1:8001, opens a browser
```

### Network / hosted (recommended for Forge)
```
run_omnivoice_forge.bat       # 0.0.0.0:8001, per-user libs, VRAM coordination
```

Public access is via a Cloudflare Tunnel + Cloudflare Access app pointed at
`http://<host>:8001`. The app trusts the `Cf-Access-Authenticated-User-Email`
header that Access injects, so it needs no auth config of its own — just put it
behind Access. Direct/LAN access with no header falls back to a shared `shared`
library bucket.

### Environment variables
| Var | Default | Purpose |
|---|---|---|
| `OMNIVOICE_VOICES_DIR` | `./voices` | Shared saved-voice library (all users). |
| `OMNIVOICE_GENERATIONS_DIR` | `./generations` | Base dir; the app appends `/<user>` per request. |
| `OMNIVOICE_IDLE_UNLOAD_SECONDS` | `3600` | Move the model to CPU + free VRAM after this many seconds idle. `0` disables. |
| `OMNIVOICE_FREE_COMFY` | `1` | On each OmniVoice generation, ask ComfyUI to free its VRAM first. `0` disables. |
| `OMNIVOICE_COMFYUI_URL` | `http://127.0.0.1:8188` | ComfyUI base URL for the free call. |
| `OMNIVOICE_CONTROL_PORT` | `8002` | Localhost control server port (`POST /unload`, `GET /status`). `0` disables. |

---

## GPU VRAM coordination

OmniVoice and ComfyUI share one GPU. The handoff is **demand-driven and
bidirectional** — whichever app gets a request evicts the other:

- **OmniVoice generation starts** → it calls ComfyUI's `POST /free`
  (`unload_models`, `free_memory`) so OmniVoice gets the GPU. ComfyUI lazily
  reloads its model on its next render.
- **ComfyUI render is queued** → the `omnivoice_evict` custom node calls
  OmniVoice's `POST /unload`, which moves OmniVoice's model to CPU and frees its
  VRAM. OmniVoice reloads on its next voice generation.
- **Safety:** OmniVoice refuses to unload while it is mid-generation
  (`/unload` → `409`), and a long audiobook "heartbeats" per chunk, so an
  in-flight run is never disrupted.
- **Backstop:** the idle timer (`OMNIVOICE_IDLE_UNLOAD_SECONDS`) frees
  OmniVoice's VRAM after inactivity even if nothing else asks.

### Installing the ComfyUI node
Copy (or symlink) `integrations/comfyui/omnivoice_evict/` into your ComfyUI
`custom_nodes/` directory and **restart ComfyUI**. On startup it logs:
```
omnivoice_evict: registered on-prompt handler -> http://127.0.0.1:8002/unload
```
Set `OMNIVOICE_CONTROL_URL` for ComfyUI if OmniVoice's control server isn't on
the default `http://127.0.0.1:8002`.

---

## Applying the patches

The installed package under `venv/` is what actually runs. After editing files
in `site-packages-patches/`, copy them into the venv and restart:

```
copy site-packages-patches\omnivoice\cli\demo.py            venv\Lib\site-packages\omnivoice\cli\demo.py
copy site-packages-patches\omnivoice\cli\omnivoice_extras.py venv\Lib\site-packages\omnivoice\cli\omnivoice_extras.py
```

(There is also a small frontend asset patch under
`site-packages-patches/gradio/...` mirrored the same way.)

---

## Data layout

```
voices/                       # shared saved voices (all users)
generations/
  <user-email-slug>/          # per-user long-form library
    <timestamp>-<title>/
      generation.json
      source.txt
      chunks/####.wav
      final.mp3 / final.wav / partial.wav
```

`voices/` and `generations/` are gitignored — they hold user content, not code.
