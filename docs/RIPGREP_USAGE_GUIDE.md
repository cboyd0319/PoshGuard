# RipGrep Usage Guide

Quick reference for using PoshGuard's RipGrep integration features.

## Quick Start

### 1. Fast Scanning (Recommended for Large Codebases)

```powershell
# Enable FastScan for 5-10x performance improvement
Invoke-PoshGuard -Path ./enterprise-codebase -Recurse -FastScan

# With dry-run to preview changes
Invoke-PoshGuard -Path ./src -Recurse -FastScan -DryRun -ShowDiff
```

**When to use**: Scanning >100 PowerShell files, enterprise codebases, CI/CD pipelines

**Requires**: RipGrep 14+ installed (falls back to slower scan if not available)

### 2. Secret Scanning

```powershell
# Scan for hardcoded credentials
Import-Module ./tools/lib/RipGrep.psm1
$secrets = Find-HardcodedSecrets -Path ./src

# Export to SARIF for GitHub Code Scanning
$secrets = Find-HardcodedSecrets -Path ./src -ExportSarif -SarifOutputPath ./secrets.sarif

# Use in CI/CD to block commits with secrets
if ($secrets.Count -gt 0) {
    Write-Error "Secrets detected - blocking deployment"
    exit 1
}
```

**Detects**: AWS keys, GitHub tokens, passwords, API keys, connection strings, private keys

### 3. Pre-Commit Hook

```powershell
# Copy to .git/hooks/pre-commit
cp samples/pre-commit-hook.ps1 .git/hooks/pre-commit

# Make executable (Linux/macOS)
chmod +x .git/hooks/pre-commit

# Test manually
pwsh .git/hooks/pre-commit
```

**Purpose**: Automatically scan staged files for secrets before commit

### 4. Configuration Validation

```powershell
# Check for security misconfigurations
Import-Module ./tools/lib/RipGrep.psm1
$issues = Test-ModuleSecurityConfig -Path ./modules

# View issues
$issues | Format-Table File, Issue, Rule, Severity -AutoSize
```

**Checks**: Execution policy bypasses, unsigned scripts, dangerous cmdlet usage

### 5. Organization-Wide Scanning

```powershell
# Scan multiple repositories
Import-Module ./tools/lib/RipGrep.psm1
$results = Invoke-OrgWideScan -OrgPath ./cloned-repos -OutputPath ./org-scan-results

# View summary
Write-Host "Total Scripts: $($results.TotalScripts)"
Write-Host "High-Risk: $($results.HighRiskScripts)"
Write-Host "Secrets: $($results.SecretsFound)"
Write-Host "Config Issues: $($results.ConfigIssues)"
```

**Use Cases**: Security audits, compliance reporting, organization-wide analysis

### 6. SARIF Report Querying

```powershell
# Extract critical findings from SARIF
Import-Module ./tools/lib/RipGrep.psm1
$critical = Get-CriticalFindings -SarifPath ./results.sarif -CWEFilter @('CWE-798', 'CWE-327')

# View findings
$critical | Format-Table Line, CWE, Context -AutoSize
```

**Purpose**: Dashboard reporting, metric extraction, compliance checks

## CI/CD Integration

### GitHub Actions (Incremental Scanning)

The repository includes `.github/workflows/poshguard-incremental.yml` which:
- Installs RipGrep automatically
- Scans only changed PowerShell files in PRs
- Uploads SARIF to GitHub Security tab
- Provides 60-80% time reduction vs full scans

### Azure DevOps Pipeline

```yaml
steps:
  - task: PowerShell@2
    displayName: 'Install RipGrep'
    inputs:
      targetType: 'inline'
      script: |
        choco install ripgrep -y
        
  - task: PowerShell@2
    displayName: 'PoshGuard FastScan'
    inputs:
      targetType: 'inline'
      script: |
        Import-Module PoshGuard
        Invoke-PoshGuard -Path $(Build.SourcesDirectory) -Recurse -FastScan -DryRun
```

### GitLab CI

```yaml
poshguard-scan:
  stage: test
  image: mcr.microsoft.com/powershell:latest
  before_script:
    - apt-get update && apt-get install -y ripgrep
  script:
    - pwsh -Command "Import-Module PoshGuard; Invoke-PoshGuard -Path . -Recurse -FastScan -DryRun"
```

## Performance Tips

### Optimize Pattern Matching

```powershell
# Use specific patterns instead of broad regex
$patterns = @(
    'Invoke-Expression',           # Specific cmdlet
    'ConvertTo-SecureString.*-AsPlainText'  # Specific pattern
)

$files = Find-SuspiciousScripts -Path ./src -Patterns $patterns
```

### Exclude Test Directories

```powershell
# FastScan automatically excludes *test* and *.Tests.ps1
# To include tests:
$files = Find-SuspiciousScripts -Path ./src -IncludeTests
```

### Parallel Processing

```powershell
# Scan multiple directories in parallel
$dirs = @('./src', './modules', './scripts')
$dirs | ForEach-Object -Parallel {
    Import-Module PoshGuard
    Invoke-PoshGuard -Path $_ -FastScan -DryRun
} -ThrottleLimit 4
```

## Troubleshooting

### RipGrep Not Found

**Symptom**: Warning messages about RipGrep not installed

**Solution**: Install RipGrep:
- Windows: `choco install ripgrep` or `winget install BurntSushi.ripgrep.MSVC`
- macOS: `brew install ripgrep`
- Linux: `apt install ripgrep`

**Alternative**: PoshGuard automatically falls back to slower PowerShell-native scanning

### False Positives

**Symptom**: Secret scanner flags test data or examples

**Solution**:
1. Exclude test directories (default behavior)
2. Use `.gitignore` patterns
3. Add comments to whitelist: `# poshguard-ignore-secret`

### Performance Issues

**Symptom**: FastScan not faster than normal scan

**Check**:
1. Verify RipGrep is installed: `rg --version`
2. Ensure scanning local files (not network drives)
3. Check file count: `rg --files --type ps1 ./path | wc -l`

**Expected**: 5-10x faster for codebases with >1000 files

## Examples

See comprehensive examples at:
- `samples/ripgrep-examples.ps1` - All 6 integration points demonstrated
- `samples/pre-commit-hook.ps1` - Production-ready Git hook
- `.github/workflows/poshguard-incremental.yml` - CI/CD workflow

## Reference

- Full specification: `docs/RIPGREP_INTEGRATION.md`
- Architecture: `docs/ARCHITECTURE.md`
- API reference: `docs/api.md`
- RipGrep documentation: https://github.com/BurntSushi/ripgrep

## Support

- Issues: https://github.com/cboyd0319/PoshGuard/issues
- Discussions: https://github.com/cboyd0319/PoshGuard/discussions
