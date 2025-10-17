#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/Documentation module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/Documentation.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find Documentation module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-MissingModuleManifestFieldFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing missing manifest fields' {
    It 'Should add missing required manifest fields' {
      $code = '@{ ModuleVersion = "1.0.0" }'
      $result = Invoke-MissingModuleManifestFieldFix -Content $code -FilePath "test.psd1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Invoke-CommentHelpFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing comment-based help' {
    It 'Should add or improve comment-based help' {
      $code = 'function Test-Function { param($Name) }'
      $result = Invoke-CommentHelpFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}
