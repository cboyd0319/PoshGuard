# PoshGuard Test Suite

Comprehensive Pester v5+ test suite for PoshGuard following best practices for deterministic, hermetic, cross-platform testing.

## Overview

- **Framework**: Pester v5.7+
- **Pattern**: AAA (Arrange-Act-Assert)
- **Coverage**: 147 tests across 7 modules
- **Status**: ✅ All passing
- **Platforms**: Windows, macOS, Linux (PowerShell 7+)

## Directory Structure

```
tests/
├── Unit/                      # Unit tests (function-level)
│   ├── Core.Tests.ps1        # Core module (32 tests)
│   ├── Security.Tests.ps1    # Security module (31 tests)
│   ├── ConfigurationManager.Tests.ps1 # Config module (13 tests)
│   ├── BestPractices/
│   │   ├── Syntax.Tests.ps1  # Syntax best practices (38 tests)
│   │   └── Naming.Tests.ps1  # Naming conventions (9 tests)
│   └── Formatting/
│       ├── Aliases.Tests.ps1  # Alias expansion (17 tests)
│       └── Whitespace.Tests.ps1 # Whitespace formatting (7 tests)
├── Helpers/                   # Shared test utilities
│   ├── TestHelpers.psm1      # Helper functions
│   ├── MockBuilders.psm1     # Mock object factories
│   └── TestData.psm1         # Test data generators
├── Integration/               # Integration tests (future)
├── AdvancedDetection.Tests.ps1 # Existing tests (16 tests)
├── CodeQuality.Tests.ps1      # Existing tests (17 tests)
├── EnhancedMetrics.Tests.ps1  # Existing tests (11 tests)
├── Phase2-AutoFix.Tests.ps1   # Existing tests (21 tests, 4 skipped)
├── TEST_PLAN.md              # Comprehensive test plan
└── README.md                  # This file
```

## Running Tests

### All Tests
```powershell
Invoke-Pester -Path ./tests
```

### Specific Module
```powershell
# Core module tests
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1

# Security module tests
Invoke-Pester -Path ./tests/Unit/Security.Tests.ps1

# All unit tests
Invoke-Pester -Path ./tests/Unit
```

### With Tags
```powershell
# Only unit tests
Invoke-Pester -Path ./tests -Tag 'Unit'

# Only security tests
Invoke-Pester -Path ./tests -Tag 'Security'

# Multiple tags
Invoke-Pester -Path ./tests -Tag 'Unit','Core'
```

### With Code Coverage
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(
    './tools/lib/Core.psm1',
    './tools/lib/Security.psm1',
    './tools/lib/ConfigurationManager.psm1',
    './tools/lib/Formatting/Aliases.psm1'
)
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = 'coverage.xml'

Invoke-Pester -Configuration $config
```

### Detailed Output
```powershell
Invoke-Pester -Path ./tests -Output Detailed
```

## Test Coverage by Module

### Core.psm1 ✅ (32 tests)
- `Clean-Backups`: Backup cleanup with date filtering
- `Write-Log`: Logging with levels, icons, timestamps
- `Get-PowerShellFiles`: File discovery with filtering
- `New-FileBackup`: File backup creation
- `New-UnifiedDiff`: Diff generation

**Coverage**: Happy paths, edge cases, parameter validation, error handling

### Security.psm1 ✅ (31 tests)
- `Invoke-PlainTextPasswordFix`: SecureString conversion
- `Invoke-ConvertToSecureStringFix`: Dangerous pattern detection
- `Invoke-UsernamePasswordParamsFix`: PSCredential suggestions
- `Invoke-AllowUnencryptedAuthFix`: Unencrypted auth warnings
- `Invoke-HardcodedComputerNameFix`: Computer name parameterization
- `Invoke-InvokeExpressionFix`: Invoke-Expression removal
- `Invoke-EmptyCatchBlockFix`: Error handling enforcement

**Coverage**: AST transformations, multiple security patterns, integration scenarios

### ConfigurationManager.psm1 ✅ (13 tests)
- `Initialize-PoshGuardConfiguration`: Config loading and validation
- `Get-DefaultConfiguration`: Default settings
- `Get-PoshGuardConfiguration`: Config retrieval
- `Set-PoshGuardConfigurationValue`: Config updates

**Coverage**: Config loading, merging, environment overrides, validation

### Formatting/Aliases.psm1 ✅ (17 tests)
- `Invoke-AliasFix`: Alias expansion with context awareness
- `Invoke-AliasFixAst`: AST-based alias replacement

**Coverage**: Common aliases (gci, ls, cat, rm, cp), multiple aliases, special cases, integration

### BestPractices/Syntax.psm1 ✅ (38 tests)
- `Invoke-SemicolonFix`: Trailing semicolon removal
- `Invoke-NullComparisonFix`: Null comparison order fixes
- `Invoke-ExclaimOperatorFix`: Exclaim operator replacement with -not

**Coverage**: AST transformations, idempotency, edge cases, integration scenarios

### BestPractices/Naming.psm1 ✅ (9 tests)
- `Invoke-SingularNounFix`: Plural to singular noun conversion
- `Invoke-ApprovedVerbFix`: Approved verb enforcement
- `Invoke-ReservedCmdletCharFix`: Reserved character handling

**Coverage**: Naming conventions, function declarations, PowerShell standards

### Formatting/Whitespace.psm1 ✅ (7 tests)
- `Invoke-WhitespaceFix`: Trailing whitespace removal, line ending normalization
- `Invoke-FormatterFix`: PSScriptAnalyzer Invoke-Formatter integration
- `Invoke-MisleadingBacktickFix`: Backtick handling

**Coverage**: Whitespace cleanup, formatting integration, idempotency

### Existing Tests ✅ (65 tests, 4 skipped)
- `AdvancedDetection.Tests.ps1`: Complexity and nesting detection
- `CodeQuality.Tests.ps1`: Beyond-PSSA enhancements
- `EnhancedMetrics.Tests.ps1`: Metrics and reporting
- `Phase2-AutoFix.Tests.ps1`: Auto-fix functionality

## Test Helpers

Located in `tests/Helpers/TestHelpers.psm1`:

### Test Data Generation
- **New-TestScriptContent**: Generate scripts with configurable issues
- **New-TestFile**: Create files in TestDrive
- **New-TestHashtable**: Generate test data structures
- **New-TestModuleManifest**: Create test manifests

### Assertions
- **Assert-ContentContains**: Content assertion helper
- **Assert-NoVerboseOutput**: Verbose output validation

### Utilities
- **Test-FunctionExists**: Check function availability
- **New-MockAST**: Parse script content to AST
- **Invoke-WithMockedDate**: Execute with frozen time
- **ConvertTo-UnixLineEndings**: Cross-platform line endings

## Testing Principles

### Determinism
- ✅ No real time/date dependencies (mocked)
- ✅ No external network calls (mocked)
- ✅ No real filesystem operations (TestDrive)
- ✅ Seeded randomness where needed

### Hermetic Isolation
- ✅ Each test is independent
- ✅ No shared state between tests
- ✅ TestDrive for file operations
- ✅ Mock external dependencies
- ✅ InModuleScope for private functions

### Cross-Platform
- ✅ Works on Windows, macOS, Linux
- ✅ PowerShell 7+ compatible
- ✅ Line ending normalization
- ✅ Path handling with Join-Path

### Performance
- ✅ Most tests < 100ms
- ✅ Full suite < 4 seconds
- ✅ No external dependencies
- ✅ Efficient test organization

## CI/CD Integration

### GitHub Actions
Located at `../.github/workflows/pester-tests.yml`:

- **Platforms**: Ubuntu, Windows, macOS
- **PowerShell**: 7.4+
- **Triggers**: Push, PR, manual dispatch
- **Steps**:
  1. Install Pester 5.5+ and PSScriptAnalyzer 1.24+
  2. Run PSScriptAnalyzer on all modules
  3. Run Pester tests with coverage
  4. Upload coverage to Codecov
  5. Generate test artifacts

### Running CI Locally

Simulate CI environment:

```powershell
# Install required modules
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Pester -MinimumVersion 5.5.0 -Force
Install-Module PSScriptAnalyzer -MinimumVersion 1.24.0 -Force

# Run static analysis
Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse

# Run tests with coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/*.psm1'
$config.CodeCoverage.OutputFormat = 'JaCoCo'
Invoke-Pester -Configuration $config
```

## Writing New Tests

### Template

```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1

BeforeAll {
  # Import helpers
  $helpersPath = Join-Path $PSScriptRoot '../Helpers/TestHelpers.psm1'
  Import-Module $helpersPath -Force

  # Import module under test
  $modulePath = Join-Path $PSScriptRoot '../../tools/lib/YourModule.psm1'
  Import-Module $modulePath -Force
}

Describe 'Your-Function' -Tag 'Unit', 'YourModule' {
  
  Context 'When [scenario]' {
    It 'Should [expected behavior]' {
      # Arrange
      $input = 'test input'
      
      # Act
      $result = Your-Function -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match 'expected pattern'
    }
  }
}
```

### Best Practices

1. **One assertion per It**: Focus on single behavior
2. **Use TestDrive**: For file operations
3. **Mock externals**: Network, time, filesystem
4. **Descriptive names**: Clear intent in test names
5. **AAA pattern**: Arrange, Act, Assert
6. **Fast tests**: Keep under 100ms
7. **Table-driven**: Use -TestCases for variations
8. **Error cases**: Test both success and failure

### Example: Table-Driven Test

```powershell
It 'Should expand <Alias> to <Expected>' -TestCases @(
  @{ Alias = 'gci'; Expected = 'Get-ChildItem' }
  @{ Alias = 'ls'; Expected = 'Get-ChildItem' }
  @{ Alias = 'cat'; Expected = 'Get-Content' }
) {
  param($Alias, $Expected)
  
  $result = Invoke-AliasFix -Content $Alias
  $result | Should -Match $Expected
}
```

## Troubleshooting

### Tests fail locally but pass in CI
- Check PowerShell version: `$PSVersionTable`
- Verify module versions: `Get-Module Pester,PSScriptAnalyzer -ListAvailable`
- Clean module cache: `Remove-Module * -Force`

### "Module not found" errors
- Use absolute paths with `Join-Path`
- Check `$PSScriptRoot` is correct
- Verify module files exist

### Timeout issues
- Increase timeout in async bash calls
- Remove external dependencies
- Check for infinite loops

### Line ending differences
- Use `ConvertTo-UnixLineEndings` helper
- Test on multiple platforms
- Normalize in assertions

## Future Enhancements

### Planned Test Additions
- [x] BestPractices/Syntax.psm1 (38 tests - completed)
- [x] BestPractices/Naming.psm1 (9 tests - completed)  
- [x] Formatting/Whitespace.psm1 (7 tests - completed)
- [x] Test infrastructure (MockBuilders, TestData helpers)
- [ ] Formatting submodules (Casing, Output, Alignment, Runspaces)
- [ ] BestPractices submodules (Scoping, StringHandling, TypeSafety, UsagePatterns, CodeQuality)
- [ ] Advanced submodules (CmdletBinding, ParameterManagement, ShouldProcess, Documentation, ManifestManagement)
- [ ] Security detection modules (EnhancedSecurityDetection, EntropySecretDetection)
- [ ] AI/ML modules (AIIntegration, ReinforcementLearning)
- [ ] Enterprise features (NISTSP80053Compliance, SupplyChainSecurity)
- [ ] Infrastructure modules (Observability, OpenTelemetryTracing, PerformanceOptimization)

### Quality Improvements
- [ ] Mutation testing for test effectiveness
- [ ] Property-based testing for edge cases
- [ ] Performance benchmarks with tracking
- [ ] Snapshot testing for stable outputs
- [ ] Integration tests for end-to-end scenarios

## Resources

- [TEST_PLAN.md](../docs/TEST_PLAN.md) - Comprehensive testing strategy
- [Pester Documentation](https://pester.dev)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation)
- [GitHub Actions Workflow](../.github/workflows/pester-tests.yml)

## Contributing

When adding tests:

1. Follow existing patterns
2. Add to appropriate directory (Unit, Integration)
3. Use test helpers where applicable
4. Maintain deterministic execution
5. Keep tests fast (< 100ms)
6. Document complex scenarios
7. Update this README

## Current Status

✅ **147 tests passing** (93 original + 54 new)  
⏭️ **4 tests skipped** (known limitations in existing tests)  
❌ **0 tests failing**  
⏱️ **~3.5s total execution time**  
📊 **Coverage**: Core, Security, Configuration, BestPractices (Syntax, Naming), Formatting (Aliases, Whitespace)  

**Last Updated**: 2025-10-16  
**Version**: 2.0
