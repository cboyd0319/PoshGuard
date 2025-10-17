# Pester Architect Test Plan for PoshGuard

## Executive Summary

This document outlines the comprehensive test strategy for PoshGuard to meet Pester Architect standards: deterministic, hermetic, maintainable test suites with 90%+ line coverage and 85%+ branch coverage.

**Current State:**
- ✅ 48 modules with 49 corresponding test files
- ✅ Pester v5.7.1 configured
- ✅ PSScriptAnalyzer enforcement enabled
- ✅ CI/CD with GitHub Actions (Windows/macOS/Linux)
- ⚠️ Some tests have issues (timeout, failures)
- ⚠️ Coverage metrics below target thresholds

**Enhancement Goals:**
- 🎯 Fix failing and flaky tests
- 🎯 Achieve 90%+ line coverage, 85%+ branch coverage
- 🎯 Implement table-driven tests with `-TestCases`
- 🎯 Add comprehensive error path and edge case testing
- 🎯 Ensure all mocks use `InModuleScope` properly
- 🎯 Eliminate real I/O, network, time dependencies
- 🎯 Add performance regression guards

---

## Module Test Inventory

### Core Modules (tools/lib/*.psm1)

| Module | Test File | Status | Priority |
|--------|-----------|--------|----------|
| Core.psm1 | Core.Tests.ps1 | ✅ Exists | P1 - Core functionality |
| Security.psm1 | Security.Tests.ps1 | ✅ Exists | P1 - Security critical |
| BestPractices.psm1 | BestPractices.Tests.ps1 | ✅ Exists | P1 |
| Formatting.psm1 | Formatting.Tests.ps1 | ✅ Exists | P1 |
| Advanced.psm1 | Advanced.Tests.ps1 | ✅ Exists | P1 |
| AIIntegration.psm1 | AIIntegration.Tests.ps1 | ✅ Exists | P2 |
| AdvancedCodeAnalysis.psm1 | AdvancedCodeAnalysis.Tests.ps1 | ⚠️ Failures | P1 - Fix |
| AdvancedDetection.psm1 | AdvancedDetection.Tests.ps1 | ✅ Exists | P2 |
| ConfigurationManager.psm1 | ConfigurationManager.Tests.ps1 | ✅ Exists | P1 |
| EnhancedMetrics.psm1 | EnhancedMetrics.Tests.ps1 | ✅ Exists | P2 |
| EnhancedSecurityDetection.psm1 | EnhancedSecurityDetection.Tests.ps1 | ✅ Exists | P2 |
| EntropySecretDetection.psm1 | EntropySecretDetection.Tests.ps1 | ✅ Exists | P1 - Security |
| MCPIntegration.psm1 | MCPIntegration.Tests.ps1 | ✅ Exists | P3 |
| NISTSP80053Compliance.psm1 | NISTSP80053Compliance.Tests.ps1 | ✅ Exists | P2 |
| Observability.psm1 | Observability.Tests.ps1 | ✅ Exists | P2 |
| OpenTelemetryTracing.psm1 | OpenTelemetryTracing.Tests.ps1 | ✅ Exists | P3 |
| PerformanceOptimization.psm1 | PerformanceOptimization.Tests.ps1 | ✅ Exists | P2 |
| ReinforcementLearning.psm1 | ReinforcementLearning.Tests.ps1 | ✅ Exists | P3 |
| SecurityDetectionEnhanced.psm1 | SecurityDetectionEnhanced.Tests.ps1 | ✅ Exists | P2 |
| SupplyChainSecurity.psm1 | SupplyChainSecurity.Tests.ps1 | ✅ Exists | P2 |

### Submodules

#### Advanced/*.psm1
- ✅ ASTTransformations.Tests.ps1
- ✅ AttributeManagement.Tests.ps1
- ✅ CmdletBindingFix.Tests.ps1
- ✅ CodeAnalysis.Tests.ps1
- ✅ CompatibleCmdletsWarning.Tests.ps1
- ✅ DefaultValueForMandatoryParameter.Tests.ps1
- ✅ DeprecatedManifestFields.Tests.ps1
- ✅ Documentation.Tests.ps1
- ✅ InvokingEmptyMembers.Tests.ps1
- ✅ ManifestManagement.Tests.ps1
- ✅ OverwritingBuiltInCmdlets.Tests.ps1
- ✅ ParameterManagement.Tests.ps1
- ✅ ShouldProcessTransformation.Tests.ps1
- ✅ UTF8EncodingForHelpFile.Tests.ps1

#### BestPractices/*.psm1
- ✅ CodeQuality.Tests.ps1
- ✅ Naming.Tests.ps1
- ✅ Scoping.Tests.ps1
- ✅ StringHandling.Tests.ps1
- ✅ Syntax.Tests.ps1
- ✅ TypeSafety.Tests.ps1
- ✅ UsagePatterns.Tests.ps1

#### Formatting/*.psm1
- ✅ Aliases.Tests.ps1
- ✅ Alignment.Tests.ps1
- ✅ Casing.Tests.ps1
- ✅ Output.Tests.ps1
- ✅ Runspaces.Tests.ps1
- ✅ Whitespace.Tests.ps1
- ✅ WriteHostEnhanced.Tests.ps1

---

## Test Quality Standards

### Naming Convention
```powershell
Describe '<ModuleName>' -Tag 'Unit', '<Category>' {
  Context '<Scenario>' {
    It '<Function> <Condition> => <Expected>' -TestCases @(...) {
      # AAA Pattern
      # Arrange
      # Act
      # Assert
    }
  }
}
```

### Required Test Coverage Areas

For each exported function:

1. **Happy Path**
   - Valid inputs produce expected outputs
   - Table-driven with `-TestCases` for input matrices

2. **Parameter Validation**
   - Mandatory parameters enforced
   - Type validation
   - Range/pattern validation
   - Pipeline input handling

3. **Error Handling**
   - Invalid inputs throw expected exceptions
   - Error messages are descriptive
   - `-ErrorAction Stop` behavior verified

4. **Edge Cases**
   - Empty/null inputs
   - Large inputs
   - Unicode/special characters
   - Boundary values

5. **Side Effects**
   - File I/O uses `TestDrive:`
   - Network calls are mocked
   - Time dependencies mocked (`Get-Date`)
   - No real registry/environment changes

6. **ShouldProcess**
   - Functions with `-WhatIf`/`-Confirm` tested
   - No actual changes made in `-WhatIf` mode

---

## Mocking Strategy

### External Dependencies

```powershell
BeforeAll {
  # Import module under test
  Import-Module "$PSScriptRoot/../../tools/lib/ModuleName.psm1" -Force
}

Describe 'Function-WithExternalCall' {
  It 'Mocks external API call' {
    InModuleScope ModuleName {
      Mock Invoke-RestMethod -ParameterFilter {
        $Uri -eq 'https://api.example.com/data'
      } -MockWith {
        [PSCustomObject]@{ Status = 'OK' }
      } -Verifiable
      
      $result = Function-WithExternalCall
      
      $result.Status | Should -Be 'OK'
      Assert-MockCalled Invoke-RestMethod -Exactly -Times 1 -Scope It
    }
  }
}
```

### Time and Randomness

```powershell
It 'Freezes time for deterministic tests' {
  InModuleScope ModuleName {
    $frozenTime = [DateTime]::new(2025, 1, 1, 12, 0, 0)
    Mock Get-Date { return $frozenTime }
    
    $result = Get-Timestamp
    $result | Should -Be '2025-01-01T12:00:00'
  }
}
```

### File System

```powershell
It 'Uses TestDrive for file operations' {
  $testFile = Join-Path $TestDrive 'test.ps1'
  'Write-Output "Test"' | Set-Content -Path $testFile
  
  $result = Process-ScriptFile -Path $testFile
  
  Test-Path $testFile | Should -Be $true
}
```

---

## Test Helpers Enhancement

### Location: tests/Helpers/

**TestHelpers.psm1** (Enhanced)
- `New-TestFile` - Create test files in TestDrive
- `Test-FunctionExists` - Verify function export
- `New-MockAst` - Create AST objects for testing
- `Assert-NoSideEffects` - Verify no global state changes

**MockBuilders.psm1**
- `New-MockPSScriptAnalyzerResult` - Build PSSA result objects
- `New-MockAstNode` - Build AST test fixtures
- `New-MockFileInfo` - Build FileInfo objects

**PropertyTesting.psm1**
- `Test-Property` - Property-based testing framework
- `New-RandomString` - Seeded string generator
- `New-RandomScriptContent` - Generate valid PowerShell code

---

## CI/CD Quality Gates

### .github/workflows/comprehensive-tests.yml

```yaml
- name: Run Tests with Coverage
  run: |
    $config = New-PesterConfiguration
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.CoveragePercentTarget = 90
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = 'coverage.xml'
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.CodeCoverage.CoveragePercent -lt 90) {
      Write-Error "Coverage ${$result.CodeCoverage.CoveragePercent}% below 90% threshold"
      exit 1
    }
```

### Static Analysis

```yaml
- name: PSScriptAnalyzer
  run: |
    $results = Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse
    $errors = $results | Where-Object Severity -eq 'Error'
    $warnings = $results | Where-Object Severity -eq 'Warning'
    
    if ($errors) {
      Write-Error "Found $($errors.Count) error(s)"
      exit 1
    }
    if ($warnings) {
      Write-Warning "Found $($warnings.Count) warning(s)"
    }
```

---

## Performance Baselines

### Micro-benchmarks

```powershell
Describe 'Performance' -Tag 'Performance' {
  It 'Function completes within acceptable time' {
    $elapsed = Measure-Command {
      1..100 | ForEach-Object { Invoke-Function }
    }
    
    $elapsed.TotalMilliseconds | Should -BeLessThan 5000
  }
}
```

---

## Known Issues to Fix

1. **AdvancedCodeAnalysis.Tests.ps1**
   - `Find-DeadCode` returns null on valid inputs
   - Deep nesting detection causes stack overflow
   - Empty content validation fails

2. **Test Timeouts**
   - Some test suites take >10 minutes
   - Need to mock expensive operations
   - Consider splitting integration vs unit tests

3. **Flaky Tests**
   - Tests depending on real time
   - Tests with unseeded randomness
   - Tests touching filesystem outside TestDrive

---

## Implementation Phases

### Phase 1: Critical Fixes (Priority P1)
- [ ] Fix AdvancedCodeAnalysis failing tests
- [ ] Review and fix timeout issues
- [ ] Ensure all tests use TestDrive for I/O
- [ ] Add missing mocks for external dependencies

### Phase 2: Coverage Enhancement (Priority P1-P2)
- [ ] Add table-driven tests for input matrices
- [ ] Add error path tests (invalid inputs, exceptions)
- [ ] Add edge case tests (null, empty, large, unicode)
- [ ] Verify ShouldProcess behavior

### Phase 3: Test Infrastructure (Priority P2)
- [ ] Enhance test helpers with builders
- [ ] Add property-based testing framework
- [ ] Document test patterns and examples
- [ ] Add performance regression tests

### Phase 4: CI/CD Hardening (Priority P2)
- [ ] Add coverage thresholds (90% lines, 85% branches)
- [ ] Configure analyzer to fail on warnings
- [ ] Add mutation testing (optional)
- [ ] Generate coverage reports

---

## Success Criteria

- ✅ All 1066+ tests passing
- ✅ Zero flaky tests (100% deterministic)
- ✅ 90%+ line coverage on exported functions
- ✅ 85%+ branch coverage on critical paths
- ✅ All tests complete in <100ms average
- ✅ Zero real I/O (TestDrive only)
- ✅ Zero network calls (mocked)
- ✅ Zero time dependencies (mocked Get-Date)
- ✅ CI passes on Windows/macOS/Linux
- ✅ PSScriptAnalyzer 0 errors, 0 warnings

---

## Test Maintenance

### Adding New Tests

1. Use existing patterns from test files
2. Follow AAA (Arrange-Act-Assert)
3. Use `-TestCases` for data-driven tests
4. Mock all external dependencies
5. Use `InModuleScope` for internal function testing

### Reviewing Tests

1. Each test should test ONE behavior
2. Test names should be descriptive
3. No hardcoded paths or credentials
4. No sleeps or waits
5. No random values without seeds

### Refactoring Tests

1. Extract common setup to `BeforeAll`
2. Use test helpers for repetitive patterns
3. Keep tests DRY but readable
4. Document complex test scenarios

---

## References

- Pester Documentation: https://pester.dev/docs/quick-start
- PSScriptAnalyzer Rules: https://github.com/PowerShell/PSScriptAnalyzer
- PowerShell Best Practices: https://poshcode.gitbook.io/powershell-practice-and-style/
