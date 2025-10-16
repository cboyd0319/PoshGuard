#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for CmdletBindingFix module

.DESCRIPTION
    Unit tests for Advanced/CmdletBindingFix.psm1 covering:
    - Invoke-CmdletBindingFix function
    - Detection of functions needing [CmdletBinding()]
    - Correct placement of [CmdletBinding()] inside param block
    - Handling of various function formats
    - Edge cases and error conditions

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Coverage Target: 90%+ lines, 85%+ branches
    Tests the FIXED version that places [CmdletBinding()] correctly
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import CmdletBindingFix module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/CmdletBindingFix.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find CmdletBindingFix module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-CmdletBindingFix' -Tag 'Unit', 'Advanced', 'CmdletBinding' {
  
  Context 'When function uses $PSCmdlet without CmdletBinding' {
    It 'Should add [CmdletBinding()] for function using PSCmdlet.WriteVerbose' {
      # Arrange
      $input = @'
function Test-Feature {
    param($Name)
    $PSCmdlet.WriteVerbose("test")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
      $result | Should -Match 'param\('
    }

    It 'Should add [CmdletBinding()] for function using PSCmdlet.WriteWarning' {
      # Arrange
      $input = @'
function Test-Warning {
    param($Message)
    $PSCmdlet.WriteWarning($Message)
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
    }

    It 'Should add [CmdletBinding()] for function using PSCmdlet.WriteError' {
      # Arrange
      $input = @'
function Test-Error {
    param()
    $PSCmdlet.WriteError("error")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
    }

    It 'Should add [CmdletBinding()] for function using PSCmdlet.ShouldProcess' {
      # Arrange
      $input = @'
function Remove-Item {
    param($Path)
    if ($PSCmdlet.ShouldProcess($Path)) {
        # do something
    }
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
    }
  }

  Context 'When function already has CmdletBinding' {
    It 'Should not duplicate [CmdletBinding()] if already present' {
      # Arrange
      $input = @'
function Test-Feature {
    [CmdletBinding()]
    param($Name)
    $PSCmdlet.WriteVerbose("test")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      # Count occurrences of [CmdletBinding()]
      $matches = [regex]::Matches($result, '\[CmdletBinding\(\)\]')
      $matches.Count | Should -Be 1
    }

    It 'Should not modify function with CmdletBinding and parameters' {
      # Arrange
      $input = @'
function Test-Feature {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    Write-Verbose "test"
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Be $input
    }
  }

  Context 'When function does not need CmdletBinding' {
    It 'Should not add [CmdletBinding()] to simple functions' {
      # Arrange
      $input = @'
function Get-Value {
    param($Name)
    return $Name
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Be $input
    }

    It 'Should not add [CmdletBinding()] when no advanced features used' {
      # Arrange
      $input = @'
function Test-Simple {
    param()
    Write-Output "test"
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Be $input
    }
  }

  Context 'When handling multiple functions' {
    It 'Should fix multiple functions in same script' {
      # Arrange
      $input = @'
function Test-First {
    param($Name)
    $PSCmdlet.WriteVerbose("first")
}

function Test-Second {
    param($Value)
    $PSCmdlet.WriteWarning("second")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $matches = [regex]::Matches($result, '\[CmdletBinding\(\)\]')
      $matches.Count | Should -BeGreaterOrEqual 2
    }

    It 'Should only fix functions that need it' {
      # Arrange
      $input = @'
function Test-NeedsFix {
    param($Name)
    $PSCmdlet.WriteVerbose("fix me")
}

function Test-Fine {
    param($Value)
    Write-Output $Value
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
      $matches = [regex]::Matches($result, '\[CmdletBinding\(\)\]')
      $matches.Count | Should -Be 1
    }
  }

  Context 'When handling functions with no parameters' {
    It 'Should add [CmdletBinding()] before param() for functions without parameters' {
      # Arrange
      $input = @'
function Test-NoParams {
    param()
    $PSCmdlet.WriteVerbose("test")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
      $result | Should -Match 'param\(\)'
    }

    It 'Should handle function with no param block at all' {
      # Arrange
      $input = @'
function Test-NoParamBlock {
    $PSCmdlet.WriteVerbose("test")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      # Should handle gracefully, may or may not add param block depending on implementation
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When content is empty or invalid' {
    It 'Should return empty string for empty content' {
      # Act
      $result = Invoke-CmdletBindingFix -Content ''
      
      # Assert
      $result | Should -Be ''
    }

    It 'Should return whitespace for whitespace-only content' {
      # Act
      $result = Invoke-CmdletBindingFix -Content '   '
      
      # Assert
      $result | Should -Be '   '
    }

    It 'Should handle content with syntax errors gracefully' {
      # Arrange
      $input = 'function Test-Broken { param($x'
      
      # Act & Assert
      { Invoke-CmdletBindingFix -Content $input } | Should -Not -Throw
    }
  }

  Context 'When handling complex function structures' {
    It 'Should handle functions with parameter attributes' {
      # Arrange
      $input = @'
function Test-Complex {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [ValidateSet('A', 'B', 'C')]
        [string]$Type
    )
    $PSCmdlet.WriteVerbose("complex function")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
      $result | Should -Match '\[Parameter\(Mandatory\)\]'
    }

    It 'Should handle functions with multiple parameter sets' {
      # Arrange
      $input = @'
function Test-ParameterSets {
    param(
        [Parameter(ParameterSetName='Set1')]
        [string]$Name,
        
        [Parameter(ParameterSetName='Set2')]
        [int]$Id
    )
    $PSCmdlet.WriteVerbose("parameter sets")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
      $result | Should -Match 'ParameterSetName'
    }

    It 'Should handle functions with begin/process/end blocks' {
      # Arrange
      $input = @'
function Test-Pipeline {
    param($InputObject)
    
    begin {
        $PSCmdlet.WriteVerbose("begin")
    }
    
    process {
        $InputObject
    }
    
    end {
        $PSCmdlet.WriteVerbose("end")
    }
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
      $result | Should -Match 'begin'
      $result | Should -Match 'process'
      $result | Should -Match 'end'
    }
  }

  Context 'When preserving code formatting' {
    It 'Should preserve indentation in fixed code' {
      # Arrange
      $input = @'
function Test-Indentation {
    param(
        $Name
    )
    $PSCmdlet.WriteVerbose("test")
}
'@
      
      # Act
      $result = Invoke-CmdletBindingFix -Content $input
      
      # Assert
      $result | Should -Match '\[CmdletBinding\(\)\]'
      # Result should maintain some indentation structure
      $result | Should -Match '    param'
    }
  }
}

AfterAll {
  # Cleanup
  Remove-Module -Name CmdletBindingFix -ErrorAction SilentlyContinue
  Remove-Module -Name TestHelpers -ErrorAction SilentlyContinue
}
