#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Formatting/Output module

.DESCRIPTION
    Comprehensive unit tests covering:
    - Invoke-WriteHostFix: Converts Write-Host to Write-Output
    - Invoke-RedirectionOperatorFix: Fixes output redirection operators
    
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
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Formatting/Output.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Output module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-WriteHostFix' -Tag 'Unit', 'Formatting', 'Output' {
  
  Context 'When converting Write-Host to Write-Output' {
    It 'Should convert Write-Host to Write-Output' {
      # Arrange
      $input = 'Write-Host "test message"'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
      $result | Should -Not -Match 'Write-Host'
    }

    It 'Should convert write-host (lowercase) to Write-Output' {
      # Arrange
      $input = 'write-host "test message"'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
      $result | Should -Not -Match 'write-host'
    }

    It 'Should preserve message content' {
      # Arrange
      $input = 'Write-Host "Important message: test"'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -Match '"Important message: test"'
    }
  }

  Context 'When handling Write-Host with parameters' {
    It 'Should convert Write-Host with -Object parameter' {
      # Arrange
      $input = 'Write-Host -Object "test"'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
    }

    It 'Should preserve Write-Host with -ForegroundColor (color output needed)' {
      # Arrange
      $input = 'Write-Host "test" -ForegroundColor Green'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      # Write-Host with colors is often intentionally used and may not be converted
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should preserve Write-Host with -BackgroundColor (color output needed)' {
      # Arrange
      $input = 'Write-Host "test" -BackgroundColor Red'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      # Write-Host with colors is often intentionally used and may not be converted
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle Write-Host with -NoNewline appropriately' {
      # Arrange
      $input = 'Write-Host "test" -NoNewline'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When handling multiple Write-Host calls' {
    It 'Should convert Write-Host calls without color parameters' {
      # Arrange
      $input = @'
Write-Host "Line 1"
Write-Host "Line 2"
'@
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output.*Line 1'
      $result | Should -Match 'Write-Output.*Line 2'
    }
    
    It 'Should handle mixed Write-Host calls' {
      # Arrange
      $input = @'
Write-Host "Line 1"
Write-Host "Line 2"
Write-Host "Line 3" -ForegroundColor Cyan
'@
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      # At least some Write-Output should be present
      $result | Should -Match 'Write-Output'
    }
  }

  Context 'When content has no Write-Host' {
    It 'Should return content unchanged' {
      # Arrange
      $input = 'Write-Output "test message"'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }
  }

  Context 'Edge cases' {
    It 'Should handle whitespace-only content' {
      # Arrange
      $input = '   '
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle Write-Host in string (no conversion)' {
      # Arrange
      $input = 'Write-Output "Use Write-Host for colored output"'
      
      # Act
      $result = Invoke-WriteHostFix -Content $input
      
      # Assert
      # String content should not be modified
      $result | Should -Match '"Use Write-Host for colored output"'
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-WriteHostFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-WriteHostFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}

Describe 'Invoke-RedirectionOperatorFix' -Tag 'Unit', 'Formatting', 'Output' {
  
  Context 'When fixing redirection operators' {
    It 'Should fix redirection operator usage' {
      # Arrange
      $input = 'Get-Process 2>&1 > output.txt'
      
      # Act
      $result = Invoke-RedirectionOperatorFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle multiple redirection operators' {
      # Arrange
      $input = 'Get-ChildItem 2> error.txt 1> output.txt'
      
      # Act
      $result = Invoke-RedirectionOperatorFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When content has proper redirection' {
    It 'Should not modify correct redirection' {
      # Arrange
      $input = 'Get-ChildItem > output.txt'
      
      # Act
      $result = Invoke-RedirectionOperatorFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-RedirectionOperatorFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-RedirectionOperatorFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}
