# PoshGuard Comprehensive Test Plan - Pester Architect Implementation

## Executive Summary

This document provides a comprehensive test plan for enhancing the PoshGuard test suite to meet the highest standards of quality, coverage, and maintainability as defined by the Pester Architect Agent principles.

**Current State:**
- ✅ All modules have basic unit tests
- ✅ Pester v5+ is configured and working
- ✅ CI/CD pipelines with coverage tracking
- ✅ PSScriptAnalyzer enforcement

**Enhancement Goals:**
- 🎯 Achieve 90%+ line coverage and 85%+ branch coverage
- 🎯 Add comprehensive edge case and error path testing
- 🎯 Implement property-based testing patterns
- 🎯 Enhance mocking strategies for hermetic tests
- 🎯 Add performance regression tests
- 🎯 Strengthen CI/CD quality gates

---

## Test Quality Assessment

### Modules Requiring Enhanced Coverage

#### 1. ConfigurationManager.psm1 (Current Coverage Ratio: 0.35)

**Functions Under Test:**
- `Initialize-PoshGuardConfiguration`
- `Get-DefaultConfiguration`
- `Get-PoshGuardConfiguration`
- `Set-PoshGuardConfigurationValue`
- `ConvertTo-Hashtable` (Not exported, needs InModuleScope testing)
- `Merge-Configuration` (Not exported, needs InModuleScope testing)
- `Apply-EnvironmentOverrides` (Not exported, needs InModuleScope testing)
- `Test-ConfigurationValid` (Not exported, needs InModuleScope testing)

**Missing Test Cases:**
- ✗ Environment variable override parsing and type conversion
- ✗ Configuration validation edge cases (invalid ranges, missing keys)
- ✗ Merge-Configuration with deep nested structures
- ✗ ConvertTo-Hashtable with complex objects (arrays, nested PSObjects)
- ✗ Error handling when config file has invalid JSON
- ✗ Concurrent configuration access patterns
- ✗ Configuration caching and reload scenarios
- ✗ Path traversal and nested value updates

**New Test Cases to Add:**
```powershell
Describe 'ConvertTo-Hashtable' -Tag 'Unit', 'Configuration', 'Internal' {
  Context 'Converting PSCustomObject to Hashtable' {
    It 'Converts flat PSCustomObject' -TestCases @(
      @{ Input = [PSCustomObject]@{ Key = 'Value' }; Expected = @{ Key = 'Value' } }
    ) {
      param($Input, $Expected)
      InModuleScope ConfigurationManager {
        $result = ConvertTo-Hashtable -InputObject $Input
        $result | Should -BeOfType [hashtable]
        $result.Keys.Count | Should -Be $Expected.Keys.Count
      }
    }
    
    It 'Converts nested PSCustomObject structures' {}
    It 'Converts arrays within PSCustomObject' {}
    It 'Handles null input gracefully' {}
    It 'Preserves value types (int, bool, double)' {}
  }
}

Describe 'Merge-Configuration' -Tag 'Unit', 'Configuration', 'Internal' {
  Context 'Merging hashtables' {
    It 'Merges flat hashtables' {}
    It 'Deep merges nested hashtables' {}
    It 'Override wins on conflict' {}
    It 'Preserves base keys not in override' {}
    It 'Handles null/empty override' {}
  }
}

Describe 'Apply-EnvironmentOverrides' -Tag 'Unit', 'Configuration', 'Internal' {
  Context 'Environment variable parsing' {
    It 'Converts true/false strings to boolean' {}
    It 'Converts numeric strings to integers' {}
    It 'Converts decimal strings to doubles' {}
    It 'Applies nested path overrides (POSHGUARD_AI_ENABLED)' {}
    It 'Handles invalid environment variable names' {}
    It 'Logs warning on failed override' {}
  }
}

Describe 'Test-ConfigurationValid' -Tag 'Unit', 'Configuration', 'Internal' {
  Context 'Configuration validation' {
    It 'Validates Core.MaxFileSizeBytes >= 1024' -TestCases @(
      @{ Size = 1024; Valid = $true }
      @{ Size = 512; Valid = $false }
    ) {}
    
    It 'Validates ReinforcementLearning.LearningRate in (0, 1]' -TestCases @(
      @{ Rate = 0.5; Valid = $true }
      @{ Rate = 0.0; Valid = $false }
      @{ Rate = 1.5; Valid = $false }
    ) {}
    
    It 'Validates SLO.AvailabilityTarget in (0, 100]' {}
    It 'Returns false for invalid config' {}
    It 'Returns true for valid config' {}
  }
}
```

#### 2. EntropySecretDetection.psm1 (Current Coverage Ratio: 0.53)

**Functions Under Test:**
- `Invoke-EntropySecretDetection`
- `Test-SecretEntropy`
- `Get-ShannonEntropy`
- `Test-Base64Pattern`
- `Test-HexPattern`

**Missing Test Cases:**
- ✗ Edge cases: empty strings, single character, unicode
- ✗ Boundary testing: entropy thresholds (4.4, 4.5, 4.6)
- ✗ Performance: large strings (>10KB)
- ✗ False positive reduction patterns
- ✗ Multiple secret types in same string
- ✗ Encoded secrets (URL encoded, hex encoded)
- ✗ Comment and string scanning toggle behavior

**New Test Cases to Add:**
```powershell
Describe 'Get-ShannonEntropy' -Tag 'Unit', 'Security', 'Entropy' {
  Context 'Entropy calculation accuracy' {
    It 'Calculates entropy for known strings' -TestCases @(
      @{ String = 'aaaa'; ExpectedRange = @(0.0, 0.1) }
      @{ String = 'abcd1234'; ExpectedRange = @(2.5, 3.0) }
      @{ String = 'xK3m!@#Zq9&*'; ExpectedRange = @(3.5, 4.0) }
      @{ String = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('secret')); ExpectedRange = @(4.0, 5.0) }
    ) {
      param($String, $ExpectedRange)
      InModuleScope EntropySecretDetection {
        $entropy = Get-ShannonEntropy -String $String
        $entropy | Should -BeGreaterOrEqual $ExpectedRange[0]
        $entropy | Should -BeLessOrEqual $ExpectedRange[1]
      }
    }
    
    It 'Returns 0.0 for empty string' {}
    It 'Returns 0.0 for single character' {}
    It 'Handles unicode characters' {}
    It 'Completes quickly for large strings (>10KB)' {
      # Performance test: should complete in < 100ms
      $largeString = 'a' * 10000
      $duration = Measure-Command {
        InModuleScope EntropySecretDetection {
          Get-ShannonEntropy -String $largeString
        }
      }
      $duration.TotalMilliseconds | Should -BeLessThan 100
    }
  }
}

Describe 'Test-SecretEntropy' -Tag 'Unit', 'Security', 'Entropy' {
  Context 'Boundary testing' {
    It 'Detects secrets at threshold boundary' -TestCases @(
      @{ String = 'lowEntropy123'; Threshold = 3.0; ShouldDetect = $false }
      @{ String = 'ghp_xK3m9Zq2Lp5Jn8Rt4Yc1Wf6Hb7Vd0'; Threshold = 4.5; ShouldDetect = $true }
      @{ String = 'DEADBEEFCAFE1234567890ABCDEF'; Threshold = 3.0; ShouldDetect = $true }
    ) {
      param($String, $Threshold, $ShouldDetect)
      InModuleScope EntropySecretDetection {
        $result = Test-SecretEntropy -String $String -Threshold $Threshold
        $result | Should -Be $ShouldDetect
      }
    }
  }
  
  Context 'False positive reduction' {
    It 'Does not flag common words with low entropy' {}
    It 'Does not flag GUIDs' {}
    It 'Does not flag URLs' {}
    It 'Does not flag file paths' {}
  }
}
```

#### 3. NISTSP80053Compliance.psm1 (Current Coverage Ratio: 0.40)

**Missing Test Cases:**
- ✗ Control family mapping validation
- ✗ Compliance scoring calculation
- ✗ Report generation with multiple violations
- ✗ Control coverage completeness
- ✗ FedRAMP overlay requirements
- ✗ ATO (Authority to Operate) readiness checks

#### 4. EnhancedSecurityDetection.psm1 (Current Coverage Ratio: 0.46)

**Missing Test Cases:**
- ✗ OWASP Top 10 pattern detection
- ✗ CWE classification accuracy
- ✗ Severity scoring consistency
- ✗ Remediation suggestion quality
- ✗ Pattern false positives/negatives

---

## Test Infrastructure Enhancements

### 1. Enhanced Test Helpers

**File:** `tests/Helpers/AdvancedMockBuilders.psm1` (New)

```powershell
<#
.SYNOPSIS
    Advanced mock builders for complex test scenarios
#>

function New-MockAstNode {
    <#
    .SYNOPSIS
        Create mock AST nodes for testing AST-based functions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Function', 'Parameter', 'Command', 'IfStatement', 'ScriptBlock')]
        [string]$NodeType,
        
        [Parameter()]
        [hashtable]$Properties = @{}
    )
    
    # Return PSCustomObject with expected AST node properties
}

function New-MockConfiguration {
    <#
    .SYNOPSIS
        Create test configuration hashtables with realistic values
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Preset = 'Default',
        
        [Parameter()]
        [hashtable]$Overrides = @{}
    )
    
    # Return configuration hashtable
}

function New-TestScript {
    <#
    .SYNOPSIS
        Generate test PowerShell scripts with specific patterns
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Clean', 'WithSecrets', 'WithComplexity', 'WithSecurityIssues')]
        [string]$Pattern = 'Clean',
        
        [Parameter()]
        [int]$Lines = 50
    )
    
    # Return script content as string
}

Export-ModuleMember -Function @(
    'New-MockAstNode',
    'New-MockConfiguration',
    'New-TestScript'
)
```

### 2. Property-Based Testing Utilities

**File:** `tests/Helpers/PropertyTesting.psm1` (New)

```powershell
<#
.SYNOPSIS
    Property-based testing utilities for generating test data
#>

function Get-RandomString {
    <#
    .SYNOPSIS
        Generate random strings with controlled characteristics
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MinLength = 1,
        
        [Parameter()]
        [int]$MaxLength = 100,
        
        [Parameter()]
        [ValidateSet('Alphanumeric', 'Ascii', 'Unicode', 'Base64', 'Hex')]
        [string]$CharacterSet = 'Alphanumeric',
        
        [Parameter()]
        [int]$Seed = $null
    )
    
    if ($Seed) {
        Get-Random -SetSeed $Seed
    }
    
    $length = Get-Random -Minimum $MinLength -Maximum ($MaxLength + 1)
    # Generate string based on CharacterSet
}

function Get-TestCaseMatrix {
    <#
    .SYNOPSIS
        Generate test case matrices for -TestCases parameter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Dimensions
    )
    
    # Cartesian product of dimensions
}

Export-ModuleMember -Function @(
    'Get-RandomString',
    'Get-TestCaseMatrix'
)
```

---

## CI/CD Enhancements

### 1. Enhanced Coverage Gates

**File:** `.github/workflows/pester-tests.yml` (Enhanced)

Add after test execution:

```yaml
      - name: Verify coverage thresholds
        shell: pwsh
        run: |
          if ($result.CodeCoverage) {
            $coverage = $result.CodeCoverage
            $totalCommands = ($coverage.CoverageReport | Measure-Object -Property NumberOfCommandsAnalyzed -Sum).Sum
            $executedCommands = ($coverage.CoverageReport | Measure-Object -Property NumberOfCommandsExecuted -Sum).Sum
            
            $coveredPercent = if ($totalCommands -gt 0) {
              [math]::Round(($executedCommands / $totalCommands * 100), 2)
            } else { 0 }
            
            # Enforce minimum coverage
            $minCoverage = 85
            if ($coveredPercent -lt $minCoverage) {
              Write-Host "❌ Coverage $coveredPercent% is below minimum $minCoverage%" -ForegroundColor Red
              exit 1
            }
            
            Write-Host "✅ Coverage $coveredPercent% meets minimum $minCoverage%" -ForegroundColor Green
          }
```

### 2. Test Performance Monitoring

**File:** `.github/workflows/test-performance.yml` (New)

```yaml
name: Test Performance Monitoring

on:
  pull_request:
    paths:
      - 'tests/**'
      - 'tools/lib/**'

jobs:
  performance:
    name: Monitor test performance
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PowerShell
        uses: PowerShell/PowerShell-For-GitHub-Actions@v1
        with:
          version: '7.4'
      
      - name: Install dependencies
        shell: pwsh
        run: |
          Install-Module -Name Pester -Force -MinimumVersion 5.5.0
      
      - name: Run tests with timing
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './tests'
          $config.Output.Verbosity = 'Detailed'
          
          $result = Invoke-Pester -Configuration $config
          
          # Check for slow tests (> 500ms per It block)
          $slowTests = $result.Tests | Where-Object { $_.Duration.TotalMilliseconds -gt 500 }
          
          if ($slowTests) {
            Write-Host "⚠️ Found $($slowTests.Count) slow tests:" -ForegroundColor Yellow
            $slowTests | ForEach-Object {
              Write-Host "  - $($_.Name): $($_.Duration.TotalMilliseconds)ms" -ForegroundColor Yellow
            }
          }
```

---

## Test Execution Strategy

### Local Development

```powershell
# Run all tests
Invoke-Pester -Path ./tests

# Run specific module tests
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1

# Run with coverage
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/**/*.psm1'
Invoke-Pester -Configuration $config

# Run tests by tag
Invoke-Pester -Path ./tests -Tag 'Unit'
Invoke-Pester -Path ./tests -ExcludeTag 'Integration'
```

### CI/CD Execution

```bash
# GitHub Actions will automatically run tests on:
# - Push to main/develop branches
# - Pull requests to main/develop
# - Manual workflow dispatch

# Coverage reports uploaded to Codecov
# Test results uploaded as artifacts
```

---

## Test Maintenance Guidelines

### 1. Test Naming Conventions

```powershell
# Pattern: It '<Function> <Scenario> => <Expected>'
It 'Get-ShannonEntropy calculates correctly for known string => returns expected range' {}
It 'Initialize-PoshGuardConfiguration with invalid JSON => throws with helpful message' {}
It 'Merge-Configuration with null override => preserves base configuration' {}
```

### 2. Test Organization

```
tests/
├── Unit/                      # Unit tests for modules
│   ├── Core.Tests.ps1
│   ├── Security.Tests.ps1
│   └── ...
├── Integration/               # Integration tests (future)
│   └── EndToEnd.Tests.ps1
├── Helpers/                   # Test utilities
│   ├── TestHelpers.psm1
│   ├── MockBuilders.psm1
│   ├── AdvancedMockBuilders.psm1  # New
│   └── PropertyTesting.psm1       # New
└── Fixtures/                  # Test data files (future)
    └── sample-scripts/
```

### 3. Test Review Checklist

Before merging test changes:

- [ ] All tests follow AAA pattern (Arrange-Act-Assert)
- [ ] No real time/network/filesystem side effects (use mocks/TestDrive)
- [ ] Each `It` block tests one behavior
- [ ] Test names clearly describe intent
- [ ] -TestCases used for input matrices
- [ ] Mock verification with -Exactly -Times
- [ ] Edge cases and error paths covered
- [ ] No flaky tests (deterministic execution)
- [ ] Tests complete in < 100ms (or < 500ms for complex)
- [ ] PSScriptAnalyzer passes on test files

---

## Coverage Goals

### Module-Level Targets

| Module | Current | Target | Priority |
|--------|---------|--------|----------|
| ConfigurationManager | 35% | 90% | High |
| NISTSP80053Compliance | 40% | 85% | High |
| EnhancedSecurityDetection | 46% | 90% | High |
| EntropySecretDetection | 53% | 90% | Medium |
| SecurityDetectionEnhanced | 55% | 90% | Medium |
| MCPIntegration | 62% | 85% | Medium |
| SupplyChainSecurity | 67% | 85% | Low |
| All Others | 70%+ | 90% | Low |

### Overall Project Targets

- **Line Coverage:** ≥ 90%
- **Branch Coverage:** ≥ 85%
- **Function Coverage:** 100% (all exported functions tested)
- **Test Pass Rate:** 100% (zero flakes)
- **Performance:** ≥ 95% of tests < 100ms

---

## Implementation Roadmap

### Phase 1: Critical Gaps (Week 1)
- [x] Analyze existing test coverage
- [ ] Enhance ConfigurationManager tests (90%+ coverage)
- [ ] Add comprehensive EntropySecretDetection tests
- [ ] Create AdvancedMockBuilders helper module

### Phase 2: Security & Compliance (Week 2)
- [ ] Enhance NISTSP80053Compliance tests
- [ ] Enhance EnhancedSecurityDetection tests
- [ ] Add SecurityDetectionEnhanced edge cases
- [ ] Create PropertyTesting helper module

### Phase 3: Infrastructure (Week 3)
- [ ] Add coverage threshold enforcement to CI
- [ ] Create test performance monitoring workflow
- [ ] Add test result summaries to PR comments
- [ ] Document test execution strategies

### Phase 4: Maintenance (Ongoing)
- [ ] Regular coverage audits
- [ ] Test performance optimization
- [ ] Test code reviews
- [ ] Knowledge sharing sessions

---

## Success Metrics

### Quality Metrics
- Code coverage ≥ 90% (lines), ≥ 85% (branches)
- Zero flaky tests
- All tests pass on all platforms (Windows/macOS/Linux)
- Test execution time < 2 minutes for full suite

### Velocity Metrics
- New features include tests before merge
- Bug fixes include regression tests
- Test review time < 1 business day
- Test maintenance burden < 5% of development time

### Reliability Metrics
- CI test pass rate ≥ 99%
- False positive rate < 1%
- Test environment setup time < 30 seconds
- Test debugging time < 10 minutes per failure

---

## Conclusion

This comprehensive test plan ensures PoshGuard maintains the highest standards of quality, reliability, and maintainability. By following the Pester Architect principles and implementing the enhancements outlined here, we will achieve:

1. ✅ **Deterministic, hermetic tests** that never flake
2. ✅ **High signal-to-noise ratio** with meaningful coverage
3. ✅ **Fast feedback loops** with quick test execution
4. ✅ **Strong safety nets** for refactoring and feature work
5. ✅ **Clear documentation** for test maintenance

The roadmap provides a clear path forward, and the success metrics ensure we can measure and maintain quality over time.
