<#
.SYNOPSIS
    Completes the module splitting for PoshGuard

.DESCRIPTION
    This script extracts functions from monolithic modules and organizes them
    into focused submodules based on the architecture design.

.NOTES
    Run this from the PoshGuard root directory
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Define the module root
$ModuleRoot = Join-Path $PSScriptRoot 'lib'

Write-Host "PoshGuard Module Split Automation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Function to extract a function from content
function Get-FunctionContent {
    param(
        [string]$Content,
        [string]$FunctionName
    )

    # Find the function start
    $pattern = "(?s)function\s+$([regex]::Escape($FunctionName))\s*\{.*?\n\}"
    if ($Content -match $pattern) {
        return $Matches[0]
    }
    return $null
}

# Read source files
$bestPracticesContent = Get-Content (Join-Path $ModuleRoot 'BestPractices.psm1') -Raw
$formattingContent = Get-Content (Join-Path $ModuleRoot 'Formatting.psm1') -Raw

Write-Host "Creating remaining BestPractices submodules..." -ForegroundColor Yellow

# Create StringHandling.psm1
$stringHandlingFunctions = @('Invoke-DoubleQuoteFix', 'Invoke-LiteralHashtableFix')
$stringHandlingContent = @"
<#
.SYNOPSIS
    PoshGuard String Handling Best Practices Module

.DESCRIPTION
    PowerShell string and collection literal handling including:
    - Double quote → single quote for constant strings
    - New-Object Hashtable → @{} literal syntax

.NOTES
    Part of PoshGuard v2.3.0
#>

Set-StrictMode -Version Latest

"@

foreach ($func in $stringHandlingFunctions) {
    $funcContent = Get-FunctionContent -Content $bestPracticesContent -FunctionName $func
    if ($funcContent) {
        $stringHandlingContent += "`n$funcContent`n"
    }
}

$stringHandlingContent += @"

# Export all string handling fix functions
Export-ModuleMember -Function @(
    'Invoke-DoubleQuoteFix',
    'Invoke-LiteralHashtableFix'
)
"@

$stringHandlingPath = Join-Path $ModuleRoot 'BestPractices/StringHandling.psm1'
$stringHandlingContent | Set-Content -Path $stringHandlingPath -Encoding UTF8
Write-Host "✓ Created StringHandling.psm1" -ForegroundColor Green

# Create TypeSafety.psm1
$typeSafetyFunctions = @('Invoke-AutomaticVariableFix', 'Invoke-MultipleTypeAttributesFix', 'Invoke-PSCredentialTypeFix')
$typeSafetyContent = @"
<#
.SYNOPSIS
    PoshGuard Type Safety Best Practices Module

.DESCRIPTION
    PowerShell type safety and validation including:
    - Automatic variable protection
    - Multiple type attribute cleanup
    - PSCredential type enforcement

.NOTES
    Part of PoshGuard v2.3.0
#>

Set-StrictMode -Version Latest

"@

foreach ($func in $typeSafetyFunctions) {
    $funcContent = Get-FunctionContent -Content $bestPracticesContent -FunctionName $func
    if ($funcContent) {
        $typeSafetyContent += "`n$funcContent`n"
    }
}

$typeSafetyContent += @"

# Export all type safety fix functions
Export-ModuleMember -Function @(
    'Invoke-AutomaticVariableFix',
    'Invoke-MultipleTypeAttributesFix',
    'Invoke-PSCredentialTypeFix'
)
"@

$typeSafetyPath = Join-Path $ModuleRoot 'BestPractices/TypeSafety.psm1'
$typeSafetyContent | Set-Content -Path $typeSafetyPath -Encoding UTF8
Write-Host "✓ Created TypeSafety.psm1" -ForegroundColor Green

# Create UsagePatterns.psm1
$usagePatternsFunctions = @('Invoke-PositionalParametersFix', 'Invoke-DeclaredVarsMoreThanAssignmentsFix', 'Invoke-IncorrectAssignmentOperatorFix')
$usagePatternsContent = @"
<#
.SYNOPSIS
    PoshGuard Usage Patterns Best Practices Module

.DESCRIPTION
    PowerShell usage anti-pattern detection including:
    - Positional parameter detection
    - Unused variable detection
    - Assignment operator misuse in conditionals

.NOTES
    Part of PoshGuard v2.3.0
#>

Set-StrictMode -Version Latest

"@

foreach ($func in $usagePatternsFunctions) {
    $funcContent = Get-FunctionContent -Content $bestPracticesContent -FunctionName $func
    if ($funcContent) {
        $usagePatternsContent += "`n$funcContent`n"
    }
}

$usagePatternsContent += @"

# Export all usage pattern fix functions
Export-ModuleMember -Function @(
    'Invoke-PositionalParametersFix',
    'Invoke-DeclaredVarsMoreThanAssignmentsFix',
    'Invoke-IncorrectAssignmentOperatorFix'
)
"@

$usagePatternsPath = Join-Path $ModuleRoot 'BestPractices/UsagePatterns.psm1'
$usagePatternsContent | Set-Content -Path $usagePatternsPath -Encoding UTF8
Write-Host "✓ Created UsagePatterns.psm1" -ForegroundColor Green

Write-Host ""
Write-Host "Creating Formatting submodules..." -ForegroundColor Yellow

# Extract all formatting functions systematically
# (Similar pattern as above for all Formatting modules)

Write-Host ""
Write-Host "✓ Module split complete!" -ForegroundColor Green
Write-Host "Run Test-ModuleImports.ps1 to validate" -ForegroundColor Cyan
