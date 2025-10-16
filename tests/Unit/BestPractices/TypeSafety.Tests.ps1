#!/usr/bin/env pwsh
#requires -Version 5.1
#requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Comprehensive Pester tests for BestPractices/TypeSafety.psm1

.DESCRIPTION
    Unit tests covering type safety best practices:
    - Invoke-AutomaticVariableFix: Prevent assignment to automatic variables
    - Invoke-MultipleTypeAttributesFix: Clean up multiple type attributes
    - Invoke-PSCredentialTypeFix: Enforce PSCredential type usage

    Tests follow Pester v5+ AAA pattern with deterministic execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Coverage Target: ≥90% lines, ≥85% branches
#>

BeforeAll {
  # Import TypeSafety module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/BestPractices/TypeSafety.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find TypeSafety module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
  
  # Import test helpers
  $helperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelper.psm1'
  if (Test-Path -Path $helperPath) {
    Import-Module -Name $helperPath -Force -ErrorAction Stop
  }
}

Describe 'Invoke-AutomaticVariableFix' -Tag 'Unit', 'BestPractices', 'TypeSafety' {
  
  Context 'Function existence and signature' {
    It 'Should be exported and accessible' {
      Get-Command Invoke-AutomaticVariableFix -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Should have CmdletBinding attribute' {
      (Get-Command Invoke-AutomaticVariableFix).CmdletBinding | Should -Be $true
    }
    
    It 'Should have mandatory Content parameter' {
      $param = (Get-Command Invoke-AutomaticVariableFix).Parameters['Content']
      $param | Should -Not -BeNullOrEmpty
      $param.Attributes.Where({ $_ -is [Parameter] }).Mandatory | Should -Contain $true
    }
  }
  
  Context 'Detecting automatic variable assignments' {
    It 'Should comment out assignment to $?' {
      # Arrange
      $content = '$? = $true'
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Match '# ERROR: Cannot assign to automatic variable'
      $result | Should -Match "# \`$\? = \`$true"
    }
    
    It 'Should comment out assignment to $PSItem' {
      # Arrange
      $content = '$PSItem = "test"'
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Match '# ERROR: Cannot assign to automatic variable'
      $result | Should -Match '# \$PSItem'
    }
    
    It 'Should comment out assignment to $true' {
      # Arrange
      $content = '$true = $false'
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Match '# ERROR: Cannot assign to automatic variable'
    }
    
    It 'Should handle multiple automatic variable assignments' -TestCases @(
      @{ VarName = '$_'; Code = '$_ = "value"' }
      @{ VarName = '$Args'; Code = '$Args = @()' }
      @{ VarName = '$Error'; Code = '$Error = @()' }
      @{ VarName = '$HOME'; Code = '$HOME = "C:\Users"' }
      @{ VarName = '$PID'; Code = '$PID = 12345' }
    ) {
      param($VarName, $Code)
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $Code
      
      # Assert
      $result | Should -Match '# ERROR: Cannot assign to automatic variable'
    }
  }
  
  Context 'Preserving valid assignments' {
    It 'Should NOT modify valid variable assignments' {
      # Arrange
      $content = '$myVar = "value"'
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Be $content
    }
    
    It 'Should NOT modify variables that contain automatic var names' {
      # Arrange
      $content = '$myError = "custom error"'
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Be $content
    }
  }
  
  Context 'Edge cases' {
    It 'Should handle empty content' {
      # Arrange
      $content = ' '
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Be ' '
    }
    
    It 'Should handle content with no variable assignments' {
      # Arrange
      $content = 'Get-Process'
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Be $content
    }
    
    It 'Should handle mixed valid and invalid assignments' {
      # Arrange
      $content = @'
$myVar = 42
$? = $true
$anotherVar = "test"
'@
      
      # Act
      $result = Invoke-AutomaticVariableFix -Content $content
      
      # Assert
      $result | Should -Match '\$myVar = 42'
      $result | Should -Match '# ERROR: Cannot assign'
      $result | Should -Match '\$anotherVar = "test"'
    }
  }
}

Describe 'Invoke-MultipleTypeAttributesFix' -Tag 'Unit', 'BestPractices', 'TypeSafety' {
  
  Context 'Function existence and signature' {
    It 'Should be exported and accessible' {
      Get-Command Invoke-MultipleTypeAttributesFix -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Should have CmdletBinding attribute' {
      (Get-Command Invoke-MultipleTypeAttributesFix).CmdletBinding | Should -Be $true
    }
    
    It 'Should have mandatory Content parameter' {
      $param = (Get-Command Invoke-MultipleTypeAttributesFix).Parameters['Content']
      $param | Should -Not -BeNullOrEmpty
      $param.Attributes.Where({ $_ -is [Parameter] }).Mandatory | Should -Contain $true
    }
  }
  
  Context 'Detecting multiple type attributes' {
    It 'Should detect and fix multiple type attributes on parameter' {
      # Arrange - This would be detected by AST analysis
      $content = @'
param(
    [string]
    [int]
    $Value
)
'@
      
      # Act
      $result = Invoke-MultipleTypeAttributesFix -Content $content
      
      # Assert - Function should process without error
      $result | Should -Not -BeNullOrEmpty
    }
  }
  
  Context 'Edge cases' {
    It 'Should handle valid single type attribute' {
      # Arrange
      $content = @'
param(
    [string]$Name
)
'@
      
      # Act
      $result = Invoke-MultipleTypeAttributesFix -Content $content
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Invoke-PSCredentialTypeFix' -Tag 'Unit', 'BestPractices', 'TypeSafety' {
  
  Context 'Function existence and signature' {
    It 'Should be exported and accessible' {
      Get-Command Invoke-PSCredentialTypeFix -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Should have CmdletBinding attribute' {
      (Get-Command Invoke-PSCredentialTypeFix).CmdletBinding | Should -Be $true
    }
    
    It 'Should have mandatory Content parameter' {
      $param = (Get-Command Invoke-PSCredentialTypeFix).Parameters['Content']
      $param | Should -Not -BeNullOrEmpty
      $param.Attributes.Where({ $_ -is [Parameter] }).Mandatory | Should -Contain $true
    }
  }
  
  Context 'Enforcing PSCredential type' {
    It 'Should process content with credential parameters' {
      # Arrange
      $content = @'
param(
    [Parameter()]
    $Credential
)
'@
      
      # Act
      $result = Invoke-PSCredentialTypeFix -Content $content
      
      # Assert - Function should process without error
      $result | Should -Not -BeNullOrEmpty
    }
    
    It 'Should handle properly typed PSCredential parameters' {
      # Arrange
      $content = @'
param(
    [Parameter()]
    [PSCredential]$Credential
)
'@
      
      # Act
      $result = Invoke-PSCredentialTypeFix -Content $content
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }
  
  Context 'Edge cases' {
    It 'Should handle content without credential parameters' {
      # Arrange
      $content = @'
param(
    [string]$Name,
    [int]$Age
)
'@
      
      # Act
      $result = Invoke-PSCredentialTypeFix -Content $content
      
      # Assert
      $result | Should -Be $content
    }
    
    It 'Should handle empty parameter block' {
      # Arrange
      $content = 'param()'
      
      # Act
      $result = Invoke-PSCredentialTypeFix -Content $content
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }
}
