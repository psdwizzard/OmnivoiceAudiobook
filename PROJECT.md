# OmniVoice Audiobook Project Notes

This file is the quick-start memory dump for rebuilding or debugging this
workspace from scratch.

## Project

- Name: OmniVoice Audiobook
- Local path: `E:\app\Audio\OmniVoice`
- GitHub: `https://github.com/psdwizzard/OmnivoiceAudiobook.git`
- Main launch script: `run_omnivoice_demo.bat`
- Main local URL: `http://127.0.0.1:8001`
- Gradio version in the working venv: `6.15.2`

## What Is Backed Up

- Launcher scripts are committed.
- `.gitignore` excludes heavy/generated content.
- `venv/` is intentionally not committed.
- `hf_cache/` is intentionally not committed.
- `torch_cache/` is intentionally not committed.
- `voices/` is intentionally not committed.
- Copies of patched installed files live in `site-packages-patches/`.

## Important Patched Files

- Live patched demo:
  `venv\Lib\site-packages\omnivoice\cli\demo.py`
- Live patched Gradio asset:
  `venv\Lib\site-packages\gradio\templates\frontend\assets\index-Bp-AlgMP.js`
- Backup copy of demo:
  `site-packages-patches\omnivoice\cli\demo.py`
- Backup copy of Gradio asset:
  `site-packages-patches\gradio\templates\frontend\assets\index-Bp-AlgMP.js`

## Original Problem

- Voice Clone worked.
- Voice Crafter and Voice Design froze the UI when clicked.
- Browser console showed Svelte error `effect_update_depth_exceeded`.
- The failing frontend function was un-minified around `Di()` in:
  `gradio/templates/frontend/assets/index-iG-u5S-q.js`
- The symptom was a Svelte maximum update depth loop.
- It happened after activating inactive tabs.
- It made switching back to Voice Clone impossible.

## Key Observation

- Gradio 6 introduced lazy tab rendering.
- In Gradio 6.15.2, `gr.TabItem(..., render_children=True)` exists.
- `demo.py` was updated to pass `render_children=True`.
- The generated Gradio config correctly included `render_children: true`.
- But the Gradio frontend asset ignored that prop.
- So inactive tabs were still lazily pruned.
- Clicking an inactive tab still took the broken lazy-render path.

## Working Fix

- `demo.py` sets `render_children=True` on all three tabs.
- The local Gradio frontend asset was patched to honor `render_children`.
- Specifically, inactive tab children are no longer pruned when:
  `e.props.props.render_children === true`
- This forces eager mounting for Voice Crafter and Voice Design.
- That avoids the Svelte lazy-mount update loop.

## Demo.py Fixes To Preserve

- `Voice Clone` tab uses `render_children=True`.
- `Voice Crafter` tab uses `render_children=True`.
- `Voice Design` tab uses `render_children=True`.
- Voice Crafter category dropdowns are restored.
- Voice Design category dropdowns are restored.
- Category dropdowns use explicit `elem_id`s:
  `vk_cat_0` through `vk_cat_5`.
- Voice Design category dropdowns use:
  `vd_cat_0` through `vd_cat_5`.
- Dropdowns only include `info` when non-empty.
- Duration number fields use `value=None`.
- Duration info says: `Leave empty to use speed.`
- `theme` and `css` are module constants.
- `gr.Blocks(...)` does not receive `theme` or `css`.
- `demo.launch(...)` receives `theme=THEME` and `css=CSS`.

## Gradio Asset Patch

- File:
  `venv\Lib\site-packages\gradio\templates\frontend\assets\index-Bp-AlgMP.js`
- The minified tab-pruning expression now checks:
  `e.props.props.render_children!==!0`
- Before the patch, inactive tabs were always removed from the initial
  render set.
- After the patch, tabs with `render_children=True` remain in the initial
  render set.
- A no-model smoke launch confirmed the patched asset was served.

## Why The First Suspects Were Wrong

- Duplicate labels were not the issue.
- Duplicate IDs were not the issue.
- Gradio assigns auto-incrementing integer component IDs.
- Voice Clone also uses the 600+ language dropdown and works.
- Removing category dropdowns reduced error count but did not fix the loop.
- `gr.Number(value=None)` was not the issue.
- `gradio/components/number.py` passes `None` through correctly.

## Launch

- Run:
  `E:\app\Audio\OmniVoice\run_omnivoice_demo.bat`
- Browser opens:
  `http://127.0.0.1:8001`
- After changing frontend assets, hard reload with:
  `Ctrl+Shift+R`
- If stale frontend code persists, clear browser cache for localhost.

## Launch Script Behavior

- Changes directory to the script folder.
- Sets UTF-8 console behavior.
- Sets Hugging Face cache under local `hf_cache`.
- Sets Torch cache under local `torch_cache`.
- Opens `http://127.0.0.1:8001`.
- Prefers `venv\Scripts\omnivoice-demo.exe`.
- Falls back to:
  `venv\Scripts\python.exe -m omnivoice.cli.demo`

## Verification Checklist

- Start the demo with `run_omnivoice_demo.bat`.
- Hard reload the browser.
- Voice Clone appears first.
- Browser console has no new `Uncaught` errors.
- Click Voice Design.
- Voice Design body appears.
- No `effect_update_depth_exceeded` appears.
- Switch back to Voice Clone.
- Switching works.
- Click Voice Crafter.
- Voice Crafter body appears.
- Saved voices list appears.
- UI remains responsive.
- Generate/preview only after the model is fully loaded.

## Syntax Checks

- `py_compile` may fail because writing `__pycache__` in `site-packages`
  can hit Windows permissions.
- Use no-bytecode syntax check instead:

```powershell
venv\Scripts\python.exe -X utf8 -c "from pathlib import Path; p=Path('venv/Lib/site-packages/omnivoice/cli/demo.py'); compile(p.read_text(encoding='utf-8'), str(p), 'exec'); print('demo.py syntax ok')"
```

## No-Model Smoke Test

- A stub model can instantiate the UI without loading TTS weights.
- Useful for checking Gradio config and served frontend assets.
- Stub model only needs `sampling_rate`.
- Example checks:
  tabitem IDs, labels, and `render_children`.
- A previous smoke launch served the patched asset from port `8897`.

## Restore From Git

- Clone:
  `git clone https://github.com/psdwizzard/OmnivoiceAudiobook.git`
- Recreate or install the OmniVoice venv separately.
- Copy patched files from `site-packages-patches/` into the matching
  `venv\Lib\site-packages\...` locations.
- Confirm Gradio is `6.15.2` before using the asset patch.
- If Gradio asset filenames change, the minified target may move.

## If Gradio Is Reinstalled

- Reinstalling packages can overwrite both live patches.
- Reapply `site-packages-patches\omnivoice\cli\demo.py`.
- Reapply `site-packages-patches\gradio\templates\frontend\assets\index-Bp-AlgMP.js`.
- If the Gradio asset hash changes, search for:
  `t.type==="tabs"&&t.children.forEach`
- Then add the `render_children!==!0` guard to inactive tab pruning.

## If The Bug Returns

- Confirm the browser is not using cached frontend assets.
- Hard reload with `Ctrl+Shift+R`.
- Confirm `index-Bp-AlgMP.js` contains:
  `render_children!==!0`
- Confirm demo config sends `render_children: true`.
- Confirm the live edited file is inside the active venv.
- Confirm the running process was restarted after edits.

## Git Notes

- Branch: `main`
- Remote: `origin`
- Last known backup commit before this file:
  `6370f0c Initial OmniVoice audiobook backup`
- The git repo intentionally tracks patch copies, not the full environment.

## Things Not To Commit

- `venv/`
- `hf_cache/`
- `torch_cache/`
- `voices/`
- generated `__pycache__/`
- model weights
- temporary logs

## Useful Commands

```powershell
git status --short --branch
git log --oneline --decorate --max-count=5
git remote -v
venv\Scripts\python.exe -X utf8 -c "import gradio as gr; print(gr.__version__)"
```

## Practical Warning

- This is a pip-installed package patch, not a source checkout patch.
- If the environment is rebuilt, the live site-packages edits disappear.
- Treat `site-packages-patches/` as the source of truth for local fixes.
- Keep the backup copies synchronized after any future live edits.
