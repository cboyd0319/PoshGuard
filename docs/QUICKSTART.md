# Quick Start - PowerShell QA Engine v2.3.0

## Installation

```bash
cd /path/to/PoshGuard
make setup
```

Installs:
- PSScriptAnalyzer
- Pester v5

---

## Daily Workflow

### 1. Preview What Needs Fixing

```bash
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src -DryRun -ShowDiff
```

Shows proposed changes without modifying files.

### 2. Apply Fixes

```bash
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src
```

Applies fixes:
- Formatting (Invoke-Formatter)
- Trailing whitespace removal
- Cmdlet alias expansion
- Line ending normalization
- $null comparison order
- Creates backups in `.psqa-backup/`

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

## Idempotent

Safe to run multiple times:

```bash
# First run - fixes issues
pwsh ./tools/Apply-AutoFix.ps1 -Path ./src

# Second run - no changes
pwsh ./tools/Apply-AutoFix.ps1 -Path ./src
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

Done. You can now run PoshGuard QA checks.
