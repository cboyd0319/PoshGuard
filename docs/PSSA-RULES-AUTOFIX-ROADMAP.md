# PSScriptAnalyzer Rules - Auto-Fix Roadmap

**Last Updated**: 2025-10-10
**Total PSSA Rules**: 70
**Currently Auto-Fixed**: 17 rules (24%)
**Auto-Fix Coverage Goal**: 30+ rules (43%)

---

## Current Auto-Fix Coverage (17/70 = 24%)

### ✅ Fully Auto-Fixed Rules

| Rule | Severity | Implementation | File |
|------|----------|----------------|------|
| PSUseConsistentIndentation | Warning | Invoke-Formatter | Apply-AutoFix.ps1:229-257 |
| PSUseConsistentWhitespace | Warning | Invoke-Formatter + Whitespace | Apply-AutoFix.ps1:229-257, 259-276 |
| PSAvoidTrailingWhitespace | Information | Invoke-WhitespaceFix | Apply-AutoFix.ps1:259-276 |
| PSAvoidUsingCmdletAliases | Warning | Invoke-AliasFix (AST-based) | Apply-AutoFix.ps1:278-349 |
| PSUseCorrectCasing | Information | Invoke-CasingFix (AST-based) | Apply-AutoFix.ps1:517-604 |
| PSPlaceOpenBrace | Warning | Invoke-Formatter | Apply-AutoFix.ps1:229-257 |
| PSPlaceCloseBrace | Warning | Invoke-Formatter | Apply-AutoFix.ps1:229-257 |
| **PSAvoidSemicolonsAsLineTerminators** ⭐ | Warning | Invoke-SemicolonFix (AST token-based) | Apply-AutoFix.ps1:606-685 |
| **PSUseSingularNouns** ⭐ | Warning | Invoke-SingularNounFix (AST-based) | Apply-AutoFix.ps1:687-802 |
| **PSUseApprovedVerbs** ⭐ | Warning | Invoke-ApprovedVerbFix (AST-based + verb mapping) | Apply-AutoFix.ps1:912-1103 |
| **PSUseSupportsShouldProcess** ⭐ | Warning | Invoke-SupportsShouldProcessFix (AST-based) | Apply-AutoFix.ps1:1105-1214 |
| **PSAvoidGlobalVars** ⭐ | Warning | Invoke-GlobalVarFix (AST-based scope conversion) | Apply-AutoFix.ps1:1216-1285 |
| **PSAvoidUsingDoubleQuotesForConstantString** ⭐ | Information | Invoke-DoubleQuoteFix (AST string analysis) | Apply-AutoFix.ps1:1287-1365 |
| **PSUseBOMForUnicodeEncodedFile** ⭐ | Warning | Auto-detection + UTF8-BOM | Apply-AutoFix.ps1:1713-1717 |
| **PSProvideCommentHelp** ⭐ | Information | Invoke-CommentHelpFix (AST-based) | Apply-AutoFix.ps1:1367-1485 |
| **PSPossibleIncorrectComparisonWithNull** ⭐ | Warning | Invoke-NullComparisonFix (AST-based) | Apply-AutoFix.ps1:351-454 |

### 🟡 Partially Auto-Fixed Rules

| Rule | Severity | Implementation | Coverage | Notes |
|------|----------|----------------|----------|-------|
| PSAvoidUsingWriteHost | Warning | Invoke-WriteHostFix | ~70% | Preserves UI components (colors, emojis, formatting) |

---

## High Priority Auto-Fix Opportunities ✅ **ALL COMPLETED**

All high-priority quick wins from Phase 1 have been implemented:

### ✅ ~~PSAvoidSemicolonsAsLineTerminators~~ (Warning) - **COMPLETED**
**Status**: Fully implemented
**Implementation**: AST token-based detection and removal of trailing semicolons
**File**: Apply-AutoFix.ps1:606-685
**Completion Date**: 2025-10-10

---

### ✅ ~~PSUseSingularNouns~~ (Warning) - **COMPLETED**
**Status**: Fully implemented
**Implementation**: AST-based function name detection with pluralization rules
**File**: Apply-AutoFix.ps1:687-802
**Completion Date**: 2025-10-10

---

### ✅ ~~PSUseApprovedVerbs~~ (Warning) - **COMPLETED**
**Status**: Fully implemented
**Implementation**: AST-based verb detection with comprehensive unapproved→approved verb mappings (30+ mappings)
**File**: Apply-AutoFix.ps1:912-1103
**Completion Date**: 2025-10-10
**Mappings**: Validate→Test, Check→Test, Create→New, Delete→Remove, Display→Show, Fetch→Get, Modify→Set, and 20+ more

---

### ✅ ~~PSUseBOMForUnicodeEncodedFile~~ (Warning) - **COMPLETED**
**Status**: Fully implemented (was already 90% complete)
**Implementation**: Automatic UTF8-BOM detection and addition for files with non-ASCII characters
**File**: Apply-AutoFix.ps1:1447-1451
**Completion Date**: 2025-10-10

---

## Phase 2: High-Value Complex Fixes (Next Priority)

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

## Medium Priority Auto-Fix Opportunities (2 rules remaining)

These require more complex logic but are feasible:

### ✅ ~~PSPossibleIncorrectComparisonWithNull~~ (Warning) - **COMPLETED**
**Status**: Fully implemented with AST-based approach (previously was basic regex)
**Implementation**: Full AST-based binary expression analysis with support for all comparison operators
**File**: Apply-AutoFix.ps1:351-454
**Completion Date**: 2025-10-10
**Handles**: -eq, -ne, -gt, -lt, -ge, -le comparisons with $null

---

### ✅ ~~PSProvideCommentHelp~~ (Information) - **COMPLETED**
**Status**: Fully implemented
**Implementation**: AST-based function detection with template injection
**File**: Apply-AutoFix.ps1:1367-1485
**Completion Date**: 2025-10-10
**Adds**: .SYNOPSIS, .DESCRIPTION, and .EXAMPLE sections to functions without help

---

### ✅ ~~PSAvoidGlobalVars~~ (Warning) - **COMPLETED**
**Status**: Fully implemented
**Implementation**: AST-based variable scope detection and conversion
**File**: Apply-AutoFix.ps1:1216-1285
**Completion Date**: 2025-10-10
**Converts**: `$global:Variable` → `$script:Variable`

---

### ✅ ~~PSUseSupportsShouldProcess~~ (Warning) - **COMPLETED**
**Status**: Fully implemented
**Implementation**: AST-based ShouldProcess detection with CmdletBinding attribute modification
**File**: Apply-AutoFix.ps1:1105-1214
**Completion Date**: 2025-10-10
**Adds**: `SupportsShouldProcess=$true` to functions using `$PSCmdlet.ShouldProcess()`

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

### Phase 1: Quick Wins (v4.1) - ✅ **100% COMPLETED**
Target: 14/70 = 20% coverage (✅ **ACHIEVED**)

1. ✅ **PSUseBOMForUnicodeEncodedFile** - Completed 2025-10-10
2. ✅ **PSAvoidSemicolonsAsLineTerminators** - Completed 2025-10-10
3. ✅ **PSUseSingularNouns** - Completed 2025-10-10
4. ✅ **PSUseApprovedVerbs** - Completed 2025-10-10
5. ✅ **PSPossibleIncorrectComparisonWithNull** - Completed 2025-10-10
6. ✅ **PSProvideCommentHelp** - Completed 2025-10-10

**Status**: 6/6 completed (100% complete) 🎉
**Actual Effort**: 1 day
**Coverage Achieved**: 20% (14/70 rules - target met!)

### Phase 2: High-Value Complex Fixes (v4.2) - 3 rules
Target: 20/70 = 29% coverage (close to Phase 3 goal!)

1. 🔥 **PSAvoidUsingWMICmdlet** - WMI → CIM conversion
2. 🔥 **PSAvoidLongLines** - Intelligent line wrapping
3. ⚠️ **PSReviewUnusedParameter** - AST-based parameter analysis

**Estimated Effort**: 5-7 days

### Phase 3: Advanced Scaffolding (v5.0) - 2 rules
Target: 19/70 = 27% coverage

1. ⚠️ **PSShouldProcess** - Full ShouldProcess scaffolding
2. ⚠️ **PSAvoidGlobalFunctions** - Function scoping

**Estimated Effort**: 5-7 days

---

## Success Metrics

| Metric | Baseline (v4.0) | Phase 1 (v4.1) ✅ | Bonus Rules ✅ | Phase 2 (v4.2) | Phase 3 (v5.0) |
|--------|-----------------|-------------------|----------------|----------------|----------------|
| Rules Auto-Fixed | 8 | **14** ✅ | **17** ✅ | 18 | 21 |
| Coverage % | 11% | **20%** ✅ | **24%** ✅ | 26% | 30% |
| High-Priority Coverage | 0/4 | **4/4** ✅ (100%) | **4/4** ✅ | - | - |
| Medium-Priority Coverage | 0/7 | **2/7** ✅ | **5/7** ✅ (71%) | 6/7 | 7/7 |
| External Script Test | 93% | 95%+ | 96%+ | 97%+ | 98%+ |

**Notes**:
- ✅ Phase 1 target achieved: 14/70 rules = 20% coverage
- ✅ Bonus: Added 3 more easy wins → 17/70 rules = 24% coverage
- ✅ All 4 high-priority rules completed (100%)
- ✅ 5 of 7 medium-priority rules completed (71%)
- New auto-fixes: PSAvoidSemicolonsAsLineTerminators, PSUseSingularNouns, PSUseApprovedVerbs, PSUseBOMForUnicodeEncodedFile, PSProvideCommentHelp, PSPossibleIncorrectComparisonWithNull, PSUseSupportsShouldProcess, PSAvoidGlobalVars, PSAvoidUsingDoubleQuotesForConstantString
- Coverage increased by 13 percentage points (11% → 24%)
- 9 rules added in a single day 🚀

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
- PSAvoidGlobalVars ✅
- PSAvoidInvokingEmptyMembers
- PSAvoidLongLines
- PSAvoidMultipleTypeAttributes
- PSAvoidNullOrEmptyHelpMessageAttribute
- PSAvoidOverwritingBuiltInCmdlets
- PSAvoidSemicolonsAsLineTerminators ✅
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
- PSPossibleIncorrectComparisonWithNull ✅
- PSPossibleIncorrectUsageOfRedirectionOperator
- PSReservedCmdletChar
- PSReviewUnusedParameter ⚠️
- PSShouldProcess ⚠️
- PSUseApprovedVerbs ✅
- PSUseBOMForUnicodeEncodedFile ✅
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
- PSUseSingularNouns ✅
- PSUseSupportsShouldProcess ✅
- PSUseToExportFieldsInManifest
- PSUseUsingScopeModifierInNewRunspaces
- PSUseUTF8EncodingForHelpFile

### Information Severity (11 rules)
- PSAvoidTrailingWhitespace ✅
- PSAvoidUsingDoubleQuotesForConstantString ✅
- PSAvoidUsingPositionalParameters
- PSDSCDscExamplesPresent
- PSDSCDscTestsPresent
- PSDSCReturnCorrectTypesForDSCFunctions
- PSDSCUseVerboseMessageInDSCResource
- PSPossibleIncorrectUsageOfAssignmentOperator
- PSProvideCommentHelp ✅
- PSUseCorrectCasing ✅
- PSUseOutputTypeCorrectly

---

**Legend**:
- ✅ Currently auto-fixed (17 rules) ⭐ +9 new in v4.1
- 🟡 Partially auto-fixed (1 rule)
- 🔥 High priority for implementation (0 rules - all completed!)
- ⚠️ Medium priority for implementation (2 rules remaining)
- ℹ️ Low priority - requires human judgment

---

## Recent Updates

### v4.1 (2025-10-10) - Phase 1 + Bonus Easy Wins ✅ **COMPLETE**
**Added 9 new auto-fixes:**
1. PSAvoidSemicolonsAsLineTerminators - AST token-based semicolon removal
2. PSUseSingularNouns - Function name pluralization fix (4 rules: -s, -es, -ies, -ves)
3. PSUseApprovedVerbs - Comprehensive verb mapping (30+ unapproved→approved mappings)
4. PSUseBOMForUnicodeEncodedFile - Automatic UTF8-BOM detection
5. PSProvideCommentHelp - Template-based help injection (.SYNOPSIS, .DESCRIPTION, .EXAMPLE)
6. PSPossibleIncorrectComparisonWithNull - Enhanced AST-based null comparison fix
7. **PSUseSupportsShouldProcess** - CmdletBinding attribute modification for ShouldProcess
8. **PSAvoidGlobalVars** - Global to script scope conversion ($global: → $script:)
9. **PSAvoidUsingDoubleQuotesForConstantString** - String quote optimization ("text" → 'text')

**Coverage**: 11% → 24% (13 percentage point increase!)
**Status**: Phase 1 complete + 3 bonus rules 🎉🚀

---

*This roadmap is a living document and will be updated as new auto-fix capabilities are implemented.*
