@echo off
:: Run the S3 Sleep Fix script as Administrator
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0fix-s3-sleep.ps1\"'"
