<#
.SYNOPSIS
    PoshGuard Formatting Auto-Fix Module

.DESCRIPTION
    Code formatting and style enforcement functions.
    This is a facade module that imports all Formatting submodules.

    Submodules:
    - Whitespace: Formatter, trailing whitespace, misleading backticks
    - Aliases: Alias expansion (gci → Get-ChildItem)
    - Casing: Cmdlet and parameter PascalCase
    - Output: Write-Host → Write-Output, redirection operators
    - Alignment: Assignment alignment
    - Runspaces: $using: scope, ShouldContinue checks

.NOTES
    Part of PoshGuard v2.4.0
    This facade module maintains backward compatibility while organizing
    functions into logical submodules for better maintainability.

.EXAMPLE
    Import-Module .\Formatting.psm1

    Imports all Formatting functions from all submodules.
#>

Set-StrictMode -Version Latest

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# Import all Formatting submodules
$SubModules = @(
    'Whitespace',
    'Aliases',
    'Casing',
    'Output',
    'Alignment',
    'Runspaces',
    'WriteHostEnhanced'
)

foreach ($SubModule in $SubModules) {
    $SubModulePath = Join-Path -Path $ModuleRoot -ChildPath "Formatting\$SubModule.psm1"
    if (Test-Path -Path $SubModulePath) {
        Import-Module -Name $SubModulePath -Force -ErrorAction Stop
    }
    else {
        Write-Warning "Submodule not found: $SubModulePath"
    }
}

# Export all functions from all Formatting submodules
$FunctionsToExport = @(
    # Whitespace
    'Invoke-FormatterFix',
    'Invoke-WhitespaceFix',
    'Invoke-MisleadingBacktickFix',

    # Aliases
    'Invoke-AliasFix',
    'Invoke-AliasFixAst',

    # Casing
    'Invoke-CasingFix',

    # Output
    'Invoke-WriteHostFix',
    'Invoke-WriteHostEnhancedFix',
    'Invoke-RedirectionOperatorFix',

    # Alignment
    'Invoke-AlignAssignmentFix',

    # Runspaces
    'Invoke-UsingScopeModifierFix',
    'Invoke-ShouldContinueWithoutForceFix'
)

Export-ModuleMember -Function $FunctionsToExport
