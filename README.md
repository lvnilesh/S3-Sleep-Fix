# S3 Sleep Fix for ASUS Z790P-Wifi + Intel 14th Gen + RTX 4090

This guide documents the fixes required to get S3 sleep/resume working properly on this system.

## System Configuration

| Component | Details |
|-----------|---------|
| **Motherboard** | ASUS Z790P-Wifi |
| **CPU** | Intel Core i9-14900K |
| **GPU** | NVIDIA GeForce RTX 4090 |
| **RAM** | 64GB DDR5 |
| **OS** | Windows 11 |

## Issues Encountered

1. **S3 Sleep would not resume** - System hung on wake, required hard power off
2. **Hibernate would not resume** - Same issue (not fixed, disabled instead)
3. **Auto-wake from sleep** - Network adapters waking system on network traffic

## Fixes Applied

### 1. BIOS Setting (CRITICAL - Manual Step Required)

**This is the most important fix and must be done manually in BIOS.**

1. Restart and press **DEL** to enter UEFI BIOS
2. Navigate to **Boot** section
3. Set **Fast Boot** to **Disabled**
4. Save and Exit (F10)

> ⚠️ Without this change, S3 sleep will NOT work properly on Z790 boards.

### 2. Update NVIDIA Driver

Download and install the latest NVIDIA driver from:
- https://www.nvidia.com/drivers

The old driver (August 2024) had sleep/resume issues. Use the latest available.

### 3. Run the PowerShell Fix Script

After completing the BIOS change and driver update, run the included script as Administrator:

**Easiest method:** Double-click `run-fix.bat` and click Yes on UAC prompt.

Alternative - run from an elevated PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\cloudgenius\Documents\S3-Sleep-Fix\fix-s3-sleep.ps1"
```

> Note: The `run-fix.bat` file bypasses PowerShell's script execution policy automatically.

The script will:
- Disable the problematic ASUS System Analysis service
- Configure network adapters to only wake on WOL magic packets (prevents random wake)
- Disable hibernate (doesn't work on this system, frees ~30GB disk space)
- Verify sleep states are available

### 4. Test Sleep

After applying all fixes:

```powershell
# Test sleep from PowerShell
rundll32.exe powrprof.dll,SetSuspendState 0,1,0
```

Wake with keyboard or mouse. The system should resume properly.

## Troubleshooting

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

## Summary of Changes

| Change | Method | Purpose |
|--------|--------|---------|
| Fast Boot = Disabled | BIOS | Fixes S3 resume failure |
| NVIDIA Driver Update | Manual | Fixes GPU resume issues |
| ASUSSystemAnalysis Service = Disabled | Script | Prevents service timeout issues |
| Network Wake on Pattern = Disabled | Script | Prevents auto-wake from network traffic |
| Wake on Magic Packet = Enabled | Script | Preserves Wake-on-LAN functionality |
| Hibernate = Disabled | Script | Doesn't work, frees disk space |

## Power Settings (Default)

| Setting | Value |
|---------|-------|
| Turn off display | 5 minutes |
| Sleep after | 15 minutes |

These can be adjusted in Windows Settings > System > Power & battery.

---

*Created: January 10, 2026*
*System: ASUS Z790P-Wifi / i9-14900K / RTX 4090 / 64GB RAM*
