# PoshGuard - PowerShell QA & Auto-Fix Engine v2.3.0

PowerShell code quality automation with auto-fix, AST analysis, security scanning, and testing.

**Modular Architecture**: 5 specialized modules | 90% main script reduction | 100% PSSA security coverage

---

## Features

- AST-based analysis: unbound variables, shadowing, unsafe patterns, cognitive complexity
- PSScriptAnalyzer integration with custom rules
- Auto-fix: safe, idempotent fixes with unified diffs (72-93% issue reduction)
- Smart Write-Host detection: preserves UI components, fixes plain output
- Parameter casing: corrects cmdlet and parameter casing to Microsoft standards
- Code formatting with Invoke-Formatter integration
- Security: 100% PSSA security rule coverage (password handling, injection prevention)
- Logging: JSONL logs with traceId and secret redaction
- Rollback: restore from timestamped backups
- Testing: Pester v5 suite with mocks and coverage
- Cross-platform: PowerShell 5.1 and 7.x (Windows, Linux, macOS)

## Module Architecture (v2.3.0)

PoshGuard uses a modular architecture with functions extracted to specialized modules:

- `Core.psm1` (160 lines): Helper functions for backups, logging, file operations
- `Security.psm1` (498 lines): All 8 PSSA security fixes (100% coverage)
- `Formatting.psm1` (334 lines): Code formatting and style enforcement
- `BestPractices.psm1` (677 lines): PowerShell coding standards
- `Advanced.psm1` (1,288 lines): Complex AST-based transformations

Main script reduced from 3,185 to 333 lines (90% reduction).

## Test Results

Tested on production PowerShell scripts:

**v2.3.0** (10 scripts):
- 72% issue reduction (365 to 102 violations)
- 83% indentation fix rate (240/289 resolved)
- 100% fix rate: trailing whitespace, comment help, consistent whitespace
- 35% casing improvement (8/23 fixed)
- Zero parse errors after auto-fix
- Idempotent (safe to run multiple times)

**Earlier test** (18 scripts):
- 93% issue reduction (301 to 27 violations)
- Zero regressions

---

## Quick Start

### Installation

```powershell
# Clone or navigate to the qa directory
cd /path/to/qa

# Install required modules
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Install-Module Pester -Scope CurrentUser -Force -MinimumVersion 5.0.0
```

### Basic Usage

```powershell
# Analyze code
pwsh ./tools/Invoke-PSQAEngine.ps1 -Path ../src -Mode Analyze

# Preview auto-fixes (dry run)
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src -DryRun -ShowDiff

# Apply fixes
pwsh ./tools/Apply-AutoFix.ps1 -Path ../src

# Restore from backup
pwsh ./tools/Restore-Backup.ps1 -Path ../src -Latest
```

### Using Make

```bash
# Setup and validate
make setup

# Analyze code
make analyze

# Apply fixes (dry run first)
make fix DRY_RUN=1
make fix

# Run tests
make test

# Complete pipeline
make all
```

---

## Directory Structure

```
qa/
├── config/                          # Configuration files
│   ├── PSScriptAnalyzerSettings.psd1   # PSSA rules (zero-tolerance)
│   ├── QASettings.psd1                  # QA engine configuration
│   └── SecurityRules.psd1               # Security scanning rules
│
├── modules/                         # Modular architecture
│   ├── Analyzers/
│   │   └── PSQAASTAnalyzer.psm1         # Deep AST analysis
│   ├── Fixers/
│   │   └── PSQAAutoFixer.psm1           # Intelligent auto-fix engine
│   └── Loggers/
│       └── PSQALogger.psm1              # Structured JSONL logging
│
├── tools/                           # Standalone scripts
│   ├── Invoke-PSQAEngine.ps1            # Main QA engine
│   ├── Apply-AutoFix.ps1                # Idempotent auto-fix script
│   └── Restore-Backup.ps1               # Rollback automation
│
├── tests/                           # Pester v5 test suite
│   ├── PSQALogger.Tests.ps1
│   ├── PSQAASTAnalyzer.Tests.ps1
│   └── PSQAAutoFixer.Tests.ps1
│
├── docs/                            # Documentation
│   ├── ARCHITECTURE-PSQA.md             # Comprehensive system architecture
│   ├── QUICKSTART.md                    # Quick start guide
│   └── SYSTEM_CAPABILITIES.md           # Detailed capabilities reference
│
├── logs/                            # Log output (gitignored)
│   ├── qa-engine.log                    # Human-readable logs
│   └── qa-engine.jsonl                  # Structured JSONL logs
│
├── .gitignore                       # Ignore patterns for reports, backups, etc.
├── LICENSE                          # MIT License
├── Makefile                         # Automation commands
└── README.md                        # This file
```

---

## Tools Reference

### 1. Apply-AutoFix.ps1 (Standalone Auto-Fix)

```powershell
# Preview fixes without applying
.\tools\Apply-AutoFix.ps1 -Path ./src -DryRun -ShowDiff

# Apply all safe fixes
.\tools\Apply-AutoFix.ps1 -Path ./src

# Skip backups (not recommended)
.\tools\Apply-AutoFix.ps1 -Path ./src -NoBackup

# Verbose output
.\tools\Apply-AutoFix.ps1 -Path ./src -Verbose
```

**What it fixes:**
- Formatting (Invoke-Formatter)
- Trailing whitespace and line endings
- Cmdlet aliases (AST-based, preserves string literals)
- Parameter casing (`-pathType` → `-PathType`)
- Write-Host (preserves UI components, fixes plain output)
- $null comparison order
- Adds -ErrorAction Stop to I/O cmdlets (AST-based)
- Atomic file writes (temp → rename)
- Creates backups in `.psqa-backup/`
- Idempotent (safe to run multiple times)

### 2. Restore-Backup.ps1 (Rollback System)

```powershell
# List available backups
.\tools\Restore-Backup.ps1 -Path ./src -ListOnly

# Restore latest backup for all files
.\tools\Restore-Backup.ps1 -Path ./src -Latest

# Restore specific backup by timestamp
.\tools\Restore-Backup.ps1 -Path ./src -BackupTimestamp 20251008123045

# Force restore without confirmation
.\tools\Restore-Backup.ps1 -Path ./src -Latest -Force
```

**Safety:**
- Preview before restore
- Confirmation required (unless -Force)
- Creates backup before restore
- Preserves history

### 3. Invoke-PSQAEngine.ps1 (Full QA Engine)

```powershell
# Analyze only
.\tools\Invoke-PSQAEngine.ps1 -Path ../src -Mode Analyze

# Analyze and fix
.\tools\Invoke-PSQAEngine.ps1 -Path ../src -Mode Fix

# Complete pipeline with reports
.\tools\Invoke-PSQAEngine.ps1 -Path ../src -Mode All -OutputFormat All

# Dry run
.\tools\Invoke-PSQAEngine.ps1 -Path ../src -Mode Fix -DryRun
```

**Modes:**
- `Analyze` - Run analysis only
- `Fix` - Apply automated fixes
- `Test` - Run quality validation
- `Report` - Generate detailed reports
- `CI` - CI/CD optimized mode
- `All` - Complete pipeline

---

## Module Reference

### PSQALogger.psm1 - Structured Logging

```powershell
Import-Module ./modules/Loggers/PSQALogger.psm1

# Initialize with custom config
Initialize-PSQALogger -Config @{ Level = 'Debug' }

# Write logs with traceId
Write-PSQAInfo "Processing started" -TraceId $traceId
Write-PSQAWarning "Deprecated function" -Hint "Use new function" -Action "Update code"
Write-PSQAError "Analysis failed" -Code "E001" -Hint "File corrupt" -Action "Re-download"
```

**Features:**
- JSONL output
- Secret redaction (passwords, tokens, keys)
- TraceId correlation
- Multiple sinks (console, file, JSONL)
- Log rotation at 50MB
- Color-coded output

### PSQAASTAnalyzer.psm1 - Deep Code Analysis

```powershell
Import-Module ./modules/Analyzers/PSQAASTAnalyzer.psm1

# Analyze PowerShell file
$issues = Invoke-PSQAASTAnalysis -FilePath ./script.ps1 -TraceId $traceId

$issues | ForEach-Object {
    Write-Host "[$($_.Severity)] Line $($_.Line): $($_.Message)"
    Write-Host "  Suggestion: $($_.Suggestion)"
}
```

**Detects:**
- Unbound variables
- Variable shadowing
- Unsafe pipeline binding
- High cognitive complexity (>15)
- Dead code
- Invoke-Expression usage
- Global variables
- Empty catch blocks
- Missing parameter validation

### PSQAAutoFixer.psm1 - Auto-Fix

```powershell
Import-Module ./modules/Fixers/PSQAAutoFixer.psm1

# Apply fixes
$results = Invoke-PSQAAutoFix -FilePath ./script.ps1 -DryRun

$results | ForEach-Object {
    Write-Host "Fix: $($_.FixType) - $($_.Description)"
    Write-Host "Unified Diff:"
    Write-Host $_.UnifiedDiff
}

# Apply specific fix types
Invoke-PSQAAutoFix -FilePath ./script.ps1 -FixTypes @('Formatting', 'Whitespace')
```

**Fix Types:**
- `Formatting` - Invoke-Formatter integration
- `Whitespace` - Trailing whitespace, line endings, consistent indentation
- `Aliases` - Expand cmdlet aliases (AST-based, preserves string literals)
- `Casing` - **NEW**: Fix cmdlet and parameter casing to Microsoft standards
- `WriteHost` - **NEW**: Smart Write-Host replacement (preserves UI components)
- `Security` - Safe security improvements (AST-based -ErrorAction injection, $null comparison order)
- `BestPractices` - PowerShell best practices
- `All` - All safe fixes (default)

**Auto-Fix Pipeline** (Apply-AutoFix.ps1):
```
1. Formatter Fix    → Invoke-Formatter for consistent style
2. Whitespace Fix   → Remove trailing whitespace, normalize line endings
3. Alias Fix        → Expand aliases (cls → Clear-Host, % → ForEach-Object)
4. Casing Fix       → Correct parameter casing (-pathType → -PathType)
5. Write-Host Fix   → Smart replacement (preserves UI, replaces plain output)
6. Safety Fix       → Add -ErrorAction Stop, fix $null order
```

---

## Configuration

### PSScriptAnalyzerSettings.psd1

PSSA configuration with strict formatting and security rules:
- 4-space indentation (no tabs)
- K&R brace style
- No trailing whitespace
- Approved verbs only
- No Invoke-Expression
- No plaintext passwords
- Comment-based help required

### QASettings.psd1

Engine configuration:
- Max file size: 10MB
- Cross-platform checks
- Security scanning
- Code coverage threshold: 80%
- Max cyclomatic complexity: 15
- JSONL logging

### SecurityRules.psd1

Security pattern detection:
- Credentials and secrets
- Code injection
- Dangerous commands
- Error handling
- Data validation
- Module security
- System modifications

---

## Testing

### Run Pester Tests

```powershell
# Install Pester v5
Install-Module Pester -Force -MinimumVersion 5.0.0

# Run all tests
Invoke-Pester -Path ./tests

# Run with coverage
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './modules/**/*.psm1'
Invoke-Pester -Configuration $config

# Using Make
make test
```

### Test Coverage

Current test coverage targets:
- PSQALogger: Unit tests with mocking
- PSQAASTAnalyzer: Pattern detection tests
- PSQAAutoFixer: Fix validation and diff generation

---

## Best Practices

### 1. Always Use Dry Run First

```powershell
# Preview changes
.\tools\Apply-AutoFix.ps1 -Path ./src -DryRun -ShowDiff

# Review unified diffs
# Then apply if safe
.\tools\Apply-AutoFix.ps1 -Path ./src
```

### 2. Backups Are Automatic

Backups are created in `.psqa-backup/` directories with timestamps:
```
.psqa-backup/
├── script.ps1.20251008123045.bak
├── module.psm1.20251008123046.bak
└── manifest.psd1.20251008123047.bak
```

### 3. Review Logs

```powershell
# Structured JSONL logs for programmatic analysis
Get-Content ./logs/qa-engine.jsonl | Select-Object -Last 10 | ConvertFrom-Json

# Human-readable logs
Get-Content ./logs/qa-engine.log | Select-Object -Last 20
```

### 4. Idempotent Fixes

All auto-fix scripts are idempotent - running multiple times produces the same result:

```powershell
# First run - applies fixes
.\tools\Apply-AutoFix.ps1 -Path ./src

# Second run - no changes (already fixed)
.\tools\Apply-AutoFix.ps1 -Path ./src
```

---

## Makefile Commands

```bash
make help              # Show all available commands
make setup             # Initial setup and dependency check
make validate          # Validate QA system configuration
make analyze           # Run comprehensive code analysis
make fix               # Apply automated fixes
make fix DRY_RUN=1     # Preview fixes without applying
make test              # Run Pester tests
make report            # Generate detailed reports
make clean             # Clean up reports and temp files
make all               # Complete QA pipeline (analyze + fix + test + report)
make quick-check       # Check only changed files (git diff)
```

---

## Advanced Usage

### Custom Analysis Workflow

```powershell
# 1. Import modules
Import-Module ./modules/Loggers/PSQALogger.psm1
Import-Module ./modules/Analyzers/PSQAASTAnalyzer.psm1
Import-Module ./modules/Fixers/PSQAAutoFixer.psm1

# 2. Initialize logging
$traceId = (New-Guid).ToString()
Initialize-PSQALogger -Config @{ Level = 'Debug' }

# 3. Analyze files
$files = Get-ChildItem -Path ./src -Include *.ps1,*.psm1 -Recurse
foreach ($file in $files) {
    Write-PSQAInfo "Analyzing: $($file.Name)" -TraceId $traceId

    # AST analysis
    $astIssues = Invoke-PSQAASTAnalysis -FilePath $file.FullName -TraceId $traceId

    # Apply fixes if issues found
    if ($astIssues) {
        $fixes = Invoke-PSQAAutoFix -FilePath $file.FullName -TraceId $traceId -DryRun
        Write-PSQAInfo "Found $($astIssues.Count) issues, $($fixes.Count) auto-fixable" -TraceId $traceId
    }
}
```

### Rollback Strategy

```powershell
# 1. List all backups
.\tools\Restore-Backup.ps1 -Path ./src -ListOnly

# 2. Restore latest for critical files
.\tools\Restore-Backup.ps1 -Path ./src/critical.ps1 -Latest

# 3. Or restore all to specific timestamp
.\tools\Restore-Backup.ps1 -Path ./src -BackupTimestamp 20251008100000
```

---

## Troubleshooting

### Issue: Invoke-Formatter not found

```powershell
# Install PSScriptAnalyzer (includes Invoke-Formatter)
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

### Issue: PSSA warnings persist

Check custom settings:
```powershell
Invoke-ScriptAnalyzer -Path ./file.ps1 -Settings ./config/PSScriptAnalyzerSettings.psd1
```

### Issue: Tests failing

```powershell
# Ensure Pester v5 is installed
Get-Module Pester -ListAvailable
Install-Module Pester -Force -MinimumVersion 5.0.0 -SkipPublisherCheck
```

### Issue: Backups not created

Check permissions and disk space:
```powershell
# Verify write access
Test-Path -Path ./src/.psqa-backup -IsValid
```

---

## Performance

- **Analysis Speed**: ~100-200 files/second (AST + PSSA)
- **Auto-Fix Speed**: ~50-100 files/second (with Invoke-Formatter)
- **Memory Usage**: <500MB for typical projects (<10K files)
- **Log Rotation**: Automatic at 50MB threshold
- **Backup Cleanup**: Manual (keeps all by default)

---

## What's New in v2.1.0

**New auto-fixes:**
- Reserved parameter detection (Error-level)
- Switch parameter default value removal
- Broken hash algorithm replacement (MD5/SHA1 → SHA256)

**Improvements:**
- Write-Host detection now preserves UI components (colors, emojis)
- Parameter casing fix (AST-based)
- WMI to CIM cmdlet conversion
- Comment help scaffolding

**Testing:**
- Validated on 28 production scripts (fleschutz/PowerShell)
- 72-93% issue reduction proven
- Zero regressions
- 100% syntax validation

---

## Roadmap

**v2.2** (Next):
- Modularize Apply-AutoFix.ps1 into PSQACodeFixes.psm1
- Add more PSSA auto-fixes (targeting 40% coverage)
- Backup cleanup utility

**v2.3**:
- Mutation testing
- Pre-commit git hooks
- Semantic versioning automation

**v3.0**:
- VSCode extension
- Real-time analysis (file watcher)
- Diff-based incremental analysis

---

## Documentation

**Available in `docs/`:**

- **[QUICKSTART.md](docs/QUICKSTART.md)** - Installation and basic usage
- **[ARCHITECTURE-PSQA.md](docs/ARCHITECTURE-PSQA.md)** - System architecture and design
- **[SYSTEM_CAPABILITIES.md](docs/SYSTEM_CAPABILITIES.md)** - Feature reference and configuration
- **[PSSA-RULES-AUTOFIX-ROADMAP.md](docs/PSSA-RULES-AUTOFIX-ROADMAP.md)** - Auto-fix roadmap (21/70 rules, 30% coverage)

---

## Contributing

All contributions must:
1. Pass PSSA analysis (zero errors/warnings)
2. Include Pester v5 tests
3. Maintain backward compatibility (PS 5.1+)
4. Include documentation
5. Follow PowerShell best practices

---

## License

MIT License

---

## Credits

Built with:
- PowerShell 7.4+ (compatible with 5.1+)
- PSScriptAnalyzer
- Pester v5
- AST-based transformations

Validated on 28 production scripts from [fleschutz/PowerShell](https://github.com/fleschutz/PowerShell)
