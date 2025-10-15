# GitHub Actions Workflows

This directory contains automated workflows for PoshGuard CI/CD and code quality assurance.

## Workflows Overview

### code-scanning.yml - GitHub Code Scanning with SARIF

**Purpose**: Performs static code analysis and uploads results to GitHub Security tab in SARIF format.

**Triggers**:
- Push to `main` branch (PowerShell files only)
- Pull requests to `main` (PowerShell files only)
- Weekly schedule (Sundays at 6 AM UTC)
- Manual workflow dispatch

**Key Features**:
- Runs PSScriptAnalyzer on all PowerShell code
- Converts results to SARIF format using ConvertToSARIF module
- Uploads to GitHub Security tab for centralized vulnerability tracking
- Caches PowerShell modules for faster runs
- Creates artifacts for audit and review

**Required Permissions**:
```yaml
permissions:
  contents: read          # Read repository files
  security-events: write  # Upload SARIF results
  actions: read          # Required by CodeQL action
```

**Outputs**:
- GitHub Security tab alerts
- SARIF artifact (30-day retention)
- PSScriptAnalyzer results artifact

**Usage**: Results appear in the "Security" tab → "Code scanning alerts" section of your repository.

---

### ci.yml - Continuous Integration

**Purpose**: Lints and tests PowerShell code on every commit.

**Triggers**:
- Push to `main` branch
- Pull requests

**Jobs**:
1. **lint**: Runs PSScriptAnalyzer with Error/Warning severity
2. **test**: Runs Pester tests
3. **package**: Creates release artifacts (main branch only)

**Optimizations**:
- Path-based filtering (only runs on PowerShell file changes)
- Concurrency controls (cancels outdated runs)
- Module caching (faster installation)

---

### poshguard-quality-gate.yml - Quality Gate Template

**Purpose**: Example quality gate workflow for projects using PoshGuard.

**Features**:
- Configurable thresholds for security issues
- Confidence score validation
- PR comments with analysis results
- Auto-fix capability (optional)

**Note**: This is a template/example workflow. Can be customized for specific project needs.

---

### release.yml - Automated Releases

**Purpose**: Creates GitHub releases when version tags are pushed.

**Triggers**: Git tags matching `v*.*.*` (semantic versioning)

**Features**:
- Version validation
- Release notes extraction from CHANGELOG
- Package creation with SHA256 checksums
- Prerelease detection (alpha/beta/rc)

---

### dependabot-auto-merge.yml - Dependabot Automation

**Purpose**: Automatically approves and merges safe Dependabot updates.

**Triggers**: Dependabot PRs

**Safety**: Only auto-merges patch and minor version updates (not major versions).

---

## GitHub Security Tab Integration

The `code-scanning.yml` workflow integrates PoshGuard with GitHub Advanced Security features:

### How It Works

1. **Analysis**: PSScriptAnalyzer scans all PowerShell files
2. **Conversion**: Results converted to SARIF format
3. **Upload**: SARIF uploaded to GitHub using `github/codeql-action/upload-sarif@v3`
4. **Display**: Alerts appear in Security tab

### Viewing Results

1. Go to repository **Security** tab
2. Click **Code scanning alerts**
3. Filter by:
   - Severity (Error, Warning, Information)
   - Rule ID (e.g., PSAvoidUsingCmdletAliases)
   - Status (Open, Closed, Fixed)
   - Branch

### Alert Management

- **Dismiss**: Mark false positives
- **Fix**: View remediation guidance
- **Track**: Monitor trends over time

### PR Integration

When code scanning finds new issues in a PR:
- Automatically posts PR comment
- Shows affected lines
- Links to rule documentation

## Local Testing

Test workflows locally before pushing:

### Validate YAML Syntax

```bash
# Using Python
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/code-scanning.yml'))"

# Using yq (if installed)
yq eval '.github/workflows/code-scanning.yml'
```

### Test SARIF Generation

```powershell
# Install dependencies
Install-Module PSScriptAnalyzer -Force
Install-Module ConvertToSARIF -Force -AcceptLicense

# Generate SARIF
$results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning
if ($results) {
    $results | ConvertTo-SARIF -FilePath results.sarif
}

# Validate SARIF
Get-Content results.sarif | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

## Best Practices

1. **Permissions**: Always use minimal required permissions
2. **Caching**: Cache dependencies to speed up workflows
3. **Path Filters**: Only run on relevant file changes
4. **Concurrency**: Cancel outdated workflow runs
5. **Artifacts**: Store important outputs for auditing
6. **Secrets**: Never commit secrets; use GitHub Secrets
7. **Testing**: Test workflows in draft PRs before merging

## Troubleshooting

### "Resource not accessible by integration"

**Cause**: Missing permissions in workflow

**Fix**: Add required permissions:
```yaml
permissions:
  security-events: write
```

### "No SARIF results uploaded"

**Cause**: Empty or invalid SARIF file

**Fix**: Check workflow logs for conversion errors

### "Module not found" errors

**Cause**: Module installation failed

**Fix**: Check network connectivity and module availability:
```powershell
Find-Module PSScriptAnalyzer
Find-Module ConvertToSARIF
```

### Workflow not triggering

**Cause**: Path filters excluding changes

**Fix**: Check if your changes match the path filters in `on.push.paths` or `on.pull_request.paths`

## Documentation

- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)
- [SARIF Format](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
- [PoshGuard SARIF Guide](../../docs/GITHUB-SARIF-INTEGRATION.md)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

## Support

For issues with workflows:
- [GitHub Issues](https://github.com/cboyd0319/PoshGuard/issues)
- [Discussions](https://github.com/cboyd0319/PoshGuard/discussions)
