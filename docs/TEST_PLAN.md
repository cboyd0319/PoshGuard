# PoshGuard Comprehensive Test Plan

## Overview

This document outlines the comprehensive testing strategy for PoshGuard, following Pester v5+ best practices with deterministic, hermetic tests.

## Testing Principles

### Framework & Standards
- **Pester v5+** exclusively for all tests
- **AAA pattern** (Arrange-Act-Assert) for clarity
- **Deterministic execution**: No real time, network, or filesystem dependencies
- **Hermetic isolation**: TestDrive, Mocks, InModuleScope
- **Cross-platform**: Windows, macOS, Linux (PowerShell 7+)

### Test Organization

```
tests/
├── Unit/           # Function-level tests
├── Integration/    # Module-level integration tests
├── Helpers/        # Shared test utilities
└── *.Tests.ps1     # Existing integration tests
```

## Module Coverage

### Phase 1: Core Infrastructure ✅
- **Core.psm1** (5 functions)
  - Clean-Backups: Backup cleanup with date filtering
  - Write-Log: Logging with levels and formatting
  - Get-PowerShellFiles: File discovery with recursion
  - New-FileBackup: File backup with timestamps
  - New-UnifiedDiff: Diff generation
  - **Status**: 32 tests passing

- **Security.psm1** (7 functions)
  - Invoke-PlainTextPasswordFix: SecureString conversion
  - Invoke-ConvertToSecureStringFix: Dangerous pattern detection
  - Invoke-UsernamePasswordParamsFix: PSCredential suggestion
  - Invoke-AllowUnencryptedAuthFix: Unencrypted auth prevention
  - Invoke-HardcodedComputerNameFix: Computer name parameterization
  - Invoke-InvokeExpressionFix: Invoke-Expression removal
  - Invoke-EmptyCatchBlockFix: Error handling enforcement
  - **Status**: 31 tests passing

### Phase 2: Best Practices (21 functions)
Submodules:
- **Syntax.psm1**: Semicolons, null comparisons, exclaim operator
- **Naming.psm1**: Singular nouns, approved verbs, reserved chars
- **Scoping.psm1**: Global variables, global functions
- **StringHandling.psm1**: Double quotes, hashtable literals
- **TypeSafety.psm1**: Automatic variables, type attributes, PSCredential
- **UsagePatterns.psm1**: Positional params, unused variables, assignment operators
- **CodeQuality.psm1**: TODO tracking, namespace optimization (partially covered)

**Test Approach**:
- AST-based validation for code transformations
- Before/after content comparison
- Edge cases: empty files, invalid syntax, Unicode
- Parameter validation tests

### Phase 3: Formatting (12 functions)
Submodules:
- **Whitespace.psm1**: Formatting, trailing whitespace, misleading backticks
- **Aliases.psm1**: Alias expansion (gci → Get-ChildItem)
- **Casing.psm1**: Cmdlet and parameter PascalCase
- **Output.psm1**: Write-Host → Write-Output
- **Alignment.psm1**: Assignment alignment
- **Runspaces.psm1**: $using: scope, ShouldContinue
- **WriteHostEnhanced.psm1**: Enhanced Write-Host handling

**Test Approach**:
- String transformation validation
- Formatting consistency checks
- Whitespace normalization tests
- Cross-platform line ending handling

### Phase 4: Advanced (32 functions)
Submodules:
- **ASTTransformations.psm1**: WMI→CIM, hash algorithms, long lines
- **ParameterManagement.psm1**: Reserved params, switch defaults, unused params
- **CodeAnalysis.psm1**: Safety fixes, duplicate lines, validation
- **Documentation.psm1**: Comment-based help, OutputType
- **AttributeManagement.psm1**: SupportsShouldProcess, CmdletBinding
- **ManifestManagement.psm1**: Module manifest validation
- **ShouldProcessTransformation.psm1**: PSShouldProcess wrapping
- Plus 7 more specialized modules

**Test Approach**:
- Complex AST manipulation validation
- Multi-step transformation tests
- Module manifest parsing and validation
- Attribute detection and modification

### Phase 5: Security & Detection (35 functions)
- **EnhancedSecurityDetection.psm1** (10 functions): ML confidence scoring
- **EntropySecretDetection.psm1** (9 functions): Entropy-based secret detection
- **SecurityDetectionEnhanced.psm1** (10 functions): Enhanced security patterns
- **AdvancedDetection.psm1** (6 functions): Complexity, nesting detection (partially covered)

**Test Approach**:
- Secret pattern detection accuracy
- False positive/negative validation
- Entropy calculation verification
- Threshold testing with edge cases

### Phase 6: Enterprise Features (77 functions)
- **NISTSP80053Compliance.psm1** (28 functions): NIST SP 800-53 controls
- **SupplyChainSecurity.psm1** (8 functions): SBOM generation, dependency analysis
- **AIIntegration.psm1** (14 functions): ML integration, confidence scoring
- **OpenTelemetryTracing.psm1** (15 functions): Observability tracing
- **ReinforcementLearning.psm1** (12 functions): ML model training

**Test Approach**:
- Mocked external AI/ML services
- SBOM schema validation
- Compliance rule verification
- Telemetry data validation

### Phase 7: Infrastructure & Metrics (48 functions)
- **EnhancedMetrics.psm1** (7 functions): Performance metrics (partially covered)
- **AdvancedCodeAnalysis.psm1** (12 functions): Deep code analysis
- **Observability.psm1** (9 functions): Logging and monitoring
- **PerformanceOptimization.psm1** (8 functions): Performance improvements
- **MCPIntegration.psm1** (13 functions): MCP protocol integration
- **ConfigurationManager.psm1** (8 functions): Configuration management

**Test Approach**:
- Performance measurement validation
- Metric accuracy verification
- Configuration serialization/deserialization
- Integration protocol testing with mocks

## Test Patterns

### Table-Driven Tests
```powershell
It 'processes <Description>' -TestCases @(
  @{ Input = 'test1'; Expected = 'result1'; Description = 'case 1' }
  @{ Input = 'test2'; Expected = 'result2'; Description = 'case 2' }
) {
  param($Input, $Expected)
  
  $result = Invoke-Function -Content $Input
  $result | Should -Be $Expected
}
```

### Error Handling Tests
```powershell
It 'throws on invalid input' {
  { Invoke-Function -Content 'invalid' } | Should -Throw -ErrorId 'ExpectedErrorId'
}
```

### AST-Based Validation
```powershell
It 'transforms AST correctly' {
  $input = 'function Test { param([string]$Password) }'
  $result = Invoke-Fix -Content $input
  
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($result, [ref]$null, [ref]$null)
  $params = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true)
  
  $params[0].StaticType.Name | Should -Be 'SecureString'
}
```

### Mocking External Dependencies
```powershell
BeforeAll {
  Mock Invoke-RestMethod { return @{ status = 'success' } }
  Mock Get-Date { return [datetime]'2025-10-16 12:00:00' }
}
```

## Quality Gates

### Static Analysis
- **PSScriptAnalyzer** with `.psscriptanalyzer.psd1` settings
- Enforce: Error and Warning severity
- Rules: Mandatory rules from persona document
- Run in CI on all PowerShell files

### Code Coverage Targets
- **Lines**: ≥ 90% per module
- **Branches**: ≥ 85% for critical paths
- Measured with Pester's built-in coverage
- Reported to Codecov in CI

### Performance Targets
- Typical test: < 100ms
- Maximum test: < 500ms
- Total suite: < 5 minutes

### Test Quality Metrics
- Zero flaky tests (deterministic execution)
- No external dependencies (mocked)
- Cross-platform compatibility verified in CI

## CI/CD Pipeline

### GitHub Actions Workflow
- **Platforms**: Ubuntu, Windows, macOS
- **PowerShell**: 7.4+
- **Steps**:
  1. Install Pester 5.5+ and PSScriptAnalyzer 1.24+
  2. Run PSScriptAnalyzer on all modules
  3. Run Pester tests with coverage
  4. Upload coverage to Codecov
  5. Generate test artifacts

### Triggers
- Push to main, develop, copilot/** branches
- Pull requests to main, develop
- Manual workflow dispatch

## Test Helpers

### TestHelpers.psm1
Located in `tests/Helpers/`, provides:
- **New-TestScriptContent**: Generate test scripts with configurable issues
- **New-TestFile**: Create files in TestDrive
- **Assert-ContentContains**: Content assertion helper
- **New-MockAST**: Parse script content to AST
- **Test-FunctionExists**: Check function availability
- **New-TestHashtable**: Generate test data structures
- **Invoke-WithMockedDate**: Execute with frozen time
- **New-TestModuleManifest**: Create test manifests
- **ConvertTo-UnixLineEndings**: Cross-platform compatibility

## Rationale

### Why These Tests?
1. **Safety**: Security fixes need comprehensive validation
2. **Refactoring Confidence**: Tests enable fearless code improvements
3. **Cross-platform**: Ensure consistency across Windows/Mac/Linux
4. **Documentation**: Tests serve as executable specifications
5. **Quality**: Enforce standards automatically in CI

### What's Not Tested?
1. **GUI/Interactive**: PoshGuard is CLI-focused
2. **Performance**: Not micro-benchmarking (only correctness)
3. **Real External Services**: All mocked for determinism
4. **PowerShell 5.1 Specific**: Focused on PS 7+ (though 5.1 compatible)

### Trade-offs
- **Completeness vs. Maintenance**: Focus on high-value, high-risk areas first
- **Speed vs. Coverage**: Fast tests with good coverage over exhaustive slow tests
- **Strictness vs. Flexibility**: Strict on security, flexible on formatting

## Future Enhancements

1. **Property-Based Testing**: Random input generation with Pester + custom generators
2. **Mutation Testing**: Verify test suite effectiveness
3. **Integration Tests**: End-to-end scenarios with real repositories
4. **Performance Benchmarks**: Track performance regressions
5. **Snapshot Testing**: Golden file comparisons for stable outputs

## Running Tests

### Locally
```powershell
# All tests
Invoke-Pester -Path ./tests

# Specific module
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1

# With coverage
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/*.psm1'
Invoke-Pester -Configuration $config

# Specific tags
Invoke-Pester -Path ./tests -Tag 'Unit','Security'
```

### CI
Tests run automatically on:
- Every push to tracked branches
- Every pull request
- Manual workflow dispatch

See `.github/workflows/pester-tests.yml` for details.

## Current Status

- **Total Tests**: 128 (63 new + 65 existing)
- **Passing**: 128
- **Skipped**: 4
- **Failed**: 0
- **Coverage**: Core.psm1, Security.psm1 (more coming)

## Contributing

When adding new functions:
1. Write tests first (TDD)
2. Follow AAA pattern
3. Use TestDrive for files
4. Mock external calls
5. Test edge cases and errors
6. Keep tests fast (< 100ms)
7. Document complex scenarios

---

**Last Updated**: 2025-10-16  
**Version**: 1.0  
**Status**: In Progress (Phases 1-2 complete)
