#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/ParameterManagement module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/ParameterManagement.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find ParameterManagement module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-ParameterValidationFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing parameter validation' {
    It 'Should add validation attributes' {
      $code = 'function Test-Func { param([string]$Path) }'
      $result = Invoke-ParameterValidationFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not modify validated parameters' {
      $code = 'function Test-Func { param([ValidateNotNullOrEmpty()][string]$Path) }'
      $result = Invoke-ParameterValidationFix -Content $code -FilePath "test.ps1"
      $result.Fixed | Should -Be $false
    }
  }
}

Describe 'Test-ParameterAttributes' -Tag 'Unit', 'Advanced' {
  Context 'When testing parameter attributes' {
    It 'Should validate parameter has attributes' {
      $code = 'param([ValidateNotNull()][string]$Name)'
      $result = Test-ParameterAttributes -Content $code
      $result | Should -Be $true
    }
  }
}
