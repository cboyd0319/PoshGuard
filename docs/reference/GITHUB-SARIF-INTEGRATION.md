# GitHub SARIF Integration Guide

This guide explains how to integrate PoshGuard with GitHub Code Scanning to display security vulnerabilities and code quality issues in your repository's Security tab.

## What is SARIF?

SARIF (Static Analysis Results Interchange Format) is a standard JSON-based format for the output of static analysis tools. GitHub Code Scanning uses SARIF to display security vulnerabilities and code quality issues in a repository's Security tab.

## Why Use SARIF with PoshGuard?

- **Centralized Security Dashboard**: View all code quality and security issues in one place
- **Pull Request Integration**: Automatically comment on PRs with security findings
- **Trend Analysis**: Track improvements or regressions in code quality over time
- **Team Visibility**: Make code quality metrics visible to the entire team
- **Compliance**: Meet organizational requirements for security scanning

## Quick Start

### 1. Enable Code Scanning Workflow

Add the provided workflow to your repository:

```bash
# Copy the workflow file
cp .github/workflows/code-scanning.yml your-repo/.github/workflows/
```

Or create `.github/workflows/code-scanning.yml`:

```yaml
name: Code Scanning

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 0'  # Weekly on Sunday

permissions:
  contents: read
  security-events: write  # Required for SARIF upload

jobs:
  poshguard-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      
      - name: Setup PowerShell
        uses: microsoft/setup-powershell@v1
      
      - name: Install modules
        shell: pwsh
        run: |
          Install-Module PSScriptAnalyzer -Force
          Install-Module ConvertToSARIF -Force -AcceptLicense
      
      - name: Run PoshGuard
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning
          if ($results) {
            $results | ConvertTo-SARIF -FilePath results.sarif
          }
      
      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: results.sarif
```

### 2. Using PoshGuard with SARIF Export

#### Command Line

```powershell
# Analyze and export to SARIF
./tools/Apply-AutoFix.ps1 -Path ./src -DryRun -ExportSarif -SarifOutputPath ./results.sarif
```

#### Module Usage

```powershell
# Install PoshGuard from PowerShell Gallery
Install-Module PoshGuard -Force

# Analyze with SARIF export
Invoke-PoshGuard -Path ./src -DryRun -ExportSarif -SarifOutputPath ./results.sarif
```

### 3. View Results

1. Go to your repository on GitHub
2. Click the "Security" tab
3. Select "Code scanning alerts"
4. View findings organized by severity

## Complete Workflow Example

Here's a complete workflow that runs PoshGuard and uploads results to GitHub Security:

```yaml
name: PoshGuard Code Scanning

on:
  push:
    branches: [main, develop]
    paths:
      - '**.ps1'
      - '**.psm1'
      - '**.psd1'
  pull_request:
    branches: [main]
  schedule:
    # Run weekly security scan
    - cron: '0 6 * * 0'
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  security-events: write
  actions: read

jobs:
  code-scanning:
    name: PoshGuard Security Scan
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v5
        with:
          fetch-depth: 0
      
      - name: Setup PowerShell
        uses: microsoft/setup-powershell@v1
        with:
          pwsh: true
      
      - name: Cache PowerShell modules
        uses: actions/cache@v4
        with:
          path: ~/.local/share/powershell/Modules
          key: ${{ runner.os }}-psmodules-${{ hashFiles('**/PSScriptAnalyzerSettings.psd1') }}
      
      - name: Install dependencies
        shell: pwsh
        run: |
          Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck
          Install-Module ConvertToSARIF -Force -Scope CurrentUser -AcceptLicense
      
      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer `
            -Path . `
            -Recurse `
            -Severity Error,Warning,Information `
            -ErrorAction SilentlyContinue
          
          if ($results) {
            Write-Host "Found $($results.Count) issues"
            $results | Export-Clixml -Path results.xml
          } else {
            Write-Host "No issues found"
            @() | Export-Clixml -Path results.xml
          }
      
      - name: Convert to SARIF
        if: always()
        shell: pwsh
        run: |
          $results = Import-Clixml -Path results.xml
          if ($results) {
            $results | ConvertTo-SARIF -FilePath results.sarif
          } else {
            # Create empty SARIF for clean state
            @{
              '$schema' = 'https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.4.json'
              'version' = '2.1.0'
              'runs' = @(@{
                'tool' = @{
                  'driver' = @{
                    'name' = 'PSScriptAnalyzer'
                    'informationUri' = 'https://github.com/PowerShell/PSScriptAnalyzer'
                  }
                }
                'results' = @()
              })
            } | ConvertTo-Json -Depth 10 | Set-Content results.sarif
          }
      
      - name: Upload to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif
          category: poshguard
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: sarif-results
          path: results.sarif
          retention-days: 30
```

## SARIF File Structure

A SARIF file contains structured information about code analysis results:

```json
{
  "$schema": "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.4.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "PSScriptAnalyzer",
          "informationUri": "https://github.com/PowerShell/PSScriptAnalyzer",
          "rules": [
            {
              "id": "PSAvoidUsingCmdletAliases",
              "name": "PSAvoidUsingCmdletAliases",
              "helpUri": "https://github.com/PowerShell/Psscriptanalyzer"
            }
          ]
        }
      },
      "results": [
        {
          "ruleId": "PSAvoidUsingCmdletAliases",
          "message": {
            "text": "'gci' is an alias of 'Get-ChildItem'..."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "file:///path/to/script.ps1"
                },
                "region": {
                  "startLine": 42
                }
              }
            }
          ]
        }
      ]
    }
  ]
}
```

## Required Permissions

Your workflow needs these permissions to upload SARIF:

```yaml
permissions:
  contents: read          # Read repository content
  security-events: write  # Upload SARIF to Security tab
  actions: read          # Required by CodeQL action
```

## Advanced Configuration

### Filtering Results by Severity

```powershell
# Only export high-severity issues
$results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error
$results | ConvertTo-SARIF -FilePath results.sarif
```

### Custom Categories

Use different categories for different analysis types:

```yaml
- name: Upload Security Issues
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: security-results.sarif
    category: poshguard-security

- name: Upload Style Issues  
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: style-results.sarif
    category: poshguard-style
```

### Scheduled Scans

Run regular security scans:

```yaml
on:
  schedule:
    - cron: '0 0 * * 1'  # Every Monday at midnight
    - cron: '0 6 * * 0'  # Every Sunday at 6 AM
```

### Branch-Specific Scanning

```yaml
on:
  push:
    branches:
      - main
      - develop
      - 'release/**'
```

## Troubleshooting

### Issue: "Resource not accessible by integration"

**Cause**: Missing `security-events: write` permission

**Solution**: Add to workflow:

```yaml
permissions:
  security-events: write
```

### Issue: "No SARIF results uploaded"

**Cause**: Empty or malformed SARIF file

**Solution**: Verify SARIF structure:

```powershell
Get-Content results.sarif | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

### Issue: "Results not showing in Security tab"

**Possible causes**:

1. Workflow didn't complete successfully
2. SARIF file is empty
3. Results are filtered out by GitHub

**Solution**: Check workflow logs and verify SARIF content

### Issue: ConvertToSARIF module not found

**Solution**: Install the module:

```powershell
Install-Module ConvertToSARIF -Force -AcceptLicense
```

## Best Practices

1. **Run on Schedule**: Set up weekly scans to catch new vulnerabilities
2. **Filter Appropriately**: Focus on Error and Warning severity to reduce noise
3. **Use Categories**: Organize findings by type (security, style, performance)
4. **Cache Modules**: Speed up workflows by caching PowerShell modules
5. **Combine with PR Checks**: Run scans on pull requests before merging
6. **Track Trends**: Monitor the Security tab to track improvements over time
7. **Document Suppressions**: If you suppress findings, document why

## Integration with Other Tools

### Combine with CodeQL

```yaml
jobs:
  codeql:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: github/codeql-action/init@v3
      - uses: github/codeql-action/analyze@v3
  
  poshguard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      # PoshGuard steps...
```

### Use with Dependabot

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## GitHub Security Tab Features

Once SARIF is uploaded, you get:

- **Alert Dashboard**: View all security findings
- **PR Integration**: Automatic PR comments on new findings
- **Alert Management**: Dismiss, reopen, or mark as false positive
- **Trend Analysis**: Track metrics over time
- **Filtering**: Filter by severity, rule, file, or status
- **Remediation Guidance**: Links to fix documentation

## Resources

- [SARIF Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)
- [ConvertToSARIF Module](https://github.com/microsoft/ConvertTo-SARIF)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [PoshGuard Documentation](https://github.com/cboyd0319/PoshGuard)

## Support

For issues or questions:

- [GitHub Issues](https://github.com/cboyd0319/PoshGuard/issues)
- [Discussions](https://github.com/cboyd0319/PoshGuard/discussions)
