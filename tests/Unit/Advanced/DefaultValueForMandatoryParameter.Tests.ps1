#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/DefaultValueForMandatoryParameter module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/DefaultValueForMandatoryParameter.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find DefaultValueForMandatoryParameter module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-DefaultValueForMandatoryParameterFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing default values on mandatory parameters' {
    It 'Should detect and fix mandatory parameters with defaults' {
      $code = @'
function Test-Function {
    param(
        [Parameter(Mandatory)]
        [string]$Name = "default"
    )
}
'@
      $result = Invoke-DefaultValueForMandatoryParameterFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}
