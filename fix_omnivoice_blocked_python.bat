@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Unblock OmniVoice in Windows Firewall

REM ============================================================
REM   Removes the stray Inbound BLOCK rules created when
REM   Windows Defender prompted for python.exe and "Cancel" was
REM   clicked. Block rules win over Allow rules, so even with
REM   the port-8001 allow rule in place, LAN devices cannot
REM   connect until the block rules are deleted.
REM
REM   The script also adds a program-scoped Allow rule for the
REM   exact Python interpreter that the OmniVoice venv uses,
REM   so a future Defender prompt cannot recreate the block.
REM ============================================================

net session >nul 2>nul
if errorlevel 1 (
    echo Requesting administrator permission to update Windows Firewall...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "OV_PORT=8001"
set "TEST_PORT=8011"
set "VENV_PY=%~dp0venv\Scripts\python.exe"
set "VENV_HOME_PY="

REM Resolve the *real* interpreter the venv launches under, by reading
REM pyvenv.cfg. The .exe stubs in venv\Scripts re-exec this binary, so
REM that's the one Windows Firewall sees as the listening process.
if exist "%~dp0venv\pyvenv.cfg" (
    for /f "usebackq tokens=2 delims== " %%H in (`findstr /B /I "home" "%~dp0venv\pyvenv.cfg"`) do (
        set "VENV_HOME_PY=%%H\python.exe"
    )
)

echo Detected venv launcher interpreter: !VENV_HOME_PY!
echo Detected venv python.exe:           %VENV_PY%
echo.

echo --- Removing stray Inbound BLOCK rules for python.exe ---
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-NetFirewallRule -Direction Inbound -Action Block -ErrorAction SilentlyContinue | ForEach-Object { $r = $_; $a = $r | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue; if ($a -and $a.Program -and ($a.Program -ieq '%VENV_HOME_PY%' -or $a.Program -ieq '%VENV_PY%')) { Write-Host ('Removing: ' + $r.DisplayName + '  ->  ' + $a.Program); Remove-NetFirewallRule -Name $r.Name -ErrorAction SilentlyContinue } }"

echo.
echo --- Refreshing OmniVoice Allow rules ---
netsh advfirewall firewall delete rule name="OmniVoice 8001" >nul 2>nul
netsh advfirewall firewall delete rule name="OmniVoice Python venv" >nul 2>nul
netsh advfirewall firewall delete rule name="OmniVoice Python venv home" >nul 2>nul
netsh advfirewall firewall delete rule name="OmniVoice Python system" >nul 2>nul
netsh advfirewall firewall delete rule name="OmniVoice Network Test 8011" >nul 2>nul

netsh advfirewall firewall add rule name="OmniVoice 8001" dir=in action=allow protocol=TCP localport=%OV_PORT% profile=any
netsh advfirewall firewall add rule name="OmniVoice Network Test 8011" dir=in action=allow protocol=TCP localport=%TEST_PORT% profile=any

if exist "%VENV_PY%" (
    netsh advfirewall firewall add rule name="OmniVoice Python venv" dir=in action=allow program="%VENV_PY%" enable=yes profile=any
)

if defined VENV_HOME_PY if exist "!VENV_HOME_PY!" (
    netsh advfirewall firewall add rule name="OmniVoice Python venv home" dir=in action=allow program="!VENV_HOME_PY!" enable=yes profile=any
)

echo.
echo --- Resulting OmniVoice-related rules ---
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-NetFirewallRule -DisplayName 'OmniVoice*' -ErrorAction SilentlyContinue | ForEach-Object { $r = $_; $p = $r | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue; $a = $r | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue; '{0,-32} {1,-7} {2,-5} {3,-7} {4,-6} {5}' -f $r.DisplayName, $r.Action, $r.Enabled, $p.LocalPort, $p.Protocol, $a.Program }"

echo.
echo Done. Stop OmniVoice (close its window), then re-run run_omnivoice_network.bat
echo and try http://192.168.86.23:8001 from another device.
echo.
pause
