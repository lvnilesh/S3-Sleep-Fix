@echo off
:: Run Mac Trackpad Driver Installer as Administrator
:: Double-click this file to install

echo ==========================================
echo  Apple Magic Trackpad Driver Installer
echo ==========================================
echo.

:: Check for admin rights and request if needed
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Run the PowerShell installer script
powershell -ExecutionPolicy Bypass -File "%~dp0Install-MacTrackpad.ps1"

pause
