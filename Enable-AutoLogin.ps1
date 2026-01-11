#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables Windows 11 automatic login on boot and resume from sleep.
.DESCRIPTION
    This script configures Windows to automatically log in without requiring
    a password on boot or when resuming from sleep/hibernate.
.NOTES
    Must be run as Administrator
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [securestring]$Password
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows 11 Auto-Login Configuration  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Enable the "Users must enter a user name and password" checkbox in netplwiz
Write-Host "[1/4] Enabling password checkbox in User Accounts dialog..." -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
try {
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "DevicePasswordLessBuildVersion" -Value 0 -Type DWord -Force
    Write-Host "  [OK] Registry key set successfully" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not set registry key: $_" -ForegroundColor Yellow
}

# Step 2: Get credentials if not provided
if (-not $Username) {
    $Username = Read-Host "Enter username for auto-login (e.g., $env:USERNAME)"
    if ([string]::IsNullOrWhiteSpace($Username)) {
        $Username = $env:USERNAME
        Write-Host "  Using current user: $Username" -ForegroundColor Cyan
    }
}

if (-not $Password) {
    $Password = Read-Host "Enter password for '$Username'" -AsSecureString
}

# Convert SecureString to plain text for registry storage
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

# Step 3: Configure auto-login via registry
Write-Host "[2/4] Configuring auto-login in registry..." -ForegroundColor Yellow
$winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
try {
    Set-ItemProperty -Path $winlogonPath -Name "AutoAdminLogon" -Value "1" -Type String -Force
    Set-ItemProperty -Path $winlogonPath -Name "DefaultUserName" -Value $Username -Type String -Force
    Set-ItemProperty -Path $winlogonPath -Name "DefaultPassword" -Value $PlainPassword -Type String -Force
    
    # Set domain if it's a domain account, otherwise use computer name
    $domain = $env:USERDOMAIN
    if ($Username -match "\\") {
        $domain = $Username.Split("\")[0]
        $Username = $Username.Split("\")[1]
    }
    Set-ItemProperty -Path $winlogonPath -Name "DefaultDomainName" -Value $domain -Type String -Force
    
    Write-Host "  [OK] Auto-login configured for user: $Username" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to configure auto-login: $_" -ForegroundColor Red
}

# Clear the password from memory
$PlainPassword = $null
[System.GC]::Collect()

# Step 4: Disable password requirement on resume from sleep
Write-Host "[3/4] Disabling sign-in requirement after sleep..." -ForegroundColor Yellow
try {
    # Using powercfg to disable console lock on resume
    & powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 2>$null
    & powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 2>$null
    & powercfg /SETACTIVE SCHEME_CURRENT 2>$null
    
    # Also set via registry for good measure
    $powerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"
    if (-not (Test-Path $powerPath)) {
        New-Item -Path $powerPath -Force | Out-Null
    }
    Set-ItemProperty -Path $powerPath -Name "ACSettingIndex" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $powerPath -Name "DCSettingIndex" -Value 0 -Type DWord -Force
    
    Write-Host "  [OK] Sign-in after sleep disabled" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not fully configure sleep settings: $_" -ForegroundColor Yellow
}

# Step 5: Disable lock screen (optional, improves boot time)
Write-Host "[4/4] Configuring lock screen settings..." -ForegroundColor Yellow
try {
    $personalizePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    if (-not (Test-Path $personalizePath)) {
        New-Item -Path $personalizePath -Force | Out-Null
    }
    Set-ItemProperty -Path $personalizePath -Name "NoLockScreen" -Value 1 -Type DWord -Force
    Write-Host "  [OK] Lock screen disabled" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not disable lock screen: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Complete!              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  - Auto-login enabled for: $Username" -ForegroundColor White
Write-Host "  - Sign-in after sleep: Disabled" -ForegroundColor White
Write-Host "  - Lock screen: Disabled" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: Restart your computer for changes to take full effect." -ForegroundColor Yellow
Write-Host ""
Write-Host "SECURITY WARNING:" -ForegroundColor Red
Write-Host "  Your password is stored in the registry (not encrypted)." -ForegroundColor Red
Write-Host "  Only use this on physically secure devices!" -ForegroundColor Red
Write-Host ""

$restart = Read-Host "Would you like to restart now? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-Host "Restarting in 5 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
