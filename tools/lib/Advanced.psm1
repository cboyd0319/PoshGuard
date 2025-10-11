<#
.SYNOPSIS
    PoshGuard Advanced Auto-Fix Module (Facade)

.DESCRIPTION
    This is a facade module that imports all Advanced category submodules.
    It maintains backward compatibility while providing a modular architecture.

    Submodules:
    - ASTTransformations: WMI→CIM, hash algorithms, long lines
    - ParameterManagement: Reserved params, switch defaults, unused params, HelpMessage
    - CodeAnalysis: Safety fixes, duplicate lines, cmdlet parameter validation
    - Documentation: Comment-based help, OutputType
    - AttributeManagement: SupportsShouldProcess, CmdletBinding, Process blocks
    - ManifestManagement: Module manifest validation, export fields, alias scoping

.NOTES
    Part of PoshGuard v2.7.0
    This module automatically imports all Advanced submodules for convenience.
#>

Set-StrictMode -Version Latest

# Get the directory where this module resides
$ModuleRoot = $PSScriptRoot

# Import all Advanced submodules
$SubModules = @(
    'ASTTransformations',
    'ParameterManagement',
    'CodeAnalysis',
    'Documentation',
    'AttributeManagement',
    'ManifestManagement'
)

foreach ($SubModule in $SubModules) {
    $SubModulePath = Join-Path -Path $ModuleRoot -ChildPath "Advanced\$SubModule.psm1"

    if (Test-Path -Path $SubModulePath) {
        try {
            Import-Module -Name $SubModulePath -Force -ErrorAction Stop
            Write-Verbose "Imported Advanced submodule: $SubModule"
        }
        catch {
            Write-Warning "Failed to import Advanced submodule $SubModule : $_"
        }
    }
    else {
        Write-Warning "Advanced submodule not found: $SubModulePath"
    }
}

# Re-export all functions from submodules for backward compatibility
$FunctionsToExport = @(
    # ASTTransformations.psm1
    'Invoke-WmiToCimFix',
    'Invoke-BrokenHashAlgorithmFix',
    'Invoke-LongLinesFix',

    # ParameterManagement.psm1
    'Invoke-ReservedParamsFix',
    'Invoke-SwitchParameterDefaultFix',
    'Invoke-UnusedParameterFix',
    'Invoke-NullHelpMessageFix',

    # CodeAnalysis.psm1
    'Invoke-SafetyFix',
    'Invoke-DuplicateLineFix',
    'Invoke-CmdletParameterFix',

    # Documentation.psm1
    'Invoke-CommentHelpFix',
    'Invoke-OutputTypeCorrectlyFix',

    # AttributeManagement.psm1
    'Invoke-SupportsShouldProcessFix',
    'Invoke-ShouldProcessForStateChangingFix',
    'Invoke-CmdletCorrectlyFix',
    'Invoke-ProcessBlockForPipelineFix',

    # ManifestManagement.psm1
    'Invoke-MissingModuleManifestFieldFix',
    'Invoke-UseToExportFieldsInManifestFix',
    'Invoke-AvoidGlobalAliasesFix'
)

Export-ModuleMember -Function $FunctionsToExport
