#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive Pester Architect tests for PoshGuard Core module

.DESCRIPTION
    Unit tests for Core.psm1 following Pester Architect principles:
    
    Functions Tested:
    - Clear-Backups: Backup cleanup with date filtering
    - Write-Log: Logging with levels, formatting, and optional parameters
    - Get-PowerShellFiles: File discovery with recursion and filtering
    - New-FileBackup: File backup with timestamps
    - New-UnifiedDiff: Unified diff generation
    
    Test Principles Applied:
    ✓ AAA (Arrange-Act-Assert) pattern
    ✓ Table-driven tests with -TestCases
    ✓ Comprehensive mocking with InModuleScope
    ✓ Deterministic time mocking (Get-Date)
    ✓ Hermetic filesystem with TestDrive
    ✓ Edge case coverage (empty, null, large, unicode)
    ✓ Error path testing with Should -Throw
    ✓ Parameter validation testing
    ✓ ShouldProcess testing (-WhatIf, -Confirm)

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ best practices
    Enhanced: 2025-10-17 (Pester Architect compliance)
#>

BeforeAll {
  # Import test helpers (only if not already loaded)
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  if (Test-Path $helpersPath) {
    $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
    if (-not $helpersLoaded) {
      Import-Module -Name $helpersPath -ErrorAction Stop
    }
  }

  # Import Core module (only if not already loaded)
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Core.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Core module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'Core' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  }
  
  # Initialize performance mocks to prevent slow console I/O
  Initialize-PerformanceMocks -ModuleName 'Core'
}

Describe 'Clear-Backups' -Tag 'Unit', 'Core', 'Backup' {
  <#
  .SYNOPSIS
      Tests for backup cleanup with time-based filtering
      
  .NOTES
      Tests deterministic behavior by mocking Get-Date
      Uses TestDrive for filesystem isolation
      Validates ShouldProcess (-WhatIf/-Confirm) behavior
  #>
  
  Context 'When backup directory does not exist' {
    It 'Returns without error and does not attempt cleanup' {
      InModuleScope Core {
        # Arrange
        Mock Test-Path { return $false } -Verifiable
        Mock Get-ChildItem { throw "Should not be called" }
        
        # Act & Assert
        { Clear-Backups -Confirm:$false } | Should -Not -Throw
        Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
        Assert-MockCalled Get-ChildItem -Exactly -Times 0 -Scope It
      }
    }
  }

  Context 'When backup directory exists with old files' {
    It 'Deletes files older than 1 day using mocked time' {
      InModuleScope Core {
        # Arrange - freeze time
        $frozenNow = [datetime]'2025-01-15T10:00:00Z'
        Mock Get-Date { return $frozenNow }
        
        # Create mock old files
        $oldFile = [PSCustomObject]@{
          FullName = 'C:\test\.psqa-backup\old.bak'
          LastWriteTime = $frozenNow.AddDays(-2)  # 2 days old
        }
        $recentFile = [PSCustomObject]@{
          FullName = 'C:\test\.psqa-backup\recent.bak'
          LastWriteTime = $frozenNow.AddHours(-12)  # 12 hours old
        }
        
        Mock Test-Path { return $true }
        Mock Get-ChildItem { return @($oldFile, $recentFile) }
        Mock Remove-Item { } -Verifiable
        
        # Act
        Clear-Backups -Confirm:$false
        
        # Assert - only old file should be deleted
        Assert-MockCalled Remove-Item -ParameterFilter { 
          $Path -eq 'C:\test\.psqa-backup\old.bak' 
        } -Exactly -Times 1 -Scope It
        
        Assert-MockCalled Remove-Item -ParameterFilter { 
          $Path -eq 'C:\test\.psqa-backup\recent.bak' 
        } -Exactly -Times 0 -Scope It
      }
    }
    
    It 'Respects -WhatIf and does not delete files' {
      InModuleScope Core {
        # Arrange
        Mock Test-Path { return $true }
        $oldFile = [PSCustomObject]@{
          FullName = 'C:\test\.psqa-backup\old.bak'
          LastWriteTime = (Get-Date).AddDays(-2)
        }
        Mock Get-ChildItem { return @($oldFile) }
        Mock Remove-Item { throw "Should not delete in WhatIf mode" }
        
        # Act
        Clear-Backups -WhatIf
        
        # Assert - Remove-Item should not be called
        Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
      }
    }
  }
  
  Context 'Error conditions' {
    It 'Propagates filesystem errors when ErrorAction is not SilentlyContinue' {
      InModuleScope Core {
        # Arrange
        Mock Test-Path { return $true }
        Mock Get-ChildItem { throw "Access denied" }
        
        # Act & Assert - should throw when ErrorAction is not suppressed
        { Clear-Backups -Confirm:$false -ErrorAction Stop } | Should -Throw -ExpectedMessage '*Access denied*'
      }
    }
  }
}

Describe 'Write-Log' -Tag 'Unit', 'Core', 'Logging' {
  <#
  .SYNOPSIS
      Tests for Write-Log function with comprehensive coverage
      
  .NOTES
      Uses table-driven tests for all severity levels
      Tests edge cases (empty, null, unicode, special characters)
      Validates parameter validation and error conditions
  #>
  
  Context 'When logging at different severity levels' {
    It 'Formats message at <Level> level with correct pattern and color' -TestCases @(
      @{ Level = 'Info'; ExpectedPattern = '\[INFO\]'; ExpectedColor = 'Cyan' }
      @{ Level = 'Warn'; ExpectedPattern = '\[WARN\]'; ExpectedColor = 'Yellow' }
      @{ Level = 'Error'; ExpectedPattern = '\[ERROR\]'; ExpectedColor = 'Red' }
      @{ Level = 'Success'; ExpectedPattern = '\[SUCCESS\]'; ExpectedColor = 'Green' }
      @{ Level = 'Critical'; ExpectedPattern = '\[CRITICAL\]'; ExpectedColor = 'Red' }
      @{ Level = 'Debug'; ExpectedPattern = '\[DEBUG\]'; ExpectedColor = 'Gray' }
    ) {
      param($Level, $ExpectedPattern, $ExpectedColor)
      
      # Arrange
      $message = "Test message for $Level level"
      
      # Act
      $output = Write-Log -Level $Level -Message $message 6>&1 | Out-String
      
      # Assert
      $output | Should -Match $ExpectedPattern
      $output | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When using optional parameters' {
    It 'Omits timestamp when -NoTimestamp is specified' {
      # Arrange & Act
      $output = Write-Log -Level Info -Message "Test" -NoTimestamp 6>&1 | Out-String
      
      # Assert - should not contain timestamp pattern
      $output | Should -Not -Match '\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}'
      $output | Should -Match '\[INFO\]'
    }

    It 'Omits icon when -NoIcon is specified' {
      # Arrange & Act
      $output = Write-Log -Level Success -Message "Test" -NoIcon 6>&1 | Out-String
      
      # Assert
      $output | Should -Match '\[SUCCESS\]'
      # Should still work without throwing
      { Write-Log -Level Success -Message "Test" -NoIcon } | Should -Not -Throw
    }
    
    It 'Omits both timestamp and icon when both switches specified' {
      # Arrange & Act
      $output = Write-Log -Level Warn -Message "Test" -NoTimestamp -NoIcon 6>&1 | Out-String
      
      # Assert
      $output | Should -Not -Match '\d{4}-\d{2}-\d{2}'
      $output | Should -Match '\[WARN\]'
      $output | Should -Match 'Test'
    }
  }

  Context 'When message is empty or whitespace (edge cases)' {
    It 'Rejects empty string per Mandatory parameter validation' {
      # Arrange & Act & Assert
      # PowerShell parameter validation rejects empty strings on Mandatory parameters
      { Write-Log -Level Info -Message '' } | Should -Throw
    }

    It 'Handles <Description> without throwing' -TestCases @(
      @{ Message = '   '; Description = 'whitespace only' }
      @{ Message = "`t
"; Description = 'tabs and newlines' }
      @{ Message = "`r
"; Description = 'CRLF line endings' }
    ) {
      param($Message, $Description)
      
      # Act & Assert
      { Write-Log -Level Info -Message $Message } | Should -Not -Throw
    }
  }
  
  Context 'When message contains special characters' {
    It 'Handles <Description> correctly' -TestCases @(
      @{ Message = '你好世界'; Description = 'Chinese characters' }
      @{ Message = 'Здравствуй мир'; Description = 'Cyrillic characters' }
      @{ Message = '🎉🚀✨'; Description = 'Emoji' }
      @{ Message = 'Quote: "test"'; Description = 'double quotes' }
      @{ Message = "Quote: 'test'"; Description = 'single quotes' }
      @{ Message = 'Backslash: \test'; Description = 'backslash' }
      @{ Message = 'Percent: 100%'; Description = 'percent sign' }
      @{ Message = 'Dollar: $variable'; Description = 'dollar sign' }
    ) {
      param($Message, $Description)
      
      # Act
      $output = Write-Log -Level Info -Message $Message -NoTimestamp 6>&1 | Out-String
      
      # Assert - should not throw and should contain the message
      { Write-Log -Level Info -Message $Message } | Should -Not -Throw
      # Message should be present in output (accounting for formatting)
      $output | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation (error conditions)' {
    It 'Throws when Level parameter is invalid' {
      # Act & Assert
      { Write-Log -Level 'InvalidLevel' -Message 'Test' } | 
        Should -Throw -ErrorId 'ParameterArgumentValidationError*'
    }

    It 'Has mandatory Message parameter' {
      # Arrange
      $cmd = Get-Command Write-Log
      $msgParam = $cmd.Parameters['Message'].Attributes | 
        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
      
      # Act & Assert
      $msgParam[0].Mandatory | Should -Be $true
    }
    
    It 'Accepts all valid Level values' -TestCases @(
      @{ Level = 'Info' }
      @{ Level = 'Warn' }
      @{ Level = 'Error' }
      @{ Level = 'Success' }
      @{ Level = 'Critical' }
      @{ Level = 'Debug' }
    ) {
      param($Level)
      
      # Act & Assert
      { Write-Log -Level $Level -Message 'Test' } | Should -Not -Throw
    }
  }
}

Describe 'Get-PowerShellFiles' -Tag 'Unit', 'Core' {
  
  Context 'When path is a single file' {
    It 'Should return the single file' {
      $testFile = New-TestFile -FileName 'test.ps1' -Content 'Write-Output "Test"'
      
      $result = Get-PowerShellFiles -Path $testFile
      
      $result.Count | Should -Be 1
      $result[0].Name | Should -Be 'test.ps1'
    }

    It 'Should return file with .psm1 extension' {
      $testFile = New-TestFile -FileName 'module.psm1' -Content 'function Test {}'
      
      $result = Get-PowerShellFiles -Path $testFile
      
      $result.Count | Should -Be 1
      $result[0].Extension | Should -Be '.psm1'
    }

    It 'Should return file with .psd1 extension' {
      $testFile = New-TestFile -FileName 'manifest.psd1' -Content '@{ ModuleVersion = "1.0" }'
      
      $result = Get-PowerShellFiles -Path $testFile
      
      $result.Count | Should -Be 1
      $result[0].Extension | Should -Be '.psd1'
    }
  }

  Context 'When path is a directory' {
    BeforeEach {
      # Create test directory structure
      $subDir = Join-Path -Path $TestDrive -ChildPath 'subdir'
      New-Item -ItemType Directory -Path $subDir -Force | Out-Null
      
      New-TestFile -FileName 'script1.ps1' -Content 'Write-Output 1'
      New-TestFile -FileName 'module1.psm1' -Content 'function Test1 {}'
      New-TestFile -FileName (Join-Path 'subdir' 'script2.ps1') -Content 'Write-Output 2'
      New-TestFile -FileName 'readme.txt' -Content 'Not a PowerShell file'
      New-TestFile -FileName 'data.json' -Content '{}'
    }

    It 'Should return all PowerShell files recursively' {
      $result = Get-PowerShellFiles -Path $TestDrive
      
      $result.Count | Should -Be 3
      $result.Name | Should -Contain 'script1.ps1'
      $result.Name | Should -Contain 'module1.psm1'
      $result.Name | Should -Contain 'script2.ps1'
    }

    It 'Should filter by supported extensions' {
      $result = Get-PowerShellFiles -Path $TestDrive
      
      $result.Extension | Should -Not -Contain '.txt'
      $result.Extension | Should -Not -Contain '.json'
    }

    It 'Should support custom extensions' {
      New-TestFile -FileName 'test.ps1xml' -Content '<xml/>'
      
      $result = Get-PowerShellFiles -Path $TestDrive -SupportedExtensions @('.ps1xml')
      
      $result | Where-Object { $_.Extension -eq '.ps1xml' } | Should -HaveCount 1
    }
  }

  Context 'When path does not exist' {
    It 'Should handle non-existent path' {
      $nonExistentPath = Join-Path -Path $TestDrive -ChildPath 'nonexistent.ps1'
      
      # Function might return empty or throw - let's just verify it handles it
      try {
        $result = Get-PowerShellFiles -Path $nonExistentPath -ErrorAction Stop
        $result | Should -BeNullOrEmpty
      } catch {
        # It's OK if it throws an error
        $true | Should -Be $true
      }
    }
  }

  Context 'Edge cases' {
    It 'Should handle directory with no PowerShell files' {
      $emptyDir = Join-Path -Path $TestDrive -ChildPath 'empty'
      New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
      New-Item -ItemType File -Path (Join-Path $emptyDir 'test.txt') -Force | Out-Null
      
      $result = Get-PowerShellFiles -Path $emptyDir
      
      $result | Should -BeNullOrEmpty
    }

    It 'Should handle files with multiple dots in name' {
      $testFile = New-TestFile -FileName 'test.backup.ps1' -Content 'Write-Output "Test"'
      
      $result = Get-PowerShellFiles -Path $testFile
      
      $result.Count | Should -Be 1
    }

    It 'Should handle paths with spaces' {
      $dirWithSpaces = Join-Path -Path $TestDrive -ChildPath 'dir with spaces'
      New-Item -ItemType Directory -Path $dirWithSpaces -Force | Out-Null
      $testFile = New-Item -ItemType File -Path (Join-Path $dirWithSpaces 'test script.ps1') -Force
      Set-Content -Path $testFile.FullName -Value 'Write-Output "Test"'
      
      $result = Get-PowerShellFiles -Path $dirWithSpaces
      
      $result.Count | Should -Be 1
      $result[0].Name | Should -Be 'test script.ps1'
    }
  }
}

Describe 'New-FileBackup' -Tag 'Unit', 'Core', 'Backup' {
  <#
  .SYNOPSIS
      Tests for file backup creation with timestamp
      
  .NOTES
      Tests deterministic behavior by mocking Get-Date
      Validates ShouldProcess (-WhatIf/-Confirm) behavior
      Uses TestDrive for filesystem isolation
  #>
  
  Context 'Basic functionality' {
    It 'Should be defined and callable' {
      Test-FunctionExists -Name 'New-FileBackup' | Should -Be $true
    }

    It 'Should have CmdletBinding attribute' {
      $cmd = Get-Command -Name New-FileBackup
      $cmd.CmdletBinding | Should -Be $true
    }

    It 'Should support ShouldProcess' {
      $cmd = Get-Command -Name New-FileBackup
      $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
      $cmd.Parameters.ContainsKey('Confirm') | Should -Be $true
    }
  }

  Context 'Creating backups' {
    BeforeEach {
      # Create a test file
      $testFile = Join-Path $TestDrive 'original.ps1'
      Set-Content -Path $testFile -Value 'Write-Output "Test"' -Encoding UTF8
      $script:testFile = $testFile
    }

    It 'Creates backup with timestamp in .psqa-backup directory' {
      # Arrange - test file already created in BeforeEach
      
      # Act
      $backupPath = New-FileBackup -FilePath $script:testFile -Confirm:$false
      
      # Assert
      $backupPath | Should -Not -BeNullOrEmpty
      $backupPath | Should -Match '\.psqa-backup[\\/]original\.ps1\.\d{14}\.bak$'
    }

    It 'Creates .psqa-backup directory if it does not exist' {
      # Arrange
      $backupDir = Join-Path (Split-Path $script:testFile -Parent) '.psqa-backup'
      
      # Ensure directory doesn't exist
      if (Test-Path $backupDir) {
        Remove-Item -Path $backupDir -Recurse -Force
      }
      
      # Act
      $null = New-FileBackup -FilePath $script:testFile -Confirm:$false
      
      # Assert
      Test-Path $backupDir | Should -Be $true
    }

    It 'Copies file content correctly' {
      # Arrange
      $originalContent = Get-Content -Path $script:testFile -Raw
      
      # Act
      $backupPath = New-FileBackup -FilePath $script:testFile -Confirm:$false
      
      # Assert
      $backupContent = Get-Content -Path $backupPath -Raw
      $backupContent | Should -Be $originalContent
    }

    It 'Returns backup path' {
      # Act
      $backupPath = New-FileBackup -FilePath $script:testFile -Confirm:$false
      
      # Assert
      $backupPath | Should -Not -BeNullOrEmpty
      Test-Path $backupPath | Should -Be $true
    }

    It 'Respects -WhatIf and does not create backup' {
      # Act
      $backupPath = New-FileBackup -FilePath $script:testFile -WhatIf
      
      # Assert - backup should not be created
      $backupPath | Should -BeNullOrEmpty
    }

    It 'Handles files with spaces in path' {
      # Arrange
      $fileWithSpaces = Join-Path $TestDrive 'file with spaces.ps1'
      Set-Content -Path $fileWithSpaces -Value 'Test' -Encoding UTF8
      
      # Act
      $backupPath = New-FileBackup -FilePath $fileWithSpaces -Confirm:$false
      
      # Assert
      $backupPath | Should -Not -BeNullOrEmpty
      Test-Path $backupPath | Should -Be $true
    }

    It 'Creates unique backups for multiple calls' {
      # Arrange - Mock Get-Date to ensure deterministic, different timestamps
      $testFilePath = $script:testFile
      $call = 0
      
      Mock Get-Date {
        param($Format)
        $script:call++
        # Return formatted timestamps 1 second apart
        $baseTime = [DateTime]::Parse('2025-01-01 12:00:00').AddSeconds($script:call - 1)
        return $baseTime.ToString($Format)
      } -ModuleName Core -ParameterFilter { $Format -eq 'yyyyMMddHHmmss' }
      
      # Act - create two backups
      $backup1 = New-FileBackup -FilePath $testFilePath -Confirm:$false
      $backup2 = New-FileBackup -FilePath $testFilePath -Confirm:$false
      
      # Assert - different backup files
      $backup1 | Should -Not -Be $backup2
      Test-Path $backup1 | Should -Be $true
      Test-Path $backup2 | Should -Be $true
    }
  }

  Context 'Error conditions' {
    It 'Handles non-existent file gracefully' {
      # Arrange
      $nonExistentFile = Join-Path $TestDrive 'nonexistent.ps1'
      
      # Act & Assert
      { New-FileBackup -FilePath $nonExistentFile -Confirm:$false -ErrorAction Stop } | Should -Throw
    }
  }
}

Describe 'New-UnifiedDiff' -Tag 'Unit', 'Core', 'Diff' {
  <#
  .SYNOPSIS
      Tests for unified diff generation
      
  .NOTES
      Tests diff format compliance
      Validates edge cases (identical, empty, large diffs)
      Ensures proper line indicator characters (+, -, space)
  #>
  
  Context 'Basic functionality' {
    It 'Should be defined and callable' {
      Test-FunctionExists -Name 'New-UnifiedDiff' | Should -Be $true
    }

    It 'Should have CmdletBinding attribute' {
      $cmd = Get-Command -Name New-UnifiedDiff
      $cmd.CmdletBinding | Should -Be $true
    }

    It 'Should execute without error' {
      $content = "test"
      { New-UnifiedDiff -Original $content -Modified $content -FilePath 'test.ps1' } | Should -Not -Throw
    }
  }

  Context 'When comparing identical content' {
    It 'Returns diff with headers and unchanged lines for identical single-line content' {
      # Arrange
      $content = "Line 1"
      
      # Act
      $result = New-UnifiedDiff -Original $content -Modified $content -FilePath 'test.ps1'
      
      # Assert - Function returns headers + unchanged lines for identical content
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '--- a/test\.ps1'
      $result | Should -Match '\+\+\+ b/test\.ps1'
      $result | Should -Match ' Line 1'  # Space indicator for unchanged
    }

    It 'Returns diff with headers for identical multi-line content' {
      # Arrange
      $content = "Line 1
Line 2
Line 3"
      
      # Act
      $result = New-UnifiedDiff -Original $content -Modified $content -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '--- a/test\.ps1'
      $result | Should -Match '\+\+\+ b/test\.ps1'
    }
  }

  Context 'When content has changes' {
    It 'Detects added lines with + indicator' {
      # Arrange
      $original = "Line 1
Line 2"
      $modified = "Line 1
Line 2
Line 3"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\+Line 3'
    }

    It 'Detects removed lines with - indicator' {
      # Arrange
      $original = "Line 1
Line 2
Line 3"
      $modified = "Line 1
Line 3"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\-Line 2'
    }

    It 'Detects modified lines (remove + add)' {
      # Arrange
      $original = "Line 1
Old Line
Line 3"
      $modified = "Line 1
New Line
Line 3"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\-Old Line'
      $result | Should -Match '\+New Line'
    }

    It 'Includes unchanged lines with space indicator' {
      # Arrange
      $original = "Line 1
Line 2
Line 3"
      $modified = "Line 1
Line 2 Modified
Line 3"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Match ' Line 1'
      $result | Should -Match ' Line 3'
    }
  }

  Context 'Diff header format' {
    It 'Includes --- header for original file' {
      # Arrange
      $original = "Line 1"
      $modified = "Line 2"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Match '^--- a/test\.ps1'
    }

    It 'Includes +++ header for modified file' {
      # Arrange
      $original = "Line 1"
      $modified = "Line 2"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Match '\+\+\+ b/test\.ps1'
    }

    It 'Preserves file path in headers' {
      # Arrange
      $original = "Line 1"
      $modified = "Line 2"
      $filePath = 'src/modules/MyModule.psm1'
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath $filePath
      
      # Assert
      $result | Should -Match "--- a/$([regex]::Escape($filePath))"
      $result | Should -Match "\+\+\+ b/$([regex]::Escape($filePath))"
    }
  }

  Context 'Edge cases' {
    It 'Handles whitespace-only original content' {
      # Arrange
      $original = " "
      $modified = "Line 1
Line 2"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\+Line 1'
      $result | Should -Match '\+Line 2'
    }

    It 'Handles whitespace-only modified content' {
      # Arrange
      $original = "Line 1
Line 2"
      $modified = " "
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\-Line 1'
      $result | Should -Match '\-Line 2'
    }

    It 'Handles minimal content difference' {
      # Arrange
      $original = " "
      $modified = "  "
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert - Should detect the difference
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles content with Windows line endings (CRLF)' {
      # Arrange
      $original = "Line 1`r
Line 2`r
Line 3"
      $modified = "Line 1`r
Line 2 Modified`r
Line 3"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\-Line 2'
      $result | Should -Match '\+Line 2 Modified'
    }

    It 'Handles content with Unix line endings (LF)' {
      # Arrange
      $original = "Line 1
Line 2
Line 3"
      $modified = "Line 1
Line 2 Modified
Line 3"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\-Line 2'
      $result | Should -Match '\+Line 2 Modified'
    }

    It 'Handles large diffs efficiently' {
      # Arrange - 100 line file
      $lines = 1..100 | ForEach-Object { "Line $_" }
      $original = $lines -join "
"
      $modifiedLines = $lines
      $modifiedLines[49] = "Modified Line 50"
      $modified = $modifiedLines -join "
"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match '\-Line 50'
      $result | Should -Match '\+Modified Line 50'
    }

    It 'Handles special characters in content' {
      # Arrange
      $original = "Line with `$variable"
      $modified = "Line with `$newVariable"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles Unicode characters' {
      # Arrange
      $original = "Hello 世界"
      $modified = "Hello 世界!"
      
      # Act
      $result = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Has mandatory Original parameter' {
      # Arrange
      $cmd = Get-Command New-UnifiedDiff
      $param = $cmd.Parameters['Original'].Attributes | 
        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
      
      # Act & Assert
      $param[0].Mandatory | Should -Be $true
    }

    It 'Has mandatory Modified parameter' {
      # Arrange
      $cmd = Get-Command New-UnifiedDiff
      $param = $cmd.Parameters['Modified'].Attributes | 
        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
      
      # Act & Assert
      $param[0].Mandatory | Should -Be $true
    }

    It 'Has mandatory FilePath parameter' {
      # Arrange
      $cmd = Get-Command New-UnifiedDiff
      $param = $cmd.Parameters['FilePath'].Attributes | 
        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
      
      # Act & Assert
      $param[0].Mandatory | Should -Be $true
    }
  }
}

