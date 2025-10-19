# Test Performance Guide

## Overview
This guide explains PoshGuard's test categorization system and how to write performant tests following Pester Architect principles.

## Test Categories

### Fast Tests (Default)
**Target: < 100ms per test, < 2 minutes total**

Tests that:
- Mock expensive operations (AST parsing, file I/O, network calls)
- Use deterministic data (no real time/randomness)
- Validate function contracts and simple logic
- Run in CI on every commit

**Example:**
```powershell
Describe 'Get-User' -Tag 'Unit', 'MyModule' {
  It 'Should add Authorization header' {
    InModuleScope MyModule {
      Mock Invoke-RestMethod { [PSCustomObject]@{ id = 1 } } -Verifiable
      Get-User -Token 'test' -Id 1 | Should -Not -BeNullOrEmpty
      Assert-MockCalled Invoke-RestMethod -Exactly -Times 1
    }
  }
}
```

### Slow Tests
**Target: < 5 seconds per test**

Tests tagged with `-Tag 'Slow'` that perform:
- Deep AST analysis and recursion
- Complex dependency scanning
- SBOM generation
- Vulnerability analysis
- Real file system operations (when mocking isn't feasible)

**Example:**
```powershell
Describe 'Find-CodeSmells' -Tag 'Unit', 'MyModule', 'Slow' {
  It 'Should detect deeply nested control structures' -Tag 'Slow' {
    # This test does real AST parsing which is inherently slow
    $result = Find-CodeSmells -Content $complexCode -FilePath 'test.ps1'
    $result | Should -Not -BeNullOrEmpty
  }
}
```

## Running Tests

### Run Fast Tests Only (Default for Development)
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Filter.ExcludeTag = @('Slow')
Invoke-Pester -Configuration $config
```

### Run Slow Tests Only
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Filter.Tag = @('Slow')
Invoke-Pester -Configuration $config
```

### Run All Tests (Comprehensive)
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
Invoke-Pester -Configuration $config
```

### Run Specific Test File
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit/MyModule.Tests.ps1'
Invoke-Pester -Configuration $config
```

## CI/CD Integration

The CI pipeline runs tests in two stages:

1. **Fast Tests** (runs first, fails fast)
   - Excludes `-Tag 'Slow'`
   - Runs on all platforms (Windows, macOS, Linux)
   - Includes code coverage on Linux
   - Target: < 2 minutes

2. **Slow Tests** (runs after fast tests pass)
   - Includes only `-Tag 'Slow'`
   - Runs on all platforms
   - Target: < 5 minutes

## Performance Anti-Patterns (AVOID)

### ❌ Real Sleep Calls
```powershell
# BAD
It 'Should create unique backups' {
  New-Backup -Path 'file1.ps1'
  Start-Sleep -Seconds 2  # SLOW!
  New-Backup -Path 'file1.ps1'
}

# GOOD
It 'Should create unique backups' {
  InModuleScope Core {
    Mock Get-Date {
      param($Format)
      $script:call++
      [DateTime]::Parse('2025-01-01').AddSeconds($script:call).ToString($Format)
    }
    New-Backup -Path 'file1.ps1'
    New-Backup -Path 'file1.ps1'
  }
}
```

### ❌ Interactive Prompts
```powershell
# BAD - Causes test hang
It 'Should require parameter' {
  { Get-Something } | Should -Throw  # Prompts for mandatory param!
}

# GOOD
It 'Should require parameter' {
  $threw = $false
  try {
    Get-Something -RequiredParam $null -ErrorAction Stop
  } catch {
    $threw = $true
  }
  $threw | Should -Be $true
}
```

### ❌ Excessive Warnings/Output
```powershell
# BAD - Spams hundreds of warnings
It 'Should handle deep recursion' {
  $result = Get-DeepAST -Content $veryDeepCode
  # Generates 500+ warnings that slow output processing
}

# GOOD
It 'Should handle deep recursion' -Tag 'Slow' {
  $result = Get-DeepAST -Content $veryDeepCode -WarningAction SilentlyContinue
  $result | Should -Not -BeNullOrEmpty
}
```

### ❌ Real File System Operations
```powershell
# BAD
It 'Should create backup file' {
  $path = "$env:TEMP/test.ps1"
  'content' | Set-Content -Path $path
  New-Backup -Path $path
  Test-Path "$env:TEMP/.backup/test.ps1" | Should -Be $true
}

# GOOD
It 'Should create backup file' {
  $path = Join-Path $TestDrive 'test.ps1'
  'content' | Set-Content -Path $path
  New-Backup -Path $path
  Test-Path (Join-Path $TestDrive '.backup/test.ps1') | Should -Be $true
}
```

## When to Tag a Test as Slow

Tag a test (or entire `Describe` block) as `Slow` if:

1. **It takes > 100ms** consistently
2. **It performs AST parsing** on complex code
3. **It does real I/O** that can't be mocked (rare)
4. **It makes external calls** (even if mocked, if setup is expensive)
5. **It generates large datasets** for property-based testing

## Optimizing Slow Tests

If you must write a slow test, optimize it:

1. **Reduce input size**: Use minimal but representative test data
2. **Mock expensive operations**: Mock AST parsing, file I/O, network calls
3. **Share setup**: Use `BeforeAll` instead of `BeforeEach`
4. **Suppress unnecessary output**: Use `-WarningAction SilentlyContinue`
5. **Consider parallelization**: Tag for parallel execution if tests are independent

## Test Performance Targets

| Category | Per Test | Per File | Full Suite |
|----------|----------|----------|------------|
| Fast     | < 100ms  | < 5s     | < 2 min    |
| Slow     | < 5s     | < 30s    | < 5 min    |

## Monitoring Performance

Check test performance with:

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

$result = Invoke-Pester -Configuration $config

# View slow tests
$result.Tests | 
  Where-Object { $_.Duration.TotalMilliseconds -gt 100 } |
  Sort-Object -Property { $_.Duration.TotalMilliseconds } -Descending |
  Select-Object -First 10 Name, @{N='Duration(ms)';E={$_.Duration.TotalMilliseconds}}
```

## Examples

### Good Fast Test
```powershell
Describe 'Write-Log' -Tag 'Unit', 'Core' {
  Context 'When logging at different severity levels' {
    It 'Should format message at <Level> level' -TestCases @(
      @{ Level = 'Info'; ExpectedPattern = '\[INFO\]' }
      @{ Level = 'Warn'; ExpectedPattern = '\[WARN\]' }
      @{ Level = 'Error'; ExpectedPattern = '\[ERROR\]' }
    ) {
      param($Level, $ExpectedPattern)
      
      $output = Write-Log -Level $Level -Message "Test" -NoTimestamp 6>&1 | Out-String
      $output | Should -Match $ExpectedPattern
    }
  }
}
# This test runs in ~5ms per case
```

### Acceptable Slow Test
```powershell
Describe 'Find-DeadCode' -Tag 'Unit', 'AdvancedCodeAnalysis', 'Slow' {
  Context 'When code contains unreachable statements' {
    It 'Should detect code after return statement' -Tag 'Slow' {
      # Real AST parsing - can't efficiently mock this
      $content = @'
function Test-Function {
    return $value
    Write-Output "Unreachable"
}
'@
      
      $issues = Find-DeadCode -Content $content -FilePath 'test.ps1'
      $issues | Where-Object { $_.Name -eq 'UnreachableCode' } | Should -Not -BeNullOrEmpty
    }
  }
}
# This test runs in ~150ms due to AST parsing
```

## Summary

- **Fast tests** (default): Mock everything, run on every commit
- **Slow tests** (tagged): Real operations when necessary, run periodically
- **CI runs both**: Fast first (fail fast), then Slow (comprehensive)
- **Target**: < 2 minutes fast, < 5 minutes total

Following these guidelines ensures our test suite remains fast, maintainable, and provides quick feedback to developers.
