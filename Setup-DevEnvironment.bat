@echo off
:: ============================================================================
:: UAC ELEVATION - Elevate once at the start
:: ============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo      Setup Development Environment
echo        (Running as Administrator)
echo ==========================================
echo.

:: Prompt for S3 Sleep Fix script
echo [1/5] S3 Sleep Fix Script
echo This script applies fixes for S3 sleep issues.
set /p choice1="Do you want to run fix-s3-sleep.ps1? (y/n): "
if /i "%choice1%"=="y" (
    echo Running fix-s3-sleep.ps1...
    powershell -ExecutionPolicy Bypass -File "%~dp0fix-s3-sleep.ps1"
    echo.
) else (
    echo Skipped fix-s3-sleep.ps1
    echo.
)

:: Prompt for Enable AutoLogin script
echo [2/5] Enable AutoLogin Script
echo This script enables automatic login for the current user.
set /p choice2="Do you want to run Enable-AutoLogin.ps1? (y/n): "
if /i "%choice2%"=="y" (
    echo Running Enable-AutoLogin.ps1...
    powershell -ExecutionPolicy Bypass -File "%~dp0Enable-AutoLogin.ps1"
    echo.
) else (
    echo Skipped Enable-AutoLogin.ps1
    echo.
)

:: Prompt for Set UTC Clock script
echo [3/5] Set UTC Clock Script
echo This script configures Windows to use UTC for the hardware clock.
set /p choice3="Do you want to run Set-UTCClock.ps1? (y/n): "
if /i "%choice3%"=="y" (
    echo Running Set-UTCClock.ps1...
    powershell -ExecutionPolicy Bypass -File "%~dp0Set-UTCClock.ps1"
    echo.
) else (
    echo Skipped Set-UTCClock.ps1
    echo.
)

:: Prompt for Apple Magic Trackpad driver installation
echo [4/5] Apple Magic Trackpad Driver
echo This script installs the Mac Precision Touchpad driver for gesture support.
set /p choice4="Do you want to run Install-MacTrackpad.ps1? (y/n): "
if /i "%choice4%"=="y" (
    echo Running Install-MacTrackpad.ps1...
    powershell -ExecutionPolicy Bypass -File "%~dp0Install-MacTrackpad.ps1"
    echo.
) else (
    echo Skipped Install-MacTrackpad.ps1
    echo.
)

:: Prompt for Dev Environment setup
echo [5/5] Development Environment Setup
echo This script installs development tools (Git, VS Code, Node.js, etc.).
set /p choice5="Do you want to run Setup-DevEnvironment.ps1? (y/n): "
if /i "%choice5%"=="y" (
    echo Running Setup-DevEnvironment.ps1...
    powershell -ExecutionPolicy Bypass -File "%~dp0Setup-DevEnvironment.ps1"
    echo.
) else (
    echo Skipped Setup-DevEnvironment.ps1
    echo.
)

echo ==========================================
echo              All done!
echo ==========================================
pause
