<#
.SYNOPSIS
    PoshGuard - PowerShell Auto-Fix Engine

.DESCRIPTION
    Root module for PoshGuard. This module loads all submodules and exports
    the main entry point functions for PowerShell Gallery installation.

.NOTES
    Part of PoshGuard v3.0.0
    For direct repo usage, use ./tools/Apply-AutoFix.ps1
    For module usage, use the exported functions below.
#>

Set-StrictMode -Version Latest

# Get the directory where this module resides
$ModuleRoot = $PSScriptRoot

# Helper function to resolve paths based on installation location
function Resolve-PoshGuardPath {
    param(
        [string]$GalleryRelativePath,
        [string]$DevRelativePath
    )
    
    $GalleryPath = Join-Path $ModuleRoot $GalleryRelativePath
    $DevPath = Join-Path (Split-Path $ModuleRoot -Parent) $DevRelativePath
    
    if (Test-Path $GalleryPath) {
        return $GalleryPath
    } elseif (Test-Path $DevPath) {
        return $DevPath
    } else {
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
- Gallery: $(Join-Path $ModuleRoot 'lib')
- Dev: $(Join-Path (Split-Path $ModuleRoot -Parent) 'tools' 'lib')
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
        }
        catch {
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

    .EXAMPLE
        Invoke-PoshGuard -Path ./MyScript.ps1 -DryRun

    .EXAMPLE
        Invoke-PoshGuard -Path ./src -Recurse -ShowDiff
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Path,

        [Parameter()]
        [switch]$DryRun,

        [Parameter()]
        [switch]$ShowDiff,

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [string[]]$Skip
    )

    # Locate Apply-AutoFix.ps1 using helper function
    $ScriptPath = Resolve-PoshGuardPath -GalleryRelativePath 'Apply-AutoFix.ps1' `
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

    # Execute the script
    & $ScriptPath @params
}

# Export main function
Export-ModuleMember -Function Invoke-PoshGuard
