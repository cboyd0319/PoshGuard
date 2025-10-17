#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/OverwritingBuiltInCmdlets module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/OverwritingBuiltInCmdlets.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find OverwritingBuiltInCmdlets module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-OverwritingBuiltInCmdletsFix' -Tag 'Unit', 'Advanced' {
  Context 'When detecting built-in cmdlet overwrites' {
    It 'Should detect functions overwriting built-in cmdlets' {
      $code = 'function Get-Process { param($Name) Write-Output "custom" }'
      $result = Invoke-OverwritingBuiltInCmdletsFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should allow custom function names' {
      $code = 'function Get-MyProcess { param($Name) Write-Output "custom" }'
      $result = Invoke-OverwritingBuiltInCmdletsFix -Content $code -FilePath "test.ps1"
      $result.Fixed | Should -Be $false
    }
  }
}
