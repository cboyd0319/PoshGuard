# PoshGuard Testing Quick Start Guide

## Prerequisites

```powershell
# Verify PowerShell version (7.4+ recommended)
$PSVersionTable.PSVersion

# Install Pester (v5.5.0+)
Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.5.0

# Install PSScriptAnalyzer (1.24.0+)
Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -MinimumVersion 1.24.0

# Verify installations
Get-Module Pester, PSScriptAnalyzer -ListAvailable
```

## Quick Test Runs

### 1. Run All Tests (Fast)
```powershell
Invoke-Pester -Path ./tests/Unit
```

### 2. Run Single Module Tests
```powershell
# Core module
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1

# Security module
Invoke-Pester -Path ./tests/Unit/Security.Tests.ps1

# PoshGuard main module
Invoke-Pester -Path ./tests/Unit/PoshGuard.Tests.ps1
```

### 3. Run Tests with Detailed Output
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit/Core.Tests.ps1'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

## Common Test Scenarios

### Scenario 1: Before Committing Code
```powershell
# 1. Run static analysis
Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse

# 2. Run affected module tests
Invoke-Pester -Path ./tests/Unit/YourModule.Tests.ps1

# 3. Run all tests (if time permits)
Invoke-Pester -Path ./tests/Unit
```

### Scenario 2: Debugging a Failing Test
```powershell
# Run with detailed output and stop on first failure
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit/FailingModule.Tests.ps1'
$config.Run.Exit = $false
$config.Run.SkipRemainingOnFailure = 'Container'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

### Scenario 3: Code Coverage Analysis
```powershell
$config = New-PesterConfiguration

# Specify test path
$config.Run.Path = './tests/Unit'
$config.Run.PassThru = $true

# Enable code coverage
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(
    './tools/lib/Core.psm1',
    './tools/lib/Security.psm1',
    './tools/lib/*.psm1'
)
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = './coverage.xml'

$result = Invoke-Pester -Configuration $config

# Display coverage summary
if ($result.CodeCoverage) {
    $cc = $result.CodeCoverage
    $percent = ($cc.CommandsExecutedCount / $cc.CommandsAnalyzedCount) * 100
    Write-Host "Coverage: $($percent.ToString('F2'))% ($($cc.CommandsExecutedCount)/$($cc.CommandsAnalyzedCount) commands)"
}
```

### Scenario 4: Run Tagged Tests Only
```powershell
# Only unit tests
Invoke-Pester -Path ./tests -Tag 'Unit'

# Only security tests
Invoke-Pester -Path ./tests -Tag 'Security'

# Exclude slow tests
Invoke-Pester -Path ./tests -ExcludeTag 'Slow'

# Multiple tags (AND logic)
Invoke-Pester -Path ./tests -Tag 'Unit','Core'
```

### Scenario 5: CI/CD Simulation
```powershell
# Simulate full CI pipeline locally
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Normal'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = './test-results.xml'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/*.psm1'
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = './coverage.xml'

$result = Invoke-Pester -Configuration $config

# Check for failures
if ($result.FailedCount -gt 0) {
    Write-Error "$($result.FailedCount) test(s) failed"
    exit 1
}

Write-Host "All tests passed! ✅" -ForegroundColor Green
```

## Writing New Tests

### Template: Basic Test File
```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for [ModuleName] module

.DESCRIPTION
    Comprehensive unit tests for [ModuleName].psm1:
    - [Function1]
    - [Function2]
    
    Tests follow AAA pattern with deterministic execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  # Import helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/ModuleName.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'FunctionName' -Tag 'Unit', 'ModuleName' {
  
  Context 'When called with valid input' {
    It 'Should return expected result' {
      # Arrange
      $input = 'test'
      
      # Act
      $result = FunctionName -Input $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Be 'expected'
    }
  }

  Context 'When called with invalid input' {
    It 'Should throw ArgumentException' {
      # Arrange / Act / Assert
      { FunctionName -Input $null } | Should -Throw -ExceptionType 'ArgumentException'
    }
  }

  Context 'Parameter validation' {
    It 'Should have mandatory Input parameter' {
      $cmd = Get-Command FunctionName
      $cmd.Parameters['Input'].Attributes.Mandatory | Should -Be $true
    }
  }
}
```

### Template: Table-Driven Tests
```powershell
Describe 'ParseVersion' -Tag 'Unit' {
  It 'Parses <Input> => <Expected>' -TestCases @(
    @{ Input = '1.0.0'; Expected = @{Major=1; Minor=0; Patch=0} }
    @{ Input = '2.3.4'; Expected = @{Major=2; Minor=3; Patch=4} }
    @{ Input = '10.20.30'; Expected = @{Major=10; Minor=20; Patch=30} }
  ) {
    param($Input, $Expected)
    
    # Act
    $result = ParseVersion -Version $Input
    
    # Assert
    $result.Major | Should -Be $Expected.Major
    $result.Minor | Should -Be $Expected.Minor
    $result.Patch | Should -Be $Expected.Patch
  }
}
```

### Template: Mocking External Dependencies
```powershell
Describe 'Get-ExternalData' {
  It 'Calls Invoke-RestMethod with correct URI' {
    InModuleScope ModuleName {
      # Arrange
      Mock Invoke-RestMethod -ParameterFilter { 
        $Uri -eq 'https://api.example.com/data' 
      } -MockWith {
        @{ data = 'test' }
      } -Verifiable

      # Act
      $result = Get-ExternalData
      
      # Assert
      $result.data | Should -Be 'test'
      Assert-MockCalled Invoke-RestMethod -Exactly -Times 1 -Scope It
    }
  }
}
```

### Template: TestDrive Usage
```powershell
Describe 'Read-ConfigFile' {
  It 'Reads valid JSON config' {
    # Arrange
    $configPath = Join-Path TestDrive: 'config.json'
    @{ setting = 'value' } | ConvertTo-Json | Set-Content $configPath
    
    # Act
    $config = Read-ConfigFile -Path $configPath
    
    # Assert
    $config.setting | Should -Be 'value'
  }
}
```

## Troubleshooting

### Problem: "Module not found"
```powershell
# Solution: Check module path is correct
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/YourModule.psm1'
Test-Path $modulePath  # Should return $true

# Alternative: Use absolute path
$modulePath = '/home/runner/work/PoshGuard/PoshGuard/tools/lib/YourModule.psm1'
```

### Problem: "Test hangs/times out"
```powershell
# Solution: Add timeout to Pester configuration
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit/SlowModule.Tests.ps1'
$config.Run.Timeout = 120  # 120 seconds

# Or: Debug specific test with breakpoints
# Add 'Wait-Debugger' in test, run with -Debug
```

### Problem: "Mock not working"
```powershell
# Solution: Ensure InModuleScope is used for internal functions
Describe 'MyTest' {
  It 'Should mock internal call' {
    InModuleScope MyModule {  # ✅ Required for internal functions
      Mock Get-InternalData { 'mocked' }
      
      $result = Invoke-MyFunction
      
      Assert-MockCalled Get-InternalData -Exactly -Times 1
    }
  }
}
```

### Problem: "Tests pass locally but fail in CI"
```powershell
# Common causes:
# 1. Platform-specific paths (use Join-Path, not hardcoded /)
# 2. Real time dependencies (mock Get-Date)
# 3. Real network calls (mock Invoke-RestMethod)
# 4. Environment variables (mock or set in BeforeAll)

# Solution: Run in container locally
docker run -it mcr.microsoft.com/powershell:7.4.4-ubuntu-22.04
# Then run tests inside container
```

### Problem: "Coverage is lower than expected"
```powershell
# Solution: Check which lines are not covered
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit/MyModule.Tests.ps1'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/MyModule.psm1'
$config.CodeCoverage.OutputFormat = 'JaCoCo'

$result = Invoke-Pester -Configuration $config

# Inspect missed commands
$result.CodeCoverage.MissedCommands | Format-Table File, Line, Command
```

## Test Performance Tips

### 1. Use BeforeAll for Setup
```powershell
# ❌ Slow: Runs for every test
Describe 'MyTests' {
  It 'Test 1' {
    $module = Import-Module './Module.psm1' -PassThru  # Repeated
  }
  It 'Test 2' {
    $module = Import-Module './Module.psm1' -PassThru  # Repeated
  }
}

# ✅ Fast: Runs once per Describe
Describe 'MyTests' {
  BeforeAll {
    $module = Import-Module './Module.psm1' -PassThru
  }
  
  It 'Test 1' { <# Uses $module #> }
  It 'Test 2' { <# Uses $module #> }
}
```

### 2. Avoid Real I/O
```powershell
# ❌ Slow: Real file operations
It 'Reads file' {
  $content = Get-Content './largefile.txt'
}

# ✅ Fast: Mock or TestDrive
It 'Reads file' {
  InModuleScope MyModule {
    Mock Get-Content { 'mocked content' }
    $content = Read-MyFile
  }
}
```

### 3. Batch Related Tests
```powershell
# ❌ Slow: Many small Describe blocks
Describe 'Test1' { It 'A' {} }
Describe 'Test2' { It 'B' {} }

# ✅ Fast: Group related tests
Describe 'MyFeature' {
  Context 'Scenario 1' { It 'A' {} }
  Context 'Scenario 2' { It 'B' {} }
}
```

## Advanced Techniques

### Parametrized Describe Blocks
```powershell
@('Small', 'Medium', 'Large') | ForEach-Object {
  Describe "Processing $_ files" {
    It "Handles $_ file size" {
      # Test implementation
    }
  }
}
```

### Custom Assertions
```powershell
# tests/Helpers/CustomAssertions.psm1
function Assert-ValidEmail {
  param([string]$Email)
  $Email | Should -Match '^[^@]+@[^@]+\.[^@]+$'
}

# In test file
It 'Should validate email format' {
  Assert-ValidEmail -Email 'test@example.com'
}
```

### Test Data Builders
```powershell
# tests/Helpers/TestData.psm1
function New-TestUser {
  param(
    [string]$Name = 'Test User',
    [string]$Email = 'test@example.com'
  )
  
  return [PSCustomObject]@{
    Name = $Name
    Email = $Email
    CreatedAt = [DateTime]::Parse('2025-01-01T00:00:00Z')
  }
}

# In test file
It 'Processes user' {
  $user = New-TestUser -Name 'John Doe'
  $result = Process-User -User $user
  $result | Should -Not -BeNullOrEmpty
}
```

## Best Practices Checklist

- [ ] **AAA Pattern**: Every test has clear Arrange, Act, Assert sections
- [ ] **Descriptive Names**: `It "<Unit> <Scenario> => <Expected>"`
- [ ] **One Behavior**: Each test validates exactly one behavior
- [ ] **Isolated**: No test depends on another test's state
- [ ] **Deterministic**: No randomness, real time, or network calls
- [ ] **Fast**: Target < 100ms per test
- [ ] **Readable**: Clear intent without reading implementation
- [ ] **TestDrive**: Use for all file operations
- [ ] **Mocks Verified**: `Assert-MockCalled -Exactly` for all mocks
- [ ] **Tags**: Apply relevant tags (`Unit`, module name, feature)

## Resources

- [Pester Documentation](https://pester.dev/)
- [Pester Best Practices](https://pester.dev/docs/usage/mocking)
- [PoshGuard Test Architecture](./COMPREHENSIVE_PESTER_ARCHITECTURE.md)
- [PoshGuard Contributing Guide](../CONTRIBUTING.md)

---

**Last Updated**: 2025-10-17  
**Version**: 4.3.0
