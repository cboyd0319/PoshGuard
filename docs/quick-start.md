# PoshGuard Quick Start

Get up and running with PoshGuard in under 5 minutes.

## 🚀 Installation

### Option 1: PowerShell Gallery (Fastest)
```powershell
Install-Module PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard
```

### Option 2: Git Clone
```powershell
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard
Import-Module ./tools/lib/Core.psm1
```

## ⚡ Quick Commands

### Check Your Code (Safe - No Changes)
```powershell
# Preview what would be fixed
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1 -DryRun

# See unified diff
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1 -ShowDiff
```

### Fix Your Code
```powershell
# Apply fixes (creates automatic backup)
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1

# Fix entire directory
./tools/Apply-AutoFix.ps1 -Path ./src/ -Recurse
```

### Rollback If Needed
```powershell
# Restore from backup
./tools/Restore-Backup.ps1 -BackupPath .backup/MyScript.ps1.20251011_140523.bak
```

## 🎯 Common Use Cases

### Before Committing Code
```powershell
# Check files you're about to commit
./tools/Apply-AutoFix.ps1 -Path . -DryRun -Recurse
```

### In CI/CD Pipeline
```powershell
# Non-interactive mode for automation
./tools/Apply-AutoFix.ps1 -Path . -NonInteractive -OutputFormat jsonl
```

### Skip Specific Rules
```powershell
# Exclude certain fixes
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -Skip @('PSAvoidUsingWriteHost')
```

## 📊 What Gets Fixed?

PoshGuard automatically fixes **60 types** of PowerShell issues:

- 🔒 **Security** (8 rules) - Plain text passwords, hardcoded servers, unsafe cmdlets
- ✅ **Best Practices** (28 rules) - Global vars, empty catch blocks, positional params
- 🎨 **Formatting** (24 rules) - Brace placement, indentation, casing

## 🔍 Try the Samples

```powershell
# See fixes in action
cd samples/
../tools/Apply-AutoFix.ps1 -Path ./before-security-issues.ps1 -ShowDiff
```

**Before:**
```powershell
function Connect-Service {
    param([string]$Password)  # ❌ Plain text
    gci C:\Logs                # ❌ Alias
    Write-Host "Connecting"    # ❌ Write-Host
}
```

**After:**
```powershell
function Connect-Service {
    param([SecureString]$Password)           # ✅ Secure
    Get-ChildItem C:\Logs                    # ✅ Full cmdlet
    Write-Information "Connecting" -Info...  # ✅ Write-Information
}
```

## 📝 Exit Codes

- `0` = Success (no issues or all fixed)
- `1` = Issues found (DryRun mode)
- `2` = Error (parse failure, permissions, etc.)

## 🆘 Help

```powershell
# Get help
Get-Help ./tools/Apply-AutoFix.ps1 -Full

# Verbose output for troubleshooting
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -Verbose
```

## 🔗 Learn More

- **Full Documentation**: [README.md](README.md)
- **How It Works**: [docs/how-it-works.md](docs/how-it-works.md)
- **CI Integration**: [docs/ci-integration.md](docs/ci-integration.md)
- **GitHub Setup**: [docs/github-setup.md](docs/github-setup.md)

## 💡 Pro Tips

1. **Always DryRun first** - See what changes before applying
2. **Backups are automatic** - Check `.backup/` folder if you need to rollback
3. **Use -Verbose** - See detailed information about what's being fixed
4. **Check samples/** - Real examples show exactly what gets fixed
5. **CI/CD ready** - Use `-NonInteractive` for pipelines

## 🎉 You're Ready!

Start fixing your PowerShell code:

```powershell
./tools/Apply-AutoFix.ps1 -Path ./your-script.ps1 -DryRun
```

Questions? Open an issue: https://github.com/cboyd0319/PoshGuard/issues
