@echo off
setlocal EnableExtensions
cd /d "%~dp0"
chcp 65001 >nul 2>nul
title OmniVoice (Forge)

REM ============================================================
REM   OmniVoice - Forge edition. Binds 0.0.0.0:8001 for the
REM   Cloudflare tunnel (omnivoice.bluemediaserver.xyz).
REM
REM   Voices are SHARED across all users (OMNIVOICE_VOICES_DIR).
REM   The long-form generation library is split PER USER: the
REM   patched app reads the Cloudflare Access identity header and
REM   stores each user's runs under generations\<user-email>\.
REM   See site-packages-patches\omnivoice\cli\ for the patch.
REM ============================================================

if not exist "%~dp0hf_cache" mkdir "%~dp0hf_cache"
if not exist "%~dp0torch_cache" mkdir "%~dp0torch_cache"
if not exist "%~dp0voices" mkdir "%~dp0voices"
if not exist "%~dp0generations" mkdir "%~dp0generations"

set "HF_HOME=%~dp0hf_cache"
set "HF_HUB_DISABLE_SYMLINKS_WARNING=1"
set "TORCH_HOME=%~dp0torch_cache"
set "PIP_DISABLE_PIP_VERSION_CHECK=1"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

REM Shared voice library (every user sees the same saved voices).
set "OMNIVOICE_VOICES_DIR=%~dp0voices"
REM Base generations dir; the patched app appends \<user> per request.
set "OMNIVOICE_GENERATIONS_DIR=%~dp0generations"
REM Free the model's VRAM after this many seconds idle (0 disables). Model
REM moves to CPU and reloads to GPU on the next generation. Default 3600 (1h).
set "OMNIVOICE_IDLE_UNLOAD_SECONDS=3600"
REM Evict ComfyUI's VRAM when an OmniVoice generation starts (1=on, 0=off).
set "OMNIVOICE_FREE_COMFY=1"

set "OV_PORT=8001"
set "OV_HOST=0.0.0.0"

echo =====================================================
echo OmniVoice - Forge edition on %OV_HOST%:%OV_PORT%
echo   Voices:      shared      (%~dp0voices)
echo   Generations: per-user    (%~dp0generations\^<user^>)
echo =====================================================
echo.
echo Public URL (once tunnel is live): https://omnivoice.bluemediaserver.xyz/
echo Local/Tailscale:                  http://100.81.127.80:%OV_PORT%
echo.
echo Press Ctrl+C to stop.
echo.

if exist "%~dp0venv\Scripts\omnivoice-demo.exe" (
    "%~dp0venv\Scripts\omnivoice-demo.exe" --ip %OV_HOST% --port %OV_PORT%
) else (
    "%~dp0venv\Scripts\python.exe" -m omnivoice.cli.demo --ip %OV_HOST% --port %OV_PORT%
)

echo.
echo OmniVoice has stopped.
pause