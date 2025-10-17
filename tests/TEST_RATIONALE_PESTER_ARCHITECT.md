# Test Rationale & Design Decisions

## Purpose
This document explains the testing philosophy, trade-offs, and intentional design decisions for the PoshGuard test suite following Pester Architect standards.

## Core Testing Philosophy

### 1. Test the Contract, Not the Implementation
✅ **DO**: Test public function behavior and outputs
❌ **DON'T**: Test internal implementation details

**Rationale**: Public contracts are stable; implementations may change during refactoring. Tests should enable refactoring, not hinder it.

**Example**:
```powershell
# ✅ Good: Tests public behavior
It 'Invoke-PlainTextPasswordFix converts string passwords to SecureString' {
  $input = 'param([string]$Password)'
  $result = Invoke-PlainTextPasswordFix -Content $input
  $result | Should -Match '\[SecureString\]\$Password'
}

# ❌ Avoid: Testing internal parsing logic
It 'uses specific AST traversal strategy' {
  # This couples tests to implementation
}
```

### 2. Determinism Over Coverage Percentage
Achieving 100% coverage is meaningless if tests are flaky or non-deterministic.

**Trade-offs**:
- ✅ Prioritize stable, repeatable tests
- ✅ Accept slightly lower coverage for hermetic tests
- ❌ Reject random sleeps or time-dependent assertions

**Example**:
```powershell
# ✅ Deterministic time testing
Mock Get-Date { [DateTime]'2025-01-01 12:00:00' }
Clean-Backups  # Will use mocked time

# ❌ Non-deterministic (flaky)
Start-Sleep -Seconds 5
Get-OldFiles | Should -HaveCount 0  # Race condition!
```

### 3. AAA Pattern for Clarity
All tests follow Arrange-Act-Assert for readability and maintainability.

**Benefits**:
- Clear setup vs. execution vs. validation
- Easy to understand failure points
- Consistent across all test files

### 4. Table-Driven Tests for Input Matrices
Use `-TestCases` to eliminate duplication and make test intent explicit.

**Before** (repetitive):
```powershell
It 'handles Password' { ... }
It 'handles Pwd' { ... }
It 'handles Pass' { ... }
It 'handles Secret' { ... }
```

**After** (concise):
```powershell
It 'converts <ParameterName> to SecureString' -TestCases @(
  @{ ParameterName = 'Password' }
  @{ ParameterName = 'Pwd' }
  @{ ParameterName = 'Pass' }
  @{ ParameterName = 'Secret' }
) {
  param($ParameterName)
  # Test logic
}
```

## Mocking Strategy

### When to Mock
1. **External I/O**: Filesystem, network, registry
2. **Time**: `Get-Date`, `Start-Sleep`
3. **Random**: Any RNG sources
4. **System State**: Environment variables, processes
5. **Expensive Operations**: Long-running computations

### When NOT to Mock
1. **Pure Functions**: Functions without side effects
2. **PowerShell Built-ins**: Core cmdlets like `Where-Object`, `ForEach-Object`
3. **String Manipulation**: `Join-Path`, `-split`, `-replace`

### Mocking Patterns

#### Pattern 1: InModuleScope for Internal Calls
```powershell
It 'calls Invoke-RestMethod with correct headers' {
  InModuleScope AIIntegration {
    Mock Invoke-RestMethod -ParameterFilter {
      $Headers['Authorization'] -eq 'Bearer token123'
    } -MockWith {
      [pscustomobject]@{ status = 'ok' }
    }
    
    Get-AIAnalysis -Token 'token123'
    
    Assert-MockCalled Invoke-RestMethod -Exactly -Times 1
  }
}
```

#### Pattern 2: TestDrive for Filesystem
```powershell
It 'creates backup with timestamp' {
  $testFile = Join-Path TestDrive: 'script.ps1'
  'test content' | Set-Content $testFile
  
  $backupPath = New-FileBackup -FilePath $testFile
  
  $backupPath | Should -Exist
  $backupPath | Should -Match '\.bak$'
}
```

#### Pattern 3: Parameter Filters for Precision
```powershell
Mock Remove-Item -ParameterFilter {
  $Path -like '*.tmp' -and $Force -eq $true
}
```

## Coverage Decisions

### Intentionally Lower Coverage Areas

1. **Error Formatting Code** (~70% coverage acceptable)
   - Rationale: Complex string formatting logic with diminishing returns
   - Mitigation: Critical error paths are tested

2. **Logging/Diagnostic Output** (~75% coverage acceptable)
   - Rationale: Console output formatting is low-risk
   - Mitigation: Core logging logic is fully tested

3. **Legacy Compatibility Shims** (~80% coverage acceptable)
   - Rationale: Will be deprecated in future versions
   - Mitigation: Modern code paths have 90%+ coverage

### High Coverage Requirements (90%+)

1. **Security Modules**: Any module handling passwords, secrets, or auth
2. **Core.psm1**: Foundation for all other modules
3. **AST Transformations**: Code modifications must be verified
4. **Error Detection**: False negatives are critical failures

## Edge Case Testing Strategy

### Priority 1: Security-Critical Inputs
- Empty/null credentials
- Unicode in passwords
- SQL injection patterns
- Path traversal attempts
- Code injection vectors

### Priority 2: Boundary Conditions
- Empty strings vs. whitespace vs. null
- Single-character inputs
- Maximum-length inputs
- Special characters (`$`, `` ` ``, `"`, `'`)

### Priority 3: Type Coercion
- String vs. SecureString
- Array vs. single value
- PSCustomObject vs. Hashtable

### Priority 4: Filesystem Edge Cases
- Paths with spaces
- UNC paths
- Relative vs. absolute paths
- Non-existent paths
- Permission errors (mocked)

## Performance Testing Approach

### Micro-Benchmarks (Discouraged)
We avoid micro-benchmarks in unit tests because:
- Non-deterministic on CI
- Vary by platform (Windows vs. Linux)
- Maintenance burden

### Performance Regression Guards (Encouraged)
```powershell
It 'completes within reasonable time' {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Invoke-LargeCodebaseAnalysis
  $sw.Stop()
  
  # Generous threshold to avoid flakiness
  $sw.ElapsedMilliseconds | Should -BeLessThan 5000
}
```

**Threshold Selection**:
- 10x slower than typical execution
- Catches catastrophic regressions (O(n²) → O(n³))
- Tolerates CI variability

## ShouldProcess Testing Rationale

All state-changing functions implement `-WhatIf` and `-Confirm` per PowerShell best practices.

**Test Strategy**:
1. Verify `-WhatIf` prevents actual changes
2. Verify side-effect cmdlets are not called
3. Verify return values are still correct

**Example**:
```powershell
It 'respects -WhatIf and does not delete files' {
  InModuleScope Core {
    Mock Remove-Item -Verifiable
    
    Clean-Backups -WhatIf
    
    Assert-MockCalled Remove-Item -Times 0
  }
}
```

## Error Path Testing Philosophy

### Error Categories

1. **User Input Errors** (non-exceptional)
   - Invalid file paths
   - Malformed content
   - Missing required parameters
   → Return error objects, don't throw

2. **System Errors** (exceptional)
   - Disk full
   - Permission denied
   - Network timeout
   → Throw with `$ErrorActionPreference = 'Stop'`

3. **Programming Errors** (bugs)
   - Null reference
   - Index out of range
   → Should never occur; tests prevent regression

### Test Coverage Priorities
1. ✅ **Must Test**: User input errors (highest frequency)
2. ✅ **Should Test**: System errors (for robustness)
3. ⚠️ **Optional**: Programming errors (should be impossible)

## Platform-Specific Testing

### Cross-Platform Compatibility
All tests run on Windows/macOS/Linux via CI.

**Path Handling**:
```powershell
# ✅ Portable
Join-Path TestDrive: 'subdir' 'file.ps1'

# ❌ Windows-only
"TestDrive:\subdir\file.ps1"
```

**Line Endings**:
Use `-split '\r?\n'` for cross-platform line splitting.

**Cmdlet Availability**:
Some cmdlets are Windows-only (e.g., `Get-WmiObject`). Tests for these skip on non-Windows:
```powershell
BeforeAll {
  if (-not $IsWindows) {
    Set-ItResult -Skipped -Because 'Windows-only cmdlet'
  }
}
```

## Test Data Management

### Fixture Strategy
1. **Inline**: Small, simple test data directly in test
2. **Builders**: Helper functions for complex objects
3. **Files**: Reserved for large, realistic samples (avoided when possible)

**Example Builder**:
```powershell
function New-TestFunction {
  param([switch]$WithSecurity, [switch]$WithFormatting)
  
  $base = 'function Test-Function { param() }'
  if ($WithSecurity) {
    $base = $base -replace 'param\(\)', 'param([string]$Password)'
  }
  return $base
}
```

### Snapshot/Golden Testing (Limited Use)
We avoid golden file testing because:
- Hard to maintain
- Sensitive to formatting changes
- Unclear failure messages

**Exception**: Complex AST transformations where full output validation is critical.

## Intentionally Uncovered Code

### 1. Module Initialization
Module-level code in `.psm1` that runs on import is not directly tested.

**Rationale**: Tested indirectly through function usage.

### 2. Deprecation Warnings
Code that emits deprecation warnings for old APIs.

**Rationale**: Low risk; will be removed in future versions.

### 3. Debug Logging
Verbose/Debug stream output formatting.

**Rationale**: Cosmetic; doesn't affect functionality.

### 4. Example/Sample Code
Code in `samples/` directory used for demonstration.

**Rationale**: Not part of production module.

## Test Maintenance Guidelines

### Updating Tests for New Features
1. Add tests **before** implementing feature (TDD-lite)
2. Use `-Tag 'NewFeature'` for work-in-progress
3. Ensure coverage target met before merging

### Refactoring Tests
1. Extract common setup to `BeforeEach`/`BeforeAll`
2. Convert repetitive tests to table-driven
3. Keep one assertion per `It` when possible

### Handling Flaky Tests
1. **Investigate**: Identify source of non-determinism
2. **Fix**: Mock time/IO, seed random, add retry logic
3. **Last Resort**: Mark with `-Skip` and file issue

## Lessons Learned

### Success Stories
1. **Table-Driven Tests**: Reduced test count by 60% while improving coverage
2. **InModuleScope Mocking**: Enabled testing of complex internal interactions
3. **TestDrive**: Eliminated filesystem pollution and race conditions

### Pitfalls Avoided
1. **Over-Mocking**: Initially mocked too much; now mock only external I/O
2. **Brittle Assertions**: Switched from exact string matching to regex patterns
3. **Test Duplication**: Consolidated similar tests with `-TestCases`

## Future Improvements

### Planned Enhancements
1. **Mutation Testing**: Validate test effectiveness by injecting bugs
2. **Property-Based Testing**: Generate random (but seeded) inputs
3. **Contract Testing**: Ensure API stability across versions
4. **Performance Profiling**: Track test execution time trends

### Under Consideration
1. **Integration Test Suite**: End-to-end workflows (separate from unit tests)
2. **Chaos Engineering**: Inject failures to test resilience
3. **Test Data Anonymization**: Use real codebases with PII removed

## Conclusion

The PoshGuard test suite prioritizes:
1. **Stability** over coverage percentages
2. **Clarity** over cleverness
3. **Maintainability** over brevity
4. **Real-world scenarios** over theoretical edge cases

These principles enable confident refactoring, rapid feature development, and long-term maintainability.

---

**Document Version:** 2.0
**Last Updated:** 2025-10-17
**Authors:** PoshGuard Team
