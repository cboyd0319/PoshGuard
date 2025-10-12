<#
.SYNOPSIS
    PoshGuard Best Practices Auto-Fix Module

.DESCRIPTION
    PowerShell coding standard and best practice enforcement functions.
    This is a facade module that imports all BestPractices submodules.

    Submodules:
    - Syntax: Semicolons, null comparisons, exclaim operator
    - Naming: Singular nouns, approved verbs, reserved characters
    - Scoping: Global variables, global functions
    - StringHandling: Double quotes, hashtable literals
    - TypeSafety: Automatic variables, type attributes, PSCredential
    - UsagePatterns: Positional parameters, unused variables, assignment operators
    - CodeQuality: Beyond-PSSA enhancements (TODO tracking, namespace optimization, etc.)

.NOTES
    Part of PoshGuard v2.4.0
    This facade module maintains backward compatibility while organizing
    functions into logical submodules for better maintainability.

.EXAMPLE
    Import-Module .\BestPractices.psm1

    Imports all BestPractices functions from all submodules.
#>

Set-StrictMode -Version Latest

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# Import all BestPractices submodules
$SubModules = @(
    'Syntax',
    'Naming',
    'Scoping',
    'StringHandling',
    'TypeSafety',
    'UsagePatterns',
    'CodeQuality'
)

foreach ($SubModule in $SubModules) {
    $SubModulePath = Join-Path -Path $ModuleRoot -ChildPath "BestPractices\$SubModule.psm1"
    if (Test-Path -Path $SubModulePath) {
        Import-Module -Name $SubModulePath -Force -ErrorAction Stop
    }
    else {
        Write-Warning "Submodule not found: $SubModulePath"
    }
}

# Export all functions from all BestPractices submodules
$FunctionsToExport = @(
    # Syntax
    'Invoke-SemicolonFix',
    'Invoke-NullComparisonFix',
    'Invoke-ExclaimOperatorFix',

    # Naming
    'Invoke-SingularNounFix',
    'Invoke-ApprovedVerbFix',
    'Invoke-ReservedCmdletCharFix',

    # Scoping
    'Invoke-GlobalVarFix',
    'Invoke-GlobalFunctionsFix',

    # StringHandling
    'Invoke-DoubleQuoteFix',
    'Invoke-LiteralHashtableFix',

    # TypeSafety
    'Invoke-AutomaticVariableFix',
    'Invoke-MultipleTypeAttributesFix',
    'Invoke-PSCredentialTypeFix',

    # UsagePatterns
    'Invoke-PositionalParametersFix',
    'Invoke-DeclaredVarsMoreThanAssignmentsFix',
    'Invoke-IncorrectAssignmentOperatorFix',
    
    # CodeQuality (Beyond-PSSA)
    'Invoke-TodoCommentDetectionFix',
    'Invoke-UnusedNamespaceDetectionFix',
    'Invoke-AsciiCharacterWarningFix',
    'Invoke-ConvertFromJsonOptimizationFix',
    'Invoke-SecureStringDisclosureFix'
)

Export-ModuleMember -Function $FunctionsToExport
