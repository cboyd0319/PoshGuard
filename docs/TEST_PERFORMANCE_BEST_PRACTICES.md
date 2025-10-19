# Test Performance Best Practices

## Overview
This document outlines best practices for writing fast, deterministic Pester tests following the Pester Architect principles.

## Anti-Patterns to Avoid

### 1. Real Sleep Calls ❌
**Bad:**
```powershell
It 'Creates unique backups' {
    $backup1 = New-FileBackup -FilePath $file
    Start-Sleep -Seconds 2  # SLOW! Non-deterministic!
    $backup2 = New-FileBackup -FilePath $file
    $backup1 | Should -Not -Be $backup2
}
```

**Good:**
```powershell
It 'Creates unique backups' {
    $call = 0
    Mock Get-Date {
        param($Format)
        $script:call++
        $baseTime = [DateTime]::Parse('2025-01-01 12:00:00').AddSeconds($script:call - 1)
        return $baseTime.ToString($Format)
    } -ModuleName Core -ParameterFilter { $Format -eq 'yyyyMMddHHmmss' }
    
    $backup1 = New-FileBackup -FilePath $file -Confirm:$false
    $backup2 = New-FileBackup -FilePath $file -Confirm:$false
    
    $backup1 | Should -Not -Be $backup2
}
```

### 2. Redundant Module Imports ❌
**Bad:**
```powershell
BeforeAll {
    Import-Module './Module.psm1' -Force  # Forces reload every time!
}
```

**Good:**
```powershell
BeforeAll {
    $module = Get-Module -Name 'Module' -ErrorAction SilentlyContinue
    if (-not $module) {
        Import-Module './Module.psm1' -ErrorAction Stop
    }
}
```

**Even Better (for submodules):**
```powershell
# In the facade module
foreach ($SubModule in $SubModules) {
    $loadedModule = Get-Module -Name $SubModule -ErrorAction SilentlyContinue
    if (-not $loadedModule) {
        Import-Module -Name $SubModulePath -ErrorAction Stop
    }
}
```

## Mocking Time-Dependent Functions

### Get-Date Mocking
When functions use `Get-Date` for timestamps:

```powershell
# For formatted dates
Mock Get-Date {
    param($Format)
    return '20250101120000'
} -ModuleName YourModule -ParameterFilter { $Format -eq 'yyyyMMddHHmmss' }

# For DateTime objects
Mock Get-Date {
    return [DateTime]::Parse('2025-01-01 12:00:00')
} -ModuleName YourModule

# For progressive time (simulating passage of time)
$call = 0
Mock Get-Date {
    $script:call++
    return [DateTime]::Parse('2025-01-01 12:00:00').AddSeconds($script:call - 1)
} -ModuleName YourModule
```

### Session Duration Testing
```powershell
It 'Should track session duration' {
    InModuleScope EnhancedMetrics {
        $startTime = [DateTime]::Parse('2025-01-01 12:00:00')
        $endTime = [DateTime]::Parse('2025-01-01 12:01:45')
        
        Mock Get-Date { return $startTime }
        Initialize-MetricsTracking
        
        Mock Get-Date { return $endTime }
        $summary = Get-MetricsSummary
        
        $summary.SessionDuration.TotalSeconds | Should -BeGreaterThan 100
    }
}
```

## Performance Targets

### Test Execution Time
- Individual `It` blocks: **< 100ms** (target), **< 500ms** (maximum)
- Test file: **< 30 seconds** for unit tests
- Full test suite: **< 2 minutes** (target for 1644 tests)

### Optimization Techniques
1. **Mock external dependencies** - No real network, filesystem (outside TestDrive), or system calls
2. **Use TestDrive** - For all file operations
3. **Avoid loops in tests** - Use `-TestCases` for parameterized tests
4. **Mock expensive operations** - AST parsing, file I/O, process spawning
5. **Check module load state** - Don't force-reload unnecessarily

## Module Loading Strategy

### Current Optimizations
1. **Advanced.psm1** now checks if submodules are already loaded before importing
2. Tests still use `-Force` in `BeforeAll` for isolation (Pester requirement)
3. Submodules are only imported once per test run, not per test file

### Measured Improvements
- Removed 2.1 seconds of `Start-Sleep` calls (2s in Core.Tests, 100ms in EnhancedMetrics.Tests)
- Reduced redundant submodule imports in Advanced.psm1 from 122 forced imports to conditional loading

## Static Analysis for Tests

Use the provided `.psscriptanalyzer.tests.psd1` configuration to lint test files:

```powershell
Invoke-ScriptAnalyzer -Path ./tests -Settings ./.psscriptanalyzer.tests.psd1 -Recurse
```

This configuration enforces:
- No `Start-Sleep` usage (via manual review)
- Consistent indentation (2 spaces)
- Proper whitespace
- No `Write-Host` (use test output mechanisms)

## Troubleshooting Slow Tests

### Finding Slow Tests
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $config

# Review the output for tests taking > 500ms
```

### Common Causes
1. **Parallel processing tests** - Mock runspaces instead of creating real ones
2. **Large AST parsing** - Use smaller test code samples
3. **File I/O outside TestDrive** - Ensure all file ops use TestDrive
4. **Unmocked external calls** - Verify all external dependencies are mocked
5. **Interactive prompts** - Ensure mandatory parameters have default values in test code

## Future Improvements
- [ ] Implement custom PSScriptAnalyzer rule to detect `Start-Sleep` in test files
- [ ] Add parallel test execution support in CI
- [ ] Create test performance profiler script
- [ ] Add test categorization (Fast/Slow/Integration) with appropriate timeouts
