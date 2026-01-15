# Windows System Setup & S3 Sleep Fix

A collection of PowerShell scripts to configure a fresh Windows 11 installation, including S3 sleep fixes for ASUS Z790P-Wifi + Intel 14th Gen + RTX 4090.

## Quick Start

**Double-click `Setup-DevEnvironment.bat`** and follow the interactive prompts to run any or all of the included scripts.

## System Configuration

| Component | Details |
|-----------|---------|
| **Motherboard** | ASUS Z790P-Wifi |
| **CPU** | Intel Core i9-14900K |
| **GPU** | NVIDIA GeForce RTX 4090 |
| **RAM** | 64GB DDR5 |
| **OS** | Windows 11 |

## Included Scripts

### 1. S3 Sleep Fix (`fix-s3-sleep.ps1`)

Fixes S3 sleep/resume issues on ASUS Z790 systems:

- Disables ASUS System Analysis service (causes timeout issues)
- Configures network adapters to only wake on WOL magic packets
- Disables hibernate (frees ~30GB disk space)
- Disables Hybrid Sleep (prevents prolonged sleep crashes)
- Disables Wake Timers (prevents scheduled wake interruptions)
- Configures media playback to prevent idle sleep
- Disables USB selective suspend

**PREREQUISITE:** Disable Fast Boot in BIOS first (Boot > Fast Boot > Disabled)

### 2. Enable Auto-Login (`Enable-AutoLogin.ps1`)

Configures Windows to automatically log in without requiring a password:

- Enables the password checkbox in User Accounts dialog (netplwiz)
- Sets auto-login credentials in registry
- Disables sign-in requirement after sleep/resume

### 3. Set UTC Clock (`Set-UTCClock.ps1`)

Configures Windows for dual-boot compatibility with Linux:

- Sets `RealTimeIsUniversal` registry key so Windows interprets hardware clock as UTC
- Sets timezone to Pacific Standard Time
- Requires restart to take effect

### 4. Apple Magic Trackpad Driver (`Install-MacTrackpad.ps1`)

Installs the Mac Precision Touchpad driver for full gesture support:

- Downloads driver from [mac-precision-touchpad](https://github.com/imbushuo/mac-precision-touchpad) GitHub releases
- Installs driver to Windows driver store via pnputil
- Provides instructions for manual device driver update

### 5. Development Environment Setup (`Setup-DevEnvironment.ps1`)

Installs common development tools via winget:

- **Git** - Version control
- **Visual Studio Code** - Code editor
- **Google Chrome** - Web browser
- **Apple Music** - From Microsoft Store
- **WSL (Windows Subsystem for Linux)** - With Ubuntu
- **Bitwarden** - Password manager extension for Edge/Chrome
- **Node.js LTS** - JavaScript runtime
- Configures Windows settings (file extensions, hidden files, dark mode)

## Usage

### Interactive Mode (Recommended)

Double-click `Setup-DevEnvironment.bat` - you'll be prompted to run each script:

```
[1/5] S3 Sleep Fix Script
[2/5] Enable AutoLogin Script
[3/5] Set UTC Clock Script
[4/5] Apple Magic Trackpad Driver
[5/5] Development Environment Setup
```

### Run Individual Scripts

From an elevated PowerShell:

```powershell
# S3 Sleep Fix
powershell -ExecutionPolicy Bypass -File "fix-s3-sleep.ps1"

# Enable Auto-Login
powershell -ExecutionPolicy Bypass -File "Enable-AutoLogin.ps1"

# Set UTC Clock
powershell -ExecutionPolicy Bypass -File "Set-UTCClock.ps1"

# Install Trackpad Driver
powershell -ExecutionPolicy Bypass -File "Install-MacTrackpad.ps1"

# Dev Environment Setup
powershell -ExecutionPolicy Bypass -File "Setup-DevEnvironment.ps1"
```

## S3 Sleep Troubleshooting

### Check what woke the system
```powershell
powercfg /lastwake
```

### Check available sleep states
```powershell
powercfg /a
```

### Check for unexpected shutdowns
```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; Id=41,6008} -MaxEvents 5
```

### View sleep/wake history
```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 5 | Format-List TimeCreated, Message
```

### Test sleep manually
```powershell
rundll32.exe powrprof.dll,SetSuspendState 0,1,0
```

### If prolonged sleep still fails

Try these additional BIOS settings:
- **C-State settings** - Try disabling deep C-states (C6, C7, C8)
- **Package C-State Limit** - Set to C2 or disable
- **ASPM (Active State Power Management)** - Disable

## Summary of S3 Sleep Changes

| Change | Method | Purpose |
|--------|--------|---------|
| Fast Boot = Disabled | BIOS | Fixes S3 resume failure |
| NVIDIA Driver Update | Manual | Fixes GPU resume issues |
| ASUSSystemAnalysis Service = Disabled | Script | Prevents service timeout issues |
| Network Wake on Pattern = Disabled | Script | Prevents auto-wake from network traffic |
| Wake on Magic Packet = Enabled | Script | Preserves Wake-on-LAN functionality |
| Hibernate = Disabled | Script | Doesn't work, frees disk space |
| Hybrid Sleep = Disabled | Script | Prevents prolonged sleep crashes |
| Wake Timers = Disabled | Script | Prevents scheduled wake interruptions |

---

*Last Updated: January 14, 2026*
