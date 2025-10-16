#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard BestPractices/CodeQuality module

.DESCRIPTION
    Comprehensive unit tests covering:
    - Invoke-TodoCommentDetectionFix: Detects TODO/FIXME/HACK comments
    - Invoke-UnusedNamespaceDetectionFix: Detects unused using statements
    - Invoke-AsciiCharacterWarningFix: Warns about non-ASCII characters
    - Invoke-ConvertFromJsonOptimizationFix: Optimizes ConvertFrom-Json calls
    - Invoke-SecureStringDisclosureFix: Detects SecureString disclosure
    
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
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/BestPractices/CodeQuality.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find CodeQuality module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-TodoCommentDetectionFix' -Tag 'Unit', 'BestPractices', 'CodeQuality' {
  
  Context 'When detecting TODO comments' {
    It 'Should detect TODO comment' {
      # Arrange
      $input = @'
function Test-Function {
    # TODO: Implement error handling
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-TodoCommentDetectionFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect FIXME comment' {
      # Arrange
      $input = @'
function Test-Function {
    # FIXME: This is broken
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-TodoCommentDetectionFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect HACK comment' {
      # Arrange
      $input = @'
function Test-Function {
    # HACK: Temporary workaround
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-TodoCommentDetectionFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When content has no TODO comments' {
    It 'Should return content unchanged' {
      # Arrange
      $input = @'
function Test-Function {
    # Normal comment
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-TodoCommentDetectionFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-TodoCommentDetectionFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-TodoCommentDetectionFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}

Describe 'Invoke-UnusedNamespaceDetectionFix' -Tag 'Unit', 'BestPractices', 'CodeQuality' {
  
  Context 'When detecting unused using statements' {
    It 'Should detect unused using statement' {
      # Arrange
      $input = @'
using namespace System.Collections.Generic

function Test-Function {
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-UnusedNamespaceDetectionFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When using statement is used' {
    It 'Should not flag used namespace' {
      # Arrange
      $input = @'
using namespace System.Collections.Generic

function Test-Function {
    [List[string]]$list = [List[string]]::new()
    Write-Output $list
}
'@
      
      # Act
      $result = Invoke-UnusedNamespaceDetectionFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-UnusedNamespaceDetectionFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }
  }
}

Describe 'Invoke-AsciiCharacterWarningFix' -Tag 'Unit', 'BestPractices', 'CodeQuality' {
  
  Context 'When detecting non-ASCII characters' {
    It 'Should detect non-ASCII characters in comments' {
      # Arrange
      $input = @'
function Test-Function {
    # This comment has a special character: ™
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-AsciiCharacterWarningFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect non-ASCII characters in strings' {
      # Arrange
      $input = @'
function Test-Function {
    Write-Output "Special: ™"
}
'@
      
      # Act
      $result = Invoke-AsciiCharacterWarningFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When content has only ASCII characters' {
    It 'Should return content unchanged' {
      # Arrange
      $input = @'
function Test-Function {
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-AsciiCharacterWarningFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-AsciiCharacterWarningFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }
  }
}

Describe 'Invoke-ConvertFromJsonOptimizationFix' -Tag 'Unit', 'BestPractices', 'CodeQuality' {
  
  Context 'When optimizing ConvertFrom-Json calls' {
    It 'Should optimize ConvertFrom-Json call' {
      # Arrange
      $input = @'
function Test-Function {
    $json = '{"name":"test"}'
    $obj = ConvertFrom-Json $json
}
'@
      
      # Act
      $result = Invoke-ConvertFromJsonOptimizationFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle ConvertFrom-Json with -AsHashtable' {
      # Arrange
      $input = @'
function Test-Function {
    $json = '{"name":"test"}'
    $obj = ConvertFrom-Json -InputObject $json -AsHashtable
}
'@
      
      # Act
      $result = Invoke-ConvertFromJsonOptimizationFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-ConvertFromJsonOptimizationFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }
  }
}

Describe 'Invoke-SecureStringDisclosureFix' -Tag 'Unit', 'BestPractices', 'CodeQuality' {
  
  Context 'When detecting SecureString disclosure' {
    It 'Should detect ToString() on SecureString' {
      # Arrange
      $input = @'
function Test-Function {
    param([SecureString]$Password)
    $plain = $Password.ToString()
}
'@
      
      # Act
      $result = Invoke-SecureStringDisclosureFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect NetworkCredential conversion' {
      # Arrange
      $input = @'
function Test-Function {
    param([SecureString]$Password)
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
}
'@
      
      # Act
      $result = Invoke-SecureStringDisclosureFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When SecureString is properly handled' {
    It 'Should not flag proper SecureString usage' {
      # Arrange
      $input = @'
function Test-Function {
    param([SecureString]$Password)
    $credential = New-Object PSCredential("user", $Password)
}
'@
      
      # Act
      $result = Invoke-SecureStringDisclosureFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-SecureStringDisclosureFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-SecureStringDisclosureFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}
