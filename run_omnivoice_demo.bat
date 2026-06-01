@echo off
setlocal EnableExtensions
cd /d "%~dp0"
chcp 65001 >nul 2>nul
title OmniVoice

if not exist "%~dp0hf_cache" mkdir "%~dp0hf_cache"
if not exist "%~dp0torch_cache" mkdir "%~dp0torch_cache"

set "HF_HOME=%~dp0hf_cache"
set "HF_HUB_DISABLE_SYMLINKS_WARNING=1"
set "TORCH_HOME=%~dp0torch_cache"
set "PIP_DISABLE_PIP_VERSION_CHECK=1"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

echo =====================================================
echo Starting OmniVoice web UI...
echo =====================================================
echo.
echo First launch can take a while because models download from Hugging Face.
echo.
echo Open this in your browser:
echo   http://127.0.0.1:8001
echo.
start "" "http://127.0.0.1:8001"

if exist "%~dp0venv\Scripts\omnivoice-demo.exe" (
    "%~dp0venv\Scripts\omnivoice-demo.exe" --ip 127.0.0.1 --port 8001
) else (
    "%~dp0venv\Scripts\python.exe" -m omnivoice.cli.demo --ip 127.0.0.1 --port 8001
)

echo.
echo OmniVoice has stopped or closed.
pause
