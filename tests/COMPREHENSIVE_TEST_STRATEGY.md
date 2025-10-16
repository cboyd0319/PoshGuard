# PoshGuard Comprehensive Test Strategy

## Executive Summary
This document outlines the comprehensive testing strategy for PoshGuard, following the **Pester Architect Agent** playbook. The goal is to achieve ≥90% line coverage and ≥85% branch coverage across all modules with deterministic, maintainable, and hermetic tests.

## Current State (Baseline)
- **Existing Tests**: 9 test files, 203 passing tests
- **Pester Version**: 5.7.1
- **Test Success Rate**: 100% (203/203 passing)
- **Execution Time**: ~4 seconds
- **Coverage**: Partial (Core, Security, ConfigurationManager, EntropySecretDetection, PoshGuard, partial BestPractices/Formatting)

## Modules Inventory

### Tested Modules (9)
1. Core.psm1 - 37 tests
2. Security.psm1 - 63 tests
3. ConfigurationManager.psm1 - 14 tests
4. EntropySecretDetection.psm1 - 21 tests
5. PoshGuard.psm1 - 13 tests
6. BestPractices/Naming.Tests.ps1 - 8 tests
7. BestPractices/Syntax.Tests.ps1 - 20 tests
8. Formatting/Aliases.Tests.ps1 - 14 tests
9. Formatting/Whitespace.Tests.ps1 - 13 tests

### Untested Modules (39)

#### Critical Priority (AST Transformations & Auto-Fix)
1. **Advanced/ASTTransformations.psm1** - WMI→CIM, hash algorithms, long lines
2. **Advanced/ParameterManagement.psm1** - Reserved params, switch defaults
3. **Advanced/CodeAnalysis.psm1** - Safety fixes, duplicate lines
4. **Advanced/Documentation.psm1** - Comment-based help, OutputType
5. **Advanced/AttributeManagement.psm1** - ShouldProcess, CmdletBinding
6. **Advanced/ManifestManagement.psm1** - Module manifest validation
7. **Advanced/ShouldProcessTransformation.psm1** - PSShouldProcess body wrapping
8. **Advanced/InvokingEmptyMembers.psm1** - Non-constant member access
9. **Advanced/OverwritingBuiltInCmdlets.psm1** - Built-in cmdlet shadowing
10. **Advanced/DefaultValueForMandatoryParameter.psm1** - Mandatory param defaults
11. **Advanced/UTF8EncodingForHelpFile.psm1** - Help file encoding
12. **Advanced/CmdletBindingFix.psm1** - CmdletBinding placement
13. **Advanced/CompatibleCmdletsWarning.psm1** - Cross-platform compatibility
14. **Advanced/DeprecatedManifestFields.psm1** - Deprecated manifest fields

#### High Priority (Best Practices)
15. **BestPractices/CodeQuality.psm1** - Beyond-PSSA enhancements
16. **BestPractices/Scoping.psm1** - Global variables and functions
17. **BestPractices/StringHandling.psm1** - Double quotes, hashtable literals
18. **BestPractices/TypeSafety.psm1** - Type attributes, PSCredential
19. **BestPractices/UsagePatterns.psm1** - Positional params, unused variables

#### High Priority (Formatting)
20. **Formatting/Alignment.psm1** - Assignment alignment
21. **Formatting/Casing.psm1** - Cmdlet and parameter PascalCase
22. **Formatting/Output.psm1** - Write-Host → Write-Output
23. **Formatting/Runspaces.psm1** - $using: scope, ShouldContinue
24. **Formatting/WriteHostEnhanced.psm1** - Enhanced Write-Host fixes

#### High Priority (Detection & Analysis)
25. **AdvancedCodeAnalysis.psm1** - Advanced code analysis
26. **AdvancedDetection.psm1** - Advanced security detection
27. **SecurityDetectionEnhanced.psm1** - Enhanced security detection
28. **EnhancedSecurityDetection.psm1** - Additional security detection
29. **EnhancedMetrics.psm1** - Code quality metrics

#### Medium Priority (Integration & Compliance)
30. **AIIntegration.psm1** - AI-powered analysis
31. **MCPIntegration.psm1** - Model Context Protocol integration
32. **NISTSP80053Compliance.psm1** - NIST compliance validation
33. **SupplyChainSecurity.psm1** - SBOM and supply chain security

#### Medium Priority (Observability)
34. **Observability.psm1** - Logging and metrics
35. **OpenTelemetryTracing.psm1** - OpenTelemetry integration
36. **PerformanceOptimization.psm1** - Performance enhancements
37. **ReinforcementLearning.psm1** - ML-based learning

#### Facade Modules (Import submodules)
38. **Advanced.psm1** - Facade for Advanced submodules
39. **BestPractices.psm1** - Facade for BestPractices submodules
40. **Formatting.psm1** - Facade for Formatting submodules

## Testing Principles (Pester Architect Playbook)

### 1. Framework & Structure
- **Pester v5+** exclusively
- **AAA Pattern**: Arrange-Act-Assert
- **Naming**: `It "<Unit> <Scenario> => <Expected>"`
- **File Names**: `*.Tests.ps1`
- **Location**: `tests/Unit/<Module>/<Submodule>.Tests.ps1`

### 2. Determinism
- ❌ **NO** real time, randomness, network, registry/filesystem side effects
- ✅ **YES** Mock `Get-Date`, `Start-Sleep`, network calls
- ✅ **YES** Freeze time via mocks
- ✅ **YES** Seeded generators if needed

### 3. Isolation
- **TestDrive:** for filesystem operations
- **Mock** for external dependencies
- **InModuleScope** for internal testing
- **BeforeAll/BeforeEach** for setup
- **No cross-test state leakage**

### 4. Coverage Targets
- **Lines**: ≥90% per module
- **Branches**: ≥85% for critical paths
- **Focus**: Meaningful branches and error semantics, not just percent

### 5. Test Priorities
1. ✅ Public contract of exported functions (happy paths)
2. ✅ Error handling (thrown exceptions, error records)
3. ✅ Boundary/edge inputs (empty/null/large/unicode/invalid types)
4. ✅ Branching/guards (if/elseif/else, early returns, ShouldProcess)
5. ✅ Side-effects (file IO, registry, env vars - mock or TestDrive:)
6. ✅ Pipelines (ValueFromPipeline, streaming behavior)
7. ✅ Concurrency/time (timeouts, retries - via mocks)

## Test Structure Requirements

### File Structure
```
tests/
  Unit/
    Advanced/
      ASTTransformations.Tests.ps1
      ParameterManagement.Tests.ps1
      ...
    BestPractices/
      CodeQuality.Tests.ps1
      Scoping.Tests.ps1
      ...
    Formatting/
      Alignment.Tests.ps1
      Casing.Tests.ps1
      ...
    AdvancedCodeAnalysis.Tests.ps1
    ...
  Helpers/
    TestHelpers.psm1
    ASTHelpers.psm1
    MockHelpers.psm1
  COMPREHENSIVE_TEST_STRATEGY.md
```

### Test Template
```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for <ModuleName>

.DESCRIPTION
    Comprehensive unit tests covering:
    - Function1: Description
    - Function2: Description
    
    Tests include happy paths, edge cases, error conditions,
    and parameter validation with deterministic execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/<Path>/<Module>.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe '<FunctionName>' -Tag 'Unit', '<ModuleName>' {
  
  Context 'When <scenario>' {
    It 'Should <expected behavior>' {
      # Arrange
      # Act
      # Assert
    }
  }
  
  Context 'Error handling' {
    It 'Should throw when <invalid condition>' {
      { <FunctionName> -Param <invalid> } | Should -Throw -ErrorId '<ErrorId>'
    }
  }
}
```

### Common Test Patterns

#### Table-Driven Tests
```powershell
It 'Should <behavior> for <input>' -TestCases @(
  @{ Input = 'a'; Expected = 'A'; Id = 'lowercase' }
  @{ Input = 'Z'; Expected = 'Z'; Id = 'uppercase' }
  @{ Input = ''; Expected = ''; Id = 'empty' }
) {
  param($Input, $Expected)
  $result = Transform-Text -Text $Input
  $result | Should -BeExactly $Expected
}
```

#### Mocking External Calls
```powershell
It 'Should call external dependency with correct parameters' {
  InModuleScope <ModuleName> {
    Mock Invoke-RestMethod -ParameterFilter {
      $Uri -eq 'https://api.example.com' -and
      $Headers['Authorization'] -eq 'Bearer token'
    } -MockWith {
      [pscustomobject]@{ result = 'success' }
    } -Verifiable

    Get-RemoteData -Token 'token'
    
    Assert-MockCalled Invoke-RestMethod -Exactly -Times 1 -Scope It
  }
}
```

#### TestDrive for File Operations
```powershell
It 'Should create file with correct content' {
  # Arrange
  $testPath = Join-Path TestDrive: 'test.txt'
  $content = 'Hello World'
  
  # Act
  New-TestFile -Path $testPath -Content $content
  
  # Assert
  $testPath | Should -Exist
  Get-Content -Path $testPath -Raw | Should -BeExactly $content
}
```

#### ShouldProcess / WhatIf
```powershell
It 'Should respect -WhatIf and not make changes' {
  InModuleScope <ModuleName> {
    Mock Remove-Item -Verifiable
    
    Remove-TestResource -Path 'test.txt' -WhatIf
    
    Assert-MockCalled Remove-Item -Times 0
  }
}
```

## Implementation Phases

### Phase 1: Foundation & High-Priority Modules (Week 1)
**Goal**: Establish test infrastructure and cover critical AST transformation modules

1. **Enhance Test Helpers** (Day 1)
   - [ ] Add ASTHelpers.psm1 for AST testing utilities
   - [ ] Add MockHelpers.psm1 for common mock patterns
   - [ ] Update TestHelpers.psm1 with table-driven test builders

2. **Advanced Submodules** (Days 2-5)
   - [ ] ASTTransformations.Tests.ps1
   - [ ] ParameterManagement.Tests.ps1
   - [ ] CodeAnalysis.Tests.ps1
   - [ ] Documentation.Tests.ps1
   - [ ] AttributeManagement.Tests.ps1
   - [ ] ManifestManagement.Tests.ps1
   - [ ] ShouldProcessTransformation.Tests.ps1
   - [ ] InvokingEmptyMembers.Tests.ps1
   - [ ] OverwritingBuiltInCmdlets.Tests.ps1
   - [ ] DefaultValueForMandatoryParameter.Tests.ps1
   - [ ] UTF8EncodingForHelpFile.Tests.ps1
   - [ ] CmdletBindingFix.Tests.ps1
   - [ ] CompatibleCmdletsWarning.Tests.ps1
   - [ ] DeprecatedManifestFields.Tests.ps1

3. **Facade Module Tests** (Day 5)
   - [ ] Advanced.Tests.ps1 (verify submodule imports)

### Phase 2: Best Practices & Formatting (Week 2)
**Goal**: Complete BestPractices and Formatting module coverage

1. **BestPractices Submodules** (Days 1-3)
   - [ ] CodeQuality.Tests.ps1
   - [ ] Scoping.Tests.ps1
   - [ ] StringHandling.Tests.ps1
   - [ ] TypeSafety.Tests.ps1
   - [ ] UsagePatterns.Tests.ps1
   - [ ] BestPractices.Tests.ps1 (facade)

2. **Formatting Submodules** (Days 4-5)
   - [ ] Alignment.Tests.ps1
   - [ ] Casing.Tests.ps1
   - [ ] Output.Tests.ps1
   - [ ] Runspaces.Tests.ps1
   - [ ] WriteHostEnhanced.Tests.ps1
   - [ ] Formatting.Tests.ps1 (facade)

### Phase 3: Detection & Analysis (Week 3)
**Goal**: Cover security and code analysis modules

1. **Detection Modules** (Days 1-5)
   - [ ] AdvancedCodeAnalysis.Tests.ps1
   - [ ] AdvancedDetection.Tests.ps1
   - [ ] SecurityDetectionEnhanced.Tests.ps1
   - [ ] EnhancedSecurityDetection.Tests.ps1
   - [ ] EnhancedMetrics.Tests.ps1

### Phase 4: Integration & Compliance (Week 4)
**Goal**: Cover integration and compliance modules

1. **Integration Modules** (Days 1-4)
   - [ ] AIIntegration.Tests.ps1
   - [ ] MCPIntegration.Tests.ps1
   - [ ] NISTSP80053Compliance.Tests.ps1
   - [ ] SupplyChainSecurity.Tests.ps1

2. **Observability Modules** (Day 5)
   - [ ] Observability.Tests.ps1
   - [ ] OpenTelemetryTracing.Tests.ps1
   - [ ] PerformanceOptimization.Tests.ps1
   - [ ] ReinforcementLearning.Tests.ps1

### Phase 5: CI/CD Integration (Week 5)
**Goal**: Integrate comprehensive testing into CI/CD pipeline

1. **GitHub Actions Workflow** (Days 1-2)
   - [ ] Create `.github/workflows/pester-tests.yml`
   - [ ] Add matrix testing (Windows/macOS/Linux)
   - [ ] Configure coverage reporting (JaCoCo format)
   - [ ] Add PSScriptAnalyzer static analysis step

2. **Coverage Gates** (Day 3)
   - [ ] Configure Pester code coverage
   - [ ] Set up coverage thresholds (90% lines, 85% branches)
   - [ ] Add coverage reports to pull requests

3. **SARIF Integration** (Day 4)
   - [ ] Export PSScriptAnalyzer results in SARIF format
   - [ ] Upload to GitHub Security tab
   - [ ] Configure security scanning alerts

4. **Documentation** (Day 5)
   - [ ] Update README with testing information
   - [ ] Document test writing guidelines
   - [ ] Create contributor guide for tests

## Quality Gates

### Static Analysis (PSScriptAnalyzer)
**Mandatory Rules** (fail CI on violations):
- PSUseDeclaredVarsMoreThanAssignments
- PSAvoidUsingWriteHost
- PSUseBOMForUnicodeEncodedFile
- PSUseConsistentIndentation
- PSUseConsistentWhitespace
- PSUseApprovedVerbs
- PSAvoidUsingPlainTextForPassword

**Severity**: Error + Warning (fail build)

### Code Coverage
**Targets per module**:
- Lines: ≥90%
- Branches: ≥85%
- Functions: 100% (all public functions must have tests)

**Enforcement**: CI fails if coverage drops below threshold

### Performance
**Test execution**:
- Typical `It`: <100ms
- Maximum `It`: <500ms
- Full test suite: <5 minutes

### Determinism
**Zero tolerance for**:
- Flaky tests
- Network dependencies
- Real filesystem operations outside TestDrive:
- Unseeded randomness
- Real time dependencies

## Mocking Strategies

### Network Calls
```powershell
Mock Invoke-RestMethod -ParameterFilter {
  $Uri -like 'https://api.example.com/*'
} -MockWith {
  [pscustomobject]@{ data = 'mocked' }
}
```

### File System
```powershell
# Use TestDrive: for all file operations
$testFile = Join-Path TestDrive: 'test.ps1'
New-Item -Path $testFile -ItemType File -Force
```

### Time
```powershell
Mock Get-Date { [datetime]'2025-01-15 12:00:00' }
Mock Start-Sleep { }  # Never actually sleep in tests
```

### Registry
```powershell
Mock Get-ItemProperty -ParameterFilter {
  $Path -eq 'HKLM:\Software\Test'
} -MockWith {
  @{ Value = 'mocked' }
}
```

### Process Execution
```powershell
Mock Start-Process -MockWith {
  [pscustomobject]@{ ExitCode = 0; Output = 'mocked' }
}
```

## Success Metrics

### Quantitative
- **Total Tests**: Target 1000+ tests
- **Line Coverage**: ≥90% across all modules
- **Branch Coverage**: ≥85% across all modules
- **Test Execution Time**: <5 minutes
- **Flake Rate**: 0% (no flaky tests tolerated)
- **CI Success Rate**: ≥99%

### Qualitative
- **Maintainability**: Tests follow consistent patterns
- **Readability**: Intent-revealing test names and structure
- **Documentation**: All complex tests have explanatory comments
- **Isolation**: Each test can run independently
- **Speed**: Fast feedback loop for developers

## Anti-Patterns to Avoid

### ❌ Flaky Tests
- Real time/network/registry dependencies
- Hidden sleeps
- Unseeded randomness

### ❌ Poor Mocking
- Mocking private helpers instead of testing public behavior
- Over-mocking (mock everything, test nothing)
- Under-mocking (real external dependencies)

### ❌ Bad Structure
- Multiple unrelated behaviors in one `It`
- Unclear test names
- Missing AAA structure
- Cross-test dependencies

### ❌ Filesystem Issues
- Touching real user profile
- Modifying global environment
- Changing repo files
- Not using TestDrive:

### ❌ Contract Violations
- Exporting functions without CmdletBinding()
- Missing parameter validation
- Ignoring ShouldProcess when declared

## Resources

### Documentation
- [Pester Documentation](https://pester.dev/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [PowerShell AST Documentation](https://docs.microsoft.com/en-us/powershell/scripting/developer/prog-guide/windows-powershell-programmer-s-guide)

### Tools
- Pester v5.7.1
- PSScriptAnalyzer v1.24.0+
- PowerShell 5.1+ / PowerShell 7+

### Test Helpers
- `tests/Helpers/TestHelpers.psm1` - General utilities
- `tests/Helpers/ASTHelpers.psm1` - AST testing utilities
- `tests/Helpers/MockHelpers.psm1` - Common mock patterns

## Conclusion

This comprehensive test strategy ensures PoshGuard maintains the highest quality standards through:
1. **Deterministic, hermetic tests** that run reliably across platforms
2. **High coverage targets** (≥90% lines, ≥85% branches) enforced in CI
3. **Maintainable test code** following Pester Architect playbook patterns
4. **Fast feedback loops** with <5 minute test suite execution
5. **Zero tolerance** for flaky tests and anti-patterns

The phased implementation approach allows incremental progress while maintaining existing functionality and test coverage.
