#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for Formatting/Whitespace module

.DESCRIPTION
    Unit tests for Whitespace.psm1 functions:
    - Invoke-FormatterFix
    - Invoke-WhitespaceFix
    - Invoke-MisleadingBacktickFix

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  # Import Whitespace module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Formatting/Whitespace.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Whitespace module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-WhitespaceFix' -Tag 'Unit', 'Formatting', 'Whitespace' {

  It 'Should remove trailing whitespace' {
    # Arrange
    $content = "function Test {  `n  `$x = 1  `n}"
    
    # Act
    $result = Invoke-WhitespaceFix -Content $content
    
    # Assert
    $result | Should -Not -Match '\s+\n'
  }

  It 'Should ensure file ends with newline' {
    # Arrange
    $content = 'function Test { $x = 1 }'
    
    # Act
    $result = Invoke-WhitespaceFix -Content $content
    
    # Assert
    $result | Should -Match '\n$'
  }

  It 'Should handle empty content' {
    # Arrange
    $content = '   '
    
    # Act
    $result = Invoke-WhitespaceFix -Content $content
    
    # Assert
    $result | Should -Not -BeNullOrEmpty
  }

  It 'Should be idempotent' {
    # Arrange
    $content = "function Test {  `n  `$x = 1  `n}"
    
    # Act
    $first = Invoke-WhitespaceFix -Content $content
    $second = Invoke-WhitespaceFix -Content $first
    
    # Assert
    $first | Should -BeExactly $second
  }
}

Describe 'Invoke-FormatterFix' -Tag 'Unit', 'Formatting', 'Formatter' {

  It 'Should return content if Invoke-Formatter not available' {
    # Arrange
    $content = 'function Test{$x=1}'
    
    # Act - Function checks for Invoke-Formatter availability
    $result = Invoke-FormatterFix -Content $content
    
    # Assert
    $result | Should -Not -BeNullOrEmpty
  }

  It 'Should skip PSQAAutoFixer.psm1 to prevent self-corruption' {
    # Arrange
    $content = 'function Test { $x = 1 }'
    $filePath = 'C:\Path\To\PSQAAutoFixer.psm1'
    
    # Act
    $result = Invoke-FormatterFix -Content $content -FilePath $filePath
    
    # Assert
    $result | Should -BeExactly $content
  }

  It 'Should process content without FilePath parameter' {
    # Arrange
    $content = 'function Test { $x = 1 }'
    
    # Act & Assert
    { Invoke-FormatterFix -Content $content } | Should -Not -Throw
  }
}

Describe 'Invoke-MisleadingBacktickFix' -Tag 'Unit', 'Formatting', 'Whitespace' {

  It 'Should handle content without backticks' {
    # Arrange
    $content = 'function Test { $x = 1 }'
    
    # Act
    $result = Invoke-MisleadingBacktickFix -Content $content
    
    # Assert
    $result | Should -BeExactly $content
  }

  It 'Should handle valid line continuation' {
    # Arrange
    $content = @'
Get-Process `
  -Name powershell
'@
    
    # Act & Assert
    { Invoke-MisleadingBacktickFix -Content $content } | Should -Not -Throw
  }
}
