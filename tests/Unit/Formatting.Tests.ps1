#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Formatting facade module

.DESCRIPTION
    Comprehensive unit tests for Formatting.psm1 facade module:
    - Module loading and submodule imports
    - Function export verification
    - Module metadata validation

    Tests verify that all Formatting submodules are properly imported
    and functions are exported for backward compatibility.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers (only if not already loaded)
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }

  # Import module under test (only if not already loaded)
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Formatting.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Formatting module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'Formatting' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
  
  # Initialize performance mocks to prevent slow console I/O
  Initialize-PerformanceMocks -ModuleName 'Formatting'
  }
}

Describe 'Formatting Module Structure' -Tag 'Unit', 'Formatting', 'Facade' {
  
  Context 'When module is imported' {
    It 'Should import without error' {
      # Arrange
      $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Formatting.psm1'
      
      # Act & Assert
      { Import-Module -Name $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should be a valid PowerShell module' {
      # Arrange
      $moduleInfo = Get-Module -Name Formatting
      
      # Assert
      $moduleInfo | Should -Not -BeNullOrEmpty
      $moduleInfo.ModuleType | Should -Be 'Script'
    }
  }

  Context 'Exported functions from Whitespace submodule' {
    It 'Should export Invoke-FormatterFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-FormatterFix' | Should -Be $true
    }

    It 'Should export Invoke-WhitespaceFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-WhitespaceFix' | Should -Be $true
    }

    It 'Should export Invoke-MisleadingBacktickFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-MisleadingBacktickFix' | Should -Be $true
    }
  }

  Context 'Exported functions from Aliases submodule' {
    It 'Should export Invoke-AliasFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-AliasFix' | Should -Be $true
    }

    It 'Should export Invoke-AliasFixAst' {
      # Assert
      Test-FunctionExists -Name 'Invoke-AliasFixAst' | Should -Be $true
    }
  }

  Context 'Exported functions from Casing submodule' {
    It 'Should export Invoke-CasingFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-CasingFix' | Should -Be $true
    }
  }

  Context 'Exported functions from Output submodule' {
    It 'Should export Invoke-WriteHostFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-WriteHostFix' | Should -Be $true
    }

    It 'Should export Invoke-WriteHostEnhancedFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-WriteHostEnhancedFix' | Should -Be $true
    }

    It 'Should export Invoke-RedirectionOperatorFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-RedirectionOperatorFix' | Should -Be $true
    }
  }

  Context 'Exported functions from Alignment submodule' {
    It 'Should export Invoke-AlignAssignmentFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-AlignAssignmentFix' | Should -Be $true
    }
  }

  Context 'Exported functions from Runspaces submodule' {
    It 'Should export Invoke-UsingScopeModifierFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-UsingScopeModifierFix' | Should -Be $true
    }

    It 'Should export Invoke-ShouldContinueWithoutForceFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-ShouldContinueWithoutForceFix' | Should -Be $true
    }
  }
}

Describe 'Formatting Module Functions' -Tag 'Unit', 'Formatting' {
  
  Context 'Function count validation' {
    It 'Should export at least 11 functions' {
      # Arrange
      $expectedFunctions = @(
        'Invoke-FormatterFix',
        'Invoke-WhitespaceFix',
        'Invoke-MisleadingBacktickFix',
        'Invoke-AliasFix',
        'Invoke-AliasFixAst',
        'Invoke-CasingFix',
        'Invoke-WriteHostFix',
        'Invoke-WriteHostEnhancedFix',
        'Invoke-RedirectionOperatorFix',
        'Invoke-AlignAssignmentFix',
        'Invoke-UsingScopeModifierFix',
        'Invoke-ShouldContinueWithoutForceFix'
      )
      
      # Act
      $existingCount = ($expectedFunctions | Where-Object { Test-FunctionExists -Name $_ }).Count
      
      # Assert
      $existingCount | Should -BeGreaterOrEqual 11
    }

    It 'Should have all expected Formatting fix functions' {
      # Arrange - list of core fix functions that should always exist
      $coreFunctions = @(
        'Invoke-FormatterFix',
        'Invoke-AliasFix',
        'Invoke-CasingFix',
        'Invoke-WriteHostFix',
        'Invoke-AlignAssignmentFix'
      )
      
      # Act & Assert
      foreach ($func in $coreFunctions) {
        Test-FunctionExists -Name $func | Should -Be $true
      }
    }
  }

  Context 'Function naming conventions' {
    It 'Should follow Invoke-*Fix naming pattern' {
      # Arrange
      $moduleInfo = Get-Module -Name Formatting
      $exportedFunctions = $moduleInfo.ExportedFunctions.Keys
      
      # Act - filter functions that don't follow the pattern
      $nonCompliant = $exportedFunctions | Where-Object { $_ -notmatch '^Invoke-.*Fix' }
      
      # Assert - all should follow the pattern (allowing FixAst variant)
      $nonCompliant | Should -BeNullOrEmpty
    }
  }

  Context 'Submodule organization' {
    It 'Should organize functions logically by category' {
      # Arrange
      $whitespaceFunctions = @('Invoke-FormatterFix', 'Invoke-WhitespaceFix', 'Invoke-MisleadingBacktickFix')
      $aliasFunctions = @('Invoke-AliasFix', 'Invoke-AliasFixAst')
      $outputFunctions = @('Invoke-WriteHostFix', 'Invoke-WriteHostEnhancedFix', 'Invoke-RedirectionOperatorFix')
      
      # Act & Assert - verify each category has at least one function
      $whitespaceFunctions | ForEach-Object { Test-FunctionExists -Name $_ } | Where-Object { $_ -eq $true } | Should -Not -BeNullOrEmpty
      $aliasFunctions | ForEach-Object { Test-FunctionExists -Name $_ } | Where-Object { $_ -eq $true } | Should -Not -BeNullOrEmpty
      $outputFunctions | ForEach-Object { Test-FunctionExists -Name $_ } | Where-Object { $_ -eq $true } | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Formatting Module Integration' -Tag 'Integration', 'Formatting' {
  
  Context 'When combining with other modules' {
    It 'Should not conflict with Core module functions' {
      # Arrange - Import Core module if available
      $corePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Core.psm1'
      
      if (Test-Path -Path $corePath) {
        Import-Module -Name $corePath -Force -ErrorAction SilentlyContinue
        
        # Act - verify Formatting functions still exist
        $formattingFuncs = @('Invoke-FormatterFix', 'Invoke-AliasFix', 'Invoke-CasingFix')
        
        # Assert
        foreach ($func in $formattingFuncs) {
          Test-FunctionExists -Name $func | Should -Be $true
        }
      }
      else {
        Set-ItResult -Skipped -Because "Core module not found"
      }
    }

    It 'Should not conflict with Security module functions' {
      # Arrange - Import Security module if available
      $securityPath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Security.psm1'
      
      if (Test-Path -Path $securityPath) {
        Import-Module -Name $securityPath -Force -ErrorAction SilentlyContinue
        
        # Act - verify Formatting functions still exist
        $formattingFuncs = @('Invoke-FormatterFix', 'Invoke-AliasFix')
        
        # Assert
        foreach ($func in $formattingFuncs) {
          Test-FunctionExists -Name $func | Should -Be $true
        }
      }
      else {
        Set-ItResult -Skipped -Because "Security module not found"
      }
    }
  }
}
