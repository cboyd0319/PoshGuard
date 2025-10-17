#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Formatting/Alignment module

.DESCRIPTION
    Comprehensive unit tests for Formatting/Alignment.psm1 covering:
    - Code alignment fixes
    - Indentation consistency
    - Assignment operator alignment
    
    Tests verify formatting alignment transformations.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Formatting/Alignment.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Alignment module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-AlignmentFix' -Tag 'Unit', 'Formatting', 'Alignment' {
  
  Context 'When aligning code elements' {
    It 'Should align assignment operators' {
      $code = @'
$short = 1
$longerVariable = 2
$x = 3
'@
      
      $result = Invoke-AlignmentFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
      $result.Fixed | Should -Be $true
    }

    It 'Should align hashtable assignments' {
      $code = @'
$hash = @{
    Key = "value"
    LongerKey = "value2"
    K = "value3"
}
'@
      
      $result = Invoke-AlignmentFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not modify already aligned code' {
      $code = @'
$a    = 1
$b    = 2
$c    = 3
'@
      
      $result = Invoke-AlignmentFix -Content $code -FilePath "test.ps1"
      
      $result.Fixed | Should -Be $false
    }
  }

  Context 'When handling edge cases' {
    It 'Should handle single-line code' {
      $code = '$variable = "value"'
      
      $result = Invoke-AlignmentFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle empty lines' {
      $code = @'
$a = 1

$b = 2
'@
      
      $result = Invoke-AlignmentFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should preserve code structure' {
      $code = @'
function Test {
    $local = 1
    $anotherLocal = 2
}
'@
      
      $result = Invoke-AlignmentFix -Content $code -FilePath "test.ps1"
      
      $result.FixedContent | Should -Match 'function Test'
    }
  }
}

Describe 'Test-Alignment' -Tag 'Unit', 'Formatting', 'Alignment' {
  
  Context 'When testing alignment' {
    It 'Should detect misaligned code' {
      $code = @'
$a = 1
$bb = 2
$ccc = 3
'@
      
      $result = Test-Alignment -Content $code
      
      $result | Should -Be $false
    }

    It 'Should confirm aligned code' {
      $code = @'
$a   = 1
$bb  = 2
$ccc = 3
'@
      
      $result = Test-Alignment -Content $code
      
      $result | Should -Be $true
    }
  }
}

Describe 'Get-AlignmentSettings' -Tag 'Unit', 'Formatting', 'Alignment' {
  
  Context 'When getting alignment settings' {
    It 'Should return default alignment settings' {
      $settings = Get-AlignmentSettings
      
      $settings | Should -Not -BeNullOrEmpty
      $settings.AlignAssignments | Should -BeOfType [bool]
    }

    It 'Should include hashtable alignment settings' {
      $settings = Get-AlignmentSettings
      
      $settings.AlignHashtables | Should -Not -BeNullOrEmpty
    }
  }
}
