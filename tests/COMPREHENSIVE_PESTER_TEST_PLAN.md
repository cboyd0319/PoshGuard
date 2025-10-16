# Comprehensive Pester Test Plan for PoshGuard

## Executive Summary
This document outlines a complete test strategy for PoshGuard following Pester v5+ best practices with comprehensive coverage of all PowerShell modules.

## Testing Philosophy

### Core Principles
1. **Deterministic Execution**: No real time, randomness, network, or filesystem side effects
2. **Hermetic Tests**: Use `TestDrive:`, mocks, and `InModuleScope` for complete isolation
3. **AAA Pattern**: Arrange-Act-Assert structure in every test
4. **Meaningful Coverage**: Focus on logic branches, error paths, and edge cases (not just line coverage)
5. **Fast & Repeatable**: All tests < 100ms per `It`, cross-platform (Windows/macOS/Linux)

### Coverage Targets
- **Lines**: ≥ 90% across exported functions
- **Branches**: ≥ 85% for critical paths
- **Functions**: 100% of exported functions tested

## Module Inventory & Test Priorities

### Priority 1: Core Infrastructure Modules

#### 1. Core.psm1 (5 exported functions)
**Location**: `tools/lib/Core.psm1`  
**Test File**: `tests/Unit/Core.Tests.ps1`

**Functions**:
1. `Clean-Backups` - Backup directory cleanup with ShouldProcess
2. `Write-Log` - Structured logging with levels and formatting
3. `Get-PowerShellFiles` - File discovery with extension filtering
4. `New-FileBackup` - Create timestamped backups
5. `New-UnifiedDiff` - Generate unified diffs

**Test Scenarios**:
- **Clean-Backups**: 
  - WhatIf support (no deletion)
  - Cutoff date logic (mock Get-Date)
  - Missing directory handling
  - Recursive file deletion
- **Write-Log**:
  - All log levels (Info/Warn/Error/Success/Critical/Debug)
  - Timestamp formatting (mock Get-Date)
  - Icon/NoIcon switches
  - Color output validation
- **Get-PowerShellFiles**:
  - Single file path
  - Directory recursion
  - Extension filtering (.ps1, .psm1, .psd1)
  - Empty directory handling
  - Invalid path error
- **New-FileBackup**:
  - Backup creation with timestamp
  - Directory structure preservation
  - ShouldProcess support
  - Existing file handling
- **New-UnifiedDiff**:
  - Empty files
  - Identical files
  - Added/removed/modified lines
  - Unicode content handling

#### 2. Security.psm1 (7 exported functions)
**Location**: `tools/lib/Security.psm1`  
**Test File**: `tests/Unit/Security.Tests.ps1`

**Functions**:
1. `Invoke-PlainTextPasswordFix` - Fix plain text password parameters
2. `Invoke-ConvertToSecureStringFix` - Fix insecure SecureString conversion
3. `Invoke-UsernamePasswordParamsFix` - Add PSCredential parameters
4. `Invoke-AllowUnencryptedAuthFix` - Fix unencrypted auth flags
5. `Invoke-HardcodedComputerNameFix` - Replace hardcoded computer names
6. `Invoke-InvokeExpressionFix` - Replace dangerous Invoke-Expression
7. `Invoke-EmptyCatchBlockFix` - Add error handling to empty catches

**Test Scenarios**:
- Each function tests:
  - AST parsing and detection
  - Code transformation accuracy
  - Edge cases (nested, multiline, comments)
  - No false positives
  - DryRun mode support
  - Error handling for invalid input

### Priority 2: Best Practices & Formatting

#### 3. BestPractices.psm1 (18 functions across 7 submodules)
**Location**: `tools/lib/BestPractices.psm1`  
**Test Files**: 
- `tests/Unit/BestPractices.Tests.ps1` (facade)
- `tests/Unit/BestPractices/Syntax.Tests.ps1`
- `tests/Unit/BestPractices/Naming.Tests.ps1`
- `tests/Unit/BestPractices/Scoping.Tests.ps1`
- `tests/Unit/BestPractices/StringHandling.Tests.ps1`
- `tests/Unit/BestPractices/TypeSafety.Tests.ps1`
- `tests/Unit/BestPractices/UsagePatterns.Tests.ps1`
- `tests/Unit/BestPractices/CodeQuality.Tests.ps1`

**Submodule Functions**:
- **Syntax**: Invoke-SemicolonFix, Invoke-NullComparisonFix, Invoke-ExclaimOperatorFix
- **Naming**: Invoke-SingularNounFix, Invoke-ApprovedVerbFix, Invoke-ReservedCmdletCharFix
- **Scoping**: Invoke-GlobalVarFix, Invoke-GlobalFunctionsFix
- **StringHandling**: Invoke-DoubleQuoteFix, Invoke-LiteralHashtableFix
- **TypeSafety**: Invoke-AutomaticVariableFix, Invoke-MultipleTypeAttributesFix, Invoke-PSCredentialTypeFix
- **UsagePatterns**: Invoke-PositionalParametersFix, Invoke-DeclaredVarsMoreThanAssignmentsFix, Invoke-IncorrectAssignmentOperatorFix
- **CodeQuality**: Invoke-TodoCommentDetectionFix, Invoke-UnusedNamespaceDetectionFix, Invoke-AsciiCharacterWarningFix, Invoke-ConvertFromJsonOptimizationFix, Invoke-SecureStringDisclosureFix

#### 4. Formatting.psm1 (12 functions across 7 submodules)
**Location**: `tools/lib/Formatting.psm1`  
**Test Files**:
- `tests/Unit/Formatting.Tests.ps1` (facade)
- `tests/Unit/Formatting/Whitespace.Tests.ps1`
- `tests/Unit/Formatting/Aliases.Tests.ps1`
- `tests/Unit/Formatting/Casing.Tests.ps1`
- `tests/Unit/Formatting/Output.Tests.ps1`
- `tests/Unit/Formatting/Alignment.Tests.ps1`
- `tests/Unit/Formatting/Runspaces.Tests.ps1`
- `tests/Unit/Formatting/WriteHostEnhanced.Tests.ps1`

**Submodule Functions**:
- **Whitespace**: Invoke-FormatterFix, Invoke-WhitespaceFix, Invoke-MisleadingBacktickFix
- **Aliases**: Invoke-AliasFix, Invoke-AliasFixAst
- **Casing**: Invoke-CasingFix
- **Output**: Invoke-WriteHostFix, Invoke-WriteHostEnhancedFix, Invoke-RedirectionOperatorFix
- **Alignment**: Invoke-AlignAssignmentFix
- **Runspaces**: Invoke-UsingScopeModifierFix, Invoke-ShouldContinueWithoutForceFix

### Priority 3: Advanced & Extended Modules

#### 5. Advanced.psm1 (Submodules)
**Location**: `tools/lib/Advanced.psm1`  
**Test File**: `tests/Unit/Advanced.Tests.ps1`

**Submodules to test**:
- ASTTransformations.psm1
- AttributeManagement.psm1
- CmdletBindingFix.psm1
- CodeAnalysis.psm1
- CompatibleCmdletsWarning.psm1
- DefaultValueForMandatoryParameter.psm1
- DeprecatedManifestFields.psm1
- Documentation.psm1
- InvokingEmptyMembers.psm1
- ManifestManagement.psm1
- OverwritingBuiltInCmdlets.psm1
- ParameterManagement.psm1
- ShouldProcessTransformation.psm1
- UTF8EncodingForHelpFile.psm1

#### 6. Additional Modules
- **EnhancedMetrics.psm1**: Already has tests (249 lines) - review and enhance
- **ConfigurationManager.psm1**: Configuration loading and management
- **EntropySecretDetection.psm1**: Entropy-based secret detection
- **Observability.psm1**: Telemetry and monitoring
- **PerformanceOptimization.psm1**: Performance analysis

### Priority 4: Main Module
- **PoshGuard.psm1**: Already has tests (209 lines) - review and enhance

## Test Infrastructure

### Helpers & Fixtures
**Location**: `tests/Helpers/`

**Required Helper Functions**:
1. **TestHelper.psm1**:
   - `New-TestPowerShellFile` - Create temp .ps1 files in TestDrive
   - `Get-MockedAst` - Return parsed AST for test content
   - `Assert-CodeTransformation` - Compare before/after code
   - `New-MockedPSScriptAnalyzerResult` - Create mock PSSA results

2. **MockData.psm1**:
   - Sample code snippets for each fix type
   - Expected transformation results
   - Edge case scenarios

### Mock Strategies

#### Time Mocking
```powershell
Mock Get-Date { [DateTime]'2025-01-01T12:00:00Z' }
```

#### Filesystem Mocking
```powershell
# Use TestDrive: for all file operations
$testFile = Join-Path TestDrive: 'test.ps1'
New-Item -Path $testFile -Value $content
```

#### PSScriptAnalyzer Mocking
```powershell
Mock Invoke-ScriptAnalyzer {
  [PSCustomObject]@{
    RuleName = 'TestRule'
    Message = 'Test message'
    Extent = ...
  }
}
```

## Test Structure Template

### Standard Test File Structure
```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1
#requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Pester tests for [ModuleName]

.DESCRIPTION
    Comprehensive unit tests covering:
    - Function contract and parameters
    - Happy path scenarios
    - Error handling and edge cases
    - AST parsing and transformations
    - ShouldProcess support

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ with deterministic execution
#>

BeforeAll {
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/ModuleName.psm1'
  Import-Module -Name $modulePath -Force -ErrorAction Stop
  
  # Import test helpers
  $helperPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelper.psm1'
  if (Test-Path $helperPath) {
    Import-Module -Name $helperPath -Force
  }
}

Describe 'FunctionName' -Tag 'Unit', 'ModuleName', 'FunctionName' {
  
  Context 'Function existence and signature' {
    It 'Should be exported and accessible' {
      Get-Command FunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Should have CmdletBinding attribute' {
      (Get-Command FunctionName).CmdletBinding | Should -Be $true
    }
  }
  
  Context 'Parameter validation' {
    It 'Should have required parameters' -TestCases @(
      @{ ParamName = 'Path'; Mandatory = $true }
      @{ ParamName = 'Content'; Mandatory = $true }
    ) {
      param($ParamName, $Mandatory)
      $param = (Get-Command FunctionName).Parameters[$ParamName]
      $param | Should -Not -BeNullOrEmpty
      $param.Attributes.Mandatory | Should -Be $Mandatory
    }
  }
  
  Context 'Happy path scenarios' {
    BeforeEach {
      # Arrange - create test data in TestDrive:
    }
    
    It 'Should process valid input correctly' {
      # Arrange
      $testContent = 'valid PowerShell code'
      
      # Act
      $result = FunctionName -Content $testContent
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Success | Should -Be $true
    }
  }
  
  Context 'Error handling' {
    It 'Should throw on invalid input' {
      { FunctionName -Content '' } | Should -Throw
    }
  }
  
  Context 'Edge cases' {
    It 'Should handle empty content' -TestCases @(
      @{ Input = ''; Expected = '' }
      @{ Input = $null; Expected = $null }
    ) {
      # Test edge cases
    }
  }
}
```

## CI/CD Integration

### Coverage Enforcement
**File**: `.github/workflows/coverage.yml`

Requirements:
- Enforce 90% line coverage for Core, Security, BestPractices, Formatting modules
- Enforce 85% branch coverage for critical paths
- Generate JaCoCo format for code coverage reporting
- Fail build on coverage regression

### Multi-Platform Testing
Test on:
- Windows (latest)
- macOS (latest)
- Linux (Ubuntu latest)

PowerShell versions:
- 7.4.4+ (current LTS)

### Test Execution Strategy
```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - name: Run unit tests
        run: |
          Invoke-Pester -Path ./tests/Unit `
            -Configuration @{
              Run = @{ PassThru = $true }
              Output = @{ Verbosity = 'Detailed' }
              CodeCoverage = @{ 
                Enabled = $true
                OutputFormat = 'JaCoCo'
                OutputPath = 'coverage.xml'
                Path = @('tools/lib/*.psm1')
              }
            }
```

## Test Data Strategies

### Table-Driven Tests
Use `-TestCases` for input matrices:
```powershell
It 'Should handle various inputs' -TestCases @(
  @{ Input = 'case1'; Expected = 'result1' }
  @{ Input = 'case2'; Expected = 'result2' }
) {
  param($Input, $Expected)
  # Test logic
}
```

### Builder Pattern for Complex Objects
Create helper functions for test data:
```powershell
function New-TestAstNode {
  param([string]$Code)
  [System.Management.Automation.Language.Parser]::ParseInput($Code, [ref]$null, [ref]$null)
}
```

## Quality Gates

### Pre-Commit
1. PSScriptAnalyzer (zero warnings)
2. Pester unit tests (100% pass)
3. No Start-Sleep in tests (banned)

### CI Pipeline
1. Static analysis (PSScriptAnalyzer)
2. Unit tests (all platforms)
3. Coverage report generation
4. Coverage threshold enforcement

### Release
1. Integration tests (optional)
2. Performance benchmarks (diagnostic)
3. Full test suite on all platforms

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [x] Test plan documentation
- [ ] Test helper infrastructure
- [ ] Core.psm1 complete tests
- [ ] CI/CD coverage configuration

### Phase 2: Security & Best Practices (Week 2)
- [ ] Security.psm1 complete tests
- [ ] BestPractices.psm1 facade tests
- [ ] BestPractices submodule tests (7 files)

### Phase 3: Formatting (Week 3)
- [ ] Formatting.psm1 facade tests
- [ ] Formatting submodule tests (7 files)

### Phase 4: Advanced & Extended (Week 4)
- [ ] Advanced.psm1 and submodules
- [ ] Enhanced metrics improvements
- [ ] Additional module tests

### Phase 5: Integration & Validation (Week 5)
- [ ] Full test suite execution
- [ ] Coverage validation (≥90% lines, ≥85% branches)
- [ ] Cross-platform validation
- [ ] Performance profiling (all tests < 100ms)
- [ ] Documentation updates

## Success Criteria

### Functional
- ✅ 100% of exported functions have tests
- ✅ All tests pass on Windows/macOS/Linux
- ✅ Zero flaky tests (deterministic execution)
- ✅ All tests complete in < 2 minutes total

### Quality
- ✅ ≥90% line coverage on priority modules
- ✅ ≥85% branch coverage on critical paths
- ✅ PSScriptAnalyzer: zero warnings
- ✅ All tests follow AAA pattern

### Maintainability
- ✅ Clear test documentation
- ✅ Reusable test helpers
- ✅ Consistent naming conventions
- ✅ Easy to add new tests

## References
- [Pester v5 Documentation](https://pester.dev)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [PowerShell AST Documentation](https://docs.microsoft.com/powershell/scripting/developer/prog-guide/windows-powershell-programmer-s-guide)
