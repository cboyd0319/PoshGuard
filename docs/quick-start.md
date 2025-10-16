# Quick Start

5-minute setup.

## Install

PowerShell Gallery:

```powershell
Install-Module PoshGuard -Scope CurrentUser
Import-Module PoshGuard
```

From source:

```powershell
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard
Import-Module ./tools/lib/Core.psm1
```

## Usage

Preview (safe):

```powershell
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1 -DryRun
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1 -ShowDiff
```

Apply fixes:

```powershell
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1
./tools/Apply-AutoFix.ps1 -Path ./src/ -Recurse
```

Rollback:

```powershell
./tools/Restore-Backup.ps1 -BackupPath .backup/MyScript.ps1.20251011_140523.bak
```

## Common Scenarios

Pre-commit:

```powershell
./tools/Apply-AutoFix.ps1 -Path . -DryRun -Recurse
```

CI/CD:

```powershell
./tools/Apply-AutoFix.ps1 -Path . -NonInteractive -OutputFormat jsonl
```

Skip rules:

```powershell
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -Skip @('PSAvoidUsingWriteHost')
```

## Coverage

60+ rules: Security (8), Best Practices (28), Formatting (24)

## Samples

```powershell
# See fixes in action
cd samples/
../tools/Apply-AutoFix.ps1 -Path ./before-security-issues.ps1 -ShowDiff
```

Before:

```powershell
function Connect-Service {
    param([string]$Password)
    gci C:\Logs
    Write-Host "Connecting"
}
```

After:

```powershell
function Connect-Service {
    param([SecureString]$Password)
    Get-ChildItem C:\Logs
    Write-Information "Connecting" -InformationAction Continue
}
```

## Exit Codes

- `0` = Success
- `1` = Issues found (DryRun)
- `2` = Error

## Help

```powershell
Get-Help ./tools/Apply-AutoFix.ps1 -Full
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -Verbose
```

## Learn More

- [README](../README.md)
- [How It Works](how-it-works.md)
- [CI Integration](development/ci-integration.md)

## Tips

- Always DryRun first
- Backups in `.backup/` folder
- Use `-Verbose` for debugging
- Check `samples/` for examples
- Use `-NonInteractive` for CI/CD
