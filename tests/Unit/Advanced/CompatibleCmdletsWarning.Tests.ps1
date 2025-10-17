#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/CompatibleCmdletsWarning module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/CompatibleCmdletsWarning.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find CompatibleCmdletsWarning module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-CompatibleCmdletsWarningFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing cmdlet compatibility warnings' {
    It 'Should fix compatibility issues' {
      $code = 'Get-WmiObject Win32_Process'
      $result = Invoke-CompatibleCmdletsWarningFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Get-LineIndentation' -Tag 'Unit', 'Advanced' {
  Context 'When getting line indentation' {
    It 'Should return indentation level' {
      $result = Get-LineIndentation -Line "    Write-Output 'test'"
      $result | Should -BeGreaterOrEqual 0
    }
  }
}
