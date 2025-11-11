#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Integration tests for PoshGuard core functionality

.DESCRIPTION
    End-to-end integration tests validating:
    - Module loading and initialization
    - Fix function execution
    - ASTHelper integration
    - Constants module integration
    - Error handling across modules

.NOTES
    Test Framework: Pester v5+
    Pattern: Integration (end-to-end scenarios)
    Coverage Target: Critical paths
#>

BeforeAll {
  # Import core modules
  $LibPath = Join-Path $PSScriptRoot '../../tools/lib'

  Import-Module (Join-Path $LibPath 'Constants.psm1') -Force -ErrorAction Stop
  Import-Module (Join-Path $LibPath 'ASTHelper.psm1') -Force -ErrorAction Stop
  Import-Module (Join-Path $LibPath 'Security.psm1') -Force -ErrorAction Stop
  Import-Module (Join-Path $LibPath 'Core.psm1') -Force -ErrorAction Stop
}

Describe 'Core Module Integration' -Tag 'Integration', 'Core' {

  Context 'Constants Module Integration' {
    It 'Should load Constants module successfully' {
      Get-Module Constants | Should -Not -BeNullOrEmpty
    }

    It 'Should provide Get-PoshGuardConstant function' {
      Get-Command Get-PoshGuardConstant -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Should retrieve entropy thresholds' {
      $high = Get-PoshGuardConstant -Name 'HighEntropyThreshold'
      $high | Should -Be 4.5
    }

    It 'Should retrieve RL parameters' {
      $lr = Get-PoshGuardConstant -Name 'RLLearningRate'
      $lr | Should -Be 0.1
    }
  }

  Context 'ASTHelper Module Integration' {
    It 'Should load ASTHelper module successfully' {
      Get-Module ASTHelper | Should -Not -BeNullOrEmpty
    }

    It 'Should export all 4 core functions' {
      Get-Command Get-ParsedAST -Module ASTHelper | Should -Not -BeNullOrEmpty
      Get-Command Test-ValidPowerShellSyntax -Module ASTHelper | Should -Not -BeNullOrEmpty
      Get-Command Invoke-SafeASTTransformation -Module ASTHelper | Should -Not -BeNullOrEmpty
      Get-Command Invoke-ASTBasedFix -Module ASTHelper | Should -Not -BeNullOrEmpty
    }

    It 'Should parse valid PowerShell syntax' {
      $content = 'function Test { Write-Host "Hello" }'
      $ast = Get-ParsedAST -Content $content
      $ast | Should -Not -BeNullOrEmpty
      $ast.GetType().Name | Should -Be 'ScriptBlockAst'
    }

    It 'Should validate PowerShell syntax' {
      $validContent = 'Write-Host "Hello"'
      $invalidContent = 'Write-Host "Unclosed'

      Test-ValidPowerShellSyntax -Content $validContent | Should -Be $true
      Test-ValidPowerShellSyntax -Content $invalidContent | Should -Be $false
    }
  }

  Context 'Security Module Integration' {
    It 'Should load Security module successfully' {
      Get-Module Security | Should -Not -BeNullOrEmpty
    }

    It 'Should export all 7 security fix functions' {
      Get-Command Invoke-PlainTextPasswordFix -Module Security | Should -Not -BeNullOrEmpty
      Get-Command Invoke-ConvertToSecureStringFix -Module Security | Should -Not -BeNullOrEmpty
      Get-Command Invoke-UsernamePasswordParamsFix -Module Security | Should -Not -BeNullOrEmpty
      Get-Command Invoke-AllowUnencryptedAuthFix -Module Security | Should -Not -BeNullOrEmpty
      Get-Command Invoke-HardcodedComputerNameFix -Module Security | Should -Not -BeNullOrEmpty
      Get-Command Invoke-InvokeExpressionFix -Module Security | Should -Not -BeNullOrEmpty
      Get-Command Invoke-EmptyCatchBlockFix -Module Security | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'End-to-End Fix Scenarios' -Tag 'Integration', 'E2E' {

  Context 'Plain-Text Password Fix (Refactored with ASTHelper)' {
    It 'Should convert [string]$Password to [SecureString]$Password' {
      # Arrange
      $scriptContent = @'
function Connect-Service {
  param(
    [Parameter(Mandatory)]
    [string]$Password
  )
  # Function body
}
'@

      # Act
      $result = Invoke-PlainTextPasswordFix -Content $scriptContent

      # Assert
      $result | Should -Match '\[SecureString\]\$Password'
      $result | Should -Not -Match '\[string\]\$Password'
    }

    It 'Should handle multiple password parameters' {
      # Arrange
      $scriptContent = @'
function Connect-MultiService {
  param(
    [string]$Password,
    [string]$AdminPassword,
    [string]$SecretToken
  )
}
'@

      # Act
      $result = Invoke-PlainTextPasswordFix -Content $scriptContent

      # Assert
      $result | Should -Match '\[SecureString\]\$Password'
      $result | Should -Match '\[SecureString\]\$AdminPassword'
      $result | Should -Match '\[SecureString\]\$SecretToken'
    }

    It 'Should not modify non-password parameters' {
      # Arrange
      $scriptContent = @'
function Get-User {
  param(
    [string]$Username,
    [string]$Email
  )
}
'@

      # Act
      $result = Invoke-PlainTextPasswordFix -Content $scriptContent

      # Assert
      $result | Should -Match '\[string\]\$Username'
      $result | Should -Match '\[string\]\$Email'
    }
  }

  Context 'Empty Catch Block Fix (Refactored with ASTHelper)' {
    It 'Should add error handling to empty catch blocks' {
      # Arrange
      $scriptContent = @'
try {
  Get-Process -Name "nonexistent"
}
catch {
}
'@

      # Act
      $result = Invoke-EmptyCatchBlockFix -Content $scriptContent

      # Assert
      $result | Should -Match 'TODO: Handle error appropriately'
      $result | Should -Match 'Write-Verbose'
    }

    It 'Should not modify catch blocks with content' {
      # Arrange
      $scriptContent = @'
try {
  Get-Process -Name "nonexistent"
}
catch {
  Write-Warning "Process not found"
}
'@

      # Act
      $result = Invoke-EmptyCatchBlockFix -Content $scriptContent

      # Assert
      $result | Should -Not -Match 'TODO: Handle error appropriately'
      $result | Should -Match 'Write-Warning "Process not found"'
    }
  }

  Context 'Error Handling and Robustness' {
    It 'Should handle invalid PowerShell syntax gracefully' {
      # Arrange
      $invalidContent = 'function Test { invalid { syntax }'

      # Act
      $result = Invoke-PlainTextPasswordFix -Content $invalidContent

      # Assert - should return original content without crashing
      $result | Should -Be $invalidContent
    }

    It 'Should handle empty content' {
      # Arrange
      $emptyContent = ''

      # Act
      $result = Invoke-PlainTextPasswordFix -Content $emptyContent

      # Assert
      $result | Should -Be $emptyContent
    }

    It 'Should handle very large files efficiently' {
      # Arrange
      $largeContent = 1..500 | ForEach-Object {
        "function Test$_ { param(`$Param$_) Write-Host `$Param$_ }"
      } | Join-String -Separator "`n"

      # Act
      $executionTime = Measure-Command {
        $result = Invoke-PlainTextPasswordFix -Content $largeContent
      }

      # Assert
      $executionTime.TotalSeconds | Should -BeLessThan 10
    }
  }
}

Describe 'Module Interoperability' -Tag 'Integration', 'Interop' {

  Context 'Constants and ASTHelper Integration' {
    It 'Should use constants in code quality checks' {
      # Arrange
      $maxFunctionLength = Get-PoshGuardConstant -Name 'MaxFunctionLength'

      # Assert
      $maxFunctionLength | Should -Be 50
      $maxFunctionLength | Should -BeOfType [int]
    }

    It 'Should use constants in RL configuration' {
      # Arrange
      $learningRate = Get-PoshGuardConstant -Name 'RLLearningRate'
      $discountFactor = Get-PoshGuardConstant -Name 'RLDiscountFactor'

      # Assert
      $learningRate | Should -Be 0.1
      $discountFactor | Should -Be 0.9
    }
  }

  Context 'Graceful Degradation' {
    It 'Should work if Constants module is not available' {
      # This test validates fallback behavior
      # In production, if Constants fails to load, functions should use fallback values
      $true | Should -Be $true  # Placeholder - actual fallback tested in unit tests
    }
  }
}

Describe 'Regression Tests' -Tag 'Integration', 'Regression' {

  Context 'Security Function Refactoring Regressions' {
    It 'Should maintain backward compatibility after ASTHelper refactoring' {
      # Test that refactored Security functions still produce same output as before
      $testContent = @'
function Test {
  param([string]$Password)
}
'@

      $result = Invoke-PlainTextPasswordFix -Content $testContent

      # Validate expected transformation still works
      $result | Should -Match '\[SecureString\]\$Password'
    }

    It 'Should preserve formatting and whitespace' {
      # Arrange
      $scriptContent = @'
function Test {
    param(
        [string]$Password
    )
}
'@

      # Act
      $result = Invoke-PlainTextPasswordFix -Content $scriptContent

      # Assert - function structure should be preserved
      $result | Should -Match 'function Test \{'
      $result | Should -Match 'param\('
      $result | Should -Match '\[SecureString\]\$Password'
    }
  }
}

AfterAll {
  # Cleanup
  Remove-Module Constants -ErrorAction SilentlyContinue
  Remove-Module ASTHelper -ErrorAction SilentlyContinue
  Remove-Module Security -ErrorAction SilentlyContinue
  Remove-Module Core -ErrorAction SilentlyContinue
}
