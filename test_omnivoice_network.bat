@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title OmniVoice network test

set "TEST_PORT=8011"
set "LAN_IP="

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = [Net.Sockets.UdpClient]::new(); try { $c.Connect('8.8.8.8', 80); $c.Client.LocalEndPoint.Address.IPAddressToString } catch { '' } finally { $c.Dispose() }"`) do set "LAN_IP=%%I"

if not defined LAN_IP (
    echo Could not detect LAN IP.
    pause
    exit /b 1
)

netsh advfirewall firewall show rule name="OmniVoice Network Test %TEST_PORT%" >nul 2>nul
if errorlevel 1 (
    echo Adding Windows Firewall rule for test port %TEST_PORT%...
    netsh advfirewall firewall add rule name="OmniVoice Network Test %TEST_PORT%" dir=in action=allow protocol=TCP localport=%TEST_PORT% profile=any >nul 2>nul
    if errorlevel 1 (
        echo Could not add the firewall rule without administrator approval.
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process netsh -Verb RunAs -Wait -ArgumentList 'advfirewall firewall add rule name=\"OmniVoice Network Test %TEST_PORT%\" dir=in action=allow protocol=TCP localport=%TEST_PORT% profile=any'"
    )
)

echo =====================================================
echo Network test server
echo =====================================================
echo.
echo Keep this window open, then from another device open:
echo   http://%LAN_IP%:%TEST_PORT%
echo.
echo Do not close this window while testing from the other device.
echo.
echo If this test page does not load, the problem is network/firewall/router isolation.
echo If this test page does load, OmniVoice port 8001 is the only remaining issue.
echo.
echo Press Ctrl+C to stop the test server.
echo.

"%~dp0venv\Scripts\python.exe" -m http.server %TEST_PORT% --bind 0.0.0.0

pause
