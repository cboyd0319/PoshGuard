# PoshGuard Comprehensive Test Plan v2.0

## Executive Summary

This test plan implements comprehensive unit tests for all PoshGuard PowerShell modules following Pester v5+ best practices. The test suite aims for:
- **Line coverage**: ≥90% across all exported functions
- **Branch coverage**: ≥85% on critical paths
- **Deterministic execution**: All tests hermetic, no external dependencies
- **Cross-platform**: Compatible with Windows, macOS, Linux (PowerShell 7+)

## Testing Philosophy

### Core Principles (from Pester Architect Agent)
1. **Framework**: Pester v5+ exclusively with Describe/Context/It AAA pattern
2. **Determinism**: Mock all time, randomness, network, registry, filesystem I/O
3. **Isolation**: Use TestDrive:, Mock, InModuleScope, BeforeAll/BeforeEach
4. **Coverage as Guardrail**: Focus on meaningful branches and error semantics
5. **Explicitness**: Make dependencies explicit, mock at call site

### What We Test
- ✅ Public contract of all exported functions
- ✅ Error handling: exceptions, error records, validation
- ✅ Boundary/edge inputs: empty/null/large/unicode/invalid types
- ✅ Branching logic: if/else, early returns, ShouldProcess
- ✅ Side-effects: file IO (via TestDrive), mocked external calls
- ✅ Pipeline behavior: ValueFromPipeline, object shapes

## Current Coverage Status

### Modules WITH Tests (14 files)
1. **Core.Tests.ps1** - Core helper functions
2. **Security.Tests.ps1** - Security auto-fix functions
3. **ConfigurationManager.Tests.ps1** - Configuration management
4. **EntropySecretDetection.Tests.ps1** - Secret detection
5. **PoshGuard.Tests.ps1** - Main module entry point
6. **Formatting/Casing.Tests.ps1** - Case fixes
7. **Formatting/Whitespace.Tests.ps1** - Whitespace fixes
8. **Formatting/Aliases.Tests.ps1** - Alias expansion
9. **Formatting/Output.Tests.ps1** - Output cmdlet fixes
10. **Advanced/ASTTransformations.Tests.ps1** - AST transformations
11. **BestPractices/CodeQuality.Tests.ps1** - Code quality
12. **BestPractices/Syntax.Tests.ps1** - Syntax fixes
13. **BestPractices/Scoping.Tests.ps1** - Scoping fixes
14. **BestPractices/Naming.Tests.ps1** - Naming conventions

### Modules NEEDING Tests (Priority Order)

#### Priority 1: Critical Security & Performance (5 modules)
1. **PerformanceOptimization.psm1** (523 LOC) - 8 functions
   - Parallel processing, caching, memory management
   - Critical for large codebase performance
   
2. **SecurityDetectionEnhanced.psm1** (751 LOC)
   - Enhanced security pattern detection
   - Critical security module
   
3. **EnhancedSecurityDetection.psm1** (716 LOC)
   - Additional security detection patterns
   
4. **SupplyChainSecurity.psm1** (744 LOC)
   - SBOM generation, dependency analysis
   
5. **NISTSP80053Compliance.psm1** (822 LOC)
   - NIST compliance checking

#### Priority 2: Advanced Features (5 modules)
6. **AdvancedCodeAnalysis.psm1** (620 LOC)
   - Advanced code analysis patterns
   
7. **AdvancedDetection.psm1** (755 LOC)
   - Complex detection logic
   
8. **OpenTelemetryTracing.psm1** (665 LOC)
   - Telemetry and tracing
   
9. **Observability.psm1** (531 LOC)
   - Observability features
   
10. **ReinforcementLearning.psm1** (690 LOC)
    - ML-based optimization

#### Priority 3: AI & Integration (3 modules)
11. **AIIntegration.psm1** (699 LOC)
    - AI-powered analysis
    
12. **MCPIntegration.psm1** (590 LOC)
    - MCP protocol integration
    
13. **EnhancedMetrics.psm1** (533 LOC)
    - Metrics collection and reporting

#### Priority 4: Facade Modules (2 modules)
14. **Advanced.psm1** (129 LOC)
    - Facade for Advanced submodules
    
15. **Formatting.psm1** (81 LOC)
    - Facade for Formatting submodules

## Test Structure Template

```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard [ModuleName] module

.DESCRIPTION
    Comprehensive unit tests for [ModuleName].psm1 functions:
    - [Function1]
    - [Function2]
    ...

    Tests cover happy paths, edge cases, error conditions, and parameter validation.
    All tests are hermetic using TestDrive and mocks.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/[ModuleName].psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find [ModuleName] module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe '[FunctionName]' -Tag 'Unit', '[ModuleName]' {
  
  Context 'When [scenario]' {
    It 'Should [expected behavior]' {
      # Arrange
      
      # Act
      
      # Assert
    }
  }
  
  Context 'Parameter validation' {
    It 'Should validate mandatory parameters' {
      { [FunctionName] } | Should -Throw
    }
  }
  
  Context 'Error handling' {
    It 'Should handle invalid input gracefully' {
      { [FunctionName] -Parameter 'invalid' } | Should -Not -Throw
    }
  }
}
```

## Test Patterns by Module Type

### 1. Facade Modules (Advanced, Formatting)
- **Focus**: Module loading, function export verification
- **Tests**:
  - Verify submodule imports
  - Check exported function availability
  - Validate module metadata
  
### 2. Detection/Analysis Modules
- **Focus**: Pattern detection, AST analysis
- **Tests**:
  - Table-driven tests with test cases
  - AST parsing edge cases
  - False positive prevention
  
### 3. Performance Modules
- **Focus**: Parallel execution, caching, memory
- **Tests**:
  - Mock runspace operations
  - Cache hit/miss scenarios
  - Memory optimization triggers
  - Mock Get-Date for timing tests
  
### 4. Security Modules
- **Focus**: Vulnerability detection, compliance
- **Tests**:
  - Known vulnerable patterns
  - Compliance rule validation
  - Edge cases in security detection
  
### 5. Integration Modules (AI, MCP)
- **Focus**: External API calls, protocol handling
- **Tests**:
  - Mock all HTTP/REST calls
  - Protocol validation
  - Error response handling

## Mocking Strategy

### External Dependencies to Mock
1. **File System**: Use `TestDrive:` exclusively
2. **Network**: Mock `Invoke-RestMethod`, `Invoke-WebRequest`
3. **Processes**: Mock `Start-Process`, `Start-Job`
4. **Time**: Mock `Get-Date`, ban `Start-Sleep`
5. **Runspaces**: Mock runspace creation/execution
6. **Registry**: Mock registry access
7. **Environment**: Use scoped `$env:` variables

### Common Mock Patterns
```powershell
# Mock external HTTP calls
InModuleScope ModuleName {
  Mock Invoke-RestMethod -ParameterFilter { 
    $Uri -like '*api.example.com*' 
  } -MockWith {
    [PSCustomObject]@{ status = 'ok'; data = @{} }
  }
}

# Mock time for deterministic tests
Mock Get-Date { 
  return [DateTime]::new(2025, 1, 15, 10, 30, 0) 
}

# Mock file operations with TestDrive
$testFile = New-TestFile -FileName 'test.ps1' -Content $content
$result = Invoke-Function -Path $testFile
```

## Test Data Strategies

### 1. Table-Driven Tests
```powershell
It 'Should handle <Scenario>' -TestCases @(
  @{ Input = 'value1'; Expected = 'result1'; Scenario = 'normal' }
  @{ Input = ''; Expected = ''; Scenario = 'empty' }
  @{ Input = $null; Expected = $null; Scenario = 'null' }
) {
  param($Input, $Expected)
  $result = Invoke-Function -Input $Input
  $result | Should -Be $Expected
}
```

### 2. Object Builders (via TestHelpers)
- Use `New-TestScriptContent` for script generation
- Use `New-TestFile` for file creation in TestDrive
- Use `New-MockAST` for AST testing

### 3. Edge Cases Matrix
For each function, test:
- Empty/null/whitespace inputs
- Large inputs (>1MB strings)
- Unicode/special characters
- Invalid types
- Boundary values

## Quality Gates

### Coverage Targets
- **Overall line coverage**: ≥90%
- **Exported functions coverage**: 100%
- **Critical path branches**: ≥85%

### Static Analysis
- PSScriptAnalyzer: Zero warnings/errors
- Rules enforced (from .psscriptanalyzer.psd1):
  - PSUseDeclaredVarsMoreThanAssignments
  - PSAvoidUsingWriteHost
  - PSUseConsistentIndentation
  - PSUseConsistentWhitespace
  - PSUseBOMForUnicodeEncodedFile
  - PSUseApprovedVerbs
  - PSAvoidUsingPlainTextForPassword

### Performance Targets
- Typical `It` block: <100ms
- Maximum `It` block: <500ms
- Full test suite: <5 minutes on CI

## CI Integration

### GitHub Actions Workflow
```yaml
name: Comprehensive Tests
on: [push, pull_request]
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        pwsh: ["7.4.4"]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PowerShell
        uses: PowerShell/PowerShell-For-GitHub-Actions@v1
        with: { version: ${{ matrix.pwsh }} }
      
      - name: Install Pester & PSScriptAnalyzer
        shell: pwsh
        run: |
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module Pester -Scope CurrentUser -Force -MinimumVersion 5.5.0
          Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
      
      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse
          if ($results) {
            $results | Format-Table
            throw "PSScriptAnalyzer found issues"
          }
      
      - name: Run Unit Tests with Coverage
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './tests/Unit'
          $config.Run.PassThru = $true
          $config.CodeCoverage.Enabled = $true
          $config.CodeCoverage.Path = './tools/lib/*.psm1'
          $config.CodeCoverage.OutputFormat = 'JaCoCo'
          $config.CodeCoverage.OutputPath = 'coverage.xml'
          $config.Output.Verbosity = 'Detailed'
          
          $result = Invoke-Pester -Configuration $config
          
          if ($result.FailedCount -gt 0) {
            throw "$($result.FailedCount) test(s) failed"
          }
          
          # Check coverage threshold
          $coverage = $result.CodeCoverage
          $coveragePercent = ($coverage.CommandsExecutedCount / $coverage.CommandsAnalyzedCount) * 100
          Write-Host "Code Coverage: $($coveragePercent.ToString('F2'))%"
          
          if ($coveragePercent -lt 90) {
            Write-Warning "Coverage below 90% threshold"
          }
```

## Implementation Schedule

### Phase 1: Critical Modules (Week 1)
- [ ] PerformanceOptimization.Tests.ps1
- [ ] SecurityDetectionEnhanced.Tests.ps1
- [ ] EnhancedSecurityDetection.Tests.ps1
- [ ] SupplyChainSecurity.Tests.ps1
- [ ] NISTSP80053Compliance.Tests.ps1

### Phase 2: Advanced Features (Week 2)
- [ ] AdvancedCodeAnalysis.Tests.ps1
- [ ] AdvancedDetection.Tests.ps1 (enhance existing)
- [ ] OpenTelemetryTracing.Tests.ps1
- [ ] Observability.Tests.ps1
- [ ] ReinforcementLearning.Tests.ps1

### Phase 3: AI & Integration (Week 3)
- [ ] AIIntegration.Tests.ps1
- [ ] MCPIntegration.Tests.ps1
- [ ] EnhancedMetrics.Tests.ps1 (enhance existing)

### Phase 4: Facades & Integration (Week 4)
- [ ] Advanced.Tests.ps1
- [ ] Formatting.Tests.ps1
- [ ] Full integration test suite
- [ ] CI workflow implementation
- [ ] Coverage report and documentation

## Anti-Patterns to Avoid

1. ❌ **No real time/network/registry**: Mock everything external
2. ❌ **No touching real files**: Use TestDrive: exclusively
3. ❌ **No Start-Sleep**: Mock time instead
4. ❌ **No testing multiple behaviors in one It**: Keep tests focused
5. ❌ **No ignoring WhatIf/Confirm**: Test ShouldProcess properly
6. ❌ **No cargo-cult tests**: Every test must validate real behavior
7. ❌ **No flaky tests**: 100% deterministic or don't commit

## Success Criteria

### Completion Checklist
- [ ] All 15 missing modules have comprehensive test files
- [ ] Overall coverage ≥90% across all modules
- [ ] PSScriptAnalyzer passes with zero issues
- [ ] All tests pass on Windows/macOS/Linux
- [ ] CI workflow configured and passing
- [ ] Test execution time <5 minutes
- [ ] Zero flaky tests (100 consecutive runs pass)

### Quality Metrics
- Test count: Target 500+ total test cases
- Average test execution: <50ms per test
- Coverage gaps: Document any intentionally uncovered code
- False positives: Zero tests that pass incorrectly

## References

1. Pester Documentation: https://pester.dev/docs/quick-start
2. PSScriptAnalyzer Rules: https://github.com/PowerShell/PSScriptAnalyzer
3. PowerShell AST Explorer: https://adamtheautomator.com/powershell-abstract-syntax-tree/
4. Runspace Best Practices: https://devblogs.microsoft.com/powershell/

---

**Last Updated**: 2025-10-16
**Version**: 2.0
**Status**: In Progress
