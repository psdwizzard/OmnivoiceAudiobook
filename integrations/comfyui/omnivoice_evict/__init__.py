"""ComfyUI <-> OmniVoice VRAM coordination.

Registers an on-prompt handler so that whenever a ComfyUI render is queued,
OmniVoice is asked to release its VRAM (move its model to CPU) first. OmniVoice
reloads its model on its next voice generation, and refuses to unload while it
is mid-generation (returns 409), so an in-flight audiobook is never disrupted.

Best-effort: never blocks or fails a ComfyUI render if OmniVoice is down.

Config: env OMNIVOICE_CONTROL_URL (default http://127.0.0.1:8002).
"""

import logging
import os
import urllib.request

log = logging.getLogger("omnivoice_evict")

_CONTROL_URL = os.environ.get(
    "OMNIVOICE_CONTROL_URL", "http://127.0.0.1:8002"
).rstrip("/")


def _evict_omnivoice(json_data):
    """on_prompt handler: ask OmniVoice to free VRAM before this render runs."""
    try:
        req = urllib.request.Request(
            _CONTROL_URL + "/unload",
            data=b"{}",
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        # Wait for the offload so VRAM is actually freed before Comfy loads its
        # model. If OmniVoice is busy it returns 409 immediately; if it's down,
        # the connection fails fast. Either way we never block the render.
        with urllib.request.urlopen(req, timeout=15) as r:
            r.read()
        log.info("omnivoice_evict: requested OmniVoice unload before render")
    except Exception as e:
        log.debug("omnivoice_evict: skipped (%s)", e)
    return json_data


try:
    from server import PromptServer

    PromptServer.instance.add_on_prompt_handler(_evict_omnivoice)
    log.info(
        "omnivoice_evict: registered on-prompt handler -> %s/unload", _CONTROL_URL
    )
except Exception as e:  # pragma: no cover - defensive
    log.warning("omnivoice_evict: could not register handler (%s)", e)

# This module registers behavior only; it exposes no nodes.
NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}
