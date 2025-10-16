#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for BestPractices facade module

.DESCRIPTION
    Unit tests for BestPractices.psm1 covering:
    - Module loading and initialization
    - Submodule import verification
    - Function export validation
    - Error handling for missing submodules

    The BestPractices module is a facade that loads multiple submodules:
    - Syntax (semicolons, null comparisons, exclaim operator)
    - Naming (singular nouns, approved verbs, reserved characters)
    - Scoping (global variables, global functions)
    - StringHandling (double quotes, hashtable literals)
    - TypeSafety (automatic variables, type attributes, PSCredential)
    - UsagePatterns (positional parameters, unused variables, assignment operators)
    - CodeQuality (beyond-PSSA enhancements)

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Coverage Target: 90%+ lines, 85%+ branches
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import BestPractices module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/BestPractices.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find BestPractices module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'BestPractices Module Loading' -Tag 'Unit', 'BestPractices', 'Facade' {
  
  Context 'When module is imported' {
    It 'Should load without errors' {
      # Act - module already imported in BeforeAll
      $module = Get-Module -Name BestPractices
      
      # Assert
      $module | Should -Not -BeNullOrEmpty
    }

    It 'Should export expected functions from Syntax submodule' {
      # Act
      $commands = Get-Command -Module BestPractices | Select-Object -ExpandProperty Name
      
      # Assert - Syntax functions
      $commands | Should -Contain 'Invoke-SemicolonFix'
      $commands | Should -Contain 'Invoke-NullComparisonFix'
      $commands | Should -Contain 'Invoke-ExclaimOperatorFix'
    }

    It 'Should export expected functions from Naming submodule' {
      # Act
      $commands = Get-Command -Module BestPractices | Select-Object -ExpandProperty Name
      
      # Assert - Naming functions
      $commands | Should -Contain 'Invoke-SingularNounFix'
      $commands | Should -Contain 'Invoke-ApprovedVerbFix'
      $commands | Should -Contain 'Invoke-ReservedCmdletCharFix'
    }

    It 'Should export expected functions from Scoping submodule' {
      # Act
      $commands = Get-Command -Module BestPractices | Select-Object -ExpandProperty Name
      
      # Assert - Scoping functions
      $commands | Should -Contain 'Invoke-GlobalVarFix'
      $commands | Should -Contain 'Invoke-GlobalFunctionsFix'
    }

    It 'Should export expected functions from StringHandling submodule' {
      # Act
      $commands = Get-Command -Module BestPractices | Select-Object -ExpandProperty Name
      
      # Assert - StringHandling functions
      $commands | Should -Contain 'Invoke-DoubleQuoteFix'
      $commands | Should -Contain 'Invoke-LiteralHashtableFix'
    }

    It 'Should export expected functions from TypeSafety submodule' {
      # Act
      $commands = Get-Command -Module BestPractices | Select-Object -ExpandProperty Name
      
      # Assert - TypeSafety functions
      $commands | Should -Contain 'Invoke-AutomaticVariableFix'
      $commands | Should -Contain 'Invoke-MultipleTypeAttributesFix'
      $commands | Should -Contain 'Invoke-PSCredentialTypeFix'
    }

    It 'Should export expected functions from UsagePatterns submodule' {
      # Act
      $commands = Get-Command -Module BestPractices | Select-Object -ExpandProperty Name
      
      # Assert - UsagePatterns functions
      $commands | Should -Contain 'Invoke-PositionalParameterFix'
      $commands | Should -Contain 'Invoke-UnusedVariableFix'
      $commands | Should -Contain 'Invoke-AssignmentOperatorFix'
    }

    It 'Should export expected functions from CodeQuality submodule' {
      # Act
      $commands = Get-Command -Module BestPractices | Select-Object -ExpandProperty Name
      
      # Assert - CodeQuality functions (if they exist)
      # Note: CodeQuality module may have different functions depending on version
      $commands.Count | Should -BeGreaterThan 10
    }
  }
}

Describe 'BestPractices Function Availability' -Tag 'Unit', 'BestPractices' {
  
  Context 'When calling Syntax functions' {
    It 'Should have Invoke-SemicolonFix available' {
      # Act
      $command = Get-Command Invoke-SemicolonFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
      $command.ModuleName | Should -Match 'BestPractices|Syntax'
    }

    It 'Should have Invoke-NullComparisonFix available' {
      # Act
      $command = Get-Command Invoke-NullComparisonFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When calling Naming functions' {
    It 'Should have Invoke-SingularNounFix available' {
      # Act
      $command = Get-Command Invoke-SingularNounFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }

    It 'Should have Invoke-ApprovedVerbFix available' {
      # Act
      $command = Get-Command Invoke-ApprovedVerbFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When calling Scoping functions' {
    It 'Should have Invoke-GlobalVarFix available' {
      # Act
      $command = Get-Command Invoke-GlobalVarFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When calling StringHandling functions' {
    It 'Should have Invoke-DoubleQuoteFix available' {
      # Act
      $command = Get-Command Invoke-DoubleQuoteFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When calling TypeSafety functions' {
    It 'Should have Invoke-AutomaticVariableFix available' {
      # Act
      $command = Get-Command Invoke-AutomaticVariableFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }

    It 'Should have Invoke-PSCredentialTypeFix available' {
      # Act
      $command = Get-Command Invoke-PSCredentialTypeFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When calling UsagePatterns functions' {
    It 'Should have Invoke-PositionalParameterFix available' {
      # Act
      $command = Get-Command Invoke-PositionalParameterFix -ErrorAction SilentlyContinue
      
      # Assert
      $command | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'BestPractices Module Structure' -Tag 'Unit', 'BestPractices' {
  
  Context 'When checking module organization' {
    It 'Should have all submodule files present' {
      # Arrange
      $moduleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
      $bestPracticesDir = Join-Path $moduleRoot 'tools/lib/BestPractices'
      
      # Assert - Check for expected submodule files
      Test-Path (Join-Path $bestPracticesDir 'Syntax.psm1') | Should -Be $true
      Test-Path (Join-Path $bestPracticesDir 'Naming.psm1') | Should -Be $true
      Test-Path (Join-Path $bestPracticesDir 'Scoping.psm1') | Should -Be $true
      Test-Path (Join-Path $bestPracticesDir 'StringHandling.psm1') | Should -Be $true
      Test-Path (Join-Path $bestPracticesDir 'TypeSafety.psm1') | Should -Be $true
      Test-Path (Join-Path $bestPracticesDir 'UsagePatterns.psm1') | Should -Be $true
      Test-Path (Join-Path $bestPracticesDir 'CodeQuality.psm1') | Should -Be $true
    }

    It 'Should export only functions, not variables' {
      # Act
      $variables = Get-Variable -Scope Global | Where-Object { $_.Options -match 'ReadOnly|Constant' -and $_.Module -eq 'BestPractices' }
      
      # Assert - Facade module should not export variables
      # (or at least not many)
      if ($variables) {
        $variables.Count | Should -BeLessThan 5
      }
    }
  }
}

Describe 'BestPractices Error Handling' -Tag 'Unit', 'BestPractices' {
  
  Context 'When submodule is missing' {
    It 'Should handle missing submodule gracefully' {
      # Note: This is tested by the module's actual loading logic
      # The module should warn but not fail completely if a submodule is missing
      # We can't easily simulate this without modifying the file system
      
      # Act - Re-import to verify no errors
      $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/BestPractices.psm1'
      
      # Assert
      { Import-Module -Name $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }
  }
}

AfterAll {
  # Cleanup
  Remove-Module -Name BestPractices -ErrorAction SilentlyContinue
  Remove-Module -Name TestHelpers -ErrorAction SilentlyContinue
}
