# OmniVoice Audiobook Backup

This repository backs up the local OmniVoice launcher setup and the fixes applied
to the pip-installed demo package.

The live edits were made inside:

- `venv/Lib/site-packages/omnivoice/cli/demo.py`
- `venv/Lib/site-packages/gradio/templates/frontend/assets/index-Bp-AlgMP.js`

Because `venv/` is not committed, copies of those patched files are stored under
`site-packages-patches/`.

Restart the local demo with:

```bat
E:\app\Audio\OmniVoice\run_omnivoice_demo.bat
```

Then hard-reload the browser with `Ctrl+Shift+R`.
