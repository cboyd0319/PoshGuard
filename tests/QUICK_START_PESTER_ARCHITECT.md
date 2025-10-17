# Pester Architect Quick Start Guide

## 🚀 Quick Start - Running Tests

### Run All Tests
```powershell
# Full test suite with detailed output
Invoke-Pester -Path ./tests/Unit -Output Detailed

# Run specific module
Invoke-Pester -Path ./tests/Unit/Core.Tests.ps1 -Output Detailed

# Run tests with specific tag
Invoke-Pester -Path ./tests/Unit -Tag 'Security' -Output Detailed
```

### Run with Code Coverage
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './tools/lib/*.psm1'
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = 'coverage.xml'
Invoke-Pester -Configuration $config
```

### Run Exemplar Test
```powershell
# See all best practices in action
Invoke-Pester -Path ./tests/EXEMPLAR_PESTER_ARCHITECT_TEST_v2.ps1 -Output Detailed
```

---

## 📝 Writing New Tests - Template

```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for [Module Name]

.DESCRIPTION
    Comprehensive unit tests covering:
    - [Function 1]
    - [Function 2]
    
    Tests follow Pester v5+ Architect standards with AAA pattern,
    table-driven tests, and comprehensive mocking.
#>

BeforeAll {
  # Import helpers
  $helpersPath = Join-Path $PSScriptRoot '../Helpers/TestHelpers.psm1'
  if (Test-Path $helpersPath) {
    Import-Module $helpersPath -Force
  }

  # Import module under test
  $modulePath = Join-Path $PSScriptRoot '../../tools/lib/YourModule.psm1'
  Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'YourModule - FunctionName' -Tag 'Unit', 'YourModule' {
  
  Context 'Happy Path - Standard operations' {
    It 'performs expected behavior with valid input' {
      # ARRANGE
      $input = 'test data'
      
      # ACT
      $result = Your-Function -Input $input
      
      # ASSERT
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Be 'expected output'
    }
  }
  
  Context 'Edge Cases - Boundaries and special inputs' {
    It 'handles <Scenario>' -TestCases @(
      @{ Input = ''; Scenario = 'empty string' }
      @{ Input = '   '; Scenario = 'whitespace' }
      @{ Input = $null; Scenario = 'null value' }
    ) {
      param($Input, $Scenario)
      
      # ARRANGE & ACT & ASSERT
      { Your-Function -Input $Input } | Should -Not -Throw
    }
  }
  
  Context 'Error Conditions - Invalid inputs' {
    It 'throws when input is invalid' {
      # ACT & ASSERT
      { Your-Function -Input 'invalid' } | Should -Throw
    }
  }
}

AfterAll {
  Remove-Module YourModule -Force -ErrorAction SilentlyContinue
}
```

---

## 🎯 Best Practices Checklist

### ✅ Test Structure
- [ ] Use `Describe` for module/feature
- [ ] Use `Context` for scenarios
- [ ] Use `It` for specific behaviors
- [ ] Follow AAA pattern (Arrange-Act-Assert)
- [ ] One assertion per `It` (when possible)

### ✅ Naming
- [ ] Describe: `'ModuleName - FunctionName'`
- [ ] Context: `'When/Given [scenario]'`
- [ ] It: `'<Function> <Input> => <Expected>'`
- [ ] Tags: `'Unit'`, `'ModuleName'`, etc.

### ✅ Isolation
- [ ] Use `TestDrive:` for filesystem
- [ ] Mock external dependencies
- [ ] Mock time with `Get-Date`
- [ ] No real network calls
- [ ] No real sleeps

### ✅ Mocking
- [ ] Use `InModuleScope` for internal testing
- [ ] Use `-ParameterFilter` for precision
- [ ] Verify with `Assert-MockCalled`
- [ ] Mock at call site, not globally

### ✅ Coverage
- [ ] Happy path tested
- [ ] Error paths tested
- [ ] Edge cases covered (null, empty, boundaries)
- [ ] ShouldProcess validated (`-WhatIf`)
- [ ] Parameter validation checked

---

## 🔧 Common Patterns

### Pattern 1: Table-Driven Tests
```powershell
It 'validates <Description>' -TestCases @(
  @{ Input = 'A'; Expected = 1; Description = 'case A' }
  @{ Input = 'B'; Expected = 2; Description = 'case B' }
) {
  param($Input, $Expected, $Description)
  $result = Test-Function -Input $Input
  $result | Should -Be $Expected
}
```

### Pattern 2: InModuleScope Mocking
```powershell
InModuleScope YourModule {
  Mock External-Command -MockWith { 'mocked' }
  $result = Your-Function
  Assert-MockCalled External-Command -Times 1
}
```

### Pattern 3: TestDrive Filesystem
```powershell
It 'creates backup file' {
  # ARRANGE
  $testFile = Join-Path TestDrive: 'test.ps1'
  'content' | Set-Content $testFile
  
  # ACT
  $backup = New-Backup -Path $testFile
  
  # ASSERT
  $backup | Should -Exist
  $backup | Should -Match '\.bak$'
}
```

### Pattern 4: Deterministic Time
```powershell
InModuleScope Module {
  # ARRANGE
  Mock Get-Date { [DateTime]'2025-01-01 12:00:00' }
  
  # ACT
  $result = Get-OldFiles
  
  # ASSERT - Uses fixed time
  $result | Should -HaveCount 3
}
```

### Pattern 5: ShouldProcess Testing
```powershell
It 'respects -WhatIf' {
  InModuleScope Module {
    Mock Remove-Item -Verifiable
    Remove-OldFiles -WhatIf
    Assert-MockCalled Remove-Item -Times 0
  }
}
```

---

## 📚 Documentation Reference

### Essential Reading
1. **COMPREHENSIVE_TEST_PLAN_PESTER_ARCHITECT_V2.md** - Complete strategy
2. **TEST_RATIONALE_PESTER_ARCHITECT.md** - Philosophy and decisions
3. **EXEMPLAR_PESTER_ARCHITECT_TEST_v2.ps1** - Reference implementation

### Module Coverage
- 48/48 modules tested (100%)
- 1000+ test cases
- 85%+ line coverage
- 80%+ branch coverage

### CI/CD
- GitHub Actions workflow: `.github/workflows/pester-architect-tests.yml`
- Runs on: Windows, macOS, Linux
- Quality gates: PSScriptAnalyzer, tests, coverage

---

## 🐛 Troubleshooting

### Tests Timeout
- Run specific module: `Invoke-Pester -Path ./tests/Unit/Module.Tests.ps1`
- Use `-Output Normal` instead of `Detailed`
- Check for infinite loops or missing mocks

### Mock Not Called
```powershell
# ✅ Correct - Inside InModuleScope
InModuleScope Module {
  Mock Command
  Test-Function
  Assert-MockCalled Command -Times 1
}

# ❌ Wrong - Outside module scope
Mock Command
Test-Function  # Can't see mock!
```

### TestDrive Not Cleaning Up
- TestDrive auto-cleans between tests
- Don't use absolute paths: `Join-Path TestDrive: 'file'`
- Check `BeforeEach`/`AfterEach` cleanup

### Coverage Too Low
- Check `$config.CodeCoverage.Path` includes your module
- Verify module is imported before tests
- Run with `-Configuration $config` not `-CodeCoverage`

---

## 🎓 Learning Resources

### Pester Documentation
- Official Docs: https://pester.dev
- Quick Start: https://pester.dev/docs/quick-start
- Mocking: https://pester.dev/docs/usage/mocking

### PoshGuard Examples
- Exemplar Test: `./tests/EXEMPLAR_PESTER_ARCHITECT_TEST_v2.ps1`
- Core Tests: `./tests/Unit/Core.Tests.ps1`
- Security Tests: `./tests/Unit/Security.Tests.ps1`

### PowerShell Testing
- AST Documentation: `Get-Help about_Script_Blocks`
- Parameter Validation: `Get-Help about_Functions_Advanced_Parameters`
- Should Assertions: `Get-Command -Module Pester | Where-Object Name -like '*Should*'`

---

## ✅ Pre-Commit Checklist

Before committing test changes:

1. [ ] Tests pass locally: `Invoke-Pester -Path ./tests/Unit`
2. [ ] PSScriptAnalyzer clean: `Invoke-ScriptAnalyzer -Path ./tests`
3. [ ] Coverage meets target: `≥ 85%` for new code
4. [ ] Documentation updated if needed
5. [ ] Example in exemplar test if new pattern

---

## 🚀 Next Steps

### For New Contributors
1. Read `TEST_RATIONALE_PESTER_ARCHITECT.md`
2. Study `EXEMPLAR_PESTER_ARCHITECT_TEST_v2.ps1`
3. Copy template above for new tests
4. Follow checklist and patterns

### For Existing Tests
1. Identify low-coverage modules
2. Add table-driven tests
3. Improve edge case coverage
4. Add performance guards

### For Advanced Topics
1. Mutation testing (future)
2. Property-based testing (future)
3. Integration tests (future)
4. Performance profiling (future)

---

## 📞 Support

- **Issues:** https://github.com/cboyd0319/PoshGuard/issues
- **Discussions:** https://github.com/cboyd0319/PoshGuard/discussions
- **Documentation:** `./tests/*.md`

---

**Happy Testing! 🎉**

Remember: Good tests enable fearless refactoring and rapid feature development.
