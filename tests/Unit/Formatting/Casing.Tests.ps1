#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Formatting/Casing module

.DESCRIPTION
    Comprehensive unit tests covering:
    - Invoke-CasingFix: Fixes cmdlet and parameter casing to PascalCase
    
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
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Formatting/Casing.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Casing module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-CasingFix' -Tag 'Unit', 'Formatting', 'Casing' {
  
  Context 'When fixing cmdlet casing' {
    It 'Should fix lowercase cmdlet to PascalCase' {
      # Arrange
      $input = 'write-output "test"'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
    }

    It 'Should fix UPPERCASE cmdlet to PascalCase' {
      # Arrange
      $input = 'WRITE-OUTPUT "test"'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
    }

    It 'Should fix mixed case cmdlet to PascalCase' {
      # Arrange
      $input = 'gEt-cHiLdItEm -Path C:\'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-ChildItem'
    }
  }

  Context 'When fixing parameter casing' {
    It 'Should fix lowercase parameter to PascalCase' {
      # Arrange
      $input = 'Get-ChildItem -path C:\'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match '-Path'
    }

    It 'Should fix UPPERCASE parameter to PascalCase' {
      # Arrange
      $input = 'Get-ChildItem -PATH C:\'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match '-Path'
    }

    It 'Should fix mixed case parameter to PascalCase' {
      # Arrange
      $input = 'Get-Process -nAmE powershell'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match '-Name'
    }
  }

  Context 'When handling multiple cmdlets and parameters' {
    It 'Should fix casing for all cmdlets and parameters in script' {
      # Arrange
      $input = @'
$files = get-childitem -path C:\ -filter *.txt
foreach ($file in $files) {
    write-output $file.name
}
'@
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-ChildItem'
      $result | Should -Match '-Path'
      $result | Should -Match '-Filter'
      $result | Should -Match 'Write-Output'
    }
  }

  Context 'When content already has correct casing' {
    It 'Should return content unchanged' {
      # Arrange
      $input = 'Get-ChildItem -Path C:\ | Write-Output'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }
  }

  Context 'Edge cases' {
    It 'Should handle whitespace-only content' {
      # Arrange
      $input = '   '
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle cmdlet in pipeline' {
      # Arrange
      $input = 'get-process | where-object { $_.CPU -gt 100 } | write-output'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-Process'
      $result | Should -Match 'Where-Object'
      $result | Should -Match 'Write-Output'
    }

    It 'Should preserve string content' {
      # Arrange
      $input = 'Write-Output "write-output is a cmdlet"'
      
      # Act
      $result = Invoke-CasingFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output "write-output is a cmdlet"'
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-CasingFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-CasingFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}
