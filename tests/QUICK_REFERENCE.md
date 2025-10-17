# Pester Architect Quick Reference - PoshGuard Test Suite

## Running Tests

### Run all tests
```powershell
Invoke-Pester -Path ./tests/Unit
```

### Run specific module tests
```powershell
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1
```

### Run with coverage
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/*.psm1'
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = 'coverage.xml'
Invoke-Pester -Configuration $config
```

### Run tests with specific tags
```powershell
Invoke-Pester -Path ./tests/Unit -Tag 'Unit', 'Security'
```

### Run tests excluding slow tests
```powershell
Invoke-Pester -Path ./tests/Unit -ExcludeTag 'Performance', 'Integration'
```

## Writing Tests

### Basic Test Structure
```powershell
BeforeAll {
  # Import module under test
  $modulePath = Join-Path $PSScriptRoot '../../tools/lib/ModuleName.psm1'
  Import-Module $modulePath -Force
}

Describe 'FunctionName' -Tag 'Unit', 'ModuleName' {
  Context 'When <scenario>' {
    It 'Should <expected behavior>' {
      # Arrange
      $input = 'test'
      
      # Act
      $result = FunctionName -Parameter $input
      
      # Assert
      $result | Should -Be 'expected'
    }
  }
}
```

### Table-Driven Tests
```powershell
It 'Should validate <Type> input' -TestCases @(
  @{ Type = 'String'; Input = 'test'; Expected = 'test' }
  @{ Type = 'Integer'; Input = 42; Expected = 42 }
  @{ Type = 'Null'; Input = $null; Expected = $null }
) {
  param($Type, $Input, $Expected)
  
  # Arrange & Act
  $result = ProcessInput -Value $Input
  
  # Assert
  $result | Should -Be $Expected
}
```

### Mocking External Calls
```powershell
It 'Should call external API with correct parameters' {
  InModuleScope ModuleName {
    # Arrange
    Mock Invoke-RestMethod -ParameterFilter {
      $Uri -eq 'https://api.example.com' -and
      $Method -eq 'GET'
    } -MockWith {
      [PSCustomObject]@{ Status = 'OK' }
    } -Verifiable
    
    # Act
    $result = Call-ExternalAPI
    
    # Assert
    $result.Status | Should -Be 'OK'
    Assert-MockCalled Invoke-RestMethod -Exactly 1 -Scope It
  }
}
```

### Testing File Operations
```powershell
It 'Should create file in specified directory' {
  # Arrange
  $testDir = Join-Path $TestDrive 'output'
  New-Item -ItemType Directory -Path $testDir | Out-Null
  
  # Act
  New-ConfigFile -Path $testDir -Name 'config.json'
  
  # Assert
  $configPath = Join-Path $testDir 'config.json'
  Test-Path $configPath | Should -Be $true
  $content = Get-Content $configPath -Raw | ConvertFrom-Json
  $content | Should -Not -BeNullOrEmpty
}
```

### Testing Time-Dependent Code
```powershell
It 'Should generate timestamp consistently' {
  InModuleScope ModuleName {
    # Arrange
    $frozenTime = [DateTime]::new(2025, 10, 17, 12, 0, 0, [DateTimeKind]::Utc)
    Mock Get-Date { return $frozenTime }
    
    # Act
    $timestamp1 = Get-Timestamp
    $timestamp2 = Get-Timestamp
    
    # Assert
    $timestamp1 | Should -Be $timestamp2
    $timestamp1 | Should -Be '2025-10-17T12:00:00Z'
  }
}
```

### Testing Error Handling
```powershell
It 'Should throw on invalid input' {
  # Arrange
  $invalidInput = $null
  
  # Act & Assert
  { Process-Data -Input $invalidInput -ErrorAction Stop } | 
    Should -Throw -ErrorId '*null*'
}

It 'Should write to error stream' {
  InModuleScope ModuleName {
    # Arrange
    Mock Write-Error { }
    
    # Act
    Process-BadInput -Value 'invalid'
    
    # Assert
    Assert-MockCalled Write-Error -Exactly 1 -Scope It
  }
}
```

### Testing ShouldProcess
```powershell
It 'Should not execute action with -WhatIf' {
  # Arrange
  $testFile = Join-Path $TestDrive 'file.txt'
  'content' | Set-Content $testFile
  
  # Act
  Remove-CustomFile -Path $testFile -WhatIf
  
  # Assert
  Test-Path $testFile | Should -Be $true  # File still exists
}

It 'Should execute action with -Confirm:$false' {
  # Arrange
  $testFile = Join-Path $TestDrive 'file.txt'
  'content' | Set-Content $testFile
  
  # Act
  Remove-CustomFile -Path $testFile -Confirm:$false
  
  # Assert
  Test-Path $testFile | Should -Be $false  # File deleted
}
```

## Common Assertions

### Basic Assertions
```powershell
$result | Should -Be $expected
$result | Should -Not -Be $unexpected
$result | Should -BeExactly 'CaseSensitive'
$result | Should -Match 'pattern'
$result | Should -BeNullOrEmpty
$result | Should -Not -BeNullOrEmpty
```

### Type Assertions
```powershell
$result | Should -BeOfType [string]
$result | Should -BeOfType [System.Collections.Hashtable]
```

### Collection Assertions
```powershell
$array | Should -HaveCount 3
$array | Should -Contain 'item'
$array | Should -Not -Contain 'missing'
```

### Numeric Assertions
```powershell
$number | Should -BeGreaterThan 5
$number | Should -BeLessThan 100
$number | Should -BeGreaterOrEqual 10
$number | Should -BeLessOrEqual 50
```

### Boolean Assertions
```powershell
$result | Should -Be $true
$result | Should -Be $false
$result | Should -BeTrue
$result | Should -BeFalse
```

## Best Practices

### ✅ DO
- Use `BeforeAll` for expensive setup (module imports)
- Use `BeforeEach` for per-test setup
- Use descriptive test names: "Should do X when Y"
- Use AAA pattern: Arrange, Act, Assert
- Use `-TestCases` for data-driven tests
- Mock all external dependencies
- Use `$TestDrive` for file operations
- Mock `Get-Date` for time-dependent tests
- Use `InModuleScope` for testing private functions
- Verify mocks with `Assert-MockCalled`

### ❌ DON'T
- Touch real filesystem outside `$TestDrive`
- Make real network calls
- Use `Start-Sleep` (mock time instead)
- Use unseeded random values
- Write to global variables
- Have cross-test dependencies
- Test multiple behaviors in one `It`
- Use hardcoded paths or credentials
- Skip error path testing
- Ignore edge cases (null, empty, large, unicode)

## Test Organization

### Tag Usage
```powershell
-Tag 'Unit'           # Unit tests (fast, isolated)
-Tag 'Integration'    # Integration tests (slower, external dependencies)
-Tag 'Performance'    # Performance tests
-Tag 'Security'       # Security-related tests
-Tag 'ModuleName'     # Group by module
```

### File Naming
```
ModuleName.Tests.ps1           # Main module tests
SubModule.Tests.ps1            # Submodule tests
FunctionName.Tests.ps1         # Specific function tests (rare)
```

### Directory Structure
```
tests/
  Unit/                        # Unit tests
    Core.Tests.ps1
    Security.Tests.ps1
    Advanced/                  # Submodule tests
      ASTTransformations.Tests.ps1
  Integration/                 # Integration tests (future)
  Helpers/                     # Shared test utilities
    TestHelpers.psm1
    MockBuilders.psm1
  EXEMPLAR_PESTER_ARCHITECT_TEST.ps1  # Reference implementation
```

## Debugging Tests

### Run single test
```powershell
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1 -FullName '*Get-PowerShellFiles*'
```

### Run with verbose output
```powershell
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1 -Output Detailed
```

### Debug specific test
```powershell
# Add breakpoint in test file
Set-PSBreakpoint -Script ./tests/Unit/Core.Tests.ps1 -Line 50

# Run test
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1
```

### View coverage report
```powershell
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$result = Invoke-Pester -Configuration $config

# View missed lines
$result.CodeCoverage.MissedCommands | Format-Table
```

## Performance Tips

### Slow Tests
- Mock expensive operations (AST parsing, file I/O)
- Use `BeforeAll` instead of `BeforeEach` for shared setup
- Minimize `Import-Module` calls
- Use `-TestCases` instead of multiple `It` blocks

### Parallel Execution
```powershell
# Pester v5.2+ supports parallel execution
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Run.Parallel = $true
$config.Run.PassThru = $true
Invoke-Pester -Configuration $config
```

## CI/CD Integration

### GitHub Actions
See `.github/workflows/pester-architect-tests.yml`

### Local Pre-Commit
```powershell
# Run before committing
./tests/run-local-tests.ps1
```

### Coverage Threshold
```powershell
$result = Invoke-Pester -PassThru
if ($result.CodeCoverage.CoveragePercent -lt 85) {
  Write-Error "Coverage below 85%"
  exit 1
}
```

## References

- Pester Documentation: https://pester.dev/docs/quick-start
- Pester v5 Migration: https://pester.dev/docs/migrations/v3-to-v5
- PSScriptAnalyzer: https://github.com/PowerShell/PSScriptAnalyzer
- PoshGuard Test Plan: tests/PESTER_ARCHITECT_TEST_PLAN.md
- Test Rationale: tests/TEST_RATIONALE.md
- Exemplar Tests: tests/EXEMPLAR_PESTER_ARCHITECT_TEST.ps1
