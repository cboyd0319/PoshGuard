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

# For PowerShell Gallery installations, modules are in PoshGuard/lib/
# For development, they're in ../tools/lib/
$LibPath = if (Test-Path (Join-Path $ModuleRoot 'lib')) {
    Join-Path $ModuleRoot 'lib'
} else {
    Join-Path (Split-Path $ModuleRoot -Parent) 'tools' 'lib'
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

    # Locate Apply-AutoFix.ps1
    $DevScriptPath = Join-Path (Split-Path $ModuleRoot -Parent) 'tools' 'Apply-AutoFix.ps1'
    $GalleryScriptPath = Join-Path $ModuleRoot 'Apply-AutoFix.ps1'
    
    $ScriptPath = if (Test-Path $DevScriptPath) {
        $DevScriptPath
    } elseif (Test-Path $GalleryScriptPath) {
        $GalleryScriptPath
    } else {
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
