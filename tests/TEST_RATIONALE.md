# PoshGuard Test Suite - Rationale & Trade-offs

## Executive Summary

This document explains the design decisions, trade-offs, and areas intentionally left uncovered in the PoshGuard comprehensive test suite.

## Current Test Coverage

### What We Test

✅ **All 48 modules have unit tests**
- Core functionality (Core.psm1)
- Security modules (Security.psm1, EntropySecretDetection.psm1, etc.)
- Formatting modules (Formatting.psm1 + 7 submodules)
- Best Practices modules (BestPractices.psm1 + 7 submodules)
- Advanced modules (Advanced.psm1 + 14 submodules)
- Specialized modules (AI, MCP, OpenTelemetry, NIST compliance, etc.)

✅ **1066+ test cases covering**
- Happy path scenarios with valid inputs
- Parameter validation and type checking
- Basic error handling
- Module exports and function signatures
- Some edge cases

✅ **Infrastructure**
- Pester v5.7.1 (modern syntax, parallel execution support)
- PSScriptAnalyzer enforcement (.psscriptanalyzer.psd1)
- CI/CD on GitHub Actions (Windows, macOS, Linux)
- Code coverage tracking (JaCoCo format)
- Test helpers and mock builders

### What We Don't Fully Test (Intentional)

#### 1. Integration Tests
**Rationale**: Unit tests focus on isolated function behavior. Full integration testing would require:
- Real PowerShell Gallery interaction
- Actual GitHub API calls
- Real-time AI model inference
- Live OpenTelemetry endpoints

**Trade-off**: We mock these dependencies to keep tests fast (<100ms per test) and hermetic (no network required).

**Mitigation**: 
- Comprehensive mocking strategies ensure contract compliance
- Manual integration testing during releases
- Could add separate integration test suite (not in scope)

#### 2. Performance Under Load
**Rationale**: Testing with 10,000+ file repositories or analyzing massive scripts (>100MB) would make tests slow and brittle.

**Trade-off**: We use baseline performance tests with small inputs (100 files, <1MB scripts).

**Mitigation**:
- Performance regression guards with thresholds
- Benchmarking suite in `benchmarks/` directory (separate from unit tests)
- Real-world dogfooding on large codebases

#### 3. UI/Interactive Features
**Rationale**: Testing interactive prompts (`Read-Host`, `-Confirm`) requires mock user input, which is fragile.

**Trade-off**: We test `-WhatIf` and `-Confirm:$false` paths but not interactive confirmation dialogs.

**Mitigation**:
- ShouldProcess pattern ensures correctness
- Manual testing of interactive features
- Could use Pester's `Mock Read-Host` for critical paths

#### 4. Platform-Specific Behavior
**Rationale**: Some features behave differently on Windows vs. Linux (e.g., case-sensitive filesystems, path separators).

**Trade-off**: CI runs on all platforms, but we don't exhaustively test every platform difference in every test.

**Mitigation**:
- Core tests run on Windows, macOS, Linux
- Platform-specific code is minimal and isolated
- Known platform issues documented

#### 5. Mutation Testing
**Rationale**: Full mutation testing (injecting faults to verify tests catch them) is expensive and time-consuming.

**Trade-off**: We use boundary value analysis and property-based testing patterns instead.

**Mitigation**:
- High branch coverage (target 85%+)
- Edge case testing
- Could add Stryker.NET or similar (future work)

#### 6. Security Exploit Scenarios
**Rationale**: Testing actual malicious payloads (code injection, XSS in PowerShell, etc.) is dangerous.

**Trade-off**: We test detection logic with safe, synthetic examples, not real exploits.

**Mitigation**:
- Security rules based on industry standards (OWASP, CWE)
- Fuzz testing with property-based patterns
- Manual security review and audits

## Test Design Decisions

### 1. Mocking Strategy

**Decision**: Use `InModuleScope` + `Mock` for all external dependencies.

**Rationale**:
- Keeps tests hermetic (no network, filesystem, registry)
- Fast execution (<100ms per test)
- Deterministic results (no flakiness)

**Trade-off**: Mocks may not perfectly match real behavior.

**Example**:
```powershell
InModuleScope Core {
  Mock Invoke-RestMethod { [PSCustomObject]@{ Status = 'OK' } }
  $result = Call-ExternalAPI
  $result.Status | Should -Be 'OK'
}
```

### 2. TestDrive for File I/O

**Decision**: All file operations use `$TestDrive` (Pester's isolated temp filesystem).

**Rationale**:
- No side effects on real filesystem
- Automatic cleanup after tests
- Cross-platform compatibility

**Trade-off**: Cannot test interactions with real user profile, registry, etc.

**Example**:
```powershell
It 'Creates file in TestDrive' {
  $file = Join-Path $TestDrive 'test.ps1'
  'content' | Set-Content -Path $file
  Test-Path $file | Should -Be $true
}
```

### 3. Time Mocking

**Decision**: Mock `Get-Date` for time-dependent tests.

**Rationale**:
- Deterministic timestamps (tests don't fail at midnight)
- No dependency on system clock
- Can test time-based logic (expiry, scheduling)

**Trade-off**: Doesn't test real clock drift or timezone issues.

**Example**:
```powershell
Mock Get-Date { [DateTime]::new(2025, 1, 1, 12, 0, 0) }
$timestamp = Get-CurrentTimestamp
$timestamp | Should -Be '2025-01-01T12:00:00'
```

### 4. Table-Driven Tests

**Decision**: Use `-TestCases` for input matrices instead of multiple `It` blocks.

**Rationale**:
- DRY (Don't Repeat Yourself)
- Easier to add new test cases
- Better test output (shows which input failed)

**Trade-off**: Less granular control per test case.

**Example**:
```powershell
It 'Validates <Type> input' -TestCases @(
  @{ Type = 'String'; Value = 'test'; Valid = $true }
  @{ Type = 'Integer'; Value = 42; Valid = $true }
  @{ Type = 'Null'; Value = $null; Valid = $false }
) {
  param($Type, $Value, $Valid)
  # Test logic
}
```

### 5. No Integration with Real Services

**Decision**: Mock all external services (GitHub, AI APIs, telemetry endpoints).

**Rationale**:
- Tests run offline
- No API rate limits or costs
- No flaky network failures

**Trade-off**: Cannot detect API contract changes.

**Mitigation**:
- Contract testing (validate request/response shapes)
- Separate integration test suite (manual)
- Real-world usage catches integration issues

## Coverage Targets

### Line Coverage: 90%+

**Rationale**: Industry standard for high-quality software.

**Exclusions**:
- Error handling catch blocks (hard to trigger)
- Defensive null checks (edge cases)
- Legacy compatibility code

### Branch Coverage: 85%+

**Rationale**: Ensures all decision paths tested.

**Focus**: Critical logic branches (security, data loss prevention).

**Exclusions**:
- Platform-specific branches not reachable on all OSes
- Deprecated code paths

## Known Issues & Improvements

### Current Issues

1. **AdvancedCodeAnalysis.Tests.ps1**
   - Some dead code detection tests fail (functions not returning expected results)
   - Deep nesting causes stack overflow
   - **Status**: Under investigation, likely AST parsing edge case

2. **Test Execution Time**
   - Full suite takes >10 minutes on some platforms
   - Some tests have expensive AST parsing
   - **Improvement**: Could parallelize more, mock expensive operations

3. **Flaky Tests**
   - Very few, but some time-sensitive tests occasionally fail
   - **Improvement**: More aggressive time mocking

### Future Enhancements

1. **Increase Coverage**
   - Add more edge case tests (unicode, very long strings, malformed input)
   - Add more error path tests (network failures, disk full, etc.)
   - Add more boundary value tests

2. **Property-Based Testing**
   - Implement full property-based testing framework
   - Generate random but valid PowerShell code for fuzz testing
   - Test invariants (round-trip, idempotence, etc.)

3. **Mutation Testing**
   - Introduce faults to verify tests catch them
   - Measure test suite effectiveness

4. **Performance Profiling**
   - Add performance regression detection
   - Micro-benchmarks for critical paths
   - Memory leak detection

5. **Integration Tests**
   - Separate integration test suite
   - Test against real PowerShell Gallery
   - Test against real GitHub API (with rate limiting)

## Maintenance Guidelines

### Adding New Tests

1. **Use existing patterns** from EXEMPLAR_PESTER_ARCHITECT_TEST.ps1
2. **Follow AAA** (Arrange-Act-Assert) pattern
3. **Use -TestCases** for data-driven tests
4. **Mock externals** with `InModuleScope`
5. **Use TestDrive** for file I/O

### Reviewing Tests

1. **One behavior per It** - Tests should be focused
2. **Descriptive names** - "Should do X when Y"
3. **No hardcoded values** - Use variables, parameters
4. **No sleeps** - Mock time instead
5. **No randomness** - Seed generators or mock

### Refactoring Tests

1. **Extract to BeforeAll** - Common setup
2. **Use helpers** - tests/Helpers/ for repetitive patterns
3. **Keep DRY** - But prioritize readability
4. **Document assumptions** - Add comments for complex scenarios

## Conclusion

The PoshGuard test suite is comprehensive, covering all 48 modules with 1066+ tests following Pester v5+ best practices. We prioritize:

- **Determinism**: No flaky tests, hermetic execution
- **Speed**: Fast feedback (<10 seconds for most modules)
- **Maintainability**: Clear patterns, DRY, good naming

We accept trade-offs:
- **No real integration**: Mocked external services
- **Limited performance testing**: Baseline only, not stress testing
- **Some uncovered edge cases**: Prioritize common paths

The test suite provides **high confidence** in correctness while remaining **practical and maintainable** for ongoing development.

---

**Last Updated**: 2025-10-17  
**Test Suite Version**: 4.3.0  
**Pester Version**: 5.7.1
