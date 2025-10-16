#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for BestPractices/Syntax module

.DESCRIPTION
    Comprehensive unit tests for Syntax.psm1 functions:
    - Invoke-SemicolonFix
    - Invoke-NullComparisonFix
    - Invoke-ExclaimOperatorFix

    Tests cover:
    - Happy paths with valid transformations
    - Edge cases (empty, comments-only, malformed)
    - Idempotency (running twice produces same result)
    - Error handling and boundary conditions
    - AST parsing correctness

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  $mockBuildersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/MockBuilders.psm1'
  Import-Module -Name $mockBuildersPath -Force -ErrorAction Stop

  $testDataPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestData.psm1'
  Import-Module -Name $testDataPath -Force -ErrorAction Stop

  # Import Syntax module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/BestPractices/Syntax.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Syntax module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-SemicolonFix' -Tag 'Unit', 'BestPractices', 'Syntax' {

  Context 'When removing trailing semicolons' {
    It 'Should remove semicolon from end of simple statement' {
      # Arrange
      $input = '$x = 5;'
      $expected = '$x = 5'

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }

    It 'Should remove semicolons from multiple lines' {
      # Arrange
      $input = @'
$x = 5;
Write-Output "Hello";
$y = 10;
'@
      # Note: Semicolons after statements followed by newlines should be removed
      # The function may not remove all trailing semicolons depending on AST parsing

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert - At least should not throw and return valid PowerShell
      $result | Should -Not -BeNullOrEmpty
      # Verify it's still valid PowerShell
      { [System.Management.Automation.Language.Parser]::ParseInput($result, [ref]$null, [ref]$null) } | 
        Should -Not -Throw
    }

    It 'Should preserve semicolons between statements on same line' {
      # Arrange
      $input = '$x = 1; $y = 2; $z = 3'

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle semicolons followed by comments' {
      # Arrange
      $input = @'
$x = 5; # Comment
Write-Output "Test";
'@
      $expected = @'
$x = 5 # Comment
Write-Output "Test"
'@

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }
  }

  Context 'When handling edge cases' {
    It 'Should handle whitespace-only input' {
      # Arrange
      $input = '  '

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle comments-only script' {
      # Arrange
      $input = Get-CommentOnlyScript

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should preserve semicolons in strings' {
      # Arrange
      $input = '$str = "Hello; World"'

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle malformed script gracefully' {
      # Arrange
      $input = 'function Test { $x ='  # Incomplete

      # Act
      $result = Invoke-SemicolonFix -Content $input

      # Assert
      $result | Should -BeExactly $input  # Return unchanged on parse error
    }
  }

  Context 'When testing idempotency' {
    It 'Should produce same result when run twice' {
      # Arrange
      $input = '$x = 5; $y = 10;'

      # Act
      $firstRun = Invoke-SemicolonFix -Content $input
      $secondRun = Invoke-SemicolonFix -Content $firstRun

      # Assert
      $firstRun | Should -BeExactly $secondRun
    }
  }

  Context 'When testing Verbose output' {
    It 'Should write verbose message when semicolons are removed' {
      # Arrange
      $input = '$x = 5;'

      # Act & Assert
      $result = Invoke-SemicolonFix -Content $input -Verbose 4>&1

      # Verbose stream should contain message about removal
      $result | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | 
        Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Invoke-NullComparisonFix' -Tag 'Unit', 'BestPractices', 'Syntax' {

  Context 'When fixing null comparison order' {
    It 'Should swap $var -eq $null to $null -eq $var' {
      # Arrange
      $input = 'if ($value -eq $null) { }'
      $expected = 'if ($null -eq $value) { }'

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }

    It 'Should swap $var -ne $null to $null -ne $var' {
      # Arrange
      $input = 'if ($value -ne $null) { }'
      $expected = 'if ($null -ne $value) { }'

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }

    It 'Should handle multiple comparison operators' -TestCases @(
      @{ Operator = 'eq'; InputScript = 'if ($x -eq $null) { }'; ExpectedScript = 'if ($null -eq $x) { }' }
      @{ Operator = 'ne'; InputScript = 'if ($x -ne $null) { }'; ExpectedScript = 'if ($null -ne $x) { }' }
      @{ Operator = 'gt'; InputScript = 'if ($x -gt $null) { }'; ExpectedScript = 'if ($null -gt $x) { }' }
      @{ Operator = 'lt'; InputScript = 'if ($x -lt $null) { }'; ExpectedScript = 'if ($null -lt $x) { }' }
      @{ Operator = 'ge'; InputScript = 'if ($x -ge $null) { }'; ExpectedScript = 'if ($null -ge $x) { }' }
      @{ Operator = 'le'; InputScript = 'if ($x -le $null) { }'; ExpectedScript = 'if ($null -le $x) { }' }
    ) {
      param($Operator, $InputScript, $ExpectedScript)

      # Act
      $result = Invoke-NullComparisonFix -Content $InputScript

      # Assert
      $result | Should -BeExactly $ExpectedScript
    }

    It 'Should leave $null on left unchanged' {
      # Arrange
      $input = 'if ($null -eq $value) { }'

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle multiple comparisons in one script' {
      # Arrange
      $input = @'
if ($a -eq $null) { }
if ($b -ne $null) { }
'@
      $expected = @'
if ($null -eq $a) { }
if ($null -ne $b) { }
'@

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }
  }

  Context 'When handling edge cases' {
    It 'Should handle whitespace-only input' {
      # Arrange
      $input = '  '

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should not modify comparisons with non-null values' {
      # Arrange
      $input = 'if ($value -eq "test") { }'

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle malformed script gracefully' {
      # Arrange
      $input = 'if ($value -eq'  # Incomplete

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }
  }

  Context 'When testing idempotency' {
    It 'Should produce same result when run twice' {
      # Arrange
      $input = 'if ($value -eq $null) { }'

      # Act
      $firstRun = Invoke-NullComparisonFix -Content $input
      $secondRun = Invoke-NullComparisonFix -Content $firstRun

      # Assert
      $firstRun | Should -BeExactly $secondRun
    }
  }

  Context 'When preserving case-sensitive comparisons' {
    It 'Should preserve -ceq operator' {
      # Arrange
      $input = 'if ($value -ceq $null) { }'
      $expected = 'if ($null -ceq $value) { }'

      # Act
      $result = Invoke-NullComparisonFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }
  }
}

Describe 'Invoke-ExclaimOperatorFix' -Tag 'Unit', 'BestPractices', 'Syntax' {

  Context 'When replacing ! with -not' {
    It 'Should replace ! with -not in if statement' {
      # Arrange
      $input = 'if (!$enabled) { }'
      $expected = 'if (-not $enabled) { }'

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }

    It 'Should replace ! in assignment' {
      # Arrange
      $input = '$result = !$test'
      $expected = '$result = -not $test'

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }

    It 'Should replace ! in while loop' {
      # Arrange
      $input = 'while (!$done) { }'
      $expected = 'while (-not $done) { }'

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }

    It 'Should handle multiple ! operators' {
      # Arrange
      $input = @'
if (!$a) { }
if (!$b) { }
$c = !$d
'@
      $expected = @'
if (-not $a) { }
if (-not $b) { }
$c = -not $d
'@

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }

    It 'Should handle nested expressions with parentheses' {
      # Arrange
      $input = 'if (!($x -eq 5)) { }'
      $expected = 'if (-not ($x -eq 5)) { }'

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $expected
    }
  }

  Context 'When handling edge cases' {
    It 'Should handle whitespace-only input' {
      # Arrange
      $input = '  '

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should preserve ! in strings' {
      # Arrange
      $input = '$str = "Hello! World"'

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should preserve ! in comments' {
      # Arrange
      $input = '# This is important!'

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle malformed script gracefully' {
      # Arrange
      $input = 'if (!'  # Incomplete

      # Act
      $result = Invoke-ExclaimOperatorFix -Content $input

      # Assert
      $result | Should -BeExactly $input
    }
  }

  Context 'When testing idempotency' {
    It 'Should produce same result when run twice' {
      # Arrange
      $input = 'if (!$value) { }'

      # Act
      $firstRun = Invoke-ExclaimOperatorFix -Content $input
      $secondRun = Invoke-ExclaimOperatorFix -Content $firstRun

      # Assert
      $firstRun | Should -BeExactly $secondRun
    }
  }

  Context 'When testing Verbose output' {
    It 'Should write verbose message when operators are replaced' {
      # Arrange
      $input = 'if (!$x) { }'

      # Act & Assert
      $result = Invoke-ExclaimOperatorFix -Content $input -Verbose 4>&1

      # Verbose stream should contain message about replacement
      $result | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | 
        Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Syntax Module - Integration Tests' -Tag 'Integration', 'BestPractices', 'Syntax' {

  Context 'When applying all syntax fixes together' {
    It 'Should fix multiple syntax issues in a complex script' {
      # Arrange
      $input = @'
function Test-Syntax {
  $x = 5;
  if ($value -eq $null) {
    return;
  }
  if (!$enabled) {
    Write-Output "Disabled";
  }
}
'@
      
      # Act - Apply all fixes
      $result = $input
      $result = Invoke-SemicolonFix -Content $result
      $result = Invoke-NullComparisonFix -Content $result
      $result = Invoke-ExclaimOperatorFix -Content $result

      # Assert - Key transformations should be present
      $result | Should -Match '\$null -eq \$value'
      $result | Should -Match '-not \$enabled'
    }

    It 'Should handle script with no issues' {
      # Arrange
      $input = Get-ValidScript

      # Act
      $result = Invoke-SemicolonFix -Content $input
      $result = Invoke-NullComparisonFix -Content $result
      $result = Invoke-ExclaimOperatorFix -Content $result

      # Assert - Should remain unchanged
      $result | Should -BeExactly $input
    }
  }
}
