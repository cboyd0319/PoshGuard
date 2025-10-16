Install
=======

Answer first: two ways to install.

PowerShell Gallery (recommended)
--------------------------------

```powershell
Install-Module PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard
Get-Command -Module PoshGuard
```

From source (repo clone)
------------------------

```powershell
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard
# Use tools directly (no install)
./tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -ShowDiff

# Or load the module for this session
Import-Module ./PoshGuard/PoshGuard.psd1 -Force
Invoke-PoshGuard -Path ./samples -Recurse -DryRun
```

Prerequisites
-------------

- PowerShell 7+ (Windows PowerShell 5.1 works with reduced features)
- PSScriptAnalyzer 1.24+ (auto-installs with Gallery install)

Verify installation
-------------------

```powershell
# Module
Get-Module PoshGuard -ListAvailable
Invoke-PoshGuard -Path . -DryRun

# Tools
./tools/Apply-AutoFix.ps1 -Path . -DryRun
./tools/Restore-Backup.ps1 -BackupPath .backup/…
```

Uninstall
---------

```powershell
Remove-Module PoshGuard -ErrorAction SilentlyContinue
Uninstall-Module PoshGuard -AllVersions -Force
```

Troubleshooting
---------------

- “module not found”: run `Install-Module PoshGuard` or import from the repo path
- “cannot locate Apply-AutoFix.ps1”: use repo path `./tools/Apply-AutoFix.ps1` or import the module first
- “access denied”: install with `-Scope CurrentUser` or run PowerShell as Administrator

