# PoshGuard Comprehensive Test Plan

## Overview
This document outlines the comprehensive test strategy for PoshGuard, following Pester v5+ best practices with deterministic, hermetic, and maintainable tests.

## Test Architecture Principles

### Framework & Structure
- **Pester v5+** with Describe/Context/It AAA pattern
- **Naming**: `It "<Unit> <Scenario> => <Expected>"`
- **Determinism**: Mock all time, randomness, network, filesystem
- **Isolation**: TestDrive, Mock, InModuleScope, BeforeAll/BeforeEach
- **Coverage Targets**: Lines ≥90%, Branches ≥85%

### Quality Gates
- PSScriptAnalyzer: Fail on Warning+
- No flaky tests (banned: real sleeps, network calls, registry access)
- Typical `It` < 100ms, worst < 500ms
- Cross-platform (Windows/macOS/Linux with PowerShell 7+)

## Module Testing Priority

### Phase 1: Core Infrastructure (COMPLETE)
**Status**: 9 of 48 modules tested (203 tests passing)

#### Completed Modules
1. ✅ **PoshGuard.psm1** - Main entry point, API surface (24 tests)
2. ✅ **Core.psm1** - File operations, logging, backups, diff (47 tests)
3. ✅ **Security.psm1** - Security fix functions (29 tests)
4. ✅ **ConfigurationManager.psm1** - Configuration management (12 tests)
5. ✅ **EntropySecretDetection.psm1** - Entropy & pattern-based secret detection (32 tests)
6. ✅ **Formatting/Aliases.psm1** - Alias formatting (16 tests)
7. ✅ **Formatting/Whitespace.psm1** - Whitespace fixes (20 tests)
8. ✅ **BestPractices/Naming.psm1** - Naming conventions (5 tests)
9. ✅ **BestPractices/Syntax.psm1** - Syntax fixes (18 tests)

### Phase 2: Critical Security & Detection Modules
**Status**: 1 of 3 modules tested

#### Completed Modules
1. ✅ **EntropySecretDetection.psm1** (32 tests)
   - Get-ShannonEntropy - Entropy calculation
   - Test-IsHex - Hexadecimal detection
   - Test-IsBase64 - Base64 detection
   - Find-SecretsByEntropy - High entropy scanning
   - Find-SecretsByPattern - Pattern matching
   - Get-EntropyConfidence - Confidence scoring

#### Modules to Test
2. **EnhancedSecurityDetection.psm1**
   - Test-EnhancedSecurityIssues
   - Find-SecretsInCode
   - Find-MITREATTCKPatterns
   - Find-CodeInjectionVulnerabilities
   - Find-CryptographicWeaknesses
   
2. **EntropySecretDetection.psm1**
   - Get-ShannonEntropy
   - Test-IsHex
   - Find-SecretsByEntropy
   - Find-SecretsByPattern
   - Get-EntropyConfidence

3. **SecurityDetectionEnhanced.psm1**
   - Enhanced security scanning functions

### Phase 3: Advanced Code Analysis
**Status**: Not started

#### Modules to Test
1. **AdvancedCodeAnalysis.psm1**
   - Find-DeadCode
   - Find-UnreachableCode
   - Find-UnusedFunctions
   - Find-UnusedVariables
   - Find-CommentedCode

2. **AdvancedDetection.psm1**
   - Test-CodeComplexity
   - Get-MaxNestingDepth
   - Test-PerformanceAntiPatterns
   - Test-SecurityVulnerabilities
   - Test-MaintainabilityIssues

3. **EnhancedMetrics.psm1**
   - Initialize-MetricsTracking
   - Add-RuleMetric
   - Get-FixConfidenceScore
   - Add-FileMetric
   - Get-MetricsSummary

### Phase 4: Formatting Modules
**Status**: 2 of 7 modules tested

#### Remaining Modules
1. **Formatting/Alignment.psm1** - Code alignment
2. **Formatting/Casing.psm1** - Case corrections
3. **Formatting/Output.psm1** - Output handling
4. **Formatting/Runspaces.psm1** - Runspace management
5. **Formatting/WriteHostEnhanced.psm1** - Write-Host fixes

### Phase 5: Best Practices Modules
**Status**: 2 of 7 modules tested

#### Remaining Modules
1. **BestPractices/CodeQuality.psm1** - Code quality checks
2. **BestPractices/Scoping.psm1** - Scope management
3. **BestPractices/StringHandling.psm1** - String operations
4. **BestPractices/TypeSafety.psm1** - Type safety
5. **BestPractices/UsagePatterns.psm1** - Usage patterns

### Phase 6: Advanced Fix Modules
**Status**: Not started

#### Modules to Test
1. **Advanced/ASTTransformations.psm1** - AST transformations
2. **Advanced/AttributeManagement.psm1** - Attribute fixes
3. **Advanced/CmdletBindingFix.psm1** - CmdletBinding additions
4. **Advanced/CodeAnalysis.psm1** - Code analysis
5. **Advanced/CompatibleCmdletsWarning.psm1** - Compatibility warnings
6. **Advanced/DefaultValueForMandatoryParameter.psm1** - Parameter defaults
7. **Advanced/DeprecatedManifestFields.psm1** - Manifest cleanup
8. **Advanced/Documentation.psm1** - Documentation fixes
9. **Advanced/InvokingEmptyMembers.psm1** - Member invocation
10. **Advanced/ManifestManagement.psm1** - Manifest management
11. **Advanced/OverwritingBuiltInCmdlets.psm1** - Built-in protection
12. **Advanced/ParameterManagement.psm1** - Parameter handling
13. **Advanced/ShouldProcessTransformation.psm1** - ShouldProcess fixes
14. **Advanced/UTF8EncodingForHelpFile.psm1** - UTF-8 encoding

### Phase 7: Integration & Observability Modules
**Status**: Not started

#### Modules to Test
1. **AIIntegration.psm1** - AI-powered fix confidence scoring
2. **MCPIntegration.psm1** - MCP server integration
3. **OpenTelemetryTracing.psm1** - Distributed tracing
4. **Observability.psm1** - Structured logging and metrics
5. **PerformanceOptimization.psm1** - Performance enhancements
6. **ReinforcementLearning.psm1** - RL-based optimizations
7. **SupplyChainSecurity.psm1** - SBOM and supply chain
8. **NISTSP80053Compliance.psm1** - NIST compliance checks

### Phase 8: Root Module & Entry Points (COMPLETE)
**Status**: 1 of 1 modules tested

#### Completed Modules
1. ✅ **PoshGuard.psm1** - Main module entry point (24 tests)
   - Invoke-PoshGuard function signature and parameters
   - Parameter validation and attributes
   - Module exports and metadata
   - Module structure validation

## Next Steps (Priority Order)
1. ✅ Create test files for Phase 2 modules (EntropySecretDetection - DONE)
2. ✅ Create tests for main PoshGuard module (DONE)
3. Implement tests for remaining Security Detection modules
4. Add tests for Phase 3 modules (Advanced Code Analysis)
5. Complete Formatting and Best Practices modules
6. Add Advanced Fix modules tests
7. Test Integration modules
8. Update CI configuration for coverage enforcement
9. Generate coverage reports
10. Document any intentionally untested areas

### Security Detection Modules
**Test Cases:**
- ✅ Detect known secret patterns (API keys, tokens, passwords)
- ✅ Calculate entropy correctly for various inputs
- ✅ Handle edge cases (empty strings, unicode, very long strings)
- ✅ Validate confidence scoring (0.0 to 1.0)
- ✅ Test with real-world-like secret patterns
- ✅ Ensure no false positives on common code patterns

**Mocking Strategy:**
- Mock file I/O operations
- Use TestDrive for test files
- Mock external API calls

### Code Analysis Modules
**Test Cases:**
- ✅ Parse AST correctly for various PowerShell constructs
- ✅ Detect dead code, unreachable code, unused variables
- ✅ Calculate complexity metrics (cyclomatic, nesting depth)
- ✅ Handle malformed/unparseable scripts gracefully
- ✅ Test with real-world script examples

**Mocking Strategy:**
- Use Parser API directly with test content
- Mock Write-* cmdlets for output
- Validate AST transformations preserve semantics

### Formatting Modules
**Test Cases:**
- ✅ Fix specific formatting issues correctly
- ✅ Preserve code semantics
- ✅ Handle edge cases (comments, strings, here-strings)
- ✅ Idempotency (running twice produces same result)
- ✅ Table-driven tests with TestCases

**Mocking Strategy:**
- Direct string manipulation tests
- Compare before/after AST structures
- Validate with PSScriptAnalyzer

### AI/ML Integration Modules
**Test Cases:**
- ✅ Calculate confidence scores within valid range
- ✅ Handle missing/invalid inputs gracefully
- ✅ Test scoring algorithms with known inputs
- ✅ Validate metric collection

**Mocking Strategy:**
- Mock external API calls (if any)
- Use deterministic test data
- No real network calls

## Test Data Strategy

### Builders (tests/Helpers/)
- **TestHelpers.psm1** - General utilities (✅ DONE)
- **MockBuilders.psm1** - Mock object builders
- **TestData.psm1** - Sample scripts and test data

### Test Cases Approach
- Table-driven tests with `-TestCases`
- Parameterized inputs for boundary testing
- Golden/snapshot files for complex outputs
- Property-based testing for invariants (seeded generators)

## Coverage Strategy

### Line Coverage (Target: ≥90%)
- All exported functions
- Critical error paths
- Parameter validation

### Branch Coverage (Target: ≥85%)
- If/else branches
- Switch statements
- Early returns
- Error handlers

### Excluded from Coverage
- Vendor code/external dependencies
- Diagnostic/debug-only functions
- Deprecated functions marked for removal

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Pester Tests
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
      - name: Install Dependencies
        run: |
          Install-Module Pester -MinimumVersion 5.5.0 -Force
          Install-Module PSScriptAnalyzer -Force
      - name: Run Tests
        run: |
          Invoke-Pester -Path ./tests -Configuration @{
            Run = @{ PassThru = $true }
            CodeCoverage = @{
              Enabled = $true
              OutputFormat = 'JaCoCo'
              OutputPath = 'coverage.xml'
            }
            TestResult = @{
              Enabled = $true
              OutputFormat = 'NUnitXml'
              OutputPath = 'testresults.xml'
            }
          }
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

### Quality Gates
1. All tests must pass
2. No PSScriptAnalyzer warnings
3. Coverage thresholds met
4. No test duration > 500ms

## Test Maintenance

### Naming Conventions
- Files: `<ModuleName>.Tests.ps1`
- Describes: `<FunctionName>` or `<ModuleName> - <Feature>`
- Contexts: `When <condition>` or `<specific scenario>`
- Its: `Should <expected behavior>` or `<Unit> <Scenario> => <Expected>`

### Documentation
- Top-level comment block explaining test purpose
- Complex test cases with inline comments
- Link to related issues/PRs for context

### Anti-Patterns to Avoid
- ❌ Real filesystem operations (use TestDrive)
- ❌ Real network calls (mock Invoke-RestMethod)
- ❌ Real time/sleep (mock Get-Date, ban Start-Sleep)
- ❌ Tests depending on execution order
- ❌ Mocking at wrong scope (mock at call site)
- ❌ Multiple unrelated assertions in one It

## Implementation Progress

### Current Metrics (Updated: October 16, 2025)
- **Total Modules**: 48
- **Modules Tested**: 9 (18.75%)
- **Test Files**: 12 (including helpers)
- **Total Tests**: 203
- **Pass Rate**: 100%
- **Average Test Duration**: ~20ms per test
- **Total Suite Duration**: ~4 seconds

### Completed Modules (9 of 48)
1. ✅ **PoshGuard.psm1** - Main module entry point (24 tests)
2. ✅ **Core.psm1** - File operations, logging, backups (47 tests)
3. ✅ **ConfigurationManager.psm1** - Configuration management (12 tests)
4. ✅ **Security.psm1** - Security fix functions (29 tests)
5. ✅ **EntropySecretDetection.psm1** - Entropy-based secret detection (32 tests)
6. ✅ **Formatting/Aliases.psm1** - Alias formatting (16 tests)
7. ✅ **Formatting/Whitespace.psm1** - Whitespace fixes (20 tests)
8. ✅ **BestPractices/Naming.psm1** - Naming conventions (5 tests)
9. ✅ **BestPractices/Syntax.psm1** - Syntax fixes (18 tests)

### Target Metrics
- **Modules Tested**: 48 (100%)
- **Total Tests**: ~1500-2000 (estimated)
- **Line Coverage**: ≥90%
- **Branch Coverage**: ≥85%
- **Max Test Duration**: <500ms

## Next Steps
1. Create test files for Phase 2 modules (Security Detection)
2. Implement tests for Phase 3 modules (Advanced Code Analysis)
3. Complete Formatting and Best Practices modules
4. Add Advanced Fix modules tests
5. Test Integration modules
6. Update CI configuration
7. Generate coverage reports
8. Document any intentionally untested areas

## References
- [Pester Documentation](https://pester.dev/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [PowerShell Testing Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)
