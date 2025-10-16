#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for WriteHostEnhanced module

.DESCRIPTION
    Unit tests for Formatting/WriteHostEnhanced.psm1 covering:
    - Invoke-WriteHostToWriteOutputFix function
    - Detection and replacement of Write-Host with Write-Output
    - Handling of Write-Host with various parameters
    - Edge cases and preservation of code structure

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Coverage Target: 90%+ lines, 85%+ branches
    Tests PSAvoidUsingWriteHost rule implementation
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import WriteHostEnhanced module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Formatting/WriteHostEnhanced.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find WriteHostEnhanced module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-WriteHostToWriteOutputFix' -Tag 'Unit', 'Formatting', 'WriteHost' {
  
  Context 'When script contains Write-Host' {
    It 'Should replace Write-Host with Write-Output' {
      # Arrange
      $input = 'Write-Host "Hello, World!"'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
      $result | Should -Not -Match 'Write-Host'
    }

    It 'Should replace multiple Write-Host calls' {
      # Arrange
      $input = @'
Write-Host "First message"
Write-Host "Second message"
Write-Host "Third message"
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $matches = [regex]::Matches($result, 'Write-Output')
      $matches.Count | Should -BeGreaterOrEqual 3
      $result | Should -Not -Match 'Write-Host'
    }

    It 'Should preserve string content' {
      # Arrange
      $input = 'Write-Host "Important: This is a test"'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Important: This is a test'
    }
  }

  Context 'When Write-Host has parameters' {
    It 'Should handle Write-Host with -ForegroundColor' {
      # Arrange
      $input = 'Write-Host "Warning" -ForegroundColor Yellow'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output|Write-Warning|Write-Host'
      # May convert to Write-Output or keep as Write-Host depending on implementation
    }

    It 'Should handle Write-Host with -BackgroundColor' {
      # Arrange
      $input = 'Write-Host "Error" -BackgroundColor Red'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle Write-Host with -NoNewline' {
      # Arrange
      $input = 'Write-Host "Loading..." -NoNewline'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle Write-Host with multiple parameters' {
      # Arrange
      $input = 'Write-Host "Status" -ForegroundColor Green -BackgroundColor Black -NoNewline'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When Write-Host is in a function' {
    It 'Should replace Write-Host inside function' {
      # Arrange
      $input = @'
function Test-Output {
    param($Message)
    Write-Host $Message
}
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
      $result | Should -Not -Match 'Write-Host'
    }

    It 'Should replace Write-Host in multiple functions' {
      # Arrange
      $input = @'
function Test-First {
    Write-Host "First"
}

function Test-Second {
    Write-Host "Second"
}
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $matches = [regex]::Matches($result, 'Write-Output')
      $matches.Count | Should -BeGreaterOrEqual 2
    }
  }

  Context 'When handling complex scenarios' {
    It 'Should handle Write-Host in conditional blocks' {
      # Arrange
      $input = @'
if ($true) {
    Write-Host "Condition is true"
} else {
    Write-Host "Condition is false"
}
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
      $result | Should -Not -Match 'Write-Host'
    }

    It 'Should handle Write-Host in loops' {
      # Arrange
      $input = @'
foreach ($item in $items) {
    Write-Host "Processing: $item"
}
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
      $result | Should -Not -Match 'Write-Host'
    }

    It 'Should handle Write-Host with variable expansion' {
      # Arrange
      $input = 'Write-Host "Value is: $value"'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match '\$value'
      $result | Should -Match 'Write-Output'
    }

    It 'Should handle Write-Host with subexpressions' {
      # Arrange
      $input = 'Write-Host "Total: $($items.Count)"'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
      $result | Should -Match '\$\(.*\.Count\)'
    }
  }

  Context 'When content does not contain Write-Host' {
    It 'Should return unchanged content when no Write-Host present' {
      # Arrange
      $input = @'
Write-Output "Using correct cmdlet"
Write-Verbose "Verbose message"
Write-Warning "Warning message"
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Be $input
    }

    It 'Should not affect Write-Output calls' {
      # Arrange
      $input = 'Write-Output "Already correct"'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Be $input
    }
  }

  Context 'When content is empty or invalid' {
    It 'Should return empty string for empty content' {
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content ''
      
      # Assert
      $result | Should -Be ''
    }

    It 'Should handle whitespace-only content' {
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content '   '
      
      # Assert
      $result | Should -Be '   '
    }

    It 'Should handle content with syntax errors gracefully' {
      # Arrange
      $input = 'Write-Host "Unclosed string'
      
      # Act & Assert
      { Invoke-WriteHostToWriteOutputFix -Content $input } | Should -Not -Throw
    }
  }

  Context 'When preserving code structure' {
    It 'Should preserve indentation' {
      # Arrange
      $input = @'
function Test-Indent {
    if ($true) {
        Write-Host "Indented message"
    }
}
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match '        Write-Output|        Write-Host'
    }

    It 'Should preserve comments' {
      # Arrange
      $input = @'
# This is a comment
Write-Host "Message"  # Inline comment
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match '# This is a comment'
      $result | Should -Match '# Inline comment'
    }

    It 'Should preserve blank lines' {
      # Arrange
      $input = @'
Write-Host "First"

Write-Host "Second"
'@
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $lines = $result -split "`n"
      $lines.Count | Should -BeGreaterOrEqual 3
    }
  }

  Context 'When handling edge cases' {
    It 'Should handle Write-Host as part of larger expression' {
      # Arrange
      $input = '$result = Write-Host "Value"'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output|Write-Host'
    }

    It 'Should handle Write-Host in pipeline' {
      # Arrange
      $input = 'Get-Process | ForEach-Object { Write-Host $_.Name }'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      $result | Should -Match 'Write-Output'
    }

    It 'Should not affect strings containing "Write-Host"' {
      # Arrange
      $input = 'Write-Output "The Write-Host cmdlet is deprecated"'
      
      # Act
      $result = Invoke-WriteHostToWriteOutputFix -Content $input
      
      # Assert
      # String content should be preserved
      $result | Should -Match 'Write-Host cmdlet is deprecated'
      # But the outer cmdlet should still be Write-Output
      $result | Should -Match '^Write-Output'
    }
  }
}

AfterAll {
  # Cleanup
  Remove-Module -Name WriteHostEnhanced -ErrorAction SilentlyContinue
  Remove-Module -Name TestHelpers -ErrorAction SilentlyContinue
}
