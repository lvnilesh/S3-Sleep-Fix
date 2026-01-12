#Requires -Version 5.1
<#
.SYNOPSIS
    Automated setup script for development environment and applications.
.DESCRIPTION
    This script installs common development tools and applications with UAC elevation.
    - Git
    - VS Code
    - Google Chrome
    - Apple Music
    - WSL (Windows Subsystem for Linux)
    - Bitwarden extension for Edge and Chrome
.NOTES
    Run this script from PowerShell. It will self-elevate if not running as Administrator.
#>

# ============================================================================
# UAC ELEVATION
# ============================================================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

Write-Host "Running with administrator privileges." -ForegroundColor Green

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Step {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor White
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$PackageName
    )
    
    # Check if already installed first (using --exact and --disable-interactivity for speed)
    Write-Info "Checking if $PackageName is already installed..."
    $installed = winget list --id $PackageId --exact --disable-interactivity 2>&1
    if ($LASTEXITCODE -eq 0 -and $installed -notmatch "No installed package") {
        Write-Success "$PackageName is already installed. Skipping."
        return $true
    }
    
    Write-Info "Installing $PackageName..."
    
    try {
        $result = winget install --id $PackageId --accept-source-agreements --accept-package-agreements --silent 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "already installed") {
            Write-Success "$PackageName installed successfully."
            return $true
        } else {
            Write-Warning "$PackageName installation may have issues. Please verify manually."
            return $false
        }
    } catch {
        Write-Error "Failed to install $PackageName : $_"
        return $false
    }
}

function Install-StoreApp {
    param(
        [string]$StoreId,
        [string]$AppxName,
        [string]$PackageName
    )
    
    # Use Get-AppxPackage for instant detection of Store apps
    Write-Info "Checking if $PackageName is already installed..."
    $installed = Get-AppxPackage -Name "*$AppxName*" -ErrorAction SilentlyContinue
    if ($installed) {
        Write-Success "$PackageName is already installed. Skipping."
        return $true
    }
    
    Write-Info "Installing $PackageName from Microsoft Store..."
    
    try {
        $result = winget install --id $StoreId --source msstore --accept-source-agreements --accept-package-agreements --silent 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "already installed") {
            Write-Success "$PackageName installed successfully."
            return $true
        } else {
            Write-Warning "$PackageName installation may have issues. Please verify manually."
            return $false
        }
    } catch {
        Write-Error "Failed to install $PackageName : $_"
        return $false
    }
}

# ============================================================================
# ENSURE WINGET IS AVAILABLE
# ============================================================================
Write-Step "Checking for Windows Package Manager (winget)"

if (-not (Test-CommandExists "winget")) {
    Write-Error "winget is not installed. Please install App Installer from the Microsoft Store."
    Write-Info "You can also download it from: https://github.com/microsoft/winget-cli/releases"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Success "winget is available."

# ============================================================================
# INSTALL APPLICATIONS
# ============================================================================

# --- Git ---
Write-Step "Installing Git"
Install-WingetPackage -PackageId "Git.Git" -PackageName "Git"

# --- VS Code ---
Write-Step "Installing Visual Studio Code"
Install-WingetPackage -PackageId "Microsoft.VisualStudioCode" -PackageName "Visual Studio Code"

# --- Google Chrome ---
Write-Step "Installing Google Chrome"
Install-WingetPackage -PackageId "Google.Chrome" -PackageName "Google Chrome"

# --- Apple Music (Microsoft Store) ---
Write-Step "Installing Apple Music"
Install-StoreApp -StoreId "9PFHDD62MXS1" -AppxName "AppleInc.AppleMusic" -PackageName "Apple Music"

# ============================================================================
# INSTALL WSL
# ============================================================================
Write-Step "Installing Windows Subsystem for Linux (WSL)"

try {
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "WSL is already installed."
    } else {
        Write-Info "Installing WSL with default Ubuntu distribution..."
        wsl --install --no-launch
        Write-Success "WSL installation initiated. A restart may be required."
        $script:RestartRequired = $true
    }
} catch {
    Write-Info "Installing WSL..."
    wsl --install --no-launch
    Write-Success "WSL installation initiated. A restart may be required."
    $script:RestartRequired = $true
}

# ============================================================================
# INSTALL BITWARDEN BROWSER EXTENSIONS
# ============================================================================
Write-Step "Installing Bitwarden Extension for Edge and Chrome"

# Bitwarden Extension IDs
$bitwardenChromeId = "nngceckbapebfimnlniiiahkandclblb"
$bitwardenEdgeId = "jbkfoedolllekgbhcbcoahefnbanhhlh"

# --- Chrome Extension (via Registry) ---
Write-Info "Configuring Bitwarden extension for Google Chrome..."

$chromeExtRegPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
if (-not (Test-Path $chromeExtRegPath)) {
    New-Item -Path $chromeExtRegPath -Force | Out-Null
}

# Find next available index
$existingValues = Get-ItemProperty -Path $chromeExtRegPath -ErrorAction SilentlyContinue
$nextIndex = 1
if ($existingValues) {
    $indices = $existingValues.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | ForEach-Object { [int]$_.Name }
    if ($indices) {
        $nextIndex = ($indices | Measure-Object -Maximum).Maximum + 1
    }
}

$chromeExtValue = "$bitwardenChromeId;https://clients2.google.com/service/update2/crx"
$existingChromeExt = $false
if ($existingValues) {
    $existingChromeExt = $existingValues.PSObject.Properties | 
        Where-Object { $_.Name -match '^\d+$' -and $_.Value -like "*$bitwardenChromeId*" }
}

if (-not $existingChromeExt) {
    Set-ItemProperty -Path $chromeExtRegPath -Name $nextIndex -Value $chromeExtValue
    Write-Success "Bitwarden extension configured for Chrome (will install on next launch)."
} else {
    Write-Info "Bitwarden extension already configured for Chrome."
}

# --- Edge Extension (via Registry) ---
Write-Info "Configuring Bitwarden extension for Microsoft Edge..."

$edgeExtRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
if (-not (Test-Path $edgeExtRegPath)) {
    New-Item -Path $edgeExtRegPath -Force | Out-Null
}

# Find next available index
$existingValues = Get-ItemProperty -Path $edgeExtRegPath -ErrorAction SilentlyContinue
$nextIndex = 1
if ($existingValues) {
    $indices = $existingValues.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | ForEach-Object { [int]$_.Name }
    if ($indices) {
        $nextIndex = ($indices | Measure-Object -Maximum).Maximum + 1
    }
}

$edgeExtValue = "$bitwardenEdgeId;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
$existingEdgeExt = $false
if ($existingValues) {
    $existingEdgeExt = $existingValues.PSObject.Properties | 
        Where-Object { $_.Name -match '^\d+$' -and $_.Value -like "*$bitwardenEdgeId*" }
}

if (-not $existingEdgeExt) {
    Set-ItemProperty -Path $edgeExtRegPath -Name $nextIndex -Value $edgeExtValue
    Write-Success "Bitwarden extension configured for Edge (will install on next launch)."
} else {
    Write-Info "Bitwarden extension already configured for Edge."
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Step "Installation Summary"

Write-Host "`nApplications processed:" -ForegroundColor White
Write-Host "  - Git" -ForegroundColor Gray
Write-Host "  - Visual Studio Code" -ForegroundColor Gray
Write-Host "  - Google Chrome" -ForegroundColor Gray
Write-Host "  - Apple Music" -ForegroundColor Gray
Write-Host "  - Windows Subsystem for Linux (WSL)" -ForegroundColor Gray

Write-Host "`nBrowser Extensions configured:" -ForegroundColor White
Write-Host "  - Bitwarden for Chrome" -ForegroundColor Gray
Write-Host "  - Bitwarden for Edge" -ForegroundColor Gray

if ($script:RestartRequired) {
    Write-Host "`n" -NoNewline
    Write-Warning "A system restart is required to complete WSL installation."
    $restart = Read-Host "Would you like to restart now? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Info "Restarting in 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}

Write-Host "`n" -NoNewline
Write-Success "Setup complete!"
Write-Host "`nNote: Browser extensions will be installed when you next open Chrome/Edge." -ForegroundColor Yellow

# ============================================================================
# ADD MORE INSTALLATIONS BELOW
# ============================================================================
# Examples:
# Install-WingetPackage -PackageId "Discord.Discord" -PackageName "Discord"
# Install-WingetPackage -PackageId "Spotify.Spotify" -PackageName "Spotify"
# Install-WingetPackage -PackageId "SlackTechnologies.Slack" -PackageName "Slack"
# Install-WingetPackage -PackageId "Notion.Notion" -PackageName "Notion"
# Install-WingetPackage -PackageId "Docker.DockerDesktop" -PackageName "Docker Desktop"
# Install-WingetPackage -PackageId "Microsoft.PowerToys" -PackageName "PowerToys"

Read-Host "`nPress Enter to exit"
