# Quick Start Guide - PowerShell QA Engine v3.0.0

## Installation (One-Time Setup)

```bash
cd /Users/chadboyd/Documents/GitHub/job-search-automation/qa
make setup
```

This installs:
- PSScriptAnalyzer (for formatting & analysis)
- Pester v5 (for testing)

---

## Daily Workflow

### 1. Preview What Needs Fixing

```bash
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src -DryRun -ShowDiff
```

**Shows unified diffs** of all proposed changes without modifying files.

### 2. Apply Fixes

```bash
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src
```

**Applies all safe fixes:**
- Formats with Invoke-Formatter
- Removes trailing whitespace
- Expands cmdlet aliases (gci → Get-ChildItem)
- Normalizes line endings
- Fixes $null position in comparisons
- Creates automatic backups in `.psqa-backup/`

### 3. Verify Changes

```bash
git diff
```

Review the actual changes made.

### 4. Rollback if Needed

```bash
# List available backups
pwsh ./tools/Restore-Backup.ps1 -Path ../src -ListOnly

# Restore latest backup
pwsh ./tools/Restore-Backup.ps1 -Path ../src -Latest
```

---

## Using Make (Alternative)

```bash
# Preview fixes
make fix DRY_RUN=1

# Apply fixes
make fix

# Run full analysis
make analyze

# Run tests
make test

# Complete pipeline
make all
```

---

## Common Tasks

### Fix a Single File

```bash
pwsh ./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -ShowDiff
```

### Fix Without Backups (Not Recommended)

```bash
pwsh ./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -NoBackup
```

### Restore Specific Backup

```bash
# Find timestamp from list
pwsh ./tools/Restore-Backup.ps1 -Path ./src -ListOnly

# Restore by timestamp
pwsh ./tools/Restore-Backup.ps1 -Path ./src -BackupTimestamp 20251008123045
```

---

## Idempotent Behavior

**Running the same fix multiple times is safe:**

```bash
# First run - fixes issues
pwsh ./tools/Apply-AutoFix.ps1 -Path ./src

# Second run - no changes (already fixed)
pwsh ./tools/Apply-AutoFix.ps1 -Path ./src
# Output: "Files unchanged: X"
```

---

## Testing

### Run All Tests

```bash
pwsh -Command "Invoke-Pester -Path ./tests"
```

### Run Specific Test

```bash
pwsh -Command "Invoke-Pester -Path ./tests/PSQALogger.Tests.ps1"
```

### With Coverage

```bash
pwsh -Command '
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = "./modules/**/*.psm1"
Invoke-Pester -Configuration $config
'
```

---

## Logs

### View Recent Logs

```bash
# Human-readable
tail -f ./logs/qa-engine.log

# Structured JSONL
tail -f ./logs/qa-engine.jsonl | jq
```

### Search Logs by TraceId

```bash
grep "trace-id-here" ./logs/qa-engine.jsonl | jq
```

---

## Module Usage (Advanced)

### Import and Use Modules Directly

```powershell
# Logging
Import-Module ./modules/Loggers/PSQALogger.psm1
$traceId = (New-Guid).ToString()
Write-PSQAInfo "Processing started" -TraceId $traceId

# AST Analysis
Import-Module ./modules/Analyzers/PSQAASTAnalyzer.psm1
$issues = Invoke-PSQAASTAnalysis -FilePath ./script.ps1
$issues | Format-Table RuleName, Severity, Line, Message

# Auto-Fix
Import-Module ./modules/Fixers/PSQAAutoFixer.psm1
$results = Invoke-PSQAAutoFix -FilePath ./script.ps1 -DryRun
$results.UnifiedDiff
```

---

## Troubleshooting

### "Invoke-Formatter not found"

```bash
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

### "Module not found"

Check you're in the `/qa` directory:

```bash
cd /Users/chadboyd/Documents/GitHub/job-search-automation/qa
```

### Backup Directory Full

Manually clean old backups:

```bash
find . -name ".psqa-backup" -type d -exec du -sh {} \;
# Remove old backups if needed
```

---

## Safety Features

1. **Automatic Backups** - Every fix creates timestamped backup
2. **Dry Run Mode** - Preview before applying
3. **Unified Diffs** - See exactly what changes
4. **Idempotent** - Safe to run multiple times
5. **Rollback** - Restore any previous version
6. **Confirmation** - Restore requires confirmation (unless -Force)

---

## Full Documentation

See `README.md` for complete documentation including:
- Module reference
- Configuration details
- Advanced workflows
- Security features
- Performance tuning

---

**Quick Reference Card:**

```bash
# Most common commands
make fix DRY_RUN=1          # Preview fixes
make fix                    # Apply fixes
make test                   # Run tests
make analyze                # Full analysis

# Or direct script usage
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src -DryRun -ShowDiff
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src
pwsh ./tools/Restore-Backup.ps1 -Path ../src -Latest
```

---

**That's it! You're ready to use the world's best PowerShell QA system.**
