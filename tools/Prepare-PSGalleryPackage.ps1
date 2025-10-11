<#
.SYNOPSIS
    Prepare PoshGuard module structure for PowerShell Gallery publication.

.DESCRIPTION
    Reorganizes the PoshGuard module structure to meet PowerShell Gallery requirements.
    Creates a properly structured module directory ready for Publish-Module.

.PARAMETER OutputPath
    Directory where the reorganized module will be created.
    Defaults to ./publish/PoshGuard

.PARAMETER WhatIf
    Show what would be done without making changes.

.EXAMPLE
    ./Prepare-PSGalleryPackage.ps1

.EXAMPLE
    ./Prepare-PSGalleryPackage.ps1 -OutputPath C:\temp\PoshGuard -Verbose

.NOTES
    PowerShell Gallery requires this structure:
    PoshGuard/
      PoshGuard.psd1      (manifest)
      PoshGuard.psm1      (root module)
      Apply-AutoFix.ps1   (main script)
      lib/                (submodules)
        Core.psm1
        Security.psm1
        BestPractices.psm1
        Formatting.psm1
        Advanced.psm1
        (+ all submodule directories)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\publish\PoshGuard')
)

$ErrorActionPreference = 'Stop'

# Resolve paths
$RepoRoot = Split-Path $PSScriptRoot -Parent
$SourceManifestPath = Join-Path $RepoRoot 'PoshGuard\PoshGuard.psd1'
$SourceModulePath = Join-Path $RepoRoot 'PoshGuard\PoshGuard.psm1'
$SourceLibPath = Join-Path $RepoRoot 'tools\lib'
$SourceScriptPath = Join-Path $RepoRoot 'tools\Apply-AutoFix.ps1'

Write-Host "`n=== PoshGuard PowerShell Gallery Package Preparation ===" -ForegroundColor Cyan

# Validate source files exist
Write-Host "`nValidating source files..." -ForegroundColor Yellow
$RequiredPaths = @(
    @{Path=$SourceManifestPath; Name='Module manifest'},
    @{Path=$SourceModulePath; Name='Root module'},
    @{Path=$SourceLibPath; Name='Library directory'},
    @{Path=$SourceScriptPath; Name='Apply-AutoFix script'}
)

foreach ($item in $RequiredPaths) {
    if (-not (Test-Path $item.Path)) {
        throw "$($item.Name) not found: $($item.Path)"
    }
    Write-Host "  ✓ $($item.Name)" -ForegroundColor Green
}

# Create output directory structure
Write-Host "`nCreating output directory structure..." -ForegroundColor Yellow
if (Test-Path $OutputPath) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Remove existing directory")) {
        Remove-Item $OutputPath -Recurse -Force
        Write-Host "  • Removed existing directory" -ForegroundColor Gray
    }
}

if ($PSCmdlet.ShouldProcess($OutputPath, "Create directory")) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $OutputLibPath = Join-Path $OutputPath 'lib'
    $null = New-Item -ItemType Directory -Path $OutputLibPath -Force
    Write-Host "  ✓ Created $OutputPath" -ForegroundColor Green
}

# Copy manifest
Write-Host "`nCopying module manifest..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess($SourceManifestPath, "Copy to $OutputPath")) {
    Copy-Item $SourceManifestPath -Destination $OutputPath -Force
    Write-Host "  ✓ PoshGuard.psd1" -ForegroundColor Green
}

# Copy root module
Write-Host "`nCopying root module..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess($SourceModulePath, "Copy to $OutputPath")) {
    Copy-Item $SourceModulePath -Destination $OutputPath -Force
    Write-Host "  ✓ PoshGuard.psm1" -ForegroundColor Green
}

# Copy Apply-AutoFix script
Write-Host "`nCopying main script..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess($SourceScriptPath, "Copy to $OutputPath")) {
    Copy-Item $SourceScriptPath -Destination $OutputPath -Force
    Write-Host "  ✓ Apply-AutoFix.ps1" -ForegroundColor Green
}

# Copy lib directory recursively
Write-Host "`nCopying library modules..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess($SourceLibPath, "Copy to $OutputLibPath")) {
    Copy-Item "$SourceLibPath\*" -Destination $OutputLibPath -Recurse -Force
    
    # Count modules
    $moduleCount = (Get-ChildItem $OutputLibPath -Filter *.psm1 -Recurse).Count
    Write-Host "  ✓ Copied $moduleCount module files" -ForegroundColor Green
}

# Copy documentation files
Write-Host "`nCopying documentation..." -ForegroundColor Yellow

# Root directory files
$RootDocs = @('README.md', 'LICENSE')
foreach ($doc in $RootDocs) {
    $sourcePath = Join-Path $RepoRoot $doc
    if (Test-Path $sourcePath) {
        if ($PSCmdlet.ShouldProcess($doc, "Copy to $OutputPath")) {
            Copy-Item $sourcePath -Destination $OutputPath -Force
            Write-Host "  ✓ $doc" -ForegroundColor Green
        }
    } else {
        Write-Warning "  ⚠ $doc not found, skipping"
    }
}

# Docs directory files
$DocsDocs = @('CHANGELOG.md', 'SECURITY.md', 'CONTRIBUTING.md')
foreach ($doc in $DocsDocs) {
    $sourcePath = Join-Path $RepoRoot "docs\$doc"
    if (Test-Path $sourcePath) {
        if ($PSCmdlet.ShouldProcess($doc, "Copy to $OutputPath")) {
            Copy-Item $sourcePath -Destination $OutputPath -Force
            Write-Host "  ✓ $doc" -ForegroundColor Green
        }
    } else {
        Write-Warning "  ⚠ $doc not found in docs/, skipping"
    }
}

# Validate module manifest
Write-Host "`nValidating module manifest..." -ForegroundColor Yellow
try {
    $manifestPath = Join-Path $OutputPath 'PoshGuard.psd1'
    $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    Write-Host "  ✓ Manifest is valid" -ForegroundColor Green
    Write-Host "    Version: $($manifest.Version)" -ForegroundColor Gray
    Write-Host "    Author: $($manifest.Author)" -ForegroundColor Gray
    Write-Host "    GUID: $($manifest.Guid)" -ForegroundColor Gray
}
catch {
    Write-Error "Manifest validation failed: $_"
    throw
}

# Calculate package size
$sizeSum = (Get-ChildItem $OutputPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
$packageSize = if ($null -ne $sizeSum) { $sizeSum / 1MB } else { 0 }

Write-Host "`n=== Package Ready for PowerShell Gallery ===" -ForegroundColor Green
Write-Host "Location: $OutputPath" -ForegroundColor Cyan
Write-Host "Size: $($packageSize.ToString('F2')) MB" -ForegroundColor Cyan
Write-Host "`nTo publish to PowerShell Gallery:" -ForegroundColor Yellow
Write-Host "  Publish-Module -Path '$OutputPath' -NuGetApiKey `$env:PSGALLERY_API_KEY -Verbose" -ForegroundColor White
Write-Host "`nTo test locally:" -ForegroundColor Yellow
Write-Host "  Import-Module '$OutputPath\PoshGuard.psd1' -Force" -ForegroundColor White
Write-Host "  Invoke-PoshGuard -Path .\test.ps1 -DryRun" -ForegroundColor White
