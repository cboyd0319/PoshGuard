#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced facade module

.DESCRIPTION
    Comprehensive unit tests for Advanced.psm1 facade module:
    - Module loading and submodule imports
    - Function export verification
    - Module metadata validation

    Tests verify that all Advanced submodules are properly imported
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
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Advanced.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Advanced module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'Advanced' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
  
  # Initialize performance mocks to prevent slow console I/O
  Initialize-PerformanceMocks -ModuleName 'Advanced'
  }
}

Describe 'Advanced Module Structure' -Tag 'Unit', 'Advanced', 'Facade' {
  
  Context 'When module is imported' {
    It 'Should import without error' {
      # Arrange
      $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Advanced.psm1'
      
      # Act & Assert
      { Import-Module -Name $modulePath -Force -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should be a valid PowerShell module' {
      # Arrange
      $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Advanced.psm1'
      $moduleInfo = Get-Module -Name Advanced
      
      # Assert
      $moduleInfo | Should -Not -BeNullOrEmpty
      $moduleInfo.ModuleType | Should -Be 'Script'
    }
  }

  Context 'Exported functions from ASTTransformations submodule' {
    It 'Should export Invoke-WmiToCimFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-WmiToCimFix' | Should -Be $true
    }

    It 'Should export Invoke-BrokenHashAlgorithmFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-BrokenHashAlgorithmFix' | Should -Be $true
    }

    It 'Should export Invoke-LongLinesFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-LongLinesFix' | Should -Be $true
    }
  }

  Context 'Exported functions from ParameterManagement submodule' {
    It 'Should export Invoke-ReservedParamsFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-ReservedParamsFix' | Should -Be $true
    }

    It 'Should export Invoke-SwitchParameterDefaultFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-SwitchParameterDefaultFix' | Should -Be $true
    }

    It 'Should export Invoke-UnusedParameterFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-UnusedParameterFix' | Should -Be $true
    }

    It 'Should export Invoke-NullHelpMessageFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-NullHelpMessageFix' | Should -Be $true
    }
  }

  Context 'Exported functions from CodeAnalysis submodule' {
    It 'Should export Invoke-SafetyFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-SafetyFix' | Should -Be $true
    }

    It 'Should export Invoke-DuplicateLineFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-DuplicateLineFix' | Should -Be $true
    }

    It 'Should export Invoke-CmdletParameterFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-CmdletParameterFix' | Should -Be $true
    }
  }

  Context 'Exported functions from Documentation submodule' {
    It 'Should export Invoke-CommentHelpFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-CommentHelpFix' | Should -Be $true
    }

    It 'Should export Invoke-OutputTypeCorrectlyFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-OutputTypeCorrectlyFix' | Should -Be $true
    }
  }

  Context 'Exported functions from AttributeManagement submodule' {
    It 'Should export Invoke-SupportsShouldProcessFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-SupportsShouldProcessFix' | Should -Be $true
    }

    It 'Should export Invoke-ShouldProcessForStateChangingFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-ShouldProcessForStateChangingFix' | Should -Be $true
    }

    It 'Should export Invoke-CmdletCorrectlyFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-CmdletCorrectlyFix' | Should -Be $true
    }

    It 'Should export Invoke-ProcessBlockForPipelineFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-ProcessBlockForPipelineFix' | Should -Be $true
    }
  }

  Context 'Exported functions from ManifestManagement submodule' {
    It 'Should export Invoke-MissingModuleManifestFieldFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-MissingModuleManifestFieldFix' | Should -Be $true
    }

    It 'Should export Invoke-UseToExportFieldsInManifestFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-UseToExportFieldsInManifestFix' | Should -Be $true
    }

    It 'Should export Invoke-AvoidGlobalAliasesFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-AvoidGlobalAliasesFix' | Should -Be $true
    }
  }

  Context 'Exported functions from ShouldProcessTransformation submodule' {
    It 'Should export Invoke-PSShouldProcessFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-PSShouldProcessFix' | Should -Be $true
    }
  }

  Context 'Exported functions from additional submodules' {
    It 'Should export Invoke-InvokingEmptyMembersFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-InvokingEmptyMembersFix' | Should -Be $true
    }

    It 'Should export Invoke-OverwritingBuiltInCmdletsFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-OverwritingBuiltInCmdletsFix' | Should -Be $true
    }

    It 'Should export Invoke-DefaultValueForMandatoryParameterFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-DefaultValueForMandatoryParameterFix' | Should -Be $true
    }

    It 'Should export Invoke-UTF8EncodingForHelpFileFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-UTF8EncodingForHelpFileFix' | Should -Be $true
    }

    It 'Should export Invoke-CmdletBindingFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-CmdletBindingFix' | Should -Be $true
    }

    It 'Should export Invoke-CompatibleCmdletsWarningFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-CompatibleCmdletsWarningFix' | Should -Be $true
    }

    It 'Should export Invoke-DeprecatedManifestFieldsFix' {
      # Assert
      Test-FunctionExists -Name 'Invoke-DeprecatedManifestFieldsFix' | Should -Be $true
    }
  }
}

Describe 'Advanced Module Functions' -Tag 'Unit', 'Advanced' {
  
  Context 'Function count validation' {
    It 'Should export at least 23 functions' {
      # Arrange
      $expectedFunctions = @(
        'Invoke-WmiToCimFix',
        'Invoke-BrokenHashAlgorithmFix',
        'Invoke-LongLinesFix',
        'Invoke-ReservedParamsFix',
        'Invoke-SwitchParameterDefaultFix',
        'Invoke-UnusedParameterFix',
        'Invoke-NullHelpMessageFix',
        'Invoke-SafetyFix',
        'Invoke-DuplicateLineFix',
        'Invoke-CmdletParameterFix',
        'Invoke-CommentHelpFix',
        'Invoke-OutputTypeCorrectlyFix',
        'Invoke-SupportsShouldProcessFix',
        'Invoke-ShouldProcessForStateChangingFix',
        'Invoke-CmdletCorrectlyFix',
        'Invoke-ProcessBlockForPipelineFix',
        'Invoke-MissingModuleManifestFieldFix',
        'Invoke-UseToExportFieldsInManifestFix',
        'Invoke-AvoidGlobalAliasesFix',
        'Invoke-PSShouldProcessFix',
        'Invoke-InvokingEmptyMembersFix',
        'Invoke-OverwritingBuiltInCmdletsFix',
        'Invoke-DefaultValueForMandatoryParameterFix'
      )
      
      # Act
      $existingCount = ($expectedFunctions | Where-Object { Test-FunctionExists -Name $_ }).Count
      
      # Assert
      $existingCount | Should -BeGreaterOrEqual 23
    }

    It 'Should have all expected Advanced fix functions' {
      # Arrange - list of core fix functions that should always exist
      $coreFunctions = @(
        'Invoke-WmiToCimFix',
        'Invoke-ReservedParamsFix',
        'Invoke-SafetyFix',
        'Invoke-CommentHelpFix',
        'Invoke-PSShouldProcessFix'
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
      $moduleInfo = Get-Module -Name Advanced
      $exportedFunctions = $moduleInfo.ExportedFunctions.Keys
      
      # Act - filter functions that don't follow the pattern
      $nonCompliant = $exportedFunctions | Where-Object { $_ -notmatch '^Invoke-.*Fix$' }
      
      # Assert - all should follow the pattern
      $nonCompliant | Should -BeNullOrEmpty
    }
  }
}
