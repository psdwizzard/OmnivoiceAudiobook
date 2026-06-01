@echo off
setlocal EnableExtensions
cd /d "%~dp0"
chcp 65001 >nul 2>nul
title OmniVoice (network)

REM ============================================================
REM   OmniVoice LAN launcher.
REM   Binds 0.0.0.0:8001 so other browsers on the same home
REM   network can open http://THIS-PC-LAN-IP:8001.
REM ============================================================

if not exist "%~dp0hf_cache" mkdir "%~dp0hf_cache"
if not exist "%~dp0torch_cache" mkdir "%~dp0torch_cache"

set "HF_HOME=%~dp0hf_cache"
set "HF_HUB_DISABLE_SYMLINKS_WARNING=1"
set "TORCH_HOME=%~dp0torch_cache"
set "PIP_DISABLE_PIP_VERSION_CHECK=1"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

set "OV_PORT=8001"
set "OV_HOST=0.0.0.0"
set "LAN_IP="

REM Pick the IPv4 address Windows uses for normal LAN/internet routing.
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = [Net.Sockets.UdpClient]::new(); try { $c.Connect('8.8.8.8', 80); $c.Client.LocalEndPoint.Address.IPAddressToString } catch { '' } finally { $c.Dispose() }"`) do set "LAN_IP=%%I"

if not defined LAN_IP (
    echo Could not automatically detect the LAN IP address.
    echo Run ipconfig and use the IPv4 Address from your Wi-Fi/Ethernet adapter.
    set "LAN_URL=http://127.0.0.1:%OV_PORT%"
) else (
    set "LAN_URL=http://%LAN_IP%:%OV_PORT%"
)

echo =====================================================
echo Starting OmniVoice on all network adapters, port %OV_PORT%
echo =====================================================
echo.
echo First launch can take a while - models download from Hugging Face.
echo.
echo Open this on this computer:
echo   http://127.0.0.1:%OV_PORT%
echo.
echo Open this from another browser on the same home network:
echo   %LAN_URL%
echo.
echo Press Ctrl+C in this window to stop the server.
echo.

if /I "%~1"=="--dry-run" (
    echo Dry run only; OmniVoice was not started.
    exit /b 0
)

REM Ensure Windows Firewall allows inbound on this port (idempotent).
netsh advfirewall firewall show rule name="OmniVoice %OV_PORT%" >nul 2>nul
if errorlevel 1 (
    echo Adding Windows Firewall rule "OmniVoice %OV_PORT%"...
    netsh advfirewall firewall add rule name="OmniVoice %OV_PORT%" dir=in action=allow protocol=TCP localport=%OV_PORT% profile=any >nul 2>nul
    if errorlevel 1 (
        echo Could not add the firewall rule without administrator approval.
        echo Approve the Windows prompt so other devices can connect.
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process netsh -Verb RunAs -Wait -ArgumentList 'advfirewall firewall add rule name=\"OmniVoice %OV_PORT%\" dir=in action=allow protocol=TCP localport=%OV_PORT% profile=any'"
    )
)

if defined LAN_IP start "" "%LAN_URL%"

if exist "%~dp0venv\Scripts\omnivoice-demo.exe" (
    "%~dp0venv\Scripts\omnivoice-demo.exe" --ip %OV_HOST% --port %OV_PORT%
) else (
    "%~dp0venv\Scripts\python.exe" -m omnivoice.cli.demo --ip %OV_HOST% --port %OV_PORT%
)

echo.
echo OmniVoice has stopped.
pause
