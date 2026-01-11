#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs Mac Precision Touchpad driver for Apple Magic Trackpad on Windows.
.DESCRIPTION
    Downloads and installs the Mac Precision Touchpad driver to enable full
    gesture support for Apple Magic Trackpad on Windows.
.NOTES
    Run this script as Administrator.
    After installation, restart your PC for changes to take effect.
#>

param(
    [switch]$SkipReboot
)

$ErrorActionPreference = "Stop"

# Configuration
$DownloadPath = "$env:TEMP\mac-precision-touchpad"
$DriverUrl = "https://github.com/imbushuo/mac-precision-touchpad/releases/download/2105-3979/Drivers-amd64-ReleaseMSSigned.zip"
$ZipFile = "$DownloadPath\driver.zip"
$DriverFolder = "$DownloadPath\driver\drivers\amd64"

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    Write-Host "`n[$Step/$Total] " -NoNewline -ForegroundColor Yellow
    Write-Host $Message -ForegroundColor White
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

# Banner
Write-Host ""
Write-Host "  =========================================================" -ForegroundColor Magenta
Write-Host "       Apple Magic Trackpad - Windows Driver Installer     " -ForegroundColor Magenta
Write-Host "           Mac Precision Touchpad Driver v2105             " -ForegroundColor Magenta
Write-Host "  =========================================================" -ForegroundColor Magenta
Write-Host ""

# Check for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Create download directory
Write-Step -Step 1 -Total 5 -Message "Creating download directory"
if (Test-Path $DownloadPath) {
    Remove-Item -Path $DownloadPath -Recurse -Force
}
New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
Write-Status "Created: $DownloadPath" "Green"

# Step 2: Download driver
Write-Step -Step 2 -Total 5 -Message "Downloading Mac Precision Touchpad driver"
Write-Status "URL: $DriverUrl"
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $DriverUrl -OutFile $ZipFile -UseBasicParsing
    $ProgressPreference = 'Continue'
    $fileSize = [math]::Round((Get-Item $ZipFile).Length / 1KB, 2)
    Write-Status "Downloaded: $fileSize KB" "Green"
} catch {
    Write-Host "ERROR: Failed to download driver!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 3: Extract driver
Write-Step -Step 3 -Total 5 -Message "Extracting driver files"
try {
    Expand-Archive -Path $ZipFile -DestinationPath "$DownloadPath\driver" -Force
    $files = Get-ChildItem -Path $DriverFolder -File
    Write-Status "Extracted $($files.Count) files:" "Green"
    $files | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
} catch {
    Write-Host "ERROR: Failed to extract driver!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 4: Install driver to Windows driver store
Write-Step -Step 4 -Total 5 -Message "Installing driver to Windows driver store"
$infPath = Join-Path $DriverFolder "AmtPtpDevice.inf"
try {
    $pnpResult = & pnputil.exe /add-driver "$infPath" /install 2>&1
    $pnpResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    
    if ($LASTEXITCODE -eq 0 -or $pnpResult -match "successfully") {
        Write-Status "Driver installed successfully!" "Green"
    } else {
        Write-Status "Driver may already be installed or needs manual update" "Yellow"
    }
} catch {
    Write-Host "ERROR: Failed to install driver!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Step 5: Find and update Apple Trackpad device
Write-Step -Step 5 -Total 5 -Message "Searching for Apple Trackpad device"

# Look for Apple trackpad in various device classes
$trackpadFound = $false
$deviceClasses = @(
    "Bluetooth",
    "Mouse", 
    "HIDClass"
)

$appleDevices = Get-PnpDevice | Where-Object { 
    $_.FriendlyName -match "Magic Trackpad|Apple.*Trackpad|Trackpad" -or 
    $_.Manufacturer -match "Apple" 
} | Select-Object -First 5

if ($appleDevices) {
    Write-Status "Found Apple device(s):" "Green"
    $appleDevices | ForEach-Object {
        Write-Host "    - $($_.FriendlyName) [$($_.Status)]" -ForegroundColor Gray
        Write-Host "      Class: $($_.Class), InstanceId: $($_.InstanceId.Substring(0, [Math]::Min(50, $_.InstanceId.Length)))..." -ForegroundColor DarkGray
    }
    $trackpadFound = $true
} else {
    Write-Status "Apple Trackpad not detected - make sure it is paired via Bluetooth" "Yellow"
}

# Summary and next steps
Write-Host ""
Write-Host "  =========================================================" -ForegroundColor Green
Write-Host "                   Installation Complete!                   " -ForegroundColor Green
Write-Host "  =========================================================" -ForegroundColor Green
Write-Host ""

Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Open Device Manager (devmgmt.msc)" -ForegroundColor White
Write-Host "  2. Find your Apple Trackpad under Bluetooth or Mice" -ForegroundColor White
Write-Host "  3. Right-click > Update driver > Browse my computer" -ForegroundColor White
Write-Host "  4. Select Let me pick from a list" -ForegroundColor White
Write-Host "  5. Choose Mac Precision Touchpad" -ForegroundColor White
Write-Host "  6. Restart your PC" -ForegroundColor White
Write-Host ""

# Offer to open Device Manager
$openDevMgr = Read-Host "Open Device Manager now? (Y/n)"
if ($openDevMgr -ne "n" -and $openDevMgr -ne "N") {
    Start-Process "devmgmt.msc"
}

# Offer to restart
if (-not $SkipReboot) {
    Write-Host ""
    $restart = Read-Host "Restart computer now? (y/N)"
    if ($restart -eq "y" -or $restart -eq "Y") {
        Write-Status "Restarting in 5 seconds..." "Yellow"
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    }
}

Write-Host ""
Write-Host "After restart, configure gestures at:" -ForegroundColor Cyan
Write-Host "  Settings > Bluetooth & devices > Touchpad" -ForegroundColor White
Write-Host ""

# Cleanup temp files
Write-Status "Cleaning up temporary files..."
Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue
Write-Status "Done!" "Green"
