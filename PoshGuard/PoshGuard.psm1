<#
.SYNOPSIS
    PoshGuard - PowerShell Auto-Fix Engine

.DESCRIPTION
    Root module for PoshGuard. This module loads all submodules and exports
    the main entry point functions for PowerShell Gallery installation.

.NOTES
    Part of PoshGuard v4.3.0
    For direct repo usage, use ./tools/Apply-AutoFix.ps1
    For module usage, use the exported functions below.
#>

Set-StrictMode -Version Latest

# Get the directory where this module resides
$ModuleRoot = $PSScriptRoot

<#
.SYNOPSIS
    Helper function to resolve paths based on installation location

.DESCRIPTION
    Resolves file paths for both PowerShell Gallery installations and development/repository installations.
    Checks Gallery path first, then Dev path, returning the first valid path found.

.PARAMETER GalleryRelativePath
    Relative path for PowerShell Gallery installation structure (relative to module root)

.PARAMETER DevRelativePath
    Relative path for development/repository installation structure (relative to parent of module root)

.OUTPUTS
    System.String
    Returns the resolved absolute path, or $null if neither path exists

.EXAMPLE
    $libPath = Resolve-PoshGuardPath -GalleryRelativePath 'lib' -DevRelativePath 'tools/lib'
    Resolves the library path for the current installation type

.NOTES
    This function enables PoshGuard to work in both installed and development environments
#>
function Resolve-PoshGuardPath {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$GalleryRelativePath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DevRelativePath
  )

  $GalleryPath = Join-Path $ModuleRoot $GalleryRelativePath
  $DevPath = Join-Path (Split-Path $ModuleRoot -Parent) $DevRelativePath

  if (Test-Path $GalleryPath) {
    return $GalleryPath
  }
  elseif (Test-Path $DevPath) {
    return $DevPath
  }
  else {
    return $null
  }
}

# Resolve library path (Gallery: PoshGuard/lib/, Dev: tools/lib/)
$LibPath = Resolve-PoshGuardPath -GalleryRelativePath 'lib' -DevRelativePath (Join-Path 'tools' 'lib')

if (-not $LibPath) {
  $warningMessage = @"
PoshGuard library path not found. Module may not function correctly.

Installation Checklist:
- PowerShell Gallery: Ensure 'lib' directory exists under: $ModuleRoot
- Repository Clone: Ensure 'tools/lib/' exists relative to the repo root
- Module Root Detected: $ModuleRoot

Troubleshooting:
1. Reinstall the module: Install-Module PoshGuard -Force
2. For repo usage, ensure you're in the repository root directory
3. Verify directory structure matches documentation at:
   https://github.com/cboyd0319/PoshGuard#install

Expected Paths Checked:
- Gallery: $(Join-Path -Path $ModuleRoot -ChildPath 'lib')
- Dev: $(Join-Path -Path (Split-Path -Path $ModuleRoot -Parent) -ChildPath 'tools/lib')
"@
  Write-Warning $warningMessage
}

# Import core modules if they exist
$CoreModules = @('Core', 'Security', 'BestPractices', 'Formatting', 'Advanced')
foreach ($Module in $CoreModules) {
  $ModulePath = Join-Path $LibPath "$Module.psm1"
  if (Test-Path $ModulePath) {
    try {
      Import-Module $ModulePath -Force -ErrorAction Stop
      Write-Verbose "Loaded PoshGuard module: $Module"
    } catch {
      Write-Warning "Failed to load PoshGuard module $Module : $_"
    }
  }
}

# Main entry point function for module usage
function Invoke-PoshGuard {
  <#
    .SYNOPSIS
        Run PoshGuard auto-fix on PowerShell scripts.

    .DESCRIPTION
        Analyzes and automatically fixes PowerShell scripts using PSScriptAnalyzer
        rules. Supports dry-run, backups, and diff output.

    .PARAMETER Path
        Path to script or directory to analyze.

    .PARAMETER DryRun
        Show what would be fixed without making changes.

    .PARAMETER ShowDiff
        Display unified diff of changes.

    .PARAMETER Recurse
        Process directories recursively.

    .PARAMETER Skip
        Array of rule names to skip.

    .PARAMETER ExportSarif
        Export analysis results in SARIF format for GitHub Code Scanning.

    .PARAMETER SarifOutputPath
        Path where SARIF file should be saved (default: ./poshguard-results.sarif).

    .PARAMETER FastScan
        Use RipGrep pre-filtering to scan only suspicious files (5-10x faster for large codebases).
        Requires RipGrep to be installed. Falls back to full scan if not available.

    .EXAMPLE
        Invoke-PoshGuard -Path ./MyScript.ps1 -DryRun

    .EXAMPLE
        Invoke-PoshGuard -Path ./src -Recurse -ShowDiff

    .EXAMPLE
        Invoke-PoshGuard -Path ./src -DryRun -ExportSarif -SarifOutputPath ./results.sarif
        Analyze code and export results in SARIF format for GitHub Security tab

    .EXAMPLE
        Invoke-PoshGuard -Path ./src -FastScan -Recurse
        Use RipGrep pre-filtering for faster scanning of large codebases
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Path,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$ShowDiff,

    [Parameter()]
    [switch]$Recurse,

    [Parameter()]
    [string[]]$Skip,

    [Parameter()]
    [switch]$ExportSarif,

    [Parameter()]
    [string]$SarifOutputPath = './poshguard-results.sarif',

    [Parameter()]
    [switch]$FastScan
  )

  # Locate Apply-AutoFix.ps1 using helper function
  $ScriptPath = Resolve-PoshGuardPath `
    -GalleryRelativePath 'Apply-AutoFix.ps1' `
    -DevRelativePath (Join-Path 'tools' 'Apply-AutoFix.ps1')

  if (-not $ScriptPath) {
    throw "Cannot locate Apply-AutoFix.ps1. Please ensure module installation is complete."
  }

  # Build parameter splat
  $params = @{
    Path = $Path
  }

  if ($DryRun) { $params['DryRun'] = $true }
  if ($ShowDiff) { $params['ShowDiff'] = $true }
  if ($Recurse) { $params['Recurse'] = $true }
  if ($Skip) { $params['Skip'] = $Skip }
  if ($ExportSarif) { $params['ExportSarif'] = $true }
  if ($SarifOutputPath) { $params['SarifOutputPath'] = $SarifOutputPath }
  if ($FastScan) { $params['FastScan'] = $true }

  # Execute the script
  & $ScriptPath @params
}

# Export main function
Export-ModuleMember -Function Invoke-PoshGuard
