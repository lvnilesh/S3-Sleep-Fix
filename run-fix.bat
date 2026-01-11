@echo off
echo ==========================================
echo        S3 Sleep Fix Script Runner
echo ==========================================
echo.

:: Prompt for S3 Sleep Fix script
echo [1/3] S3 Sleep Fix Script
echo This script applies fixes for S3 sleep issues.
set /p choice1="Do you want to run fix-s3-sleep.ps1? (y/n): "
if /i "%choice1%"=="y" (
    echo Running fix-s3-sleep.ps1...
    powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0fix-s3-sleep.ps1\"' -Wait"
    echo.
) else (
    echo Skipped fix-s3-sleep.ps1
    echo.
)

:: Prompt for Enable AutoLogin script
echo [2/3] Enable AutoLogin Script
echo This script enables automatic login for the current user.
set /p choice2="Do you want to run Enable-AutoLogin.ps1? (y/n): "
if /i "%choice2%"=="y" (
    echo Running Enable-AutoLogin.ps1...
    powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Enable-AutoLogin.ps1\"' -Wait"
    echo.
) else (
    echo Skipped Enable-AutoLogin.ps1
    echo.
)

:: Prompt for Set UTC Clock script
echo [3/3] Set UTC Clock Script
echo This script configures Windows to use UTC for the hardware clock.
set /p choice3="Do you want to run Set-UTCClock.ps1? (y/n): "
if /i "%choice3%"=="y" (
    echo Running Set-UTCClock.ps1...
    powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Set-UTCClock.ps1\"' -Wait"
    echo.
) else (
    echo Skipped Set-UTCClock.ps1
    echo.
)

echo ==========================================
echo              All done!
echo ==========================================
pause
