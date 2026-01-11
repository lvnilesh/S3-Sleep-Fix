@echo off
:: Run the S3 Sleep Fix script as Administrator
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0fix-s3-sleep.ps1\"'"

:: Run the Enable AutoLogin script as Administrator
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Enable-AutoLogin.ps1\"'"

:: Run the Set UTC Clock script as Administrator
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Set-UTCClock.ps1\"'"
