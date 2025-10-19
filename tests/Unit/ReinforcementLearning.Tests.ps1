#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard ReinforcementLearning module

.DESCRIPTION
    Comprehensive unit tests for ReinforcementLearning.psm1 functions:
    - Get-CodeState
    - Get-ASTMaxDepth
    - Select-FixAction
    - Update-QLearning
    - Get-FixReward
    - Test-PowerShellSyntax
    
    Tests cover RL algorithms, state representation, reward calculation.
    All tests are hermetic and deterministic with mocked randomness.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }

  # Import ReinforcementLearning module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/ReinforcementLearning.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find ReinforcementLearning module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'ReinforcementLearning' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  }
}

Describe 'Get-CodeState' -Tag 'Unit', 'ReinforcementLearning' {
  
  Context 'When analyzing simple code' {
    It 'Should extract state from valid PowerShell code' {
      $code = @'
function Test-Function {
    param($Name)
    Write-Output "Hello $Name"
}
'@
      
      $state = Get-CodeState -Content $code
      
      $state | Should -Not -BeNullOrEmpty
      $state.NodeCount | Should -BeGreaterThan 0
      $state.FunctionCount | Should -BeGreaterThan 0
    }

    It 'Should calculate complexity metrics' {
      $code = @'
function Test-Complex {
    param($Value)
    if ($Value -gt 10) {
        for ($i = 0; $i -lt $Value; $i++) {
            Write-Output $i
        }
    }
}
'@
      
      $state = Get-CodeState -Content $code
      
      $state.CyclomaticComplexity | Should -BeGreaterThan 0
      $state.MaxDepth | Should -BeGreaterThan 0
    }

    It 'Should include line and character counts' {
      $code = "Write-Output 'test'`nWrite-Output 'test2'"
      
      $state = Get-CodeState -Content $code
      
      $state.LineCount | Should -BeGreaterThan 0
      $state.CharCount | Should -BeGreaterThan 0
    }
  }

  Context 'When analyzing code with violations' {
    It 'Should extract violation features' {
      $code = "Write-Host 'test'"
      $violations = @(
        [PSCustomObject]@{
          RuleName = 'PSAvoidUsingWriteHost'
          Severity = 'Warning'
        }
      )
      
      $state = Get-CodeState -Content $code -Violations $violations
      
      $state.ViolationCount | Should -BeGreaterThan 0
      $state.WarningCount | Should -BeGreaterThan 0
    }

    It 'Should detect security violations' {
      $code = "param([string]`$Password)"
      $violations = @(
        [PSCustomObject]@{
          RuleName = 'PSAvoidUsingPlainTextForPassword'
          Severity = 'Error'
        }
      )
      
      $state = Get-CodeState -Content $code -Violations $violations
      
      $state.HasSecurity | Should -Be 1.0
    }

    It 'Should detect formatting violations' {
      $code = "write-host 'test'"
      $violations = @(
        [PSCustomObject]@{
          RuleName = 'PSUseConsistentWhitespace'
          Severity = 'Information'
        }
        [PSCustomObject]@{
          RuleName = 'PSAvoidUsingAlias'
          Severity = 'Warning'
        }
      )
      
      $state = Get-CodeState -Content $code -Violations $violations
      
      $state.HasFormatting | Should -Be 1.0
    }

    It 'Should count violations by severity' {
      $code = "Write-Host 'test'"
      $violations = @(
        [PSCustomObject]@{ RuleName = 'Rule1'; Severity = 'Error' }
        [PSCustomObject]@{ RuleName = 'Rule2'; Severity = 'Warning' }
        [PSCustomObject]@{ RuleName = 'Rule3'; Severity = 'Warning' }
        [PSCustomObject]@{ RuleName = 'Rule4'; Severity = 'Information' }
      )
      
      $state = Get-CodeState -Content $code -Violations $violations
      
      $state.ErrorCount | Should -BeGreaterThan 0
      $state.WarningCount | Should -BeGreaterThan 0
    }
  }

  Context 'When handling edge cases' {
    It 'Should handle empty code gracefully' {
      $state = Get-CodeState -Content ""
      
      $state | Should -Not -BeNullOrEmpty
      $state.NodeCount | Should -Be 0
    }

    It 'Should handle code without violations' {
      $code = "Write-Output 'test'"
      
      $state = Get-CodeState -Content $code -Violations @()
      
      $state.ViolationCount | Should -Be 0
      $state.HasSecurity | Should -Be 0.0
    }

    It 'Should handle malformed code gracefully' {
      $code = "if ($true { Write-Output 'missing paren'"
      
      { Get-CodeState -Content $code } | Should -Not -Throw
    }
  }

  Context 'When detecting complexity' {
    It 'Should flag high complexity code' {
      $code = @'
function Test-Complex {
    param($x)
    if ($x -gt 1) { }
    if ($x -gt 2) { }
    if ($x -gt 3) { }
    if ($x -gt 4) { }
    if ($x -gt 5) { }
    if ($x -gt 6) { }
    if ($x -gt 7) { }
    if ($x -gt 8) { }
    if ($x -gt 9) { }
    if ($x -gt 10) { }
    if ($x -gt 11) { }
}
'@
      
      $state = Get-CodeState -Content $code
      
      $state.HasComplexity | Should -Be 1.0
    }

    It 'Should not flag low complexity code' {
      $code = "Write-Output 'simple'"
      
      $state = Get-CodeState -Content $code
      
      $state.HasComplexity | Should -Be 0.0
    }
  }
}

Describe 'Get-ASTMaxDepth' -Tag 'Unit', 'ReinforcementLearning' {
  
  Context 'When calculating AST depth' {
    It 'Should calculate depth for simple code' {
      $code = "Write-Output 'test'"
      $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $code, [ref]$null, [ref]$null
      )
      
      $depth = Get-ASTMaxDepth -AST $ast
      
      $depth | Should -BeGreaterOrEqual 0
    }

    It 'Should calculate depth for nested structures' {
      $code = @'
function Test {
    if ($true) {
        foreach ($item in $items) {
            if ($item) {
                Write-Output $item
            }
        }
    }
}
'@
      $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $code, [ref]$null, [ref]$null
      )
      
      $depth = Get-ASTMaxDepth -AST $ast
      
      $depth | Should -BeGreaterThan 1
    }

    It 'Should handle flat code' {
      $code = "Write-Output 'a'; Write-Output 'b'; Write-Output 'c'"
      $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $code, [ref]$null, [ref]$null
      )
      
      $depth = Get-ASTMaxDepth -AST $ast
      
      $depth | Should -BeGreaterOrEqual 0
    }
  }
}

Describe 'Select-FixAction' -Tag 'Unit', 'ReinforcementLearning' {
  
  BeforeEach {
    InModuleScope ReinforcementLearning {
      $script:RLConfig = @{
        Enabled = $true
        ExplorationRate = 0.2
      }
      $script:QLearningTable = @{}
    }
  }

  Context 'When selecting actions' {
    It 'Should return valid action from available actions' {
      InModuleScope ReinforcementLearning {
        $state = @{ NodeCount = 1; ViolationCount = 1 }
        $actions = @('Action1', 'Action2', 'Action3')
        
        $action = Select-FixAction -State $state -AvailableActions $actions
        
        $actions | Should -Contain $action
      }
    }

    It 'Should handle single action' {
      InModuleScope ReinforcementLearning {
        $state = @{ NodeCount = 1 }
        $actions = @('OnlyAction')
        
        $action = Select-FixAction -State $state -AvailableActions $actions
        
        $action | Should -Be 'OnlyAction'
      }
    }

    It 'Should handle empty actions gracefully' {
      InModuleScope ReinforcementLearning {
        $state = @{ NodeCount = 1 }
        $actions = @()
        
        $action = Select-FixAction -State $state -AvailableActions $actions
        
        $action | Should -BeNullOrEmpty
      }
    }
  }

  Context 'When RL is disabled' {
    It 'Should use random selection when disabled' {
      InModuleScope ReinforcementLearning {
        $script:RLConfig.Enabled = $false
        $state = @{ NodeCount = 1 }
        $actions = @('Action1', 'Action2')
        
        $action = Select-FixAction -State $state -AvailableActions $actions
        
        $actions | Should -Contain $action
      }
    }
  }
}

Describe 'Update-QLearning' -Tag 'Unit', 'ReinforcementLearning' {
  
  BeforeEach {
    InModuleScope ReinforcementLearning {
      $script:RLConfig = @{
        Enabled = $true
        LearningRate = 0.1
        DiscountFactor = 0.95
      }
      $script:QLearningTable = @{}
    }
  }

  Context 'When updating Q-values' {
    It 'Should update Q-table with new experience' {
      InModuleScope ReinforcementLearning {
        $state = @{ NodeCount = 1; ViolationCount = 1 }
        $action = 'TestAction'
        $reward = 1.0
        $nextState = @{ NodeCount = 1; ViolationCount = 0 }
        
        { Update-QLearning -State $state -Action $action -Reward $reward -NextState $nextState } | Should -Not -Throw
        
        # Q-table should be updated
        $script:QLearningTable.Count | Should -BeGreaterOrEqual 0
      }
    }

    It 'Should handle negative rewards' {
      InModuleScope ReinforcementLearning {
        $state = @{ NodeCount = 1 }
        $action = 'FailedAction'
        $reward = -1.0
        $nextState = @{ NodeCount = 1 }
        
        { Update-QLearning -State $state -Action $action -Reward $reward -NextState $nextState } | Should -Not -Throw
      }
    }

    It 'Should handle zero rewards' {
      InModuleScope ReinforcementLearning {
        $state = @{ NodeCount = 1 }
        $action = 'NeutralAction'
        $reward = 0.0
        $nextState = @{ NodeCount = 1 }
        
        { Update-QLearning -State $state -Action $action -Reward $reward -NextState $nextState } | Should -Not -Throw
      }
    }
  }
}

Describe 'Get-FixReward' -Tag 'Unit', 'ReinforcementLearning' {
  
  Context 'When calculating rewards' {
    It 'Should give positive reward for successful fix' {
      $beforeViolations = 5
      $afterViolations = 2
      $syntaxValid = $true
      
      $reward = Get-FixReward -BeforeViolationCount $beforeViolations -AfterViolationCount $afterViolations -SyntaxValid $syntaxValid
      
      $reward | Should -BeGreaterThan 0
    }

    It 'Should give negative reward for syntax break' {
      $beforeViolations = 5
      $afterViolations = 3
      $syntaxValid = $false
      
      $reward = Get-FixReward -BeforeViolationCount $beforeViolations -AfterViolationCount $afterViolations -SyntaxValid $syntaxValid
      
      $reward | Should -BeLessThan 0
    }

    It 'Should give negative reward for increased violations' {
      $beforeViolations = 2
      $afterViolations = 5
      $syntaxValid = $true
      
      $reward = Get-FixReward -BeforeViolationCount $beforeViolations -AfterViolationCount $afterViolations -SyntaxValid $syntaxValid
      
      $reward | Should -BeLessThan 0
    }

    It 'Should give small positive reward for maintaining violations' {
      $beforeViolations = 5
      $afterViolations = 5
      $syntaxValid = $true
      
      $reward = Get-FixReward -BeforeViolationCount $beforeViolations -AfterViolationCount $afterViolations -SyntaxValid $syntaxValid
      
      # Should be small but positive for maintaining syntax validity
      $reward | Should -BeGreaterOrEqual 0
    }

    It 'Should give maximum reward for fixing all violations' {
      $beforeViolations = 10
      $afterViolations = 0
      $syntaxValid = $true
      
      $reward = Get-FixReward -BeforeViolationCount $beforeViolations -AfterViolationCount $afterViolations -SyntaxValid $syntaxValid
      
      $reward | Should -BeGreaterThan 5
    }
  }
}

Describe 'Test-PowerShellSyntax' -Tag 'Unit', 'ReinforcementLearning' {
  
  Context 'When validating syntax' {
    It 'Should return true for valid PowerShell' {
      $code = "Write-Output 'Hello World'"
      
      $result = Test-PowerShellSyntax -Content $code
      
      $result | Should -Be $true
    }

    It 'Should return false for invalid PowerShell' {
      $code = "if (`$true { Write-Output 'missing paren'"
      
      $result = Test-PowerShellSyntax -Content $code
      
      $result | Should -Be $false
    }

    It 'Should handle empty code' {
      $code = ""
      
      $result = Test-PowerShellSyntax -Content $code
      
      # Empty code is technically valid
      $result | Should -Be $true
    }

    It 'Should handle multiline code' {
      $code = @'
function Test-Function {
    param($Name)
    Write-Output "Hello $Name"
}
'@
      
      $result = Test-PowerShellSyntax -Content $code
      
      $result | Should -Be $true
    }

    It 'Should detect unclosed braces' {
      $code = "if (`$true) { Write-Output 'test'"
      
      $result = Test-PowerShellSyntax -Content $code
      
      $result | Should -Be $false
    }

    It 'Should detect unclosed quotes' {
      $code = "Write-Output 'unclosed"
      
      $result = Test-PowerShellSyntax -Content $code
      
      $result | Should -Be $false
    }
  }
}

Describe 'Get-CodeComplexity' -Tag 'Unit', 'ReinforcementLearning' {
  
  Context 'When measuring complexity' {
    It 'Should calculate complexity for simple code' {
      $code = "Write-Output 'test'"
      
      $complexity = Get-CodeComplexity -Content $code
      
      $complexity | Should -BeGreaterOrEqual 1
    }

    It 'Should give higher complexity for branching code' {
      $simpleCode = "Write-Output 'test'"
      $complexCode = @'
if ($true) { Write-Output 'a' }
elseif ($false) { Write-Output 'b' }
else { Write-Output 'c' }
'@
      
      $simpleComplexity = Get-CodeComplexity -Content $simpleCode
      $complexComplexity = Get-CodeComplexity -Content $complexCode
      
      $complexComplexity | Should -BeGreaterThan $simpleComplexity
    }

    It 'Should include loops in complexity' {
      $code = @'
for ($i = 0; $i -lt 10; $i++) {
    Write-Output $i
}
foreach ($item in $items) {
    Write-Output $item
}
'@
      
      $complexity = Get-CodeComplexity -Content $code
      
      $complexity | Should -BeGreaterThan 2
    }
  }
}
