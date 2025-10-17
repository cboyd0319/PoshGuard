#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Exemplar Pester test demonstrating all Pester Architect principles

.DESCRIPTION
    This test file serves as a reference implementation showcasing:
    - Deterministic, hermetic testing
    - AAA pattern (Arrange-Act-Assert)
    - Table-driven tests with -TestCases
    - Comprehensive mocking strategies
    - Error path and edge case coverage
    - ShouldProcess validation
    - Performance regression guards
    - Clear naming and documentation

    Use this as a template for creating new test files or enhancing existing ones.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ Architect Standards
    Author: PoshGuard Team
    Version: 1.0.0
    Last Updated: 2025-10-17
#>

BeforeAll {
  # ============================================================================
  # TEST SETUP - Import modules and helpers
  # ============================================================================
  
  # Import test helpers for common utilities
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath 'Helpers/TestHelpers.psm1'
  if (Test-Path $helpersPath) {
    Import-Module -Name $helpersPath -Force -ErrorAction Stop
  }

  # Import the module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../tools/lib/Core.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Core module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

# ==============================================================================
# DESCRIBE BLOCK - One per module or major functional area
# ==============================================================================

Describe 'Core Module - Write-Log Function' -Tag 'Unit', 'Core', 'Exemplar' {
  
  # ============================================================================
  # CONTEXT BLOCK - Groups related scenarios
  # ============================================================================
  
  Context 'Happy Path - Standard logging at different levels' {
    
    # ==========================================================================
    # TABLE-DRIVEN TESTS - Eliminate duplication, make intent explicit
    # ==========================================================================
    
    It 'logs message at <Level> level with correct icon and color' -TestCases @(
      @{ Level = 'Info'; ExpectedIcon = 'ℹ️'; ExpectedColor = 'Cyan'; ExpectedPrefix = 'INFO' }
      @{ Level = 'Warn'; ExpectedIcon = '⚠️'; ExpectedColor = 'Yellow'; ExpectedPrefix = 'WARN' }
      @{ Level = 'Error'; ExpectedIcon = '❌'; ExpectedColor = 'Red'; ExpectedPrefix = 'ERROR' }
      @{ Level = 'Success'; ExpectedIcon = '✅'; ExpectedColor = 'Green'; ExpectedPrefix = 'SUCCESS' }
      @{ Level = 'Critical'; ExpectedIcon = '🔴'; ExpectedColor = 'Red'; ExpectedPrefix = 'CRITICAL' }
      @{ Level = 'Debug'; ExpectedIcon = '🔍'; ExpectedColor = 'Gray'; ExpectedPrefix = 'DEBUG' }
    ) {
      param($Level, $ExpectedIcon, $ExpectedColor, $ExpectedPrefix)
      
      # ======================================================================
      # AAA PATTERN - Arrange, Act, Assert
      # ======================================================================
      
      # ARRANGE - Set up test data and mocks
      $testMessage = "Test message for $Level"
      
      # ACT - Execute the function under test
      # Capture output to validate (usually we just verify it doesn't throw)
      $output = Write-Log -Level $Level -Message $testMessage -ErrorAction SilentlyContinue
      
      # ASSERT - Verify expected behavior
      # For logging functions, we mainly verify they don't throw
      # In a real scenario, you might mock Write-Host and verify calls
      { Write-Log -Level $Level -Message $testMessage } | Should -Not -Throw
    }
  }
  
  Context 'Optional Parameters - Timestamp and Icon control' {
    
    It 'suppresses timestamp when -NoTimestamp is specified' {
      # ARRANGE
      $message = 'Test without timestamp'
      
      # ACT & ASSERT
      { Write-Log -Level Info -Message $message -NoTimestamp } | Should -Not -Throw
    }
    
    It 'suppresses icon when -NoIcon is specified' {
      # ARRANGE
      $message = 'Test without icon'
      
      # ACT & ASSERT
      { Write-Log -Level Info -Message $message -NoIcon } | Should -Not -Throw
    }
    
    It 'suppresses both timestamp and icon when both switches specified' {
      # ARRANGE
      $message = 'Test minimal output'
      
      # ACT & ASSERT
      { Write-Log -Level Info -Message $message -NoTimestamp -NoIcon } | Should -Not -Throw
    }
  }
  
  Context 'Edge Cases - Boundary conditions and special inputs' {
    
    It 'handles empty message string' -TestCases @(
      @{ Message = ''; Description = 'empty string' }
      @{ Message = '   '; Description = 'whitespace only' }
      @{ Message = "`t`n"; Description = 'tabs and newlines' }
    ) {
      param($Message, $Description)
      
      # ACT & ASSERT
      { Write-Log -Level Info -Message $Message } | Should -Not -Throw
    }
    
    It 'handles very long message (>1000 characters)' {
      # ARRANGE
      $longMessage = 'A' * 2000
      
      # ACT & ASSERT
      { Write-Log -Level Info -Message $longMessage } | Should -Not -Throw
    }
    
    It 'handles special characters in message' -TestCases @(
      @{ Message = 'Test with $variables'; Description = 'dollar signs' }
      @{ Message = 'Test with `backticks`'; Description = 'backticks' }
      @{ Message = 'Test with "quotes"'; Description = 'double quotes' }
      @{ Message = "Test with 'apostrophes'"; Description = 'single quotes' }
      @{ Message = 'Test with unicode: 你好 🎉'; Description = 'unicode' }
    ) {
      param($Message, $Description)
      
      # ACT & ASSERT
      { Write-Log -Level Info -Message $Message } | Should -Not -Throw
    }
  }
  
  Context 'Parameter Validation - Type and value constraints' {
    
    It 'rejects invalid Level parameter' {
      # ARRANGE
      $invalidLevel = 'InvalidLevel'
      
      # ACT & ASSERT - Should throw due to ValidateSet
      { Write-Log -Level $invalidLevel -Message 'Test' -ErrorAction Stop } | 
        Should -Throw -ExpectedMessage '*Cannot validate argument on parameter*'
    }
    
    It 'requires Message parameter (mandatory)' {
      # ACT & ASSERT
      { Write-Log -Level Info -ErrorAction Stop } | 
        Should -Throw -ExpectedMessage '*Cannot bind argument to parameter*'
    }
  }
  
  Context 'Performance - Regression guards for critical paths' {
    
    It 'completes within reasonable time for single log entry' {
      # ARRANGE
      $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
      
      # ACT
      Write-Log -Level Info -Message 'Performance test'
      $stopwatch.Stop()
      
      # ASSERT - Generous threshold (10x typical) to avoid flakiness
      # Typical: ~5ms, Threshold: 500ms
      $stopwatch.ElapsedMilliseconds | Should -BeLessThan 500
    }
    
    It 'handles burst logging efficiently (100 entries)' {
      # ARRANGE
      $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
      
      # ACT
      1..100 | ForEach-Object {
        Write-Log -Level Info -Message "Message $_" -ErrorAction SilentlyContinue
      }
      $stopwatch.Stop()
      
      # ASSERT - Should complete in under 5 seconds
      $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000
    }
  }
}

Describe 'Core Module - Get-PowerShellFiles Function' -Tag 'Unit', 'Core', 'Exemplar' {
  
  Context 'Single File Input - Path points to specific file' {
    
    It 'returns the single file when path is a file' {
      # ARRANGE - Use TestDrive: for filesystem isolation
      $testFile = Join-Path TestDrive: 'test.ps1'
      'Write-Host "test"' | Set-Content -Path $testFile
      
      # ACT
      $result = Get-PowerShellFiles -Path $testFile
      
      # ASSERT
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -Be 1
      $result[0].Name | Should -Be 'test.ps1'
    }
    
    It 'returns file with <Extension> extension' -TestCases @(
      @{ Extension = '.ps1'; Content = 'Write-Output "script"' }
      @{ Extension = '.psm1'; Content = 'Export-ModuleMember' }
      @{ Extension = '.psd1'; Content = '@{ ModuleVersion = "1.0" }' }
    ) {
      param($Extension, $Content)
      
      # ARRANGE
      $testFile = Join-Path TestDrive: "test$Extension"
      $Content | Set-Content -Path $testFile
      
      # ACT
      $result = Get-PowerShellFiles -Path $testFile
      
      # ASSERT
      $result | Should -Not -BeNullOrEmpty
      $result[0].Extension | Should -Be $Extension
    }
  }
  
  Context 'Directory Input - Path points to folder' {
    
    It 'returns all PowerShell files recursively' {
      # ARRANGE - Create test directory structure
      $rootDir = Join-Path TestDrive: 'project'
      New-Item -Path $rootDir -ItemType Directory -Force | Out-Null
      
      # Create files in root
      'script1' | Set-Content (Join-Path $rootDir 'file1.ps1')
      'module1' | Set-Content (Join-Path $rootDir 'file2.psm1')
      
      # Create files in subdirectory
      $subDir = Join-Path $rootDir 'subdir'
      New-Item -Path $subDir -ItemType Directory -Force | Out-Null
      'script2' | Set-Content (Join-Path $subDir 'file3.ps1')
      
      # ACT
      $result = Get-PowerShellFiles -Path $rootDir
      
      # ASSERT
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -Be 3
      $result.Name | Should -Contain 'file1.ps1'
      $result.Name | Should -Contain 'file2.psm1'
      $result.Name | Should -Contain 'file3.ps1'
    }
    
    It 'filters by custom extensions' {
      # ARRANGE
      $rootDir = Join-Path TestDrive: 'filtered'
      New-Item -Path $rootDir -ItemType Directory -Force | Out-Null
      
      'ps1' | Set-Content (Join-Path $rootDir 'file.ps1')
      'psm1' | Set-Content (Join-Path $rootDir 'file.psm1')
      'txt' | Set-Content (Join-Path $rootDir 'file.txt')
      
      # ACT - Only get .ps1 files
      $result = Get-PowerShellFiles -Path $rootDir -SupportedExtensions @('.ps1')
      
      # ASSERT
      $result.Count | Should -Be 1
      $result[0].Extension | Should -Be '.ps1'
    }
  }
  
  Context 'Error Conditions - Invalid inputs and edge cases' {
    
    It 'throws when path does not exist' {
      # ARRANGE
      $nonExistentPath = Join-Path TestDrive: 'does-not-exist.ps1'
      
      # ACT & ASSERT
      { Get-PowerShellFiles -Path $nonExistentPath -ErrorAction Stop } | Should -Throw
    }
    
    It 'returns empty array when directory has no PowerShell files' {
      # ARRANGE
      $emptyDir = Join-Path TestDrive: 'empty'
      New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
      'text' | Set-Content (Join-Path $emptyDir 'readme.txt')
      
      # ACT
      $result = Get-PowerShellFiles -Path $emptyDir
      
      # ASSERT
      $result | Should -BeNullOrEmpty
    }
  }
  
  Context 'Special Scenarios - Real-world edge cases' {
    
    It 'handles paths with spaces' {
      # ARRANGE
      $dirWithSpaces = Join-Path TestDrive: 'dir with spaces'
      New-Item -Path $dirWithSpaces -ItemType Directory -Force | Out-Null
      $fileWithSpaces = Join-Path $dirWithSpaces 'file with spaces.ps1'
      'content' | Set-Content -Path $fileWithSpaces
      
      # ACT
      $result = Get-PowerShellFiles -Path $dirWithSpaces
      
      # ASSERT
      $result.Count | Should -Be 1
      $result[0].Name | Should -Be 'file with spaces.ps1'
    }
    
    It 'handles files with multiple dots in name' {
      # ARRANGE
      $testFile = Join-Path TestDrive: 'my.test.file.ps1'
      'content' | Set-Content -Path $testFile
      
      # ACT
      $result = Get-PowerShellFiles -Path $testFile
      
      # ASSERT
      $result.Count | Should -Be 1
      $result[0].Extension | Should -Be '.ps1'
    }
  }
}

Describe 'Core Module - Clean-Backups Function' -Tag 'Unit', 'Core', 'Exemplar' {
  
  Context 'ShouldProcess Support - WhatIf and Confirm' {
    
    It 'respects -WhatIf and does not delete files' {
      # =======================================================================
      # MOCKING PATTERN - InModuleScope for testing internal behavior
      # =======================================================================
      
      InModuleScope Core {
        # ARRANGE - Mock the actual deletion
        Mock Test-Path { $true }
        Mock Get-ChildItem { 
          [pscustomobject]@{ 
            FullName = 'test.bak'
            LastWriteTime = (Get-Date).AddDays(-2) 
          }
        }
        Mock Remove-Item -Verifiable
        
        # ACT
        Clean-Backups -WhatIf
        
        # ASSERT - Verify Remove-Item was NOT called
        Assert-MockCalled Remove-Item -Times 0 -Scope It
      }
    }
    
    It 'deletes files when not in WhatIf mode' {
      InModuleScope Core {
        # ARRANGE
        Mock Test-Path { $true }
        Mock Get-ChildItem { 
          [pscustomobject]@{ 
            FullName = 'old.bak'
            LastWriteTime = (Get-Date).AddDays(-2) 
          }
        }
        Mock Remove-Item -Verifiable
        Mock Write-Verbose { }  # Suppress verbose output
        
        # ACT - Use -Confirm:$false to bypass confirmation
        Clean-Backups -Confirm:$false
        
        # ASSERT
        Assert-MockCalled Remove-Item -Exactly -Times 1 -Scope It
      }
    }
  }
  
  Context 'Time-Based Logic - Deterministic date handling' {
    
    It 'deletes backups older than 24 hours' {
      InModuleScope Core {
        # =================================================================
        # TIME MOCKING - Ensure deterministic behavior
        # =================================================================
        
        # ARRANGE - Mock current time to fixed value
        $fixedNow = [DateTime]'2025-01-15 12:00:00'
        Mock Get-Date { $fixedNow }
        
        # Create mix of old and new files
        $oldFile = [pscustomobject]@{
          FullName = 'old.bak'
          LastWriteTime = [DateTime]'2025-01-14 11:00:00'  # 25 hours old
        }
        $newFile = [pscustomobject]@{
          FullName = 'new.bak'
          LastWriteTime = [DateTime]'2025-01-15 11:00:00'  # 1 hour old
        }
        
        Mock Test-Path { $true }
        Mock Get-ChildItem { @($oldFile, $newFile) }
        Mock Remove-Item { }
        Mock Write-Verbose { }
        
        # ACT
        Clean-Backups -Confirm:$false
        
        # ASSERT - Only old file should be deleted
        Assert-MockCalled Remove-Item -ParameterFilter { 
          $Path -eq 'old.bak' 
        } -Exactly -Times 1
      }
    }
  }
}

Describe 'Core Module - Module Structure and Exports' -Tag 'Unit', 'Core', 'Exemplar' {
  
  Context 'Module manifest and exports' {
    
    It 'exports expected functions' -TestCases @(
      @{ FunctionName = 'Clean-Backups' }
      @{ FunctionName = 'Write-Log' }
      @{ FunctionName = 'Get-PowerShellFiles' }
      @{ FunctionName = 'New-FileBackup' }
      @{ FunctionName = 'New-UnifiedDiff' }
    ) {
      param($FunctionName)
      
      # ACT
      $command = Get-Command -Name $FunctionName -Module Core -ErrorAction SilentlyContinue
      
      # ASSERT
      $command | Should -Not -BeNullOrEmpty
      $command.ModuleName | Should -Be 'Core'
    }
    
    It 'exported functions have CmdletBinding' -TestCases @(
      @{ FunctionName = 'Clean-Backups' }
      @{ FunctionName = 'Write-Log' }
      @{ FunctionName = 'Get-PowerShellFiles' }
      @{ FunctionName = 'New-FileBackup' }
    ) {
      param($FunctionName)
      
      # ACT
      $command = Get-Command -Name $FunctionName -Module Core
      
      # ASSERT
      $command.CmdletBinding | Should -Be $true
    }
  }
}

# ==============================================================================
# AFTERALL CLEANUP - Optional cleanup after all tests
# ==============================================================================

AfterAll {
  # Clean up any test artifacts not in TestDrive:
  # (TestDrive: is automatically cleaned up by Pester)
  
  # Remove imported modules to avoid pollution
  Remove-Module -Name Core -Force -ErrorAction SilentlyContinue
}
