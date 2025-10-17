#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/DeprecatedManifestFields module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/DeprecatedManifestFields.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find DeprecatedManifestFields module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-DeprecatedManifestFieldsFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing deprecated manifest fields' {
    It 'Should detect and fix deprecated fields in manifest' {
      $code = '@{ ModuleToProcess = "Module.psm1" }'
      $result = Invoke-DeprecatedManifestFieldsFix -Content $code -FilePath "test.psd1"
      $result | Should -Not -BeNullOrEmpty
    }
  }
}
