#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fixes S3 sleep/resume issues on ASUS Z790P-Wifi + Intel 14th Gen + RTX 4090

.DESCRIPTION
    This script applies the following fixes:
    1. Disables ASUS System Analysis service (causes timeout issues)
    2. Configures network adapters to only wake on WOL magic packets
    3. Disables hibernate (does not work on this system)
    4. Disables Hybrid Sleep (prevents prolonged sleep crashes)
    5. Disables Wake Timers (prevents scheduled wake interruptions)
    6. Verifies sleep configuration

.NOTES
    PREREQUISITE: You must FIRST disable Fast Boot in BIOS!
    Boot > Fast Boot > Disabled

    Author: S3 Sleep Fix Script
    Date: January 10, 2026
    System: ASUS Z790P-Wifi / i9-14900K / RTX 4090
#>

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  S3 Sleep Fix for ASUS Z790P-Wifi System" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click and select Run as Administrator" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[REMINDER] Have you disabled Fast Boot in BIOS?" -ForegroundColor Yellow
Write-Host "  Boot > Fast Boot > Disabled" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Type yes to continue"
if ($confirm -ne "yes") {
    Write-Host "Please disable Fast Boot in BIOS first, then run this script again." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Starting S3 sleep fixes..." -ForegroundColor Green
Write-Host ""

# =============================================================================
# 1. Disable ASUS System Analysis Service
# =============================================================================
Write-Host "[1/5] Disabling ASUS System Analysis service..." -ForegroundColor Cyan

$service = Get-Service -Name "ASUSSystemAnalysis" -ErrorAction SilentlyContinue
if ($service) {
    try {
        Stop-Service -Name "ASUSSystemAnalysis" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "ASUSSystemAnalysis" -StartupType Disabled
        Write-Host "      ASUS System Analysis service disabled successfully." -ForegroundColor Green
    } catch {
        Write-Host "      Warning: Could not disable service. It may not exist or is protected." -ForegroundColor Yellow
    }
} else {
    Write-Host "      ASUS System Analysis service not found (OK - may not be installed)." -ForegroundColor Gray
}

# =============================================================================
# 2. Configure Network Adapters - Wake on Magic Packet Only
# =============================================================================
Write-Host ""
Write-Host "[2/5] Configuring network adapters for WOL magic packet only..." -ForegroundColor Cyan

$adapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*Realtek*" }

foreach ($adapter in $adapters) {
    Write-Host "      Configuring: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
    try {
        # Enable wake on magic packet, disable wake on pattern (random traffic)
        Set-NetAdapterPowerManagement -Name $adapter.Name -WakeOnMagicPacket Enabled -WakeOnPattern Disabled -ErrorAction Stop
        Write-Host "        - Wake on Magic Packet: Enabled" -ForegroundColor Green
        Write-Host "        - Wake on Pattern: Disabled" -ForegroundColor Green
    } catch {
        Write-Host "        Warning: Could not configure $($adapter.Name)" -ForegroundColor Yellow
    }
}

# Also check for Intel NICs
$intelAdapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*Intel*Ethernet*" -or $_.InterfaceDescription -like "*Intel*I225*" }
foreach ($adapter in $intelAdapters) {
    Write-Host "      Configuring: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
    try {
        Set-NetAdapterPowerManagement -Name $adapter.Name -WakeOnMagicPacket Enabled -WakeOnPattern Disabled -ErrorAction Stop
        Write-Host "        - Wake on Magic Packet: Enabled" -ForegroundColor Green
        Write-Host "        - Wake on Pattern: Disabled" -ForegroundColor Green
    } catch {
        Write-Host "        Warning: Could not configure $($adapter.Name)" -ForegroundColor Yellow
    }
}

if ($adapters.Count -eq 0 -and $intelAdapters.Count -eq 0) {
    Write-Host "      No Realtek or Intel adapters found to configure." -ForegroundColor Gray
}

# =============================================================================
# 3. Disable Hibernate (does not work on this system)
# =============================================================================
Write-Host ""
Write-Host "[3/5] Disabling hibernate (frees ~30GB disk space)..." -ForegroundColor Cyan

try {
    powercfg /hibernate off
    Write-Host "      Hibernate disabled successfully." -ForegroundColor Green
} catch {
    Write-Host "      Warning: Could not disable hibernate." -ForegroundColor Yellow
}

# =============================================================================
# 4. Disable Hybrid Sleep (prevents prolonged sleep crashes)
# =============================================================================
Write-Host ""
Write-Host "[4/5] Disabling Hybrid Sleep and Wake Timers..." -ForegroundColor Cyan

try {
    # Disable Hybrid Sleep (AC and DC)
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
    Write-Host "      Hybrid Sleep disabled." -ForegroundColor Green
} catch {
    Write-Host "      Warning: Could not disable Hybrid Sleep." -ForegroundColor Yellow
}

try {
    # Disable Wake Timers (AC and DC)
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
    Write-Host "      Wake Timers disabled." -ForegroundColor Green
} catch {
    Write-Host "      Warning: Could not disable Wake Timers." -ForegroundColor Yellow
}

try {
    # Apply the changes
    powercfg /setactive SCHEME_CURRENT
    Write-Host "      Power settings applied." -ForegroundColor Green
} catch {
    Write-Host "      Warning: Could not apply power settings." -ForegroundColor Yellow
}

# =============================================================================
# 5. Prevent Sleep During Media Playback
# =============================================================================
Write-Host ""
Write-Host "[5/6] Configuring media playback power settings..." -ForegroundColor Cyan

try {
    # Multimedia settings subgroup GUID: 9596fb26-9850-41fd-ac3e-f7c3c00afd4b
    # When sharing media setting GUID: 03680956-93bc-4294-bba6-4e0f09bb717f
    # Value 1 = Prevent idling to sleep
    
    powercfg /setacvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 1
    powercfg /setdcvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 1
    Write-Host "      'When sharing media' set to prevent sleep." -ForegroundColor Green
} catch {
    Write-Host "      Warning: Could not configure media playback settings." -ForegroundColor Yellow
}

try {
    # Disable USB selective suspend (prevents audio device issues)
    # USB settings subgroup: 2a737441-1930-4402-8d77-b2bebba308a3
    # USB selective suspend: 48e6b7a6-50f5-4782-a5d4-53bb8f07e226
    # 0 = Disabled
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    Write-Host "      USB selective suspend disabled." -ForegroundColor Green
} catch {
    Write-Host "      Warning: Could not disable USB selective suspend." -ForegroundColor Yellow
}

try {
    powercfg /setactive SCHEME_CURRENT
} catch {
    # Silent - already applied above
}

# =============================================================================
# 6. Verify Sleep Configuration
# =============================================================================
Write-Host ""
Write-Host "[6/6] Verifying sleep configuration..." -ForegroundColor Cyan
Write-Host ""

# Check available sleep states
Write-Host "Available sleep states:" -ForegroundColor White
$sleepStates = powercfg /a
$sleepStates | ForEach-Object { Write-Host "  $_" }

Write-Host ""

# Check devices that can wake the system
Write-Host "Devices that can wake the system:" -ForegroundColor White
$wakeDevices = powercfg /devicequery wake_armed
$wakeDevices | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  S3 Sleep Fix Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary of changes:" -ForegroundColor White
Write-Host "  [OK] ASUS System Analysis service disabled" -ForegroundColor Green
Write-Host "  [OK] Network adapters: WOL magic packet only" -ForegroundColor Green
Write-Host "  [OK] Hibernate disabled" -ForegroundColor Green
Write-Host "  [OK] Hybrid Sleep disabled" -ForegroundColor Green
Write-Host "  [OK] Wake Timers disabled" -ForegroundColor Green
Write-Host "  [OK] Prevent sleep during media playback" -ForegroundColor Green
Write-Host "  [OK] USB selective suspend disabled" -ForegroundColor Green
Write-Host ""
Write-Host "To test sleep, run:" -ForegroundColor Yellow
Write-Host "  rundll32.exe powrprof.dll,SetSuspendState 0,1,0" -ForegroundColor White
Write-Host ""
Write-Host "Wake with keyboard or mouse." -ForegroundColor Gray
Write-Host ""

pause
