#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/InvokingEmptyMembers module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/InvokingEmptyMembers.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find InvokingEmptyMembers module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-InvokingEmptyMembersFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing empty member invocations' {
    It 'Should detect and fix empty member calls' {
      $code = '$obj.()'
      $result = Invoke-InvokingEmptyMembersFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle valid member access' {
      $code = '$obj.Method()'
      $result = Invoke-InvokingEmptyMembersFix -Content $code -FilePath "test.ps1"
      $result.Fixed | Should -Be $false
    }
  }
}
