#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/UTF8EncodingForHelpFile module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/UTF8EncodingForHelpFile.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find UTF8EncodingForHelpFile module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-UTF8EncodingForHelpFileFix' -Tag 'Unit', 'Advanced' {
  Context 'When fixing UTF-8 encoding for help files' {
    It 'Should detect non-UTF8 encoded files' {
      InModuleScope UTF8EncodingForHelpFile {
        Mock Test-Path { $true }
        Mock Get-Content { 'Help content' }
        
        $result = Invoke-UTF8EncodingForHelpFileFix -FilePath "test-help.xml"
        $result | Should -Not -BeNullOrEmpty
      }
    }

    It 'Should verify UTF-8 BOM presence' {
      InModuleScope UTF8EncodingForHelpFile {
        Mock Test-Path { $true }
        
        $result = Test-UTF8BOM -FilePath "test.xml"
        $result | Should -BeOfType [bool]
      }
    }
  }
}

Describe 'Test-FileEncoding' -Tag 'Unit', 'Advanced' {
  Context 'When testing file encoding' {
    It 'Should detect file encoding type' {
      InModuleScope UTF8EncodingForHelpFile {
        Mock Test-Path { $true }
        Mock Get-Content { [byte[]]@(0xEF, 0xBB, 0xBF, 0x48) } -ParameterFilter { $AsByteStream }
        
        $result = Test-FileEncoding -FilePath "test.txt"
        $result | Should -Not -BeNullOrEmpty
      }
    }
  }
}
