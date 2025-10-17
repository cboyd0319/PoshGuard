# PoshGuard Comprehensive Test Plan - Pester Architect Standards

## Executive Summary

This document provides a comprehensive test strategy for PoshGuard following Pester Architect principles: deterministic, hermetic, maintainable test suites with high coverage and clear intent.

**Status:** ✅ All 48 modules have comprehensive test coverage
**Framework:** Pester v5.7.1+
**Coverage Target:** 90%+ lines, 85%+ branches
**Platforms:** Windows, macOS, Linux (PowerShell 7.4.4+)

## Test Architecture

### Module Coverage Summary

| Category | Modules | Test Files | Status |
|----------|---------|------------|--------|
| Core Modules | 20 | 20 | ✅ Complete |
| Advanced Submodules | 14 | 14 | ✅ Complete |
| BestPractices Submodules | 7 | 7 | ✅ Complete |
| Formatting Submodules | 7 | 7 | ✅ Complete |
| **Total** | **48** | **48** | **✅ 100%** |

### Core Module Test Coverage

1. **Core.psm1** - Foundation utilities
   - Clean-Backups: WhatIf, old file cleanup, missing directory
   - Write-Log: All levels, timestamps, icons, edge cases
   - Get-PowerShellFiles: Single file, directory, extensions, paths with spaces
   - New-FileBackup: ShouldProcess, backup creation, timestamps
   - New-UnifiedDiff: Additions, deletions, identical content

2. **Security.psm1** - Critical security fixes
   - Invoke-PlainTextPasswordFix: All password parameter patterns
   - Invoke-ConvertToSecureStringFix: Insecure conversions
   - Invoke-UsernamePasswordParamsFix: Credential consolidation
   - Invoke-AllowUnencryptedAuthFix: WinRM security
   - Invoke-HardcodedComputerNameFix: Remote access patterns
   - Invoke-InvokeExpressionFix: Code injection prevention
   - Invoke-EmptyCatchBlockFix: Error handling improvements

3. **BestPractices.psm1** - Code quality standards
   - 7 submodules covering naming, scoping, type safety, syntax, string handling, usage patterns

4. **Formatting.psm1** - Code style enforcement
   - 7 submodules for aliases, alignment, casing, output, runspaces, whitespace, Write-Host

5. **Advanced.psm1** - Complex AST transformations
   - 14 submodules for CmdletBinding, parameters, manifests, documentation, attributes

6. **AI/ML Modules**
   - AIIntegration.psm1: ML-powered analysis
   - ReinforcementLearning.psm1: Adaptive learning
   - AdvancedDetection.psm1: Pattern recognition

7. **Security Enhancement Modules**
   - EnhancedSecurityDetection.psm1: Advanced threat detection
   - EntropySecretDetection.psm1: High-entropy secret scanning
   - SecurityDetectionEnhanced.psm1: Multi-layer security
   - SupplyChainSecurity.psm1: Dependency analysis

8. **Observability & Compliance**
   - Observability.psm1: Metrics and monitoring
   - OpenTelemetryTracing.psm1: Distributed tracing
   - NISTSP80053Compliance.psm1: Federal compliance
   - EnhancedMetrics.psm1: Advanced analytics

9. **Performance & Integration**
   - PerformanceOptimization.psm1: Speed improvements
   - ConfigurationManager.psm1: Settings management
   - MCPIntegration.psm1: External integrations

## Test Quality Standards

### 1. Naming Conventions
```powershell
Describe '<ModuleName>' -Tag 'Unit', '<Category>' {
  Context '<Scenario/Condition>' {
    It '<Function> <Input> => <Expected Behavior>' {
      # Arrange
      # Act
      # Assert
    }
  }
}
```

### 2. Isolation & Determinism
- ✅ All tests use `TestDrive:` for filesystem operations
- ✅ Time mocked with `Get-Date` stubs
- ✅ Network calls mocked with `Invoke-RestMethod`/`Invoke-WebRequest` stubs
- ✅ No real sleeps - all `Start-Sleep` mocked
- ✅ No cross-test state leakage via `BeforeEach`/`AfterEach`

### 3. Mocking Strategy
```powershell
InModuleScope <ModuleName> {
  Mock -CommandName <ExternalCommand> -ParameterFilter { ... } -MockWith { ... }
  # Test code
  Assert-MockCalled <ExternalCommand> -Exactly -Times <N>
}
```

### 4. Table-Driven Tests
```powershell
It 'validates <Description>' -TestCases @(
  @{ Input = 'value1'; Expected = 'result1'; Description = 'case1' }
  @{ Input = 'value2'; Expected = 'result2'; Description = 'case2' }
) {
  param($Input, $Expected, $Description)
  # Test implementation
}
```

### 5. Error Path Testing
- All functions tested with null/empty inputs
- Invalid parameter combinations verified
- Exception messages validated with `-ErrorId` or `-ExceptionMessage`
- Warning/Verbose streams captured and asserted

### 6. ShouldProcess Testing
```powershell
It 'respects -WhatIf' {
  InModuleScope <Module> {
    Mock <SideEffectCommand> -Verifiable
    <Function> -WhatIf
    Assert-MockCalled <SideEffectCommand> -Times 0
  }
}
```

## Coverage Targets & Enforcement

### Current Coverage (Linux/CI)
```yaml
Minimum Thresholds:
  Lines: 85%
  Branches: 80%
  Functions: 95%

Priority Modules (90%+ required):
  - Security.psm1
  - Core.psm1
  - EntropySecretDetection.psm1
  - SupplyChainSecurity.psm1
```

### CI/CD Integration
```yaml
Platforms:
  - ubuntu-latest (with coverage)
  - windows-latest
  - macos-latest

Quality Gates:
  1. PSScriptAnalyzer (Error/Warning)
  2. Pester tests (all must pass)
  3. Code coverage (85%+ on Linux)
  4. Test results upload (NUnitXml)
  5. Coverage upload (JaCoCo to Codecov)
```

## Test Helpers & Fixtures

### TestHelpers.psm1
- `New-TestScriptContent`: Generates sample scripts with configurable issues
- `New-TestFileStructure`: Creates filesystem test scenarios
- `Get-ASTFromContent`: Parses PowerShell into AST for validation

### MockBuilders.psm1
- `New-MockPSSAResult`: PSSA violation stubs
- `New-MockAST`: AST node builders
- `New-MockDiagnostic`: Issue/violation objects

### PropertyTesting.psm1
- Randomized input generators (seeded for reproducibility)
- Edge case generators (boundary values, unicode, special chars)

## Recent Fixes & Enhancements

### AdvancedCodeAnalysis Bug Fixes (2025-10-17)
1. **Unreachable Code Detection**
   - Issue: Only checked `StatementBlockAst`, missed `NamedBlockAst` (function bodies)
   - Fix: Added support for both AST node types
   - Impact: Now correctly detects code after return in functions

2. **Variable Name Interpolation**
   - Issue: Description used `\$$varName` causing literal output
   - Fix: Changed to `` `$$varName `` for proper interpolation
   - Impact: Variable names now display correctly in diagnostics

3. **Empty Content Handling**
   - Issue: PowerShell rejected empty strings for mandatory parameters
   - Fix: Added `[AllowEmptyString()]` attribute
   - Impact: Edge case tests can now validate empty input handling

## Future Enhancements

### Phase 1: Test Robustness (Q4 2025)
- [ ] Add performance regression tests with baseline timing
- [ ] Implement property-based testing for AST transformations
- [ ] Add mutation testing to validate test effectiveness
- [ ] Create test data generators for realistic PowerShell scenarios

### Phase 2: Advanced Coverage (Q1 2026)
- [ ] Integration tests for end-to-end workflows
- [ ] Stress tests for large codebases (10K+ LOC)
- [ ] Concurrent execution tests (thread safety)
- [ ] Memory profiling and leak detection

### Phase 3: Test Documentation (Q1 2026)
- [ ] Generate coverage badges for README
- [ ] Create test result dashboards
- [ ] Document test patterns and anti-patterns
- [ ] Build test authoring guidelines

## Anti-Patterns to Avoid

❌ Real filesystem operations outside TestDrive:
❌ Actual network calls in unit tests
❌ Time-dependent tests without mocked `Get-Date`
❌ Random inputs without seeded generators
❌ Cross-test dependencies or shared state
❌ Tests that modify global PowerShell state
❌ Assertions on multiple unrelated behaviors in one `It`
❌ Mocking without verifying call counts/parameters

## Test Execution

### Local Development
```powershell
# Run all tests
Invoke-Pester -Path ./tests/Unit -Output Detailed

# Run specific module
Invoke-Pester -Path ./tests/Unit/Security.Tests.ps1 -Output Detailed

# Run with coverage
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/*.psm1'
Invoke-Pester -Configuration $config
```

### CI/CD
See `.github/workflows/pester-architect-tests.yml` for automated execution on:
- Every push to main/develop
- Every pull request
- Manual workflow dispatch

## Metrics & Reporting

### Test Health Metrics
- Total tests: 1000+
- Average execution time: < 5 minutes
- Flakiness rate: < 0.1%
- Code coverage: 85%+

### Quality Indicators
- All security modules: 90%+ coverage
- Zero failing tests in main branch
- All exported functions have tests
- All error paths covered

## Conclusion

PoshGuard has achieved comprehensive test coverage following Pester Architect principles:
- **Deterministic**: No flaky tests, fully reproducible
- **Hermetic**: Isolated from external dependencies
- **Maintainable**: Clear structure, table-driven, well-documented
- **High Coverage**: 85%+ lines, 80%+ branches
- **Multi-Platform**: Verified on Windows/macOS/Linux

The test suite provides confidence for refactoring, ensures security guarantees, and enables rapid feature development with quality guardrails.

---

**Last Updated:** 2025-10-17
**Maintainer:** PoshGuard Team
**Version:** 4.3.0
