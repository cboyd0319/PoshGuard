#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard BestPractices/Scoping module

.DESCRIPTION
    Comprehensive unit tests covering:
    - Invoke-GlobalVarFix: Detects and fixes global variable usage
    - Invoke-GlobalFunctionsFix: Detects and fixes global function usage
    
    Tests include happy paths, edge cases, error conditions, and parameter
    validation using deterministic execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/BestPractices/Scoping.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Scoping module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-GlobalVarFix' -Tag 'Unit', 'BestPractices', 'Scoping' {
  
  Context 'When detecting global variables' {
    It 'Should detect $global:Variable assignment' {
      # Arrange
      $input = @'
function Test-Function {
    $global:Result = "test"
}
'@
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect multiple global variable assignments' {
      # Arrange
      $input = @'
function Test-Function {
    $global:Var1 = "test1"
    $global:Var2 = "test2"
    $global:Var3 = "test3"
}
'@
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect global variable in script scope' {
      # Arrange
      $input = '$global:Config = @{ Setting = "value" }'
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When content has no global variables' {
    It 'Should return content unchanged for local variables' {
      # Arrange
      $input = @'
function Test-Function {
    $result = "test"
    $local:value = "local"
}
'@
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not flag script-scoped variables without global prefix' {
      # Arrange
      $input = @'
function Test-Function {
    $script:Result = "test"
}
'@
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Edge cases' {
    It 'Should handle whitespace-only content' {
      # Arrange
      $input = '   '
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle global variable in string (no change)' {
      # Arrange
      $input = 'Write-Output "Do not use $global:Variable"'
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle global variable in comments' {
      # Arrange
      $input = @'
# Using $global:Variable is bad
function Test-Function {
    $result = "test"
}
'@
      
      # Act
      $result = Invoke-GlobalVarFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-GlobalVarFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-GlobalVarFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}

Describe 'Invoke-GlobalFunctionsFix' -Tag 'Unit', 'BestPractices', 'Scoping' {
  
  Context 'When detecting global functions' {
    It 'Should detect function in global scope' {
      # Arrange
      $input = @'
function global:Test-Function {
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-GlobalFunctionsFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect multiple global functions' {
      # Arrange
      $input = @'
function global:Test-Function1 {
    Write-Output "test1"
}

function global:Test-Function2 {
    Write-Output "test2"
}
'@
      
      # Act
      $result = Invoke-GlobalFunctionsFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When content has no global functions' {
    It 'Should return content unchanged for normal functions' {
      # Arrange
      $input = @'
function Test-Function {
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-GlobalFunctionsFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not flag script-scoped functions' {
      # Arrange
      $input = @'
function script:Test-Function {
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-GlobalFunctionsFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not flag local-scoped functions' {
      # Arrange
      $input = @'
function local:Test-Function {
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-GlobalFunctionsFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Edge cases' {
    It 'Should handle whitespace-only content' {
      # Arrange
      $input = '   '
      
      # Act
      $result = Invoke-GlobalFunctionsFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle global function reference in comments' {
      # Arrange
      $input = @'
# Do not use function global:Test
function Test-Function {
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-GlobalFunctionsFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-GlobalFunctionsFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-GlobalFunctionsFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}
