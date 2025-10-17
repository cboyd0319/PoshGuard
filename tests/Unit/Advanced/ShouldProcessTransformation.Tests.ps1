#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/ShouldProcessTransformation module
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/ShouldProcessTransformation.psm1'
  if (-not (Test-Path -Path $modulePath)) { throw "Cannot find ShouldProcessTransformation module" }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-ShouldProcessTransformationFix' -Tag 'Unit', 'Advanced' {
  Context 'When transforming ShouldProcess implementations' {
    It 'Should add proper ShouldProcess pattern' {
      $code = @'
function Remove-MyItem {
    [CmdletBinding(SupportsShouldProcess)]
    param($Path)
    Remove-Item -Path $Path
}
'@
      $result = Invoke-ShouldProcessTransformationFix -Content $code -FilePath "test.ps1"
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should not modify correct implementations' {
      $code = @'
function Remove-MyItem {
    [CmdletBinding(SupportsShouldProcess)]
    param($Path)
    if ($PSCmdlet.ShouldProcess($Path, "Remove")) {
        Remove-Item -Path $Path
    }
}
'@
      $result = Invoke-ShouldProcessTransformationFix -Content $code -FilePath "test.ps1"
      $result.Fixed | Should -Be $false
    }
  }
}

Describe 'Test-ShouldProcessUsage' -Tag 'Unit', 'Advanced' {
  Context 'When testing ShouldProcess usage' {
    It 'Should detect missing ShouldProcess' {
      $code = @'
[CmdletBinding(SupportsShouldProcess)]
param($Path)
Remove-Item $Path
'@
      $result = Test-ShouldProcessUsage -Content $code
      $result | Should -Be $false
    }

    It 'Should confirm correct ShouldProcess usage' {
      $code = 'if ($PSCmdlet.ShouldProcess($item, "Action")) { }'
      $result = Test-ShouldProcessUsage -Content $code
      $result | Should -Be $true
    }
  }
}
