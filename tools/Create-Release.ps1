#Requires -Version 5.1
<#
.SYNOPSIS
    Creates a new PoshGuard release with proper tagging and asset generation.

.NOTES
    PSScriptAnalyzer Suppressions:
    - PSAvoidUsingWriteHost: This is an interactive script for developers, Write-Host is appropriate for user feedback

.DESCRIPTION
    Automates the release process:
    - Validates version format
    - Creates git tag
    - Generates release package (GitHub release format)
    - Optionally pushes to GitHub (triggers release workflow)

    IMPORTANT: This script creates a GitHub release package, NOT a PowerShell
    Gallery package. For PSGallery publication, use Prepare-PSGalleryPackage.ps1
    to reorganize the module structure:
      PoshGuard/
        PoshGuard.psd1
        PoshGuard.psm1
        lib/              <- tools/lib/* files copied here
        Apply-AutoFix.ps1 <- tools/Apply-AutoFix.ps1 copied here

    See docs/implementation-summary.md for complete PSGallery publishing instructions.

.PARAMETER Version
    Semantic version string (e.g., "3.0.0")

.PARAMETER Push
    Push tag to GitHub to trigger release workflow

.EXAMPLE
    ./tools/Create-Release.ps1 -Version 3.0.0

.EXAMPLE
    ./tools/Create-Release.ps1 -Version 3.0.0 -Push

.NOTES
    For PowerShell Gallery publishing, run Prepare-PSGalleryPackage.ps1 after
    this script to create the properly structured module package.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter()]
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$TagName = "v$Version"

Write-Host "Creating release $TagName..." -ForegroundColor Cyan

# Validate we're in a git repository
if (-not (Test-Path "$RepoRoot/.git")) {
    throw "Not in a git repository. Run from repository root."
}

# Check if tag already exists
$existingTag = git tag -l $TagName
if ($existingTag) {
    throw "Tag $TagName already exists. Use a different version or delete the existing tag."
}

# Validate VERSION.txt matches
$versionFilePath = "$RepoRoot/PoshGuard/VERSION.txt"
$versionFile = Get-Content $versionFilePath -Raw
if ($versionFile.Trim() -ne $Version) {
    Write-Warning "VERSION.txt contains '$($versionFile.Trim())' but release is '$Version'"
    Write-Host "Updating VERSION.txt to $Version..." -ForegroundColor Yellow
    Set-Content $versionFilePath -Value $Version -NoNewline
}

# Validate module manifest matches
$manifestPath = "$RepoRoot/PoshGuard/PoshGuard.psd1"
if (Test-Path $manifestPath) {
    try {
        $manifest = Test-ModuleManifest $manifestPath -ErrorAction Stop

        if ($manifest.Version -ne $Version) {
            Write-Warning "Module manifest version is $($manifest.Version) but release is $Version"

            # Update manifest
            $manifestContent = Get-Content $manifestPath -Raw
            $manifestContent = $manifestContent -replace "ModuleVersion\s*=\s*'[\d.]+'", "ModuleVersion = '$Version'"
            Set-Content $manifestPath -Value $manifestContent
            Write-Host "Updated PoshGuard.psd1 to version $Version" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Module manifest validation failed: $($_.Exception.Message)"
        throw
    }
}

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Warning "Uncommitted changes detected:"
    Write-Host $gitStatus
    $commit = Read-Host "Commit changes before creating tag? (y/n)"
    if ($commit -eq 'y') {
        git add PoshGuard/VERSION.txt PoshGuard/PoshGuard.psd1 docs/CHANGELOG.md
        git commit -m "chore: release v$Version"
        Write-Host "Committed version changes" -ForegroundColor Green
    }
}

# Create annotated tag
Write-Host "Creating annotated tag $TagName..." -ForegroundColor Yellow

# Extract changelog snippet for this version
# Expected format: Keep a Changelog (https://keepachangelog.com/)
# Each version starts with a heading: ## [x.y.z] - YYYY-MM-DD
$changelogPath = "$RepoRoot/docs/CHANGELOG.md"
$changelogSnippet = ""

if (Test-Path $changelogPath) {
    $changelogLines = Get-Content $changelogPath
    $inSection = $false
    $snippetLines = @()

    foreach ($line in $changelogLines) {
        # Start of target version section
        if ($line -match "^##\s+\[$([regex]::Escape($Version))\]") {
            $inSection = $true
            continue  # Skip the header line itself
        }

        # Start of next version section (stop collecting)
        if ($inSection -and $line -match "^##\s+\[\d+\.\d+\.\d+\]") {
            break
        }

        # Collect lines within the target section
        if ($inSection) {
            $snippetLines += $line
        }
    }

    $changelogSnippet = ($snippetLines -join "`n").Trim()
}

if ([string]::IsNullOrWhiteSpace($changelogSnippet)) {
    Write-Warning "Could not extract changelog for version $Version"
    $changelogSnippet = "Release $Version"
}

if ($PSCmdlet.ShouldProcess($TagName, "Create Git Tag")) {
    git tag -a $TagName -m "Release $Version`n`n$changelogSnippet"
    Write-Host "✓ Created tag $TagName" -ForegroundColor Green
}

# Show tag details
Write-Host "`nTag details:" -ForegroundColor Cyan
git show $TagName --no-patch

# Create local release package
$packageName = "poshguard-$Version.zip"
$packagePath = Join-Path $RepoRoot $packageName

Write-Host "`nCreating release package..." -ForegroundColor Yellow
if (Test-Path $packagePath) {
    Remove-Item $packagePath -Force
}

# Define the list of files and directories to include in the release package
# NOTE: For PSGallery publishing, use Prepare-PSGalleryPackage.ps1 instead
$ReleaseFiles = @(
    'PoshGuard'
    'tools'
    'README.md'
    'LICENSE'
    'docs/CHANGELOG.md'
    'docs/SECURITY.md'
    'docs/CONTRIBUTING.md'
)

# Use Compress-Archive if available, otherwise use zip command
if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
    $FullPaths = $ReleaseFiles | ForEach-Object { Join-Path $RepoRoot $_ }
    Compress-Archive -Path $FullPaths -DestinationPath $packagePath
} else {
    # Fallback to system zip (external command requires explicit array expansion)
    if (-not (Get-Command zip -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Neither 'Compress-Archive' nor 'zip' command is available." -ForegroundColor Red
        Write-Host "Please install one of the following:" -ForegroundColor Yellow
        Write-Host "  • PowerShell 5.1+ (includes Compress-Archive)" -ForegroundColor Yellow
        Write-Host "  • System 'zip' utility (available on most Unix systems)" -ForegroundColor Yellow
        exit 1
    }

    Push-Location $RepoRoot
    try {
        & zip -r $packageName $ReleaseFiles
        if ($LASTEXITCODE -ne 0) {
            throw "zip command failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Pop-Location
        Write-Error "Failed to create release package with zip command: $_"
        exit 1
    }
    Pop-Location
}

Write-Host "✓ Created $packagePath" -ForegroundColor Green
$packageSize = (Get-Item $packagePath).Length / 1MB
Write-Host "  Package size: $($packageSize.ToString('F2')) MB" -ForegroundColor Gray

# Push tag if requested
if ($Push) {
    Write-Host "`nPushing tag to GitHub..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("origin", "Push tag $TagName")) {
        git push origin $TagName
        Write-Host "✓ Pushed $TagName to GitHub" -ForegroundColor Green
        Write-Host "`nRelease workflow will start automatically." -ForegroundColor Cyan
        Write-Host "Monitor at: https://github.com/cboyd0319/PoshGuard/actions" -ForegroundColor Cyan
    }
} else {
    Write-Host "`n⚠ Tag created locally but not pushed." -ForegroundColor Yellow
    Write-Host "To push and trigger release workflow, run:" -ForegroundColor Yellow
    Write-Host "  git push origin $TagName" -ForegroundColor White
    Write-Host "`nOr re-run with -Push parameter:" -ForegroundColor Yellow
    Write-Host "  ./tools/Create-Release.ps1 -Version $Version -Push" -ForegroundColor White
}

Write-Host "`n✓ Release preparation complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review the tag: git show $TagName" -ForegroundColor White
Write-Host "  2. Push to GitHub: git push origin $TagName" -ForegroundColor White
Write-Host "  3. Monitor release workflow: https://github.com/cboyd0319/PoshGuard/actions" -ForegroundColor White
