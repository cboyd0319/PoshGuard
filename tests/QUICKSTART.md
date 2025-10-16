# Quick Start Guide - Running PoshGuard Tests

## Prerequisites
- PowerShell 7.4+ 
- Pester 5.0.0+
- PSScriptAnalyzer 1.24.0+

## Install Dependencies
```powershell
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Pester -Scope CurrentUser -Force -MinimumVersion 5.5.0
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

## Running Tests

### Run All Tests
```powershell
# From repository root
Import-Module Pester -Force
Invoke-Pester -Path ./tests/Unit -Output Detailed
```

### Run Specific Module Tests
```powershell
# Core module
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1 -Output Detailed

# Security module
Invoke-Pester -Path ./tests/Unit/Security.Tests.ps1 -Output Detailed

# BestPractices
Invoke-Pester -Path ./tests/Unit/BestPractices/ -Output Detailed

# Formatting
Invoke-Pester -Path ./tests/Unit/Formatting/ -Output Detailed
```

### Run with Code Coverage
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = 'coverage.xml'
$config.CodeCoverage.Path = @(
    'tools/lib/*.psm1',
    'PoshGuard/*.psm1'
)

$result = Invoke-Pester -Configuration $config

# View coverage summary
Write-Host "`nCoverage: $($result.CodeCoverage.CoveragePercent)%" -ForegroundColor Cyan
```

### Run Tests by Tag
```powershell
# Run only Core module tests
Invoke-Pester -Path ./tests/Unit -Tag 'Core'

# Run BestPractices tests
Invoke-Pester -Path ./tests/Unit -Tag 'BestPractices'

# Run Formatting tests
Invoke-Pester -Path ./tests/Unit -Tag 'Formatting'

# Run Security tests
Invoke-Pester -Path ./tests/Unit -Tag 'Security'
```

### Run Specific Test
```powershell
# Run a specific Describe block
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1 -FullNameFilter 'Write-Log'

# Run a specific Context
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1 -FullNameFilter '*Log levels*'
```

## Test Results

### Expected Output
```
Starting discovery in X files.
Discovery found X tests in XXXms.
Running tests.

Describing Core Module
  Context Function existence
    [+] Should be exported
  Context Happy path
    [+] Should work correctly
  Context Error handling
    [+] Should throw on invalid input

Tests completed in X.XXs
Tests Passed: XX, Failed: 0, Skipped: 0
```

### Current Status (As of Last Run)
- ✅ **Core.Tests.ps1**: 32 tests passing
- ✅ **PoshGuard.Tests.ps1**: 24 tests passing  
- ✅ **StringHandling.Tests.ps1**: 33 tests passing
- ✅ **TypeSafety.Tests.ps1**: 28 tests passing
- ✅ **Total**: 200+ tests across 21+ files

## Troubleshooting

### Module Not Found Error
```powershell
# Ensure you're in the repository root
cd /path/to/PoshGuard

# Check module path
$modulePath = Join-Path $PSScriptRoot '../../tools/lib/Core.psm1'
Test-Path $modulePath
```

### Tests Failing
```powershell
# Run with verbose output
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1 -Output Diagnostic

# Check Pester version
Get-Module Pester -ListAvailable
```

### Coverage Not Working
```powershell
# Ensure Pester 5.5.0+ is installed
Install-Module Pester -Force -MinimumVersion 5.5.0

# Import explicitly
Import-Module Pester -Force
```

## CI/CD Integration

### GitHub Actions
Tests run automatically on:
- Push to main branch
- Pull requests
- Manual workflow dispatch

View results at:
```
https://github.com/cboyd0319/PoshGuard/actions
```

### Local Pre-Commit Check
```powershell
# Run before committing
.\tests\scripts\pre-commit-check.ps1
```

## Test Structure

### Directory Layout
```
tests/
├── Helpers/
│   └── TestHelper.psm1       # Shared test utilities
├── Unit/
│   ├── Core.Tests.ps1        # Core module tests
│   ├── Security.Tests.ps1    # Security module tests
│   ├── PoshGuard.Tests.ps1   # Main module tests
│   ├── BestPractices/        # BestPractices submodules
│   │   ├── StringHandling.Tests.ps1
│   │   ├── TypeSafety.Tests.ps1
│   │   ├── Syntax.Tests.ps1
│   │   └── ...
│   ├── Formatting/           # Formatting submodules
│   └── Advanced/             # Advanced submodules
└── Integration/              # (Future) Integration tests
```

### Test File Template
```powershell
BeforeAll {
  # Import module under test
  $modulePath = Join-Path $PSScriptRoot '../../tools/lib/MyModule.psm1'
  Import-Module $modulePath -Force
  
  # Import test helpers
  Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1')
}

Describe 'MyFunction' -Tag 'Unit', 'MyModule' {
  Context 'Happy path' {
    It 'Should do something' {
      # Arrange
      $input = 'test'
      
      # Act
      $result = MyFunction -Input $input
      
      # Assert
      $result | Should -Be 'expected'
    }
  }
}
```

## Performance Tips

### Parallel Execution (Pester 5.3+)
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.Run.Parallel = $true
$config.Run.MaximumParallelJobs = 4

Invoke-Pester -Configuration $config
```

### Skip Slow Tests
```powershell
# Tag slow tests
It 'Should handle large file' -Tag 'Slow' {
  # test code
}

# Skip during development
Invoke-Pester -Path ./tests/Unit -ExcludeTag 'Slow'
```

## Additional Resources

- [Pester Documentation](https://pester.dev)
- [PoshGuard Test Plan](./COMPREHENSIVE_PESTER_TEST_PLAN.md)
- [Implementation Summary](./IMPLEMENTATION_SUMMARY_COMPREHENSIVE.md)
- [Test Helpers Reference](./Helpers/TestHelper.psm1)

## Contributing Tests

When adding new tests:
1. Follow the AAA pattern (Arrange-Act-Assert)
2. Use descriptive test names
3. Include edge cases and error handling
4. Use TestDrive: for file operations
5. Mock external dependencies
6. Add appropriate tags
7. Update this guide if needed

## Example Test Session
```powershell
# Navigate to repo
cd /path/to/PoshGuard

# Install/update Pester
Install-Module Pester -Force -MinimumVersion 5.5.0

# Run all tests
Import-Module Pester -Force
Invoke-Pester -Path ./tests/Unit -Output Detailed

# Check a specific module
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1

# Run with coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = 'tools/lib/*.psm1'
Invoke-Pester -Configuration $config
```
