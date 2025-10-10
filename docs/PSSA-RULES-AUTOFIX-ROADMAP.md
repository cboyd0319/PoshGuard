# PSScriptAnalyzer Rules - Auto-Fix Roadmap

**Last Updated**: 2025-10-09
**Total PSSA Rules**: 70
**Currently Auto-Fixed**: 8 rules (11%)
**Auto-Fix Coverage Goal**: 30+ rules (43%)

---

## Current Auto-Fix Coverage (8/70 = 11%)

### ✅ Fully Auto-Fixed Rules

| Rule | Severity | Implementation | File |
|------|----------|----------------|------|
| PSUseConsistentIndentation | Warning | Invoke-Formatter | Apply-AutoFix.ps1:240-275 |
| PSUseConsistentWhitespace | Warning | Invoke-Formatter + Whitespace | Apply-AutoFix.ps1:240-275, 350-370 |
| PSAvoidTrailingWhitespace | Information | Invoke-WhitespaceFix | Apply-AutoFix.ps1:350-370 |
| PSAvoidUsingCmdletAliases | Warning | Invoke-AliasFix (AST-based) | Apply-AutoFix.ps1:277-348 |
| PSUseCorrectCasing | Information | Invoke-CasingFix (AST-based) | Apply-AutoFix.ps1:415-500 |
| PSPlaceOpenBrace | Warning | Invoke-Formatter | Apply-AutoFix.ps1:240-275 |
| PSPlaceCloseBrace | Warning | Invoke-Formatter | Apply-AutoFix.ps1:240-275 |

### 🟡 Partially Auto-Fixed Rules

| Rule | Severity | Implementation | Coverage | Notes |
|------|----------|----------------|----------|-------|
| PSAvoidUsingWriteHost | Warning | Invoke-WriteHostFix | ~70% | Preserves UI components (colors, emojis, formatting) |

---

## High Priority Auto-Fix Opportunities (6 rules)

These rules are straightforward to implement and provide high value:

### 🔥 PSAvoidUsingWMICmdlet (Warning)
**Issue**: Get-WmiObject is deprecated in PowerShell 7+
**Auto-Fix**: Replace with Get-CimInstance
**Complexity**: Medium (AST-based replacement)
**Example**:
```powershell
# Before:
Get-WmiObject -Class Win32_Process

# After:
Get-CimInstance -ClassName Win32_Process
```
**Implementation Strategy**:
- AST-based CommandAst detection
- Map WMI class parameters to CIM equivalents
- Handle common parameter translations

---

### 🔥 PSUseBOMForUnicodeEncodedFile (Warning)
**Issue**: Unicode files should have BOM for proper encoding detection
**Auto-Fix**: Add UTF-8 BOM when file contains non-ASCII characters
**Complexity**: Easy
**Example**:
```powershell
# Detect non-ASCII characters, add UTF-8 BOM
[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $true))
```
**Implementation Strategy**:
- Check if file contains non-ASCII characters
- Add UTF-8 BOM if missing
- Already partially implemented in Apply-AutoFix.ps1:687-694

---

### 🔥 PSUseApprovedVerbs (Warning)
**Issue**: Functions should use approved PowerShell verbs
**Auto-Fix**: Suggest approved verb or add to approved list
**Complexity**: Medium
**Example**:
```powershell
# Before:
function Validate-Input { }

# After:
function Test-Input { }  # Validate → Test
```
**Implementation Strategy**:
- Parse function names
- Use `Get-Verb` to find approved alternatives
- Map common unapproved verbs (Validate → Test, Check → Test, etc.)

---

### 🔥 PSUseSingularNouns (Warning)
**Issue**: Function nouns should be singular
**Auto-Fix**: Convert plural nouns to singular
**Complexity**: Easy
**Example**:
```powershell
# Before:
function Get-Users { }

# After:
function Get-User { }
```
**Implementation Strategy**:
- Simple pluralization rules (remove trailing 's', 'es', 'ies' → 'y')
- Use PowerShell.Pluralization library if available

---

### 🔥 PSAvoidSemicolonsAsLineTerminators (Warning)
**Issue**: Semicolons are unnecessary in PowerShell (not C#)
**Auto-Fix**: Remove trailing semicolons
**Complexity**: Easy
**Example**:
```powershell
# Before:
$x = 5;
Write-Host "Hello";

# After:
$x = 5
Write-Host "Hello"
```
**Implementation Strategy**:
- AST token-based detection
- Remove semicolons that are line terminators (not statement separators)

---

### 🔥 PSAvoidLongLines (Warning)
**Issue**: Lines should be <= 120 characters for readability
**Auto-Fix**: Intelligent line wrapping
**Complexity**: Hard (requires context awareness)
**Example**:
```powershell
# Before:
$result = Get-ChildItem -Path C:\VeryLongPath\With\Many\Subdirectories -Filter *.ps1 -Recurse -ErrorAction Stop

# After:
$result = Get-ChildItem `
    -Path C:\VeryLongPath\With\Many\Subdirectories `
    -Filter *.ps1 `
    -Recurse `
    -ErrorAction Stop
```
**Implementation Strategy**:
- AST-based line length detection
- Intelligent parameter wrapping
- Respect splatting opportunities

---

## Medium Priority Auto-Fix Opportunities (7 rules)

These require more complex logic but are feasible:

### ⚠️ PSPossibleIncorrectComparisonWithNull (Warning)
**Issue**: $null should be on left side of comparison
**Auto-Fix**: Swap comparison order
**Complexity**: Easy (already partially implemented)
**Current Implementation**: Apply-AutoFix.ps1:592 (Invoke-SafetyFix)
```powershell
# Already handles: $var -eq $null → $null -eq $var
```

---

### ⚠️ PSAvoidGlobalVars (Warning)
**Issue**: Global variables should be avoided
**Auto-Fix**: Convert to script-scoped or add explicit $script:
**Complexity**: Medium
**Example**:
```powershell
# Before:
$global:Config = @{}

# After:
$script:Config = @{}
```

---

### ⚠️ PSAvoidGlobalFunctions (Warning)
**Issue**: Functions should be scoped appropriately
**Auto-Fix**: Add explicit scope or make private
**Complexity**: Medium

---

### ⚠️ PSReviewUnusedParameter (Warning)
**Issue**: Parameters declared but never used
**Auto-Fix**: Comment out or add underscore prefix
**Complexity**: Medium (requires AST analysis)
```powershell
# Before:
function Test-Foo {
    param($Used, $Unused)
    Write-Output $Used
}

# After:
function Test-Foo {
    param($Used)  # Removed: $Unused
    Write-Output $Used
}
```

---

### ⚠️ PSProvideCommentHelp (Information)
**Issue**: Functions should have comment-based help
**Auto-Fix**: Generate basic help template
**Complexity**: Easy
```powershell
# Add before function:
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.EXAMPLE
    PS C:\> Verb-Noun
    Example usage
#>
```

---

### ⚠️ PSShouldProcess (Warning)
**Issue**: Functions with state-changing verbs should support -WhatIf
**Auto-Fix**: Add ShouldProcess scaffolding
**Complexity**: Hard
**Example**:
```powershell
# Before:
function Remove-Item { }

# After:
[CmdletBinding(SupportsShouldProcess)]
function Remove-Item {
    if ($PSCmdlet.ShouldProcess($target, "Remove")) {
        # actual logic
    }
}
```

---

### ⚠️ PSUseSupportsShouldProcess (Warning)
**Issue**: Functions using $PSCmdlet.ShouldProcess need [CmdletBinding(SupportsShouldProcess)]
**Auto-Fix**: Add SupportsShouldProcess to CmdletBinding
**Complexity**: Easy

---

## Low Priority (Requires Human Judgment - 5+ rules)

These rules generally indicate design issues that require human review:

### ℹ️ Cannot Auto-Fix (Human Review Required)

| Rule | Severity | Reason |
|------|----------|--------|
| PSAvoidInvokingEmptyMembers | Warning | Requires understanding of runtime state |
| PSAvoidOverwritingBuiltInCmdlets | Warning | May be intentional (function shadowing) |
| PSAvoidDefaultValueForMandatoryParameter | Warning | Logic error - no safe auto-fix |
| PSAvoidUsingEmptyCatchBlock | Warning | Requires understanding of error handling intent |
| PSAvoidInvokeExpression | Warning | Security issue - requires code refactoring |
| PSAvoidUsingPlainTextForPassword | Warning | Security issue - requires SecureString refactoring |
| PSAvoidUsingComputerNameHardcoded | Error | Design issue - requires parameterization |
| PSAvoidUsingConvertToSecureStringWithPlainText | Error | Security issue - requires proper secret management |

---

## Not Applicable (DSC-Specific Rules - 7 rules)

These rules only apply to DSC resources:

- PSDSCDscExamplesPresent
- PSDSCDscTestsPresent
- PSDSCReturnCorrectTypesForDSCFunctions
- PSDSCStandardDSCFunctionsInResource
- PSDSCUseIdenticalMandatoryParametersForDSC
- PSDSCUseIdenticalParametersForDSC
- PSDSCUseVerboseMessageInDSCResource

---

## Implementation Roadmap

### Phase 1: Quick Wins (v4.1) - 6 rules
Target: 14/70 = 20% coverage

1. ✅ **PSUseBOMForUnicodeEncodedFile** - Already 90% implemented
2. 🔥 **PSAvoidSemicolonsAsLineTerminators** - Easy AST fix
3. 🔥 **PSUseSingularNouns** - Simple string manipulation
4. 🔥 **PSUseApprovedVerbs** - Verb mapping table
5. ⚠️ **PSPossibleIncorrectComparisonWithNull** - Already 50% implemented
6. ⚠️ **PSProvideCommentHelp** - Template injection

**Estimated Effort**: 2-3 days

### Phase 2: High-Value Complex Fixes (v4.2) - 4 rules
Target: 18/70 = 26% coverage

1. 🔥 **PSAvoidUsingWMICmdlet** - WMI → CIM conversion
2. 🔥 **PSAvoidLongLines** - Intelligent line wrapping
3. ⚠️ **PSReviewUnusedParameter** - AST-based parameter analysis
4. ⚠️ **PSUseSupportsShouldProcess** - CmdletBinding attribute fix

**Estimated Effort**: 5-7 days

### Phase 3: Advanced Scaffolding (v5.0) - 3 rules
Target: 21/70 = 30% coverage

1. ⚠️ **PSShouldProcess** - Full ShouldProcess scaffolding
2. ⚠️ **PSAvoidGlobalVars** - Scope refactoring
3. ⚠️ **PSAvoidGlobalFunctions** - Function scoping

**Estimated Effort**: 7-10 days

---

## Success Metrics

| Metric | Current | Phase 1 | Phase 2 | Phase 3 |
|--------|---------|---------|---------|---------|
| Rules Auto-Fixed | 8 | 14 | 18 | 21 |
| Coverage % | 11% | 20% | 26% | 30% |
| High-Priority Coverage | 0/6 | 4/6 | 6/6 | 6/6 |
| External Script Test | 93% | 95%+ | 97%+ | 98%+ |

---

## All 70 PSSA Rules - Complete Reference

### Error Severity (8 rules)
- PSAvoidUsingComputerNameHardcoded
- PSAvoidUsingConvertToSecureStringWithPlainText
- PSAvoidUsingUsernameAndPasswordParams
- PSDSCStandardDSCFunctionsInResource
- PSDSCUseIdenticalMandatoryParametersForDSC
- PSDSCUseIdenticalParametersForDSC
- PSReservedParams
- PSUseCompatibleSyntax

### Warning Severity (51 rules)
- PSAlignAssignmentStatement
- PSAvoidAssignmentToAutomaticVariable
- PSAvoidDefaultValueForMandatoryParameter
- PSAvoidDefaultValueSwitchParameter
- PSAvoidExclaimOperator
- PSAvoidGlobalAliases
- PSAvoidGlobalFunctions
- PSAvoidGlobalVars
- PSAvoidInvokingEmptyMembers
- PSAvoidLongLines
- PSAvoidMultipleTypeAttributes
- PSAvoidNullOrEmptyHelpMessageAttribute
- PSAvoidOverwritingBuiltInCmdlets
- PSAvoidSemicolonsAsLineTerminators
- PSAvoidShouldContinueWithoutForce
- PSAvoidUsingAllowUnencryptedAuthentication
- PSAvoidUsingBrokenHashAlgorithms
- PSAvoidUsingCmdletAliases ✅
- PSAvoidUsingEmptyCatchBlock
- PSAvoidUsingInvokeExpression
- PSAvoidUsingPlainTextForPassword
- PSAvoidUsingWMICmdlet 🔥
- PSAvoidUsingWriteHost 🟡
- PSMisleadingBacktick
- PSMissingModuleManifestField
- PSPlaceCloseBrace ✅
- PSPlaceOpenBrace ✅
- PSPossibleIncorrectComparisonWithNull ⚠️
- PSPossibleIncorrectUsageOfRedirectionOperator
- PSReservedCmdletChar
- PSReviewUnusedParameter ⚠️
- PSShouldProcess ⚠️
- PSUseApprovedVerbs 🔥
- PSUseBOMForUnicodeEncodedFile 🔥
- PSUseCmdletCorrectly
- PSUseCompatibleCmdlets
- PSUseCompatibleCommands
- PSUseCompatibleTypes
- PSUseConsistentIndentation ✅
- PSUseConsistentWhitespace ✅
- PSUseLiteralInitializerForHashtable
- PSUseDeclaredVarsMoreThanAssignments
- PSUseProcessBlockForPipelineCommand
- PSUsePSCredentialType
- PSUseShouldProcessForStateChangingFunctions
- PSUseSingularNouns 🔥
- PSUseSupportsShouldProcess ⚠️
- PSUseToExportFieldsInManifest
- PSUseUsingScopeModifierInNewRunspaces
- PSUseUTF8EncodingForHelpFile

### Information Severity (11 rules)
- PSAvoidTrailingWhitespace ✅
- PSAvoidUsingDoubleQuotesForConstantString
- PSAvoidUsingPositionalParameters
- PSDSCDscExamplesPresent
- PSDSCDscTestsPresent
- PSDSCReturnCorrectTypesForDSCFunctions
- PSDSCUseVerboseMessageInDSCResource
- PSPossibleIncorrectUsageOfAssignmentOperator
- PSProvideCommentHelp ⚠️
- PSUseCorrectCasing ✅
- PSUseOutputTypeCorrectly

---

**Legend**:
- ✅ Currently auto-fixed (8 rules)
- 🟡 Partially auto-fixed (1 rule)
- 🔥 High priority for implementation (6 rules)
- ⚠️ Medium priority for implementation (7 rules)
- ℹ️ Low priority - requires human judgment

---

*This roadmap is a living document and will be updated as new auto-fix capabilities are implemented.*
