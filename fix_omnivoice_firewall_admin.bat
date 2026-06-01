@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Fix OmniVoice Firewall

net session >nul 2>nul
if errorlevel 1 (
    echo Requesting administrator permission to update Windows Firewall...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "OV_PORT=8001"
set "TEST_PORT=8011"
set "VENV_PY=%~dp0venv\Scripts\python.exe"
set "SYSTEM_PY="

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Command python.exe -ErrorAction SilentlyContinue).Source"`) do set "SYSTEM_PY=%%I"

echo Adding inbound firewall rules for OmniVoice...
netsh advfirewall firewall delete rule name="OmniVoice 8001" >nul 2>nul
netsh advfirewall firewall delete rule name="OmniVoice Python venv" >nul 2>nul
netsh advfirewall firewall delete rule name="OmniVoice Python system" >nul 2>nul
netsh advfirewall firewall delete rule name="OmniVoice Network Test 8011" >nul 2>nul

netsh advfirewall firewall add rule name="OmniVoice 8001" dir=in action=allow protocol=TCP localport=%OV_PORT% profile=any
netsh advfirewall firewall add rule name="OmniVoice Network Test 8011" dir=in action=allow protocol=TCP localport=%TEST_PORT% profile=any

if exist "%VENV_PY%" (
    netsh advfirewall firewall add rule name="OmniVoice Python venv" dir=in action=allow program="%VENV_PY%" enable=yes profile=any
)

if defined SYSTEM_PY if exist "%SYSTEM_PY%" (
    netsh advfirewall firewall add rule name="OmniVoice Python system" dir=in action=allow program="%SYSTEM_PY%" enable=yes profile=any
)

echo.
echo Done. Now run run_omnivoice_network.bat again and try:
echo   http://192.168.86.23:8001
echo.
pause
