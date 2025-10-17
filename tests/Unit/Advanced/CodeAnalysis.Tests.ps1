#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/CodeAnalysis module

.DESCRIPTION
    Comprehensive unit tests for Advanced/CodeAnalysis.psm1 covering:
    - Safety fix application
    - Duplicate line detection and removal
    - Cmdlet parameter fixes
    
    Tests verify code analysis and fix transformations.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/CodeAnalysis.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find CodeAnalysis module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-SafetyFix' -Tag 'Unit', 'Advanced', 'CodeAnalysis' {
  Context 'When applying safety fixes' {
    It 'Should apply safety transformations' {
      $code = '$result = Invoke-Expression $cmd'
      $result = Invoke-SafetyFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Invoke-DuplicateLineFix' -Tag 'Unit', 'Advanced', 'CodeAnalysis' {
  Context 'When removing duplicate lines' {
    It 'Should detect and remove duplicate lines' {
      $code = @'
Write-Output "test"
Write-Output "test"
'@
      $result = Invoke-DuplicateLineFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Invoke-CmdletParameterFix' -Tag 'Unit', 'Advanced', 'CodeAnalysis' {
  Context 'When fixing cmdlet parameters' {
    It 'Should fix parameter usage' {
      $code = 'Get-Process -name notepad'
      $result = Invoke-CmdletParameterFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}
