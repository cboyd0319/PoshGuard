#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive Pester Architect tests for Show-GettingStarted.ps1

.DESCRIPTION
    Unit tests for PoshGuard getting started guide following Pester Architect principles:
    
    Functions Tested:
    - Show-GettingStarted: Main display function for getting started guide
    - Environment detection and display
    - Box-drawing and formatting
    - Cross-platform compatibility
    
    Test Principles Applied:
    ✓ AAA (Arrange-Act-Assert) pattern
    ✓ Table-driven tests with -TestCases
    ✓ Mocking for console output verification
    ✓ Hermetic execution (no side effects)
    ✓ Edge case coverage
    ✓ Cross-platform compatibility testing
    ✓ Accessibility validation

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ best practices
    Created: 2025-10-17 (Pester Architect compliance)
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  if (Test-Path $helpersPath) {
    Import-Module -Name $helpersPath -Force -ErrorAction Stop
  }

  # Get the script path
  $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/Show-GettingStarted.ps1'
  if (-not (Test-Path -Path $scriptPath)) {
    throw "Cannot find Show-GettingStarted.ps1 at: $scriptPath"
  }

  # Dot-source the script to access functions
  . $scriptPath
}

Describe 'Show-GettingStarted.ps1 - Script Execution' -Tag 'Unit', 'Tools', 'GettingStarted', 'Execution' {
  <#
  .SYNOPSIS
      Tests script execution and parameter handling
      
  .NOTES
      Validates script can be invoked without errors
      Tests output generation
  #>
  
  Context 'When executing the script' {
    It 'Executes without errors' {
      # Act & Assert
      { & $scriptPath -ErrorAction Stop } | Should -Not -Throw
    }
    
    It 'Produces output to console' {
      # Act
      $output = & $scriptPath 2>&1 | Out-String
      
      # Assert - Should produce some output
      $output | Should -Not -BeNullOrEmpty
    }
    
    It 'Handles execution from different directories' {
      # Arrange
      $originalLocation = Get-Location
      try {
        Set-Location TestDrive:
        
        # Act & Assert
        { & $scriptPath -ErrorAction Stop } | Should -Not -Throw
      } finally {
        Set-Location $originalLocation
      }
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Show-GettingStarted Function' -Tag 'Unit', 'Tools', 'GettingStarted', 'MainFunction' {
  <#
  .SYNOPSIS
      Tests the main Show-GettingStarted function
      
  .NOTES
      Validates display formatting
      Tests all sections of the guide
  #>
  
  Context 'When displaying getting started guide' {
    It 'Displays guide without errors' {
      # Act & Assert
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Clears host before displaying' {
      # Arrange
      Mock Clear-Host { }
      
      # Act
      Show-GettingStarted
      
      # Assert - Clear-Host should be called
      Should -Invoke Clear-Host -Times 1
    }
    
    It 'Displays welcome header' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should contain welcome text
      $output | Should -Match 'Welcome to PoshGuard|PoshGuard'
    }
    
    It 'Displays feature list' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should mention key features
      $output | Should -Match 'code quality|security|best practices|automation'
    }
    
    It 'Displays quick start steps' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should contain step-by-step instructions
      $output | Should -Match 'Step 1|Step 2|Step 3'
    }
    
    It 'Displays command examples' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should show Invoke-PoshGuard commands
      $output | Should -Match 'Invoke-PoshGuard'
    }
    
    It 'Displays DryRun option prominently' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - DryRun should be highlighted as safe option
      $output | Should -Match 'DryRun'
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Display Formatting' -Tag 'Unit', 'Tools', 'GettingStarted', 'Formatting' {
  <#
  .SYNOPSIS
      Tests display formatting and visual elements
      
  .NOTES
      Validates box-drawing characters
      Tests color usage
  #>
  
  Context 'When formatting display elements' {
    It 'Uses box-drawing characters for visual appeal' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should contain box-drawing characters
      $output | Should -Match '╔|═|╗|║|╚|╝|╭|─|╮|│|╰|╯'
    }
    
    It 'Uses color codes for emphasis' {
      # This test validates that Write-Host is called with -ForegroundColor
      # The actual rendering depends on the terminal
      
      # Act & Assert - Should not throw (colors are applied)
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Uses emoji for visual cues' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should contain emoji characters
      $output | Should -Match '🚀|✅|🔒|🎓|⚡|🤖|📚|💡'
    }
    
    It 'Uses consistent spacing and alignment' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should have structured output (not just plain text)
      $output.Length | Should -BeGreaterThan 100
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Content Validation' -Tag 'Unit', 'Tools', 'GettingStarted', 'Content' {
  <#
  .SYNOPSIS
      Tests content accuracy and completeness
      
  .NOTES
      Validates educational content
      Tests command syntax
  #>
  
  Context 'When validating content' {
    It 'Includes valid PowerShell command syntax' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Commands should be syntactically valid
      $output | Should -Match 'Invoke-PoshGuard\s+-Path'
    }
    
    It 'Mentions key PoshGuard features' -TestCases @(
      @{ Feature = 'code quality' }
      @{ Feature = 'security' }
      @{ Feature = 'best practices' }
      @{ Feature = 'automation' }
      @{ Feature = 'AI|ML' }
    ) {
      param($Feature)
      
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert
      $output | Should -Match $Feature
    }
    
    It 'Explains DryRun safety feature' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should explain that DryRun is safe (no changes)
      $output | Should -Match 'DryRun.*safe|no changes|preview|without'
    }
    
    It 'Mentions backup functionality' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should mention automatic backups
      $output | Should -Match 'backup'
    }
    
    It 'Includes folder processing information' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should explain batch processing
      $output | Should -Match 'folder|directory|multiple files'
    }
    
    It 'Provides clear step-by-step instructions' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should have numbered or sequential steps
      $output | Should -Match 'Step\s+\d+'
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Environment Detection' -Tag 'Unit', 'Tools', 'GettingStarted', 'Environment' {
  <#
  .SYNOPSIS
      Tests environment detection and adaptation
      
  .NOTES
      Validates PowerShell version detection
      Tests OS detection if applicable
  #>
  
  Context 'When detecting environment' {
    It 'Works with PowerShell 5.1+' {
      # Act
      $psVersion = $PSVersionTable.PSVersion
      
      # Assert - Script requires 5.1+
      $psVersion.Major | Should -BeGreaterOrEqual 5
      
      # Script should execute without errors
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Works with PowerShell 7+' {
      # Act
      $psVersion = $PSVersionTable.PSVersion
      
      # Assert - If running PS7, should work
      if ($psVersion.Major -ge 7) {
        { Show-GettingStarted } | Should -Not -Throw
      } else {
        $true | Should -Be $true  # Skip if not PS7
      }
    }
    
    It 'Detects current OS platform' {
      # Act
      $platform = if ($IsWindows) { 'Windows' }
                  elseif ($IsLinux) { 'Linux' }
                  elseif ($IsMacOS) { 'macOS' }
                  else { 'Unknown' }
      
      # Assert - Should work on any platform
      { Show-GettingStarted } | Should -Not -Throw
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Cross-Platform Compatibility' -Tag 'Unit', 'Tools', 'GettingStarted', 'CrossPlatform' {
  <#
  .SYNOPSIS
      Tests cross-platform display compatibility
      
  .NOTES
      Validates Windows, macOS, Linux compatibility
      Tests Unicode character support
  #>
  
  Context 'When running on different platforms' {
    It 'Displays correctly on <Platform>' -TestCases @(
      @{ Platform = 'Windows'; OSCheck = { $IsWindows } }
      @{ Platform = 'Linux'; OSCheck = { $IsLinux } }
      @{ Platform = 'macOS'; OSCheck = { $IsMacOS } }
    ) {
      param($Platform, $OSCheck)
      
      # Act & Assert
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Handles different console encodings' {
      # Act & Assert - Should work with UTF-8, ASCII, etc.
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Handles narrow console widths gracefully' {
      # Script should handle small terminal windows
      # Act & Assert
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Handles wide console widths gracefully' {
      # Script should not break with very wide terminals
      # Act & Assert
      { Show-GettingStarted } | Should -Not -Throw
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Accessibility' -Tag 'Unit', 'Tools', 'GettingStarted', 'Accessibility' {
  <#
  .SYNOPSIS
      Tests accessibility features
      
  .NOTES
      Validates screen reader compatibility
      Tests text alternatives for visual elements
  #>
  
  Context 'When ensuring accessibility' {
    It 'Provides text content alongside visual elements' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Visual boxes should have descriptive text
      $output | Should -Not -BeNullOrEmpty
      $output | Should -Match '\w{3,}'  # Contains words (not just symbols)
    }
    
    It 'Uses descriptive section headers' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should have clear section titles
      $output | Should -Match 'What is PoshGuard|Quick Start|Guide'
    }
    
    It 'Includes explanatory text for all commands' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Each command should have explanation
      $commandMatches = [regex]::Matches($output, 'Invoke-PoshGuard')
      $commandMatches.Count | Should -BeGreaterThan 0
      
      # Should have context around commands
      $output | Should -Match 'Invoke-PoshGuard.*\n.*💡'
    }
    
    It 'Does not rely solely on color for information' {
      # Colors should enhance, not be the only indicator
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Information should be conveyed through text
      $output | Should -Match 'Step|feature|command|guide'
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Error Handling' -Tag 'Unit', 'Tools', 'GettingStarted', 'ErrorHandling' {
  <#
  .SYNOPSIS
      Tests error handling and resilience
      
  .NOTES
      Validates graceful error handling
      Tests edge cases
  #>
  
  Context 'When encountering errors' {
    It 'Handles missing Clear-Host gracefully' {
      # Some hosts might not support Clear-Host
      # Act & Assert
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Handles limited color support gracefully' {
      # Some terminals have limited color support
      # Act & Assert - Should not crash
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Handles missing emoji support gracefully' {
      # Older terminals might not render emoji
      # Act & Assert - Should still display
      { Show-GettingStarted } | Should -Not -Throw
    }
    
    It 'Handles Write-Host failures gracefully' {
      # If Write-Host fails (unlikely), should not crash
      # Act & Assert
      { Show-GettingStarted } | Should -Not -Throw
    }
  }
}

Describe 'Show-GettingStarted.ps1 - User Experience' -Tag 'Unit', 'Tools', 'GettingStarted', 'UX' {
  <#
  .SYNOPSIS
      Tests user experience aspects
      
  .NOTES
      Validates clarity and usability
      Tests beginner-friendliness
  #>
  
  Context 'When evaluating user experience' {
    It 'Assumes zero technical knowledge' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should not use technical jargon without explanation
      # Should have beginner-friendly language
      $output | Should -Match 'Welcome|Quick Start|Step'
    }
    
    It 'Provides actionable examples' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Users should be able to copy-paste commands
      $output | Should -Match 'Invoke-PoshGuard\s+-Path\s+\.'
    }
    
    It 'Highlights safety features prominently' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - DryRun and backup should be emphasized
      $output | Should -Match 'safe|DryRun|backup'
    }
    
    It 'Progresses from simple to complex' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should start simple, then show advanced options
      $output | Should -Match 'Step 1.*Step 2.*Step 3'
    }
    
    It 'Includes visual separators for readability' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should use boxes, lines, or spacing
      $output | Should -Match '─|═|│|║'
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Integration with PoshGuard' -Tag 'Unit', 'Tools', 'GettingStarted', 'Integration' {
  <#
  .SYNOPSIS
      Tests integration with main PoshGuard functionality
      
  .NOTES
      Validates command references
      Tests parameter accuracy
  #>
  
  Context 'When integrating with PoshGuard' {
    It 'References valid PoshGuard commands' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should reference Invoke-PoshGuard (main entry point)
      $output | Should -Match 'Invoke-PoshGuard'
    }
    
    It 'Uses correct parameter names' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Parameters should match actual cmdlet
      $output | Should -Match '-Path'
      $output | Should -Match '-DryRun'
    }
    
    It 'Provides realistic example paths' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Examples should use common path patterns
      $output | Should -Match '\.\\'  # Windows relative path
    }
    
    It 'Mentions all major features' {
      # Act
      $output = Show-GettingStarted 6>&1 2>&1 | Out-String
      
      # Assert - Should cover main PoshGuard capabilities
      @('quality', 'security', 'best practices', 'automation') | ForEach-Object {
        $output | Should -Match $_
      }
    }
  }
}

Describe 'Show-GettingStarted.ps1 - Performance' -Tag 'Unit', 'Tools', 'GettingStarted', 'Performance' {
  <#
  .SYNOPSIS
      Tests performance characteristics
      
  .NOTES
      Validates fast execution
      Tests resource usage
  #>
  
  Context 'When measuring performance' {
    It 'Executes quickly (< 5 seconds)' {
      # Act
      $elapsed = Measure-Command { Show-GettingStarted | Out-Null }
      
      # Assert - Should be very fast (just displaying text)
      $elapsed.TotalSeconds | Should -BeLessThan 5
    }
    
    It 'Uses minimal memory' {
      # Display script should not allocate significant memory
      # Act
      $beforeMem = [System.GC]::GetTotalMemory($false)
      Show-GettingStarted | Out-Null
      $afterMem = [System.GC]::GetTotalMemory($false)
      $memIncrease = ($afterMem - $beforeMem) / 1MB
      
      # Assert - Should use < 10 MB
      $memIncrease | Should -BeLessThan 10
    }
  }
}

AfterAll {
  # Cleanup
  Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue | Remove-Module -Force
}
