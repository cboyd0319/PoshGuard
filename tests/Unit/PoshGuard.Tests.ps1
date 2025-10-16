#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard main module

.DESCRIPTION
    Unit tests for PoshGuard.psm1:
    - Invoke-PoshGuard - Main entry point function signature and parameters
    - Module exports and metadata

    Tests focus on API surface, parameter validation, and module structure.
    All tests are hermetic and do not require actual script execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import PoshGuard module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../PoshGuard/PoshGuard.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find PoshGuard module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop -WarningAction SilentlyContinue
}

Describe 'Invoke-PoshGuard' -Tag 'Unit', 'PoshGuard', 'MainFunction' {
  
  Context 'Function existence and signature' {
    It 'Should be exported and accessible' {
      Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Should have CmdletBinding attribute' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.CmdletBinding | Should -Be $true
      }
    }

    It 'Should have Path parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.Parameters.ContainsKey('Path') | Should -Be $true
      }
    }

    It 'Should have DryRun switch parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.Parameters.ContainsKey('DryRun') | Should -Be $true
      }
    }

    It 'Should have ShowDiff switch parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.Parameters.ContainsKey('ShowDiff') | Should -Be $true
      }
    }

    It 'Should have Recurse switch parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.Parameters.ContainsKey('Recurse') | Should -Be $true
      }
    }

    It 'Should have Skip parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.Parameters.ContainsKey('Skip') | Should -Be $true
        $cmd.Parameters['Skip'].ParameterType.Name | Should -Be 'String[]'
      }
    }

    It 'Should have ExportSarif switch parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.Parameters.ContainsKey('ExportSarif') | Should -Be $true
      }
    }

    It 'Should have SarifOutputPath parameter with default value' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd) {
        $cmd.Parameters.ContainsKey('SarifOutputPath') | Should -Be $true
        $cmd.Parameters['SarifOutputPath'].ParameterType.Name | Should -Be 'String'
      }
    }
  }

  Context 'Parameter attributes' {
    It 'Path parameter should be in position 0' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd -and $cmd.Parameters.ContainsKey('Path')) {
        $posAttr = $cmd.Parameters['Path'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
        if ($posAttr) {
          $posAttr[0].Position | Should -Be 0
        }
      }
    }

    It 'Path parameter should be mandatory' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd -and $cmd.Parameters.ContainsKey('Path')) {
        $mandAttr = $cmd.Parameters['Path'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
        if ($mandAttr) {
          $mandAttr[0].Mandatory | Should -Be $true
        }
      }
    }

    It 'DryRun should be a switch parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd -and $cmd.Parameters.ContainsKey('DryRun')) {
        $cmd.Parameters['DryRun'].SwitchParameter | Should -Be $true
      }
    }

    It 'ShowDiff should be a switch parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd -and $cmd.Parameters.ContainsKey('ShowDiff')) {
        $cmd.Parameters['ShowDiff'].SwitchParameter | Should -Be $true
      }
    }

    It 'Recurse should be a switch parameter' {
      $cmd = Get-Command Invoke-PoshGuard -ErrorAction SilentlyContinue
      if ($cmd -and $cmd.Parameters.ContainsKey('Recurse')) {
        $cmd.Parameters['Recurse'].SwitchParameter | Should -Be $true
      }
    }
  }
}

Describe 'PoshGuard Module' -Tag 'Unit', 'PoshGuard', 'Module' {
  
  Context 'Module metadata' {
    It 'Should be loaded' {
      $module = Get-Module PoshGuard
      $module | Should -Not -BeNullOrEmpty
    }

    It 'Should have correct module name' {
      $module = Get-Module PoshGuard
      if ($module) {
        $module.Name | Should -Be 'PoshGuard'
      }
    }

    It 'Should export Invoke-PoshGuard function' {
      $module = Get-Module PoshGuard
      if ($module) {
        $module.ExportedFunctions.Keys | Should -Contain 'Invoke-PoshGuard'
      }
    }

    It 'Should export only Invoke-PoshGuard (no internal functions)' {
      $module = Get-Module PoshGuard
      if ($module) {
        $module.ExportedFunctions.Count | Should -Be 1
      }
    }

    It 'Should not export variables' {
      $module = Get-Module PoshGuard
      if ($module) {
        $module.ExportedVariables.Count | Should -Be 0
      }
    }

    It 'Should not export aliases' {
      $module = Get-Module PoshGuard
      if ($module) {
        $module.ExportedAliases.Count | Should -Be 0
      }
    }

    It 'Should not export cmdlets' {
      $module = Get-Module PoshGuard
      if ($module) {
        $module.ExportedCmdlets.Count | Should -Be 0
      }
    }
  }

  Context 'Module structure' {
    It 'Module file exists' {
      $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../PoshGuard/PoshGuard.psm1'
      Test-Path -Path $modulePath | Should -Be $true
    }

    It 'Manifest file exists' {
      $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath '../../PoshGuard/PoshGuard.psd1'
      Test-Path -Path $manifestPath | Should -Be $true
    }

    It 'Manifest can be imported' {
      $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath '../../PoshGuard/PoshGuard.psd1'
      $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction SilentlyContinue
      $manifest | Should -Not -BeNullOrEmpty
    }
  }
}

