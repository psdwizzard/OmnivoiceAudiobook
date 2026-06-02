# OmniVoice Audiobook

Generate audiobooks and long-form narration with AI voice cloning. Clone a
voice from a short reference clip, save it, and turn whole chapters into audio —
with recoverable, resumable long-form runs and one-click downloads of finished
books.

Built on the OmniVoice (k2-fsa) TTS model, wrapped in a Gradio web UI. **Runs
standalone on a single machine — no accounts, no cloud, no Forge required.** An
optional hosted mode (multi-user behind Cloudflare Access) is described at the
bottom for anyone who wants to share it with friends.

---

## Features

- **Voice cloning** — clone a voice from a short reference audio clip (with
  optional reference text, or auto-transcribed).
- **Saved voices** — save a cloned voice with its generation settings and reuse
  it anywhere.
- **Long-form / audiobook generation** — paste a whole chapter; it's split into
  chunks and rendered with natural paragraph pauses. Runs are **recoverable**:
  if one stops, you can resume it instead of starting over.
- **Generation library** — every long-form run is saved with its text and audio,
  listed in a library you can reload, resume, or **download** (one-click
  `⬇ Download Selected` → final MP3/WAV).
- **Saved-voice settings carry over** — picking a saved voice in Long Form loads
  that voice's saved generation settings into the sliders automatically.
- **Voice design / instruct** — steer delivery with an optional instruct prompt.

---

## Quick start

```
run_omnivoice_demo.bat
```
Opens the UI at `http://127.0.0.1:8001`. First launch downloads the models from
Hugging Face (one time, can take a while). That's it — clone a voice, paste a
chapter, generate.

### Use it from other devices on your network
```
run_omnivoice_network.bat
```
Binds `0.0.0.0:8001` so other machines on your LAN / Tailscale can open
`http://<this-machine-ip>:8001`.

---

## Data layout

```
voices/                       # your saved voices
generations/                  # your audiobook library
  <timestamp>-<title>/
    generation.json
    source.txt
    chunks/####.wav
    final.mp3 / final.wav / partial.wav
```
`voices/` and `generations/` are gitignored — they're your content, not code.

---

## How this repo is organized

The upstream `omnivoice` package is installed into `venv/` (gitignored). This
repo holds the **patches and launchers layered on top**:

- **`site-packages-patches/`** — canonical edited copies of the package files we
  modify. Edit here, then copy into `venv/Lib/site-packages/omnivoice/...` and
  restart. (They're kept byte-identical to what runs.)
- **`run_omnivoice_*.bat`** — launchers.
- **`integrations/comfyui/`** — optional ComfyUI VRAM-coordination node (see
  hosted mode).

### Applying patches
```
copy site-packages-patches\omnivoice\cli\demo.py            venv\Lib\site-packages\omnivoice\cli\demo.py
copy site-packages-patches\omnivoice\cli\omnivoice_extras.py venv\Lib\site-packages\omnivoice\cli\omnivoice_extras.py
```

---

## Common settings (optional env vars)

| Var | Default | Purpose |
|---|---|---|
| `OMNIVOICE_VOICES_DIR` | `./voices` | Where saved voices live. |
| `OMNIVOICE_GENERATIONS_DIR` | `./generations` | Where the audiobook library lives. |
| `OMNIVOICE_IDLE_UNLOAD_SECONDS` | `3600` | Free GPU VRAM after this many seconds idle (model moves to CPU, reloads on next use). `0` disables. |

The idle-unload is handy on a shared GPU even in standalone mode — it gives the
VRAM back to whatever else you're running when you're not generating.

---

## Optional: hosted / multi-user mode (Forge)

Everything above works for a single user with zero setup. If you want to share
the app with friends over the internet, there's a hosted mode that runs it
behind **Cloudflare Access** so each person gets their own audiobook library
while sharing the same saved voices.

```
run_omnivoice_forge.bat
```

- **Per-user libraries** — keyed off the `Cf-Access-Authenticated-User-Email`
  header Cloudflare Access injects, each user's runs are stored under
  `generations/<user-email>/`. Saved **voices are shared** across everyone.
  Direct/LAN access with no header uses a shared `shared` bucket, so it still
  works off-tunnel.
- Put the app behind a Cloudflare Tunnel + Access app pointed at
  `http://<host>:8001`. The app needs no auth config of its own — it trusts the
  Access header.

### Optional: share a GPU with ComfyUI
If you run ComfyUI on the same GPU, the two can hand VRAM back and forth on
demand (whichever gets a request evicts the other):

- OmniVoice generation → asks ComfyUI to free VRAM (`OMNIVOICE_FREE_COMFY=1`,
  `OMNIVOICE_COMFYUI_URL`).
- ComfyUI render → asks OmniVoice to free VRAM, via the `omnivoice_evict`
  custom node calling OmniVoice's control server (`POST /unload`).

OmniVoice refuses to unload mid-generation, so an in-flight audiobook is never
interrupted. To enable the ComfyUI side, copy `integrations/comfyui/omnivoice_evict/`
into ComfyUI's `custom_nodes/` and restart ComfyUI.

| Var | Default | Purpose |
|---|---|---|
| `OMNIVOICE_FREE_COMFY` | `1` | On each OmniVoice generation, free ComfyUI's VRAM first. |
| `OMNIVOICE_COMFYUI_URL` | `http://127.0.0.1:8188` | ComfyUI base URL. |
| `OMNIVOICE_CONTROL_PORT` | `8002` | Localhost control server (`POST /unload`, `GET /status`). `0` disables. |
