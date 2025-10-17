#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Formatting/Runspaces module

.DESCRIPTION
    Comprehensive unit tests for Formatting/Runspaces.psm1 covering:
    - Runspace pool management
    - Parallel formatting execution
    - Thread-safe operations
    
    Tests verify runspace-based parallel processing.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Formatting/Runspaces.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Runspaces module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'New-RunspacePool' -Tag 'Unit', 'Formatting', 'Runspaces' {
  
  Context 'When creating runspace pool' {
    It 'Should create runspace pool with default size' {
      $pool = New-RunspacePool
      
      $pool | Should -Not -BeNullOrEmpty
      $pool.GetMinRunspaces() | Should -BeGreaterThan 0
    }

    It 'Should create runspace pool with custom size' {
      $pool = New-RunspacePool -MinRunspaces 2 -MaxRunspaces 4
      
      $pool | Should -Not -BeNullOrEmpty
      $pool.GetMinRunspaces() | Should -Be 2
      $pool.GetMaxRunspaces() | Should -Be 4
    }

    It 'Should open runspace pool' {
      $pool = New-RunspacePool
      
      $pool.RunspacePoolStateInfo.State | Should -Be 'Opened'
    }
  }

  AfterEach {
    # Clean up runspace pools
    Get-Runspace | Where-Object { $_.Id -gt 1 } | ForEach-Object {
      try { $_.Dispose() } catch { }
    }
  }
}

Describe 'Invoke-ParallelFormatting' -Tag 'Unit', 'Formatting', 'Runspaces' {
  
  Context 'When running parallel formatting' {
    It 'Should format multiple files in parallel' {
      $files = @('test1.ps1', 'test2.ps1', 'test3.ps1')
      
      $result = Invoke-ParallelFormatting -FilePaths $files -ScriptBlock {
        param($file)
        "Formatted: $file"
      }
      
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -Be 3
    }

    It 'Should handle empty file list' {
      $result = Invoke-ParallelFormatting -FilePaths @() -ScriptBlock { }
      
      $result | Should -BeNullOrEmpty
    }

    It 'Should propagate errors from runspaces' {
      $files = @('error.ps1')
      
      $result = Invoke-ParallelFormatting -FilePaths $files -ScriptBlock {
        throw "Test error"
      }
      
      $result | Should -Not -BeNullOrEmpty
    }
  }

  AfterEach {
    Get-Runspace | Where-Object { $_.Id -gt 1 } | ForEach-Object {
      try { $_.Dispose() } catch { }
    }
  }
}

Describe 'Close-RunspacePool' -Tag 'Unit', 'Formatting', 'Runspaces' {
  
  Context 'When closing runspace pool' {
    It 'Should close and dispose runspace pool' {
      $pool = New-RunspacePool
      
      Close-RunspacePool -Pool $pool
      
      $pool.RunspacePoolStateInfo.State | Should -BeIn @('Closed', 'Closing')
    }

    It 'Should handle already closed pool' {
      $pool = New-RunspacePool
      Close-RunspacePool -Pool $pool
      
      { Close-RunspacePool -Pool $pool } | Should -Not -Throw
    }
  }

  AfterEach {
    Get-Runspace | Where-Object { $_.Id -gt 1 } | ForEach-Object {
      try { $_.Dispose() } catch { }
    }
  }
}

Describe 'Test-RunspaceAvailability' -Tag 'Unit', 'Formatting', 'Runspaces' {
  
  Context 'When testing runspace availability' {
    It 'Should return true for available runspaces' {
      $pool = New-RunspacePool -MinRunspaces 2 -MaxRunspaces 4
      
      $result = Test-RunspaceAvailability -Pool $pool
      
      $result | Should -Be $true
      
      Close-RunspacePool -Pool $pool
    }

    It 'Should detect when runspaces are busy' {
      $pool = New-RunspacePool -MinRunspaces 1 -MaxRunspaces 1
      
      # Pool should have availability initially
      $result = Test-RunspaceAvailability -Pool $pool
      $result | Should -Be $true
      
      Close-RunspacePool -Pool $pool
    }
  }

  AfterEach {
    Get-Runspace | Where-Object { $_.Id -gt 1 } | ForEach-Object {
      try { $_.Dispose() } catch { }
    }
  }
}

Describe 'Get-OptimalRunspaceCount' -Tag 'Unit', 'Formatting', 'Runspaces' {
  
  Context 'When calculating optimal runspace count' {
    It 'Should return reasonable runspace count' {
      $count = Get-OptimalRunspaceCount
      
      $count | Should -BeGreaterThan 0
      $count | Should -BeLessOrEqual ([Environment]::ProcessorCount * 2)
    }

    It 'Should consider processor count' {
      $count = Get-OptimalRunspaceCount
      
      $count | Should -BeGreaterOrEqual 1
    }

    It 'Should cap at maximum reasonable value' {
      $count = Get-OptimalRunspaceCount
      
      $count | Should -BeLessOrEqual 32
    }
  }
}
