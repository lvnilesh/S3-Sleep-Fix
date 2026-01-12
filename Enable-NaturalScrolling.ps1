#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures scrolling: Natural for Apple Trackpad, Windows-style for Logitech mouse.
.DESCRIPTION
    Sets Apple Magic Trackpad to Mac-style natural scrolling (swipe up = scroll down)
    while keeping Logitech mice on Windows default scrolling (scroll up = scroll up).
.NOTES
    Run this script as Administrator.
    Requires a reboot for changes to take effect.
#>

param(
    [switch]$Revert  # Use -Revert to restore Windows default scrolling for all devices
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $Color
}

# Banner
Write-Host ""
Write-Host "  =========================================================" -ForegroundColor Magenta
Write-Host "    Trackpad Natural + Logitech Mouse Windows Scrolling    " -ForegroundColor Magenta
Write-Host "  =========================================================" -ForegroundColor Magenta
Write-Host ""

# Check for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# FlipFlopWheel = 0 means normal Windows scrolling
# FlipFlopWheel = 1 means natural/Mac-style scrolling (inverted)

if ($Revert) {
    Write-Status "REVERT MODE: Setting ALL devices to Windows default scrolling"
} else {
    Write-Status "Setting Apple Trackpad: Natural (Mac-style)"
    Write-Status "Setting Logitech Mouse: Windows default"
}
Write-Host ""

# Registry path for mouse/trackpad devices
$mouseRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\HID"

$appleDevicesUpdated = 0
$logitechDevicesUpdated = 0

# VID_046D = Logitech
# VID_004C = Apple
$logitechVID = "046D"
$appleVID = "05AC"  # Apple's actual VID is 05AC (not 004C)

# FIRST: Set Apple trackpad devices to natural scrolling (FlipFlopWheel = 1)
Write-Status "Finding Apple trackpad devices (VID_05AC and VID_004C)..."
$appleDevices = Get-ChildItem $mouseRegPath -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match "VID_05AC|VID_004C|05AC|004C" }

foreach ($device in $appleDevices) {
    $paramsPath = Join-Path $device.PSPath "Device Parameters"
    if (Test-Path $paramsPath) {
        try {
            $appleScrollValue = if ($Revert) { 0 } else { 1 }
            New-ItemProperty -Path $paramsPath -Name "FlipFlopWheel" -Value $appleScrollValue -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            New-ItemProperty -Path $paramsPath -Name "FlipFlopHScroll" -Value $appleScrollValue -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            $appleDevicesUpdated++
            Write-Host "    [APPLE] FlipFlopWheel=$appleScrollValue : $($device.PSChildName)" -ForegroundColor Green
        } catch {
            Write-Host "    [APPLE] Failed: $($device.PSChildName)" -ForegroundColor Red
        }
    }
}

# SECOND: Set Logitech mouse devices to Windows default scrolling (FlipFlopWheel = 0)
Write-Status "Finding Logitech mouse devices (VID_046D)..."
$logitechDevices = Get-ChildItem $mouseRegPath -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match "VID_046D|046D" }

foreach ($device in $logitechDevices) {
    $paramsPath = Join-Path $device.PSPath "Device Parameters"
    if (Test-Path $paramsPath) {
        try {
            # Always set Logitech to Windows default (0) unless in revert mode
            $logitechScrollValue = 0
            New-ItemProperty -Path $paramsPath -Name "FlipFlopWheel" -Value $logitechScrollValue -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            New-ItemProperty -Path $paramsPath -Name "FlipFlopHScroll" -Value $logitechScrollValue -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            $logitechDevicesUpdated++
            Write-Host "    [LOGITECH] FlipFlopWheel=$logitechScrollValue : $($device.PSChildName)" -ForegroundColor Yellow
        } catch {
            Write-Host "    [LOGITECH] Failed: $($device.PSChildName)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Status "Updated $appleDevicesUpdated Apple device entries (Natural scrolling)" "Green"
Write-Status "Updated $logitechDevicesUpdated Logitech device entries (Windows scrolling)" "Yellow"

Write-Host ""
Write-Host "  =========================================================" -ForegroundColor Green
Write-Host "                   Configuration Complete!                  " -ForegroundColor Green  
Write-Host "  =========================================================" -ForegroundColor Green
Write-Host ""

if (-not $Revert) {
    Write-Host "  Apple Trackpad: Natural scrolling (Mac-style)" -ForegroundColor Green
    Write-Host "  Logitech Mouse: Windows default scrolling" -ForegroundColor Yellow
} else {
    Write-Host "  All devices: Windows default scrolling" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Rebooting is REQUIRED for changes to take effect." -ForegroundColor Red
Write-Host ""

if (-not $Revert) {
    Write-Host "  To revert ALL devices to Windows default, run:" -ForegroundColor Cyan
    Write-Host "    .\Enable-NaturalScrolling.ps1 -Revert" -ForegroundColor White
} else {
    Write-Host "  To enable split scrolling again, run:" -ForegroundColor Cyan
    Write-Host "    .\Enable-NaturalScrolling.ps1" -ForegroundColor White
}

Write-Host ""

# Display current state summary
Write-Host "  =========================================================" -ForegroundColor Cyan
Write-Host "              Current FlipFlop Scroll Settings              " -ForegroundColor Cyan
Write-Host "  =========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  [APPLE DEVICES]" -ForegroundColor Green
Write-Host "  ---------------" -ForegroundColor Green
$appleCurrentDevices = Get-ChildItem $mouseRegPath -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match "VID_05AC|VID_004C|05AC|004C" }
$appleFound = $false
foreach ($device in $appleCurrentDevices) {
    $paramsPath = Join-Path $device.PSPath "Device Parameters"
    if (Test-Path $paramsPath) {
        $props = Get-ItemProperty $paramsPath -ErrorAction SilentlyContinue
        if ($null -ne $props.FlipFlopWheel) {
            $appleFound = $true
            $wheelDir = if ($props.FlipFlopWheel -eq 1) { "Natural (Mac)" } else { "Windows Default" }
            $hScrollDir = if ($props.FlipFlopHScroll -eq 1) { "Natural (Mac)" } else { "Windows Default" }
            Write-Host "    $($device.PSChildName)" -ForegroundColor White
            Write-Host "      FlipFlopWheel:   $($props.FlipFlopWheel) - $wheelDir" -ForegroundColor Gray
            Write-Host "      FlipFlopHScroll: $($props.FlipFlopHScroll) - $hScrollDir" -ForegroundColor Gray
        }
    }
}
if (-not $appleFound) {
    Write-Host "    No Apple devices with FlipFlop settings found" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  [LOGITECH DEVICES]" -ForegroundColor Yellow
Write-Host "  ------------------" -ForegroundColor Yellow
$logitechCurrentDevices = Get-ChildItem $mouseRegPath -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match "VID_046D|046D" }
$logitechFound = $false
foreach ($device in $logitechCurrentDevices) {
    $paramsPath = Join-Path $device.PSPath "Device Parameters"
    if (Test-Path $paramsPath) {
        $props = Get-ItemProperty $paramsPath -ErrorAction SilentlyContinue
        if ($null -ne $props.FlipFlopWheel) {
            $logitechFound = $true
            $wheelDir = if ($props.FlipFlopWheel -eq 1) { "Natural (Mac)" } else { "Windows Default" }
            $hScrollDir = if ($props.FlipFlopHScroll -eq 1) { "Natural (Mac)" } else { "Windows Default" }
            Write-Host "    $($device.PSChildName)" -ForegroundColor White
            Write-Host "      FlipFlopWheel:   $($props.FlipFlopWheel) - $wheelDir" -ForegroundColor Gray
            Write-Host "      FlipFlopHScroll: $($props.FlipFlopHScroll) - $hScrollDir" -ForegroundColor Gray
        }
    }
}
if (-not $logitechFound) {
    Write-Host "    No Logitech devices with FlipFlop settings found" -ForegroundColor DarkGray
}

Write-Host ""

Write-Status "Done!"

Write-Host ""
Read-Host "Press Enter to exit" "Green"
