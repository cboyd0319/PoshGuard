#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Example demonstrating RipGrep integration usage in PoshGuard

.DESCRIPTION
    This script demonstrates all 6 integration points from the RipGrep
    integration specification:
    1. Pre-Filtering for AST Analysis
    2. Secret Scanning
    3. Configuration File Validation
    4. Incremental CI/CD Scanning
    5. SARIF Report Enhancement
    6. Multi-Repository Scanning

.NOTES
    Requires: RipGrep 14.0+ (optional - examples show fallback behavior)
    Part of PoshGuard v4.3.0+
#>

Set-StrictMode -Version Latest

# Import the RipGrep module
$ripgrepModule = Join-Path $PSScriptRoot "../tools/lib/RipGrep.psm1"
if (-not (Test-Path $ripgrepModule)) {
    Write-Error "RipGrep module not found at: $ripgrepModule"
    exit 1
}
Import-Module $ripgrepModule -Force

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PoshGuard RipGrep Integration Examples" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check RipGrep availability
$rgStatus = Test-RipGrepAvailable
Write-Host "🔍 RipGrep Status:" -ForegroundColor Yellow
Write-Host "   Available: $($rgStatus.IsAvailable)" -ForegroundColor Gray
if ($rgStatus.IsAvailable) {
    Write-Host "   Version: $($rgStatus.Version)" -ForegroundColor Gray
}
else {
    Write-Host "   Note: Examples will use fallback mode" -ForegroundColor Gray
    Write-Host "   Install from: https://github.com/BurntSushi/ripgrep" -ForegroundColor Gray
}
Write-Host ""

# Example 1: Pre-Filtering for AST Analysis
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 1: Fast Pre-Filtering" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Use Invoke-PoshGuard with FastScan
Write-Host "Command: Invoke-PoshGuard -Path ./samples -FastScan -DryRun" -ForegroundColor Cyan
Write-Host "Purpose: 5-10x faster scanning by pre-filtering suspicious files" -ForegroundColor Gray
Write-Host ""

# Find suspicious scripts
$suspiciousFiles = Find-SuspiciousScripts -Path $PSScriptRoot -Patterns @(
    'Invoke-Expression',
    'DownloadString',
    'ConvertTo-SecureString.*-AsPlainText'
)

if ($suspiciousFiles) {
    Write-Host "Found $($suspiciousFiles.Count) suspicious file(s):" -ForegroundColor Green
    $suspiciousFiles | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Gray
    }
}
else {
    Write-Host "✓ No suspicious patterns found" -ForegroundColor Green
}
Write-Host ""

# Example 2: Secret Scanning
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 2: Hardcoded Secret Detection" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "Command: Find-HardcodedSecrets -Path ./samples -ExportSarif" -ForegroundColor Cyan
Write-Host "Purpose: Fast detection of AWS keys, passwords, tokens, etc." -ForegroundColor Gray
Write-Host ""

$secrets = Find-HardcodedSecrets -Path $PSScriptRoot

if ($secrets -and $secrets.Count -gt 0) {
    Write-Host "⚠️  Found $($secrets.Count) potential secret(s):" -ForegroundColor Red
    $secrets | ForEach-Object {
        Write-Host "  • $($_.File):$($_.Line) - $($_.SecretType)" -ForegroundColor Yellow
        Write-Host "    $($_.Match)" -ForegroundColor Gray
    }
}
else {
    Write-Host "✓ No hardcoded secrets detected" -ForegroundColor Green
}
Write-Host ""

# Example 3: Configuration Validation
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 3: Security Configuration Checks" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "Command: Test-ModuleSecurityConfig -Path ./PoshGuard" -ForegroundColor Cyan
Write-Host "Purpose: Check for execution policy bypasses, unsigned scripts" -ForegroundColor Gray
Write-Host ""

$configIssues = Test-ModuleSecurityConfig -Path $PSScriptRoot

if ($configIssues -and $configIssues.Count -gt 0) {
    Write-Host "Found $($configIssues.Count) configuration issue(s):" -ForegroundColor Yellow
    $configIssues | Group-Object Issue | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.Count) file(s)" -ForegroundColor Gray
    }
}
else {
    Write-Host "✓ No configuration issues found" -ForegroundColor Green
}
Write-Host ""

# Example 4: Multi-Repository Scanning
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 4: Organization-Wide Scanning" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "Command: Invoke-OrgWideScan -OrgPath ./repos -OutputPath ./scan-results" -ForegroundColor Cyan
Write-Host "Purpose: Scan entire organization's PowerShell codebase" -ForegroundColor Gray
Write-Host ""

# Create temp directory for demo
$tempOrgPath = Join-Path ([System.IO.Path]::GetTempPath()) "poshguard-org-scan-demo"
if (Test-Path $tempOrgPath) {
    Remove-Item -Path $tempOrgPath -Recurse -Force
}
New-Item -Path $tempOrgPath -ItemType Directory -Force | Out-Null

# Run org-wide scan on current directory
$outputPath = Join-Path ([System.IO.Path]::GetTempPath()) "poshguard-scan-results"
$orgScanResult = Invoke-OrgWideScan -OrgPath $PSScriptRoot -OutputPath $outputPath

if ($orgScanResult) {
    Write-Host "Scan Results:" -ForegroundColor Green
    Write-Host "  Total Scripts: $($orgScanResult.TotalScripts)" -ForegroundColor Gray
    Write-Host "  High-Risk Scripts: $($orgScanResult.HighRiskScripts)" -ForegroundColor Gray
    Write-Host "  Secrets Found: $($orgScanResult.SecretsFound)" -ForegroundColor Gray
    Write-Host "  Config Issues: $($orgScanResult.ConfigIssues)" -ForegroundColor Gray
    Write-Host "  Output: $($orgScanResult.OutputPath)" -ForegroundColor Gray
}
else {
    Write-Host "⚠️  Org-wide scan requires RipGrep" -ForegroundColor Yellow
}
Write-Host ""

# Example 5: SARIF Report Querying
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 5: SARIF Report Analysis" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "Command: Get-CriticalFindings -SarifPath ./results.sarif -CWEFilter @('CWE-798')" -ForegroundColor Cyan
Write-Host "Purpose: Extract specific CWE patterns from SARIF reports" -ForegroundColor Gray
Write-Host ""

# Create demo SARIF file
$demoSarif = Join-Path ([System.IO.Path]::GetTempPath()) "demo-results.sarif"
$sarifContent = @{
    version = '2.1.0'
    runs = @(
        @{
            tool = @{
                driver = @{
                    name = 'PoshGuard'
                    version = '4.3.0'
                }
            }
            results = @(
                @{
                    ruleId = 'CWE-798'
                    message = @{ text = 'Hardcoded credentials detected' }
                    level = 'error'
                }
            )
        }
    )
}
$sarifContent | ConvertTo-Json -Depth 10 | Set-Content -Path $demoSarif

$criticalFindings = Get-CriticalFindings -SarifPath $demoSarif -CWEFilter @('CWE-798', 'CWE-327')

if ($criticalFindings -and $criticalFindings.Count -gt 0) {
    Write-Host "Found $($criticalFindings.Count) critical finding(s):" -ForegroundColor Green
    $criticalFindings | ForEach-Object {
        Write-Host "  • Line $($_.Line): $($_.CWE)" -ForegroundColor Gray
    }
}
else {
    Write-Host "ℹ️  No critical findings (requires RipGrep for querying)" -ForegroundColor Cyan
}
Write-Host ""

# Example 6: Integration with Invoke-PoshGuard
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 6: Full Integration Workflow" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "Typical CI/CD Workflow:" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Step 1: Fast pre-filtering with RipGrep" -ForegroundColor Gray
Write-Host 'Invoke-PoshGuard -Path ./src -FastScan -DryRun' -ForegroundColor Green
Write-Host ""
Write-Host "# Step 2: Secret scanning" -ForegroundColor Gray
Write-Host '$secrets = Find-HardcodedSecrets -Path ./src' -ForegroundColor Green
Write-Host 'if ($secrets.Count -gt 0) { exit 1 }' -ForegroundColor Green
Write-Host ""
Write-Host "# Step 3: Configuration validation" -ForegroundColor Gray
Write-Host '$issues = Test-ModuleSecurityConfig -Path ./src' -ForegroundColor Green
Write-Host 'if ($issues.Count -gt 0) { exit 1 }' -ForegroundColor Green
Write-Host ""
Write-Host "# Step 4: Export results to SARIF" -ForegroundColor Gray
Write-Host 'Invoke-PoshGuard -Path ./src -ExportSarif -SarifOutputPath ./results.sarif' -ForegroundColor Green
Write-Host ""
Write-Host "# Step 5: Upload to GitHub Code Scanning" -ForegroundColor Gray
Write-Host '# (handled by GitHub Actions workflow)' -ForegroundColor Green
Write-Host ""

# Cleanup
if (Test-Path $tempOrgPath) {
    Remove-Item -Path $tempOrgPath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Examples Complete!" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "For more information, see:" -ForegroundColor Yellow
Write-Host "  • docs/RIPGREP_INTEGRATION.md" -ForegroundColor Gray
Write-Host "  • docs/ARCHITECTURE.md" -ForegroundColor Gray
Write-Host "  • .github/workflows/poshguard-incremental.yml" -ForegroundColor Gray
Write-Host "  • samples/pre-commit-hook.ps1" -ForegroundColor Gray
Write-Host ""
