#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Pre-commit hook for PoshGuard secret scanning

.DESCRIPTION
    This pre-commit hook uses RipGrep to quickly scan changed PowerShell files
    for hardcoded secrets before allowing the commit. Blocks commits that contain
    detected secrets.

.NOTES
    To install this hook:
    1. Copy to .git/hooks/pre-commit (or .husky/pre-commit for Husky users)
    2. Make executable: chmod +x .git/hooks/pre-commit
    3. Ensure RipGrep is installed: https://github.com/BurntSushi/ripgrep

.EXAMPLE
    # Test the hook manually
    pwsh .git/hooks/pre-commit
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "🔍 PoshGuard Pre-Commit Hook: Scanning for secrets..." -ForegroundColor Cyan

# Get staged PowerShell files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.(ps1|psm1|psd1)$' }

if (-not $stagedFiles) {
    Write-Host "✓ No PowerShell files staged - skipping secret scan" -ForegroundColor Green
    exit 0
}

Write-Host "  Found $($stagedFiles.Count) staged PowerShell file(s)" -ForegroundColor Gray

# Check if RipGrep module is available
$moduleRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$ripgrepModule = Join-Path $moduleRoot "tools/lib/RipGrep.psm1"

if (Test-Path $ripgrepModule) {
    Import-Module $ripgrepModule -Force
    
    # Scan each staged file for secrets
    $allSecrets = @()
    foreach ($file in $stagedFiles) {
        if (Test-Path $file) {
            Write-Host "  Scanning: $file" -ForegroundColor Gray
            $secrets = Find-HardcodedSecrets -Path $file
            if ($secrets) {
                $allSecrets += $secrets
            }
        }
    }
    
    if ($allSecrets.Count -gt 0) {
        Write-Host ""
        Write-Host "❌ COMMIT BLOCKED: Hardcoded secrets detected!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Found $($allSecrets.Count) potential secret(s):" -ForegroundColor Yellow
        
        foreach ($secret in $allSecrets) {
            Write-Host "  • $($secret.File):$($secret.Line) - $($secret.SecretType)" -ForegroundColor Red
            Write-Host "    $($secret.Match)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Please remove these secrets before committing." -ForegroundColor Yellow
        Write-Host "Consider using:" -ForegroundColor Yellow
        Write-Host "  • Environment variables" -ForegroundColor Gray
        Write-Host "  • Azure Key Vault / AWS Secrets Manager" -ForegroundColor Gray
        Write-Host "  • .gitignore for configuration files" -ForegroundColor Gray
        Write-Host ""
        
        exit 1
    }
    
    Write-Host "✓ No secrets detected - commit allowed" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "⚠️  RipGrep module not found - skipping secret scan" -ForegroundColor Yellow
    Write-Host "   Install PoshGuard or RipGrep for automatic secret detection" -ForegroundColor Gray
    exit 0
}
