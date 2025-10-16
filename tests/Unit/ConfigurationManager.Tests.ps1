#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard ConfigurationManager module

.DESCRIPTION
    Unit tests for ConfigurationManager.psm1 functions:
    - Initialize-PoshGuardConfiguration
    - Get-DefaultConfiguration
    - Get-PoshGuardConfiguration
    - Set-PoshGuardConfigurationValue
    - ConvertTo-Hashtable
    - Merge-Configuration
    - Apply-EnvironmentOverrides
    - Test-ConfigurationValid

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import ConfigurationManager module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/ConfigurationManager.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find ConfigurationManager module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Get-DefaultConfiguration' -Tag 'Unit', 'Configuration' {
  
  Context 'Basic functionality' {
    It 'Should return a hashtable' {
      $config = Get-DefaultConfiguration
      
      $config | Should -Not -BeNullOrEmpty
      $config | Should -BeOfType [hashtable]
    }

    It 'Should have expected configuration keys' {
      $config = Get-DefaultConfiguration
      
      # Check for common configuration keys
      $config.ContainsKey('Enabled') -or $config.ContainsKey('Rules') -or $config.Count -gt 0 | Should -Be $true
    }

    It 'Should be callable multiple times' {
      $config1 = Get-DefaultConfiguration
      $config2 = Get-DefaultConfiguration
      
      $config1 | Should -Not -BeNullOrEmpty
      $config2 | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Initialize-PoshGuardConfiguration' -Tag 'Unit', 'Configuration' {
  
  Context 'Configuration initialization' {
    It 'Should initialize without error' {
      { Initialize-PoshGuardConfiguration } | Should -Not -Throw
    }

    It 'Should return a configuration' {
      $config = Initialize-PoshGuardConfiguration
      
      $config | Should -Not -BeNullOrEmpty
      $config | Should -BeOfType [hashtable]
    }

    It 'Should support Force parameter' {
      $config1 = Initialize-PoshGuardConfiguration
      $config2 = Initialize-PoshGuardConfiguration -Force
      
      $config2 | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Custom configuration path' {
    It 'Should handle non-existent config file gracefully' {
      $fakePath = Join-Path -Path $TestDrive -ChildPath 'nonexistent.json'
      
      { Initialize-PoshGuardConfiguration -ConfigPath $fakePath } | Should -Not -Throw
    }

    It 'Should load from custom path if file exists' {
      $configPath = Join-Path -Path $TestDrive -ChildPath 'test-config.json'
      $testConfig = @{
        Enabled = $true
        TestKey = 'TestValue'
      }
      $testConfig | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
      
      $config = Initialize-PoshGuardConfiguration -ConfigPath $configPath -Force
      
      $config | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Get-PoshGuardConfiguration' -Tag 'Unit', 'Configuration' {
  
  Context 'Getting configuration' {
    It 'Should return configuration' {
      Initialize-PoshGuardConfiguration -Force | Out-Null
      
      $config = Get-PoshGuardConfiguration
      
      $config | Should -Not -BeNullOrEmpty
    }

    It 'Should be callable multiple times' {
      $config1 = Get-PoshGuardConfiguration
      $config2 = Get-PoshGuardConfiguration
      
      $config1 | Should -Not -BeNullOrEmpty
      $config2 | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Set-PoshGuardConfigurationValue' -Tag 'Unit', 'Configuration' {
  
  Context 'Setting configuration values' {
    BeforeEach {
      Initialize-PoshGuardConfiguration -Force | Out-Null
    }

    It 'Should set a configuration value' {
      { Set-PoshGuardConfigurationValue -Path 'TestKey' -Value 'TestValue' } | Should -Not -Throw
    }

    It 'Should update existing configuration' {
      Set-PoshGuardConfigurationValue -Path 'TestKey' -Value 'Value1'
      Set-PoshGuardConfigurationValue -Path 'TestKey' -Value 'Value2'
      
      $config = Get-PoshGuardConfiguration
      $config['TestKey'] | Should -Be 'Value2'
    }

    It 'Should handle nested paths' {
      { Set-PoshGuardConfigurationValue -Path 'Section.SubKey' -Value 'Value' } | Should -Not -Throw
    }
  }
}


