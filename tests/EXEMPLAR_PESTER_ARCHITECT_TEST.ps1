#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Exemplar Pester Architect Test - Reference Implementation

.DESCRIPTION
    This file demonstrates ALL Pester Architect principles and patterns:
    - AAA (Arrange-Act-Assert) pattern
    - Table-driven tests with -TestCases
    - Comprehensive mocking with InModuleScope
    - Deterministic time/random behavior
    - Hermetic filesystem with TestDrive
    - Edge case and error path coverage
    - ShouldProcess testing
    - Parameter validation testing
    - Performance baseline guards
    
    Use this as a template for enhancing existing tests or creating new ones.

.NOTES
    Part of PoshGuard Test Suite
    Demonstrates Pester v5+ best practices
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath 'Helpers/TestHelpers.psm1'
  if (Test-Path $helpersPath) {
    Import-Module -Name $helpersPath -Force -ErrorAction Stop
  }

  # Import module under test (example: Core module)
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../tools/lib/Core.psm1'
  if (Test-Path $modulePath) {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
  }
}

#region Example 1: Table-Driven Tests with Test Cases

Describe 'Write-Log' -Tag 'Unit', 'Core', 'Exemplar' {
  
  Context 'When logging at different severity levels' {
    # Table-driven test - ONE test, multiple inputs
    It 'Should format message at <Level> level with correct color' -TestCases @(
      @{ Level = 'Info'; ExpectedPattern = '\[INFO\]'; ExpectedColor = 'Cyan' }
      @{ Level = 'Warn'; ExpectedPattern = '\[WARN\]'; ExpectedColor = 'Yellow' }
      @{ Level = 'Error'; ExpectedPattern = '\[ERROR\]'; ExpectedColor = 'Red' }
      @{ Level = 'Success'; ExpectedPattern = '\[SUCCESS\]'; ExpectedColor = 'Green' }
      @{ Level = 'Critical'; ExpectedPattern = '\[CRITICAL\]'; ExpectedColor = 'Red' }
      @{ Level = 'Debug'; ExpectedPattern = '\[DEBUG\]'; ExpectedColor = 'Gray' }
    ) {
      param($Level, $ExpectedPattern, $ExpectedColor)
      
      # Arrange
      $message = "Test message for $Level"
      
      # Act
      $output = Write-Log -Level $Level -Message $message -NoTimestamp 6>&1 | Out-String
      
      # Assert
      $output | Should -Match $ExpectedPattern
    }
  }

  Context 'When message is empty or whitespace' {
    # Edge case: empty/null inputs
    It 'Should handle <Description>' -TestCases @(
      @{ Message = ''; Description = 'empty string' }
      @{ Message = '   '; Description = 'whitespace only' }
      @{ Message = "`t`n"; Description = 'tabs and newlines' }
    ) {
      param($Message, $Description)
      
      # Arrange & Act & Assert
      { Write-Log -Level Info -Message $Message } | Should -Not -Throw
    }
  }

  Context 'Parameter validation' {
    # Error path: invalid parameter values
    It 'Should throw on invalid Level parameter' {
      # Arrange
      $invalidLevel = 'InvalidLevel'
      
      # Act & Assert
      { Write-Log -Level $invalidLevel -Message 'Test' } | 
        Should -Throw -ErrorId 'ParameterArgumentValidationError*'
    }
  }
}

#endregion

#region Example 2: Mocking External Dependencies with InModuleScope

Describe 'Function-WithExternalCall' -Tag 'Unit', 'Mocking', 'Exemplar' {
  
  Context 'When calling external REST API' {
    It 'Should add correct Authorization header' {
      # This example shows proper mocking pattern
      InModuleScope Core {
        # Arrange
        $expectedToken = 'test-token-123'
        $expectedUri = 'https://api.example.com/data'
        
        Mock Invoke-RestMethod -ParameterFilter {
          $Headers['Authorization'] -eq "Bearer $expectedToken" -and
          $Uri -eq $expectedUri
        } -MockWith {
          [PSCustomObject]@{ 
            Status = 'OK'
            Data = 'Test data'
          }
        } -Verifiable
        
        # Act
        # Uncomment when actual function exists:
        # $result = Get-ApiData -Token $expectedToken
        
        # Assert
        # $result.Status | Should -Be 'OK'
        # Assert-MockCalled Invoke-RestMethod -Exactly -Times 1 -Scope It
      }
    }

    It 'Should handle API errors gracefully' {
      InModuleScope Core {
        # Arrange
        Mock Invoke-RestMethod -MockWith {
          throw 'API returned 500'
        }
        
        # Act & Assert
        # Uncomment when actual function exists:
        # { Get-ApiData -Token 'token' } | Should -Throw -ExpectedMessage '*500*'
      }
    }
  }
}

#endregion

#region Example 3: Time Determinism - Freezing Time

Describe 'Function-WithTimeStamp' -Tag 'Unit', 'Time', 'Exemplar' {
  
  Context 'When generating timestamps' {
    It 'Should generate consistent timestamp with mocked time' {
      InModuleScope Core {
        # Arrange - Freeze time to specific moment
        $frozenTime = [DateTime]::new(2025, 10, 17, 12, 0, 0, [DateTimeKind]::Utc)
        Mock Get-Date { return $frozenTime }
        
        # Act
        # Uncomment when actual function exists:
        # $timestamp1 = Get-CurrentTimestamp
        # $timestamp2 = Get-CurrentTimestamp
        
        # Assert - Both calls return same time (deterministic)
        # $timestamp1 | Should -Be $timestamp2
        # $timestamp1 | Should -Be '2025-10-17T12:00:00Z'
      }
    }
  }
}

#endregion

#region Example 4: Filesystem Isolation with TestDrive

Describe 'Get-PowerShellFiles' -Tag 'Unit', 'FileSystem', 'Exemplar' {
  
  Context 'When scanning directory for PowerShell files' {
    BeforeEach {
      # Arrange - Setup test directory structure
      $testDir = Join-Path $TestDrive 'project'
      $srcDir = Join-Path $testDir 'src'
      $testsDir = Join-Path $testDir 'tests'
      
      New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
      New-Item -ItemType Directory -Path $testsDir -Force | Out-Null
      
      # Create test files
      'function Test-Func { }' | Set-Content -Path (Join-Path $srcDir 'Module.psm1')
      '@{ ModuleVersion = "1.0" }' | Set-Content -Path (Join-Path $srcDir 'Module.psd1')
      'Describe "Test" { }' | Set-Content -Path (Join-Path $testsDir 'Test.Tests.ps1')
      'Some readme' | Set-Content -Path (Join-Path $testDir 'README.md')
      '{}' | Set-Content -Path (Join-Path $testDir 'data.json')
    }

    It 'Should find all PowerShell files recursively' {
      # Act
      $result = Get-PowerShellFiles -Path $TestDrive
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -BeGreaterOrEqual 3
      $result.Name | Should -Contain 'Module.psm1'
      $result.Name | Should -Contain 'Module.psd1'
      $result.Name | Should -Contain 'Test.Tests.ps1'
    }

    It 'Should filter by extension' {
      # Act
      $result = Get-PowerShellFiles -Path $TestDrive
      
      # Assert
      $result.Extension | Should -Not -Contain '.md'
      $result.Extension | Should -Not -Contain '.json'
    }

    It 'Should handle directory with no PowerShell files' {
      # Arrange
      $emptyDir = Join-Path $TestDrive 'empty'
      New-Item -ItemType Directory -Path $emptyDir | Out-Null
      'text' | Set-Content -Path (Join-Path $emptyDir 'file.txt')
      
      # Act
      $result = Get-PowerShellFiles -Path $emptyDir
      
      # Assert
      $result | Should -BeNullOrEmpty
    }
  }

  Context 'Edge cases' {
    It 'Should handle files with Unicode names' {
      # Arrange
      $unicodeFile = Join-Path $TestDrive '测试文件.ps1'
      'Write-Output "Test"' | Set-Content -Path $unicodeFile -Encoding UTF8
      
      # Act
      $result = Get-PowerShellFiles -Path $TestDrive
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Name | Should -Contain '测试文件.ps1'
    }

    It 'Should handle paths with spaces' {
      # Arrange
      $dirWithSpaces = Join-Path $TestDrive 'dir with spaces'
      New-Item -ItemType Directory -Path $dirWithSpaces | Out-Null
      'test' | Set-Content -Path (Join-Path $dirWithSpaces 'script file.ps1')
      
      # Act
      $result = Get-PowerShellFiles -Path $dirWithSpaces
      
      # Assert
      $result.Count | Should -Be 1
      $result[0].Name | Should -Be 'script file.ps1'
    }

    It 'Should handle very long paths' {
      # Arrange
      $longPath = Join-Path $TestDrive ('a' * 100)
      New-Item -ItemType Directory -Path $longPath | Out-Null
      'test' | Set-Content -Path (Join-Path $longPath 'test.ps1')
      
      # Act
      $result = Get-PowerShellFiles -Path $longPath
      
      # Assert
      $result.Count | Should -Be 1
    }
  }

  Context 'Error handling' {
    It 'Should handle non-existent path gracefully' {
      # Arrange
      $nonExistent = Join-Path $TestDrive 'does-not-exist'
      
      # Act & Assert
      { Get-PowerShellFiles -Path $nonExistent -ErrorAction Stop } | 
        Should -Throw
    }

    It 'Should handle access denied (mocked)' {
      # This would require mocking Get-ChildItem to throw UnauthorizedAccessException
      # Demonstrating error path testing
    }
  }
}

#endregion

#region Example 5: ShouldProcess / WhatIf Testing

Describe 'New-FileBackup' -Tag 'Unit', 'ShouldProcess', 'Exemplar' {
  
  Context 'When using -WhatIf' {
    It 'Should not create backup file with -WhatIf' {
      # Arrange
      $sourceFile = Join-Path $TestDrive 'source.ps1'
      'content' | Set-Content -Path $sourceFile
      $backupDir = Join-Path $TestDrive 'backups'
      
      # Act
      New-FileBackup -Path $sourceFile -WhatIf
      
      # Assert - No backup created
      Test-Path $backupDir | Should -Be $false
    }
  }

  Context 'When using -Confirm:$false' {
    It 'Should create backup without prompting' {
      # Arrange
      $sourceFile = Join-Path $TestDrive 'source.ps1'
      'content' | Set-Content -Path $sourceFile
      
      # Act
      New-FileBackup -Path $sourceFile -Confirm:$false
      
      # Assert - Backup created
      $backupFiles = Get-ChildItem -Path $TestDrive -Recurse -Filter '*.backup'
      $backupFiles | Should -Not -BeNullOrEmpty
    }
  }
}

#endregion

#region Example 6: Pipeline Input Testing

Describe 'Function-AcceptingPipeline' -Tag 'Unit', 'Pipeline', 'Exemplar' {
  
  Context 'When accepting pipeline input' {
    It 'Should process multiple items from pipeline' {
      # Arrange
      $items = @('item1.ps1', 'item2.ps1', 'item3.ps1')
      $items | ForEach-Object {
        $_ | Set-Content -Path (Join-Path $TestDrive $_)
      }
      
      # Act
      # Uncomment when actual function exists:
      # $result = $items | ForEach-Object { Get-Item (Join-Path $TestDrive $_) } | 
      #                     Process-ScriptFile
      
      # Assert
      # $result.Count | Should -Be 3
    }

    It 'Should handle empty pipeline' {
      # Act
      # Uncomment when actual function exists:
      # $result = @() | Process-ScriptFile
      
      # Assert
      # $result | Should -BeNullOrEmpty
    }
  }
}

#endregion

#region Example 7: Performance Baseline

Describe 'Performance' -Tag 'Performance', 'Exemplar' {
  
  Context 'When processing files' {
    It 'Should complete Get-PowerShellFiles within acceptable time' {
      # Arrange
      # Create 100 test files
      1..100 | ForEach-Object {
        "Write-Output $_" | Set-Content -Path (Join-Path $TestDrive "test$_.ps1")
      }
      
      # Act
      $elapsed = Measure-Command {
        Get-PowerShellFiles -Path $TestDrive | Out-Null
      }
      
      # Assert - Should complete in under 2 seconds
      $elapsed.TotalMilliseconds | Should -BeLessThan 2000
    }
  }
}

#endregion

#region Example 8: Property-Based Testing Pattern

Describe 'Property-Based Tests' -Tag 'Unit', 'PropertyBased', 'Exemplar' {
  
  Context 'Invariants for ConvertTo-Json round-trip' {
    It 'Should preserve data in JSON round-trip for <Type>' -TestCases @(
      @{ Type = 'String'; Value = 'test string' }
      @{ Type = 'Integer'; Value = 42 }
      @{ Type = 'Boolean'; Value = $true }
      @{ Type = 'Array'; Value = @(1, 2, 3) }
      @{ Type = 'Hashtable'; Value = @{ Key = 'Value' } }
    ) {
      param($Type, $Value)
      
      # Act
      $json = $Value | ConvertTo-Json -Compress
      $restored = $json | ConvertFrom-Json
      
      # Assert - Round-trip preserves value
      if ($Type -eq 'Hashtable') {
        $restored.Key | Should -Be $Value.Key
      } else {
        $restored | Should -Be $Value
      }
    }
  }
}

#endregion

#region Example 9: Comprehensive Error Testing

Describe 'Error Handling' -Tag 'Unit', 'ErrorHandling', 'Exemplar' {
  
  Context 'When function encounters errors' {
    It 'Should throw with -ErrorAction Stop on <Scenario>' -TestCases @(
      @{ Scenario = 'null parameter'; Parameter = $null; ErrorId = '*null*' }
      @{ Scenario = 'empty string'; Parameter = ''; ErrorId = '*empty*' }
      @{ Scenario = 'invalid path'; Parameter = 'C:\NonExistent\Path.ps1'; ErrorId = '*' }
    ) {
      param($Scenario, $Parameter, $ErrorId)
      
      # Act & Assert
      # Uncomment when actual function exists:
      # { Process-File -Path $Parameter -ErrorAction Stop } | 
      #   Should -Throw -ErrorId $ErrorId
    }
  }

  Context 'When function logs errors' {
    It 'Should write to error stream with descriptive message' {
      # Arrange
      InModuleScope Core {
        Mock Write-Error { }
        
        # Act
        # Uncomment when actual function exists:
        # Process-BadInput -Value 'invalid'
        
        # Assert
        # Assert-MockCalled Write-Error -Exactly -Times 1
      }
    }
  }
}

#endregion

#region Example 10: Mutation Testing Patterns

Describe 'Boundary Value Testing' -Tag 'Unit', 'BoundaryValue', 'Exemplar' {
  
  Context 'When validating numeric ranges' {
    It 'Should validate <Scenario> for range [1, 100]' -TestCases @(
      @{ Value = 0; Scenario = 'below minimum'; ShouldPass = $false }
      @{ Value = 1; Scenario = 'at minimum'; ShouldPass = $true }
      @{ Value = 50; Scenario = 'in middle'; ShouldPass = $true }
      @{ Value = 100; Scenario = 'at maximum'; ShouldPass = $true }
      @{ Value = 101; Scenario = 'above maximum'; ShouldPass = $false }
      @{ Value = -1; Scenario = 'negative'; ShouldPass = $false }
    ) {
      param($Value, $Scenario, $ShouldPass)
      
      # Act & Assert
      if ($ShouldPass) {
        # Uncomment when actual function exists:
        # { Validate-Range -Value $Value -Min 1 -Max 100 } | Should -Not -Throw
      } else {
        # { Validate-Range -Value $Value -Min 1 -Max 100 } | Should -Throw
      }
    }
  }
}

#endregion

<#
.SYNOPSIS
    Key Takeaways from this Exemplar

1. **Table-Driven Tests**: Use -TestCases for multiple inputs to one test
2. **AAA Pattern**: Arrange, Act, Assert - clearly separated
3. **Mocking**: Use InModuleScope + Mock with ParameterFilter and -Verifiable
4. **TestDrive**: All file I/O uses $TestDrive, never real filesystem
5. **Time Mocking**: Mock Get-Date for deterministic time-dependent tests
6. **Edge Cases**: Empty, null, unicode, long, special characters
7. **Error Paths**: Test -ErrorAction Stop behavior and exceptions
8. **ShouldProcess**: Test -WhatIf and -Confirm behavior
9. **Performance**: Use Measure-Command with thresholds
10. **Property-Based**: Test invariants and round-trip conversions

.NOTES
    This file is a REFERENCE only. The actual tests are uncommented
    when the functions exist in the modules under test.
#>
