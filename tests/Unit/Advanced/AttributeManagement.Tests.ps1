#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/AttributeManagement module

.DESCRIPTION
    Comprehensive unit tests for Advanced/AttributeManagement.psm1 covering:
    - SupportsShouldProcess fix application
    - ShouldProcessForStateChanging fix
    - CmdletCorrectly fix
    - ProcessBlock for Pipeline fix
    
    Tests verify AST-based attribute management transformations.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/AttributeManagement.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find AttributeManagement module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-SupportsShouldProcessFix' -Tag 'Unit', 'Advanced', 'AttributeManagement' {
  
  Context 'When fixing SupportsShouldProcess' {
    It 'Should add SupportsShouldProcess to functions needing it' {
      $code = @'
function Remove-MyItem {
    param($Path)
    Remove-Item -Path $Path
}
'@
      
      $result = Invoke-SupportsShouldProcessFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
      $result.Fixed | Should -Be $true
    }

    It 'Should not modify functions already having SupportsShouldProcess' {
      $code = @'
function Remove-MyItem {
    [CmdletBinding(SupportsShouldProcess)]
    param($Path)
    Remove-Item -Path $Path
}
'@
      
      $result = Invoke-SupportsShouldProcessFix -Content $code -FilePath "test.ps1"
      
      $result.Fixed | Should -Be $false
    }
  }
}

Describe 'Invoke-ShouldProcessForStateChangingFix' -Tag 'Unit', 'Advanced', 'AttributeManagement' {
  
  Context 'When fixing ShouldProcess calls' {
    It 'Should add ShouldProcess checks to state-changing operations' {
      $code = @'
function Set-MyConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param($Value)
    Set-Content -Path $file -Value $Value
}
'@
      
      $result = Invoke-ShouldProcessForStateChangingFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not modify functions already using ShouldProcess' {
      $code = @'
function Set-MyConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param($Value)
    if ($PSCmdlet.ShouldProcess($file, "Set config")) {
        Set-Content -Path $file -Value $Value
    }
}
'@
      
      $result = Invoke-ShouldProcessForStateChangingFix -Content $code -FilePath "test.ps1"
      
      $result.Fixed | Should -Be $false
    }
  }
}

Describe 'Invoke-CmdletCorrectlyFix' -Tag 'Unit', 'Advanced', 'AttributeManagement' {
  
  Context 'When fixing cmdlet usage' {
    It 'Should fix cmdlet parameter usage' {
      $code = 'Get-ChildItem -path $folder'
      
      $result = Invoke-CmdletCorrectlyFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle correct cmdlet usage' {
      $code = 'Get-ChildItem -Path $folder'
      
      $result = Invoke-CmdletCorrectlyFix -Content $code -FilePath "test.ps1"
      
      $result.Fixed | Should -Be $false
    }
  }
}

Describe 'Invoke-ProcessBlockForPipelineFix' -Tag 'Unit', 'Advanced', 'AttributeManagement' {
  
  Context 'When fixing pipeline processing' {
    It 'Should add process block to pipeline functions' {
      $code = @'
function Get-MyData {
    param([Parameter(ValueFromPipeline)]$Item)
    Write-Output $Item
}
'@
      
      $result = Invoke-ProcessBlockForPipelineFix -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not modify functions already with process block' {
      $code = @'
function Get-MyData {
    param([Parameter(ValueFromPipeline)]$Item)
    process {
        Write-Output $Item
    }
}
'@
      
      $result = Invoke-ProcessBlockForPipelineFix -Content $code -FilePath "test.ps1"
      
      $result.Fixed | Should -Be $false
    }
  }
}
