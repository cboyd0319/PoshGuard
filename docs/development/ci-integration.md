# CI/CD Integration Guide

PoshGuard is designed to integrate seamlessly into CI/CD pipelines. This guide covers common integration patterns.

## Exit Codes

PoshGuard uses standard exit codes for pipeline automation:

| Code | Meaning | CI Action |
|------|---------|-----------|
| `0` | Success - No issues found or all fixes applied | ✓ Pass build |
| `1` | Issues found (DryRun mode) | ⚠ Optional fail (configurable) |
| `2` | Fatal error (parse failure, access denied, etc.) | ✗ Fail build |

## GitHub Actions

### Basic Integration

```yaml
name: PowerShell Lint
on:
  push:
    branches: [main]
    paths:
      - '**.ps1'
      - '**.psm1'
      - '**.psd1'
  pull_request:
    paths:
      - '**.ps1'
      - '**.psm1'
      - '**.psd1'

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v5
      
      - name: Cache PSScriptAnalyzer
        uses: actions/cache@v4
        with:
          path: ~\Documents\PowerShell\Modules\PSScriptAnalyzer
          key: ${{ runner.os }}-psscriptanalyzer
      
      - name: Install Dependencies
        run: |
          if (!(Get-Module -ListAvailable PSScriptAnalyzer)) {
            Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
          }
        shell: pwsh
      
      - name: Run PSScriptAnalyzer
        run: |
          $results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning
          if ($results) {
            $results | Format-Table -AutoSize
            exit 1
          }
        shell: pwsh
```

### Auto-fix and Commit

```yaml
name: Auto-fix Code Issues
on: [push]

jobs:
  autofix:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Install dependencies
        run: |
          Install-Module PoshGuard -Scope CurrentUser -Force
          Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
        shell: pwsh
      
      - name: Apply fixes
        run: |
          Invoke-PoshGuard -Path . -Recurse -NonInteractive
        shell: pwsh
      
      - name: Commit changes
        run: |
          git config user.name "PoshGuard Bot"
          git config user.email "bot@poshguard.dev"
          git add -A
          git diff --staged --quiet || git commit -m "chore: auto-fix code issues [skip ci]"
          git push
        shell: bash
```

### Pull Request Comments

```yaml
name: PR Review
on: [pull_request]

jobs:
  review:
    runs-on: windows-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v5
      
      - name: Install dependencies
        run: |
          Install-Module PoshGuard -Scope CurrentUser -Force
        shell: pwsh
      
      - name: Run analysis
        id: analysis
        run: |
          $output = Invoke-PoshGuard -Path . -Recurse -DryRun -NonInteractive -OutputFormat json
          echo "RESULTS<<EOF" >> $env:GITHUB_OUTPUT
          echo $output >> $env:GITHUB_OUTPUT
          echo "EOF" >> $env:GITHUB_OUTPUT
        shell: pwsh
      
      - name: Comment on PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## PoshGuard Analysis\n\n```json\n${{ steps.analysis.outputs.RESULTS }}\n```'
            })
```

## Azure DevOps

### Azure Pipelines

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Install PoshGuard'
  inputs:
    targetType: 'inline'
    script: |
      Install-Module PoshGuard -Scope CurrentUser -Force
      Install-Module PSScriptAnalyzer -Scope CurrentUser -Force

- task: PowerShell@2
  displayName: 'Run PoshGuard'
  inputs:
    targetType: 'inline'
    script: |
      $result = Invoke-PoshGuard -Path $(Build.SourcesDirectory) -Recurse -DryRun -NonInteractive -OutputFormat jsonl -OutFile $(Build.ArtifactStagingDirectory)/poshguard-report.jsonl
      if ($LASTEXITCODE -eq 1) {
        Write-Host "##vso[task.complete result=SucceededWithIssues;]Code quality issues detected"
      } elseif ($LASTEXITCODE -ne 0) {
        Write-Error "PoshGuard failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
      }

- task: PublishBuildArtifacts@1
  displayName: 'Publish Report'
  inputs:
    PathtoPublish: '$(Build.ArtifactStagingDirectory)/poshguard-report.jsonl'
    ArtifactName: 'poshguard-report'
```

## GitLab CI

### .gitlab-ci.yml

```yaml
stages:
  - lint

poshguard:
  stage: lint
  image: mcr.microsoft.com/powershell:latest
  script:
    - pwsh -Command "Install-Module PoshGuard -Scope CurrentUser -Force"
    - pwsh -Command "Install-Module PSScriptAnalyzer -Scope CurrentUser -Force"
    - pwsh -Command "Invoke-PoshGuard -Path . -Recurse -DryRun -NonInteractive -OutputFormat jsonl -OutFile poshguard-report.jsonl"
  artifacts:
    paths:
      - poshguard-report.jsonl
    reports:
      codequality: poshguard-report.jsonl
  allow_failure: true
```

## Jenkins

### Jenkinsfile

```groovy
pipeline {
    agent { label 'windows' }
    
    stages {
        stage('Setup') {
            steps {
                powershell '''
                    Install-Module PoshGuard -Scope CurrentUser -Force
                    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
                '''
            }
        }
        
        stage('Lint') {
            steps {
                powershell '''
                    $result = Invoke-PoshGuard -Path . -Recurse -DryRun -NonInteractive -OutputFormat jsonl -OutFile poshguard-report.jsonl
                    if ($LASTEXITCODE -eq 1) {
                        currentBuild.result = 'UNSTABLE'
                        echo "Code quality issues detected"
                    } elseif ($LASTEXITCODE -ne 0) {
                        error "PoshGuard failed with exit code ${LASTEXITCODE}"
                    }
                '''
            }
        }
        
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'poshguard-report.jsonl', allowEmptyArchive: true
            }
        }
    }
}
```

## Pre-commit Hook

For local development, add PoshGuard to pre-commit hooks:

### .git/hooks/pre-commit

```bash
#!/bin/bash
# Pre-commit hook for PoshGuard

echo "Running PoshGuard..."

# Get list of PowerShell files to commit
PS_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.ps1$|\.psm1$|\.psd1$')

if [ -z "$PS_FILES" ]; then
    echo "No PowerShell files to check"
    exit 0
fi

# Run PoshGuard on changed files
for file in $PS_FILES; do
    pwsh -Command "Invoke-PoshGuard -Path '$file' -DryRun -NonInteractive"
    
    if [ $? -eq 1 ]; then
        echo "⚠️  Code quality issues in $file"
        echo "Run: ./tools/Apply-AutoFix.ps1 -Path '$file' -ShowDiff"
        exit 1
    elif [ $? -eq 2 ]; then
        echo "❌ PoshGuard failed on $file"
        exit 1
    fi
done

echo "✓ All PowerShell files passed PoshGuard checks"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Docker Integration

### Dockerfile

```dockerfile
FROM mcr.microsoft.com/powershell:latest

# Install PoshGuard
RUN pwsh -Command "Install-Module PoshGuard -Scope CurrentUser -Force" && \
    pwsh -Command "Install-Module PSScriptAnalyzer -Scope CurrentUser -Force"

WORKDIR /workspace

ENTRYPOINT ["pwsh", "-Command", "Invoke-PoshGuard"]
CMD ["-Path", ".", "-Recurse", "-DryRun", "-NonInteractive"]
```

Build and run:
```bash
docker build -t poshguard:latest .
docker run -v $(pwd):/workspace poshguard:latest
```

## Quality Gates

### Block merge on violations

```yaml
# GitHub Actions - enforce quality
- name: Enforce code quality
  run: |
    Invoke-PoshGuard -Path . -Recurse -DryRun -NonInteractive
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Code quality check failed - merge blocked"
      exit 1
    }
  shell: pwsh
```

### Warning only (soft enforcement)

```yaml
- name: Code quality warning
  run: |
    Invoke-PoshGuard -Path . -Recurse -DryRun -NonInteractive
    if ($LASTEXITCODE -eq 1) {
      Write-Warning "Code quality issues detected but not blocking"
    }
  shell: pwsh
  continue-on-error: true
```

## Report Formats

### JSONL Output

Each line is a JSON object representing one violation:

```jsonl
{"file":"script.ps1","rule":"PSAvoidUsingCmdletAliases","line":10,"severity":"Warning","fixed":true}
{"file":"module.psm1","rule":"PSAvoidGlobalVars","line":5,"severity":"Warning","fixed":false}
```

Parse in CI:
```powershell
$violations = Get-Content violations.jsonl | ConvertFrom-Json
$critical = $violations | Where-Object { $_.severity -eq 'Error' }
if ($critical) {
    Write-Error "Found $($critical.Count) critical violations"
    exit 1
}
```

### JSON Output

Complete report as single JSON object:

```json
{
  "summary": {
    "total_files": 5,
    "total_violations": 12,
    "fixed": 10,
    "skipped": 2
  },
  "violations": [...]
}
```

## GitHub Code Scanning with SARIF

For GitHub repositories, you can upload analysis results to the Security tab using SARIF format:

```yaml
name: Code Scanning

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 6 * * 0'

permissions:
  contents: read
  security-events: write

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
      
      - name: Analyze with PoshGuard
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning
          if ($results) {
            $results | ConvertTo-SARIF -FilePath results.sarif
          }
      
      - name: Upload SARIF to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif
```

See [GitHub SARIF Integration Guide](./GITHUB-SARIF-INTEGRATION.md) for complete documentation.

## Best Practices

1. **Start with DryRun** - Preview changes before applying in CI
2. **Use NonInteractive** - Ensure deterministic output
3. **Check exit codes** - Properly handle success/warning/error states
4. **Archive reports** - Save JSONL output for trend analysis
5. **Incremental adoption** - Start with warnings, gradually enforce
6. **Cache dependencies** - Cache PSScriptAnalyzer installation
7. **Parallel execution** - Run on changed files only for speed
8. **SARIF for GitHub** - Upload SARIF to Security tab for centralized tracking

## Troubleshooting

**Issue**: PoshGuard not found in CI
- **Solution**: Ensure `Install-Module PoshGuard` runs before invoking

**Issue**: Permissions error in CI
- **Solution**: Use `-Scope CurrentUser` for module installation

**Issue**: Different results locally vs CI
- **Solution**: Use `-NonInteractive` flag and ensure same PSScriptAnalyzer version

**Issue**: Slow CI builds
- **Solution**: Use `-Path` with changed files only, enable caching

## Support

For CI/CD integration issues, open an issue at:
https://github.com/cboyd0319/PoshGuard/issues
