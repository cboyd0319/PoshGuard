# PoshGuard Testing Guide

## Quick Start

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path ./tests

# Run specific module tests
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1

# Run with code coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/*.psm1'
Invoke-Pester -Configuration $config
```

### Running Static Analysis

```powershell
# Analyze test files
Invoke-ScriptAnalyzer -Path ./tests/Unit -Recurse -Settings ./.psscriptanalyzer.psd1

# Analyze production code
Invoke-ScriptAnalyzer -Path ./tools/lib -Recurse -Settings ./.psscriptanalyzer.psd1
```

## Test Architecture

### Pester Architect Principles

All PoshGuard tests follow these core principles:

1. **AAA Pattern**: Arrange-Act-Assert structure
2. **Deterministic Execution**: No flakes, mock time/network/filesystem
3. **Hermetic Isolation**: Use TestDrive, InModuleScope, mocks
4. **Table-Driven Tests**: Use `-TestCases` for input variations
5. **Comprehensive Coverage**: Happy paths, error conditions, edge cases
6. **Fast Execution**: Individual tests < 100ms typical, < 500ms max

### Test File Structure

```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Brief description of what's being tested

.DESCRIPTION
    Detailed description of test coverage
    
.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ best practices
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/ModuleName.psm1'
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'FunctionName' -Tag 'Unit', 'ModuleName' {
  Context 'When <scenario>' {
    It 'Should <expected behavior>' {
      # Arrange
      # ... setup
      
      # Act
      # ... execute
      
      # Assert
      # ... verify
    }
  }
}
```

## Common Testing Patterns

### Table-Driven Tests

```powershell
It 'Handles <Description>' -TestCases @(
  @{ Input = 'value1'; Expected = 'result1'; Description = 'case1' }
  @{ Input = 'value2'; Expected = 'result2'; Description = 'case2' }
  @{ Input = 'value3'; Expected = 'result3'; Description = 'case3' }
) {
  param($Input, $Expected, $Description)
  
  # Arrange & Act
  $result = Invoke-Function -Input $Input
  
  # Assert
  $result | Should -Be $Expected
}
```

### Mocking External Dependencies

```powershell
It 'Calls external API with correct parameters' {
  InModuleScope ModuleName {
    # Arrange
    Mock Invoke-RestMethod -ParameterFilter {
      $Uri -eq 'https://api.example.com' -and
      $Headers['Authorization'] -eq 'Bearer token'
    } -MockWith {
      [PSCustomObject]@{ Status = 'OK' }
    } -Verifiable
    
    # Act
    $result = Get-Data -Token 'token'
    
    # Assert
    $result.Status | Should -Be 'OK'
    Assert-MockCalled Invoke-RestMethod -Exactly -Times 1
  }
}
```

### Deterministic Time Testing

```powershell
It 'Uses frozen time for deterministic results' {
  InModuleScope ModuleName {
    # Arrange
    $frozenTime = [datetime]'2025-01-15T10:00:00Z'
    Mock Get-Date { return $frozenTime }
    
    # Act
    $result = Get-Timestamp
    
    # Assert
    $result | Should -Be '2025-01-15 10:00:00'
  }
}
```

### TestDrive for Filesystem Isolation

```powershell
It 'Creates file in isolated directory' {
  # Arrange
  $testFile = Join-Path $TestDrive 'test.ps1'
  
  # Act
  New-Item -ItemType File -Path $testFile -Force
  Set-Content -Path $testFile -Value 'Write-Output "Test"'
  
  # Assert
  Test-Path $testFile | Should -Be $true
  Get-Content $testFile | Should -Be 'Write-Output "Test"'
}
```

### Parameter Validation Testing

```powershell
It 'Has mandatory Path parameter' {
  # Arrange
  $cmd = Get-Command FunctionName
  $param = $cmd.Parameters['Path'].Attributes | 
    Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
  
  # Act & Assert
  $param[0].Mandatory | Should -Be $true
}

# Don't do this - causes interactive prompts:
# { FunctionName } | Should -Throw
```

### ShouldProcess Testing

```powershell
It 'Respects -WhatIf and does not modify state' {
  InModuleScope ModuleName {
    # Arrange
    Mock Remove-Item
    
    # Act
    Remove-Thing -Path 'test.txt' -WhatIf
    
    # Assert - Remove-Item should not be called
    Assert-MockCalled Remove-Item -Times 0
  }
}
```

### Error Path Testing

```powershell
It 'Throws on invalid input' {
  # Act & Assert
  { Invoke-Function -Input 'invalid' -ErrorAction Stop } | 
    Should -Throw -ExpectedMessage '*validation failed*'
}
```

## Test Helpers

Located in `tests/Helpers/TestHelpers.psm1`:

- **New-TestFile**: Create test files in TestDrive
- **New-TestScriptContent**: Generate test PowerShell scripts
- **New-MockAST**: Parse PowerShell content into AST
- **Test-FunctionExists**: Check if function is available
- **Invoke-WithMockedDate**: Execute with frozen time
- **New-TestHashtable**: Create test data structures
- **Assert-ContentContains**: Verify text presence

## Best Practices

### DO ✅

- Use descriptive test names: `It 'Should <action> when <condition>'`
- Mock all external dependencies (network, filesystem, time)
- Use TestDrive for file operations
- Keep tests fast (< 100ms typical)
- Test edge cases (empty, null, large, Unicode)
- Use table-driven tests for input variations
- Verify mocks with `Assert-MockCalled`
- Add UTF-8 BOM to test files (PSScriptAnalyzer requirement)
- Use parameter metadata checks instead of calling functions without params

### DON'T ❌

- Call functions with missing mandatory parameters (causes interactive prompts)
- Use real filesystem paths outside TestDrive
- Use real dates/times (mock Get-Date)
- Use Start-Sleep (mock time progression)
- Make real network calls
- Modify global state
- Use Write-Host in tests (use Write-Log if needed)
- Leave unused variables (PSScriptAnalyzer will catch)
- Create tests that depend on execution order

## Troubleshooting

### Test Hangs with Interactive Prompt

**Problem**: Test hangs waiting for input

**Solution**: Don't call functions with missing mandatory parameters. Use parameter metadata checks instead:

```powershell
# ❌ BAD - causes interactive prompt
It 'Requires Path parameter' {
  { Invoke-Function } | Should -Throw
}

# ✅ GOOD - checks parameter metadata
It 'Has mandatory Path parameter' {
  $cmd = Get-Command Invoke-Function
  $param = $cmd.Parameters['Path'].Attributes | 
    Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
  $param[0].Mandatory | Should -Be $true
}
```

### PSScriptAnalyzer Warnings

**Problem**: `PSUseDeclaredVarsMoreThanAssignments` warning

**Solution**: Assign to `$null` if you don't need the return value:

```powershell
# ❌ BAD
$backupPath = New-FileBackup -FilePath $file
# ... never use $backupPath

# ✅ GOOD
$null = New-FileBackup -FilePath $file
```

**Problem**: `PSUseBOMForUnicodeEncodedFile` warning

**Solution**: Save file with UTF-8 BOM:

```powershell
$content = Get-Content -Path $file -Raw
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($file, $content, $utf8WithBom)
```

### InModuleScope Variable Access

**Problem**: `$script:variable` not accessible inside `InModuleScope`

**Solution**: Pass as local variable or don't use InModuleScope for public functions:

```powershell
# ❌ BAD
BeforeEach {
  $script:testFile = Join-Path $TestDrive 'test.ps1'
}

It 'Works with test file' {
  InModuleScope Module {
    $file = $script:testFile  # Not accessible!
  }
}

# ✅ GOOD - Option 1: Don't use InModuleScope for public functions
BeforeEach {
  $script:testFile = Join-Path $TestDrive 'test.ps1'
}

It 'Works with test file' {
  $result = Invoke-PublicFunction -Path $script:testFile
  $result | Should -Not -BeNullOrEmpty
}

# ✅ GOOD - Option 2: Pass as parameter
BeforeEach {
  $testFile = Join-Path $TestDrive 'test.ps1'
  $script:testFile = $testFile
}

It 'Works with test file' {
  $file = $script:testFile
  InModuleScope Module -Parameters @{ File = $file } {
    param($File)
    # Use $File here
  }
}
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4
      - name: Setup PowerShell
        uses: PowerShell/PowerShell-For-GitHub-Actions@v1
      - name: Install Dependencies
        shell: pwsh
        run: |
          Install-Module Pester -MinimumVersion 5.5.0 -Force
          Install-Module PSScriptAnalyzer -Force
      - name: Run Tests
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './tests'
          $config.CodeCoverage.Enabled = $true
          $result = Invoke-Pester -Configuration $config
          if ($result.FailedCount -gt 0) { exit 1 }
```

## Coverage Goals

- **Overall**: ≥ 90% line coverage, ≥ 85% branch coverage
- **Critical modules** (Core, Security): ≥ 95% coverage
- **All public functions**: 100% coverage
- **Error paths**: ≥ 85% coverage

## Resources

- [Pester v5 Documentation](https://pester.dev/docs/quick-start)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [PoshGuard Coverage Report](./COVERAGE_REPORT.md)
- [Pester Architect Principles](../problem_statement.md)

## Getting Help

1. Check existing test files for examples
2. Review test helpers in `tests/Helpers/`
3. See `COVERAGE_REPORT.md` for module-specific patterns
4. Ask in team chat or open an issue

---

**Last Updated**: 2025-10-18  
**Test Framework**: Pester 5.7.1  
**Static Analysis**: PSScriptAnalyzer 1.24.0
