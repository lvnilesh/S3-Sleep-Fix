#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures Windows to use UTC for the hardware clock (dual-boot compatibility).

.DESCRIPTION
    This script sets the RealTimeIsUniversal registry key so Windows interprets
    the hardware clock as UTC. This fixes clock sync issues in dual-boot systems
    with Linux. The display timezone is set to Pacific Time.

.NOTES
    Requires Administrator privileges.
    A restart is required for changes to take effect.
#>

Write-Host "Configuring Windows for UTC hardware clock..." -ForegroundColor Cyan

# Set the registry key to tell Windows the hardware clock is UTC
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
$regName = "RealTimeIsUniversal"

try {
    Set-ItemProperty -Path $regPath -Name $regName -Value 1 -Type DWord -ErrorAction Stop
    Write-Host "[OK] RealTimeIsUniversal registry key set to 1" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to set registry key: $_" -ForegroundColor Red
    exit 1
}

# Set timezone to Pacific Time
try {
    Set-TimeZone -Id "Pacific Standard Time" -ErrorAction Stop
    Write-Host "[OK] Timezone set to Pacific Standard Time" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to set timezone: $_" -ForegroundColor Red
    exit 1
}

# Verify settings
Write-Host "`nCurrent Configuration:" -ForegroundColor Cyan
$currentValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
Write-Host "  RealTimeIsUniversal: $($currentValue.RealTimeIsUniversal)"
$tz = Get-TimeZone
Write-Host "  Timezone: $($tz.Id) ($($tz.DisplayName))"

Write-Host "`n[!] Please restart your computer for changes to take effect." -ForegroundColor Yellow
