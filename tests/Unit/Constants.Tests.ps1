#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Unit tests for Constants module

.DESCRIPTION
    Comprehensive tests for Constants module:
    - Constant availability and values
    - Get-PoshGuardConstant function
    - Get-AllPoshGuardConstants function
    - ReadOnly enforcement

.NOTES
    Test Framework: Pester v5+
    Pattern: AAA (Arrange-Act-Assert)
    Coverage Target: 95%+
#>

BeforeAll {
  $ModulePath = Join-Path $PSScriptRoot '../../tools/lib/Constants.psm1'
  Import-Module $ModulePath -Force -ErrorAction Stop
}

Describe 'Constants Module' -Tag 'Unit', 'Constants' {

  Context 'File Size Constants' {
    It 'Should define MaxFileSizeBytes' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxFileSizeBytes'

      # Assert
      $value | Should -Be (10 * 1024 * 1024)  # 10 MB
    }

    It 'Should define AbsoluteMaxFileSizeBytes' {
      # Act
      $value = Get-PoshGuardConstant -Name 'AbsoluteMaxFileSizeBytes'

      # Assert
      $value | Should -Be (100 * 1024 * 1024)  # 100 MB
    }

    It 'Should define MinFileSizeBytes' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MinFileSizeBytes'

      # Assert
      $value | Should -Be 1
    }
  }

  Context 'Entropy Threshold Constants' {
    It 'Should define HighEntropyThreshold' {
      # Act
      $value = Get-PoshGuardConstant -Name 'HighEntropyThreshold'

      # Assert
      $value | Should -Be 4.5
    }

    It 'Should define MediumEntropyThreshold' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MediumEntropyThreshold'

      # Assert
      $value | Should -Be 3.5
    }

    It 'Should define LowEntropyThreshold' {
      # Act
      $value = Get-PoshGuardConstant -Name 'LowEntropyThreshold'

      # Assert
      $value | Should -Be 3.0
    }
  }

  Context 'AST Processing Constants' {
    It 'Should define MaxASTDepth' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxASTDepth'

      # Assert
      $value | Should -Be 100
    }

    It 'Should define MaxASTNodes' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxASTNodes'

      # Assert
      $value | Should -Be 10000
    }
  }

  Context 'Timeout Constants' {
    It 'Should define DefaultCommandTimeoutMs' {
      # Act
      $value = Get-PoshGuardConstant -Name 'DefaultCommandTimeoutMs'

      # Assert
      $value | Should -Be 5000  # 5 seconds
    }

    It 'Should define ShortTimeoutMs' {
      # Act
      $value = Get-PoshGuardConstant -Name 'ShortTimeoutMs'

      # Assert
      $value | Should -Be 2000  # 2 seconds
    }

    It 'Should define LongTimeoutMs' {
      # Act
      $value = Get-PoshGuardConstant -Name 'LongTimeoutMs'

      # Assert
      $value | Should -Be 30000  # 30 seconds
    }
  }

  Context 'Reinforcement Learning Constants' {
    It 'Should define RLLearningRate' {
      # Act
      $value = Get-PoshGuardConstant -Name 'RLLearningRate'

      # Assert
      $value | Should -Be 0.1
    }

    It 'Should define RLDiscountFactor' {
      # Act
      $value = Get-PoshGuardConstant -Name 'RLDiscountFactor'

      # Assert
      $value | Should -Be 0.9
    }

    It 'Should define RLExplorationRate' {
      # Act
      $value = Get-PoshGuardConstant -Name 'RLExplorationRate'

      # Assert
      $value | Should -Be 0.1
    }

    It 'Should define RLBatchSize' {
      # Act
      $value = Get-PoshGuardConstant -Name 'RLBatchSize'

      # Assert
      $value | Should -Be 32
    }

    It 'Should define RLMaxExperienceSize' {
      # Act
      $value = Get-PoshGuardConstant -Name 'RLMaxExperienceSize'

      # Assert
      $value | Should -Be 10000
    }
  }

  Context 'Code Quality Constants' {
    It 'Should define MaxCyclomaticComplexity' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxCyclomaticComplexity'

      # Assert
      $value | Should -Be 15
    }

    It 'Should define MaxFunctionLength' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxFunctionLength'

      # Assert
      $value | Should -Be 50
    }

    It 'Should define MaxFileLength' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxFileLength'

      # Assert
      $value | Should -Be 600
    }

    It 'Should define MaxNestingDepth' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxNestingDepth'

      # Assert
      $value | Should -Be 4
    }
  }

  Context 'Backup Constants' {
    It 'Should define BackupRetentionDays' {
      # Act
      $value = Get-PoshGuardConstant -Name 'BackupRetentionDays'

      # Assert
      $value | Should -Be 1
    }

    It 'Should define MaxBackupsPerFile' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxBackupsPerFile'

      # Assert
      $value | Should -Be 10
    }
  }

  Context 'String Length Constants' {
    It 'Should define MinSecretLength' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MinSecretLength'

      # Assert
      $value | Should -Be 16
    }

    It 'Should define MaxLineLength' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxLineLength'

      # Assert
      $value | Should -Be 120
    }
  }

  Context 'Performance Constants' {
    It 'Should define DefaultThreadCount' {
      # Act
      $value = Get-PoshGuardConstant -Name 'DefaultThreadCount'

      # Assert
      $value | Should -Be 4
    }

    It 'Should define DefaultBatchSize' {
      # Act
      $value = Get-PoshGuardConstant -Name 'DefaultBatchSize'

      # Assert
      $value | Should -Be 100
    }
  }

  Context 'File Extension Constants' {
    It 'Should define PowerShellExtensions' {
      # Act
      $value = Get-PoshGuardConstant -Name 'PowerShellExtensions'

      # Assert
      $value | Should -Not -BeNullOrEmpty
      $value | Should -Contain '.ps1'
      $value | Should -Contain '.psm1'
      $value | Should -Contain '.psd1'
    }

    It 'Should define BackupExtension' {
      # Act
      $value = Get-PoshGuardConstant -Name 'BackupExtension'

      # Assert
      $value | Should -Be '.bak'
    }
  }

  Context 'Get-PoshGuardConstant Function' {
    It 'Should return value for valid constant name' {
      # Act
      $value = Get-PoshGuardConstant -Name 'MaxFileSizeBytes'

      # Assert
      $value | Should -Not -BeNullOrEmpty
    }

    It 'Should return null for invalid constant name' {
      # Act
      $value = Get-PoshGuardConstant -Name 'NonExistentConstant' -WarningAction SilentlyContinue

      # Assert
      $value | Should -BeNullOrEmpty
    }

    It 'Should write warning for invalid constant name' {
      # Act
      Get-PoshGuardConstant -Name 'InvalidConstant' -WarningVariable warnings -WarningAction SilentlyContinue

      # Assert
      $warnings | Should -Not -BeNullOrEmpty
    }

    It 'Should require Name parameter' {
      # Act & Assert
      { Get-PoshGuardConstant } | Should -Throw
    }

    It 'Should not accept empty Name parameter' {
      # Act & Assert
      { Get-PoshGuardConstant -Name '' } | Should -Throw
    }
  }

  Context 'Get-AllPoshGuardConstants Function' {
    It 'Should return hashtable of all constants' {
      # Act
      $constants = Get-AllPoshGuardConstants

      # Assert
      $constants | Should -Not -BeNullOrEmpty
      $constants.GetType().Name | Should -Be 'Hashtable'
    }

    It 'Should return at least 20 constants' {
      # Act
      $constants = Get-AllPoshGuardConstants

      # Assert
      $constants.Count | Should -BeGreaterOrEqual 20
    }

    It 'Should include expected constant names' {
      # Act
      $constants = Get-AllPoshGuardConstants

      # Assert
      $constants.Keys | Should -Contain 'MaxFileSizeBytes'
      $constants.Keys | Should -Contain 'HighEntropyThreshold'
      $constants.Keys | Should -Contain 'MaxASTDepth'
      $constants.Keys | Should -Contain 'DefaultCommandTimeoutMs'
      $constants.Keys | Should -Contain 'RLLearningRate'
      $constants.Keys | Should -Contain 'MaxCyclomaticComplexity'
      $constants.Keys | Should -Contain 'BackupRetentionDays'
      $constants.Keys | Should -Contain 'MinSecretLength'
      $constants.Keys | Should -Contain 'DefaultThreadCount'
      $constants.Keys | Should -Contain 'PowerShellExtensions'
    }

    It 'Should have valid values for all constants' {
      # Act
      $constants = Get-AllPoshGuardConstants

      # Assert
      foreach ($key in $constants.Keys) {
        $constants[$key] | Should -Not -BeNullOrEmpty
      }
    }
  }

  Context 'ReadOnly Enforcement' {
    It 'Should prevent modification of constants' {
      # Act & Assert
      { Set-Variable -Name 'MaxFileSizeBytes' -Value 999 -Scope Script -Force } | Should -Throw
    }

    It 'Should prevent removal of constants' {
      # Act & Assert
      { Remove-Variable -Name 'MaxFileSizeBytes' -Scope Script -Force } | Should -Throw
    }
  }

  Context 'Module Exports' {
    It 'Should export Get-PoshGuardConstant function' {
      Get-Command Get-PoshGuardConstant -Module Constants -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-AllPoshGuardConstants function' {
      Get-Command Get-AllPoshGuardConstants -Module Constants -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Should export constant variables' {
      $exports = Get-Module Constants | Select-Object -ExpandProperty ExportedVariables

      $exports.Keys | Should -Contain 'MaxFileSizeBytes'
      $exports.Keys | Should -Contain 'HighEntropyThreshold'
    }
  }

  Context 'Practical Usage Scenarios' {
    It 'Should support file size validation' {
      # Arrange
      $maxSize = Get-PoshGuardConstant -Name 'MaxFileSizeBytes'
      $testFileSize = 5 * 1024 * 1024  # 5 MB

      # Act & Assert
      $testFileSize -le $maxSize | Should -Be $true
    }

    It 'Should support entropy threshold checks' {
      # Arrange
      $highThreshold = Get-PoshGuardConstant -Name 'HighEntropyThreshold'
      $testEntropy = 4.8

      # Act & Assert
      $testEntropy -gt $highThreshold | Should -Be $true
    }

    It 'Should support code quality validation' {
      # Arrange
      $maxComplexity = Get-PoshGuardConstant -Name 'MaxCyclomaticComplexity'
      $testComplexity = 12

      # Act & Assert
      $testComplexity -le $maxComplexity | Should -Be $true
    }
  }
}
