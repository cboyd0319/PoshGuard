#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/ManifestManagement module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/ManifestManagement.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find ManifestManagement module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Test-ModuleManifest' -Tag 'Unit', 'Advanced' {
  Context 'When validating module manifests' {
    It 'Should validate valid manifest' {
      $manifest = '@{ ModuleVersion = "1.0.0"; GUID = "12345678-1234-1234-1234-123456789012" }'
      { Test-ModuleManifest -Content $manifest } | Should -Not -Throw
    }

    It 'Should detect invalid manifest' {
      $manifest = '@{ InvalidKey = "value" }'
      $result = Test-ModuleManifest -Content $manifest
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Update-ModuleManifest' -Tag 'Unit', 'Advanced' {
  Context 'When updating module manifests' {
    It 'Should update manifest fields' {
      $manifest = '@{ ModuleVersion = "1.0.0" }'
      $result = Update-ModuleManifest -Content $manifest -Updates @{ Author = "Test" }
      $result | Should -Not -BeNullOrEmpty
    }
  }
}
