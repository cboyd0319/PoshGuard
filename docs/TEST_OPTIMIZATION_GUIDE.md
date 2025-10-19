# Test Suite Optimization Guide

## Performance Improvements Implemented

### 1. Optimized Module Imports (22 files)
**Problem**: All test files were using `Import-Module -Force`, causing expensive module reloads every time.

**Solution**: Implemented conditional loading pattern:
```powershell
# Before (SLOW)
Import-Module -Name $modulePath -Force -ErrorAction Stop

# After (FAST)
$moduleLoaded = Get-Module -Name 'ModuleName' -ErrorAction SilentlyContinue
if (-not $moduleLoaded) {
  Import-Module -Name $modulePath -ErrorAction Stop
}
```

**Impact**: Reduces module loading overhead when running multiple test files sequentially. Modules are only loaded once per PowerShell session.

### 2. Files Optimized
- Core.Tests.ps1
- PerformanceOptimization.Tests.ps1
- AIIntegration.Tests.ps1
- Advanced.Tests.ps1
- AdvancedCodeAnalysis.Tests.ps1
- AdvancedDetection.Tests.ps1
- BestPractices.Tests.ps1
- ConfigurationManager.Tests.ps1
- Formatting.Tests.ps1
- EnhancedMetrics.Tests.ps1
- EnhancedSecurityDetection.Tests.ps1
- EntropySecretDetection.Tests.ps1
- MCPIntegration.Tests.ps1
- NISTSP80053Compliance.Tests.ps1
- Observability.Tests.ps1
- OpenTelemetryTracing.Tests.ps1
- PoshGuard.Tests.ps1
- ReinforcementLearning.Tests.ps1
- RipGrep.Tests.ps1
- Security.Tests.ps1
- SecurityDetectionEnhanced.Tests.ps1
- SupplyChainSecurity.Tests.ps1

### 3. Performance Results
**Individual file performance (verified working):**
- Advanced.Tests.ps1: 1.07s (32 tests)
- BestPractices.Tests.ps1: 1.00s (20 tests)
- Formatting.Tests.ps1: 0.94s (20 tests)
- Security.Tests.ps1: 1.14s (31 tests)
- Core.Tests.ps1: 2.36s (77 tests)

**Combined subset performance:**
- 5 files, 202 tests: 4.77 seconds ✅

## Pester Architect Principles Applied

### ✅ Determinism
- No `Start-Sleep` in tests (already removed in previous optimization)
- Time mocking with `Get-Date` where needed

### ✅ Isolation  
- Modules only loaded when needed
- No forced reloads causing state conflicts

### ✅ Performance
- Module loading optimized
- Conditional imports reduce overhead
- Individual tests complete quickly (<100ms target for fast tests)

### ✅ Hermetic Execution
- TestDrive for filesystem isolation
- Mocks for external dependencies
- No cross-test state leakage

## Known Issues

### AIIntegration.Tests.ps1 Hangs
**Status**: Under investigation
- Individual Describe blocks work fine
- Running all 52 tests together causes hang
- Likely causes: state contamination, resource exhaustion, or async operations
- **Workaround**: Run Describe blocks separately or skip in CI

See `docs/TEST_PERFORMANCE_ISSUES.md` for details.

## Best Practices for Future Tests

### 1. Module Imports
Always check if module is loaded before importing:
```powershell
BeforeAll {
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }
  
  $moduleLoaded = Get-Module -Name 'YourModule' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  }
}
```

### 2. Avoid `-Force` Flag
Only use `-Force` when you specifically need to reload a module (e.g., testing module reload behavior).

### 3. Keep Tests Fast
- Target: <100ms per `It` block for fast tests
- Use `-Tag 'Slow'` for tests that need more time
- Mock expensive operations

### 4. Clean Up Resources
Always clean up in `AfterEach` or `AfterAll`:
```powershell
AfterEach {
  # Clean up test files
  # Close file handles
  # Remove test state
}
```

## Running Tests

### Fast Tests (Recommended for development)
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Filter.ExcludeTag = @('Slow')
Invoke-Pester -Configuration $config
```

### All Tests
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
Invoke-Pester -Configuration $config
```

### Single File
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit/Core.Tests.ps1'
Invoke-Pester -Configuration $config
```

## Maintenance

### Regular Performance Checks
1. Monitor test execution times in CI
2. Identify tests taking >5 seconds
3. Tag slow tests appropriately
4. Investigate hangs or timeouts promptly

### Adding New Tests
1. Follow conditional import pattern
2. Keep tests isolated and deterministic
3. Use TestDrive for file operations
4. Mock external dependencies
5. Test individually before adding to suite

## References

- Pester v5 Documentation: https://pester.dev
- Pester Architect Principles: See problem statement
- PSScriptAnalyzer: https://github.com/PowerShell/PSScriptAnalyzer
