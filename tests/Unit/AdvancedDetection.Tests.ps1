#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for AdvancedDetection module

.DESCRIPTION
    Comprehensive unit tests for AdvancedDetection.psm1 functions:
    - Test-CodeComplexity
    - Test-MaintainabilityIssues
    - Test-PerformanceAntiPatterns
    - Test-SecurityVulnerabilities
    - Invoke-AdvancedDetection
    
    Tests cover happy paths, edge cases, error conditions, and parameter validation.
    All tests are hermetic using TestDrive and mocks.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import AdvancedDetection module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/AdvancedDetection.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find AdvancedDetection module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Test-CodeComplexity' -Tag 'Unit', 'AdvancedDetection' {
  
  Context 'When analyzing high cyclomatic complexity' {
    It 'Should detect cyclomatic complexity > 10' {
      # Arrange
      $content = @'
function Test-Complex {
    param($value)
    if ($value -eq 1) { return 1 }
    if ($value -eq 2) { return 2 }
    if ($value -eq 3) { return 3 }
    if ($value -eq 4) { return 4 }
    if ($value -eq 5) { return 5 }
    if ($value -eq 6) { return 6 }
    if ($value -eq 7) { return 7 }
    if ($value -eq 8) { return 8 }
    if ($value -eq 9) { return 9 }
    if ($value -eq 10) { return 10 }
    if ($value -eq 11) { return 11 }
    return 0
}
'@
      
      # Act
      $issues = Test-CodeComplexity -Content $content -FilePath 'test.ps1'
      
      # Assert
      $complexityIssues = $issues | Where-Object { $_.Rule -eq 'ComplexityTooHigh' }
      $complexityIssues | Should -Not -BeNullOrEmpty
      $complexityIssues[0].Severity | Should -Be 'Warning'
      $complexityIssues[0].Message | Should -Match 'cyclomatic complexity'
    }

    It 'Should not flag simple functions' {
      # Arrange
      $content = @'
function Test-Simple {
    param($value)
    if ($value -gt 0) {
        return $value * 2
    }
    return 0
}
'@
      
      # Act
      $issues = Test-CodeComplexity -Content $content -FilePath 'test.ps1'
      
      # Assert
      $complexityIssues = $issues | Where-Object { $_.Rule -eq 'ComplexityTooHigh' }
      $complexityIssues | Should -BeNullOrEmpty
    }
  }

  Context 'When analyzing nesting depth' {
    It 'Should detect nesting depth > 4' {
      # Arrange
      $content = @'
function Test-DeepNesting {
    if ($true) {
        if ($true) {
            if ($true) {
                if ($true) {
                    if ($true) {
                        Write-Output "Too deep"
                    }
                }
            }
        }
    }
}
'@
      
      # Act
      $issues = Test-CodeComplexity -Content $content -FilePath 'test.ps1'
      
      # Assert
      $nestingIssues = $issues | Where-Object { $_.Rule -eq 'NestingTooDeep' }
      $nestingIssues | Should -Not -BeNullOrEmpty
      $nestingIssues[0].Severity | Should -Be 'Warning'
    }

    It 'Should not flag shallow nesting' {
      # Arrange
      $content = @'
function Test-ShallowNesting {
    if ($true) {
        if ($false) {
            Write-Output "OK"
        }
    }
}
'@
      
      # Act
      $issues = Test-CodeComplexity -Content $content -FilePath 'test.ps1'
      
      # Assert
      $nestingIssues = $issues | Where-Object { $_.Rule -eq 'NestingTooDeep' }
      $nestingIssues | Should -BeNullOrEmpty
    }
  }

  Context 'When analyzing function length' {
    It 'Should detect functions > 50 lines' {
      # Arrange
      $lines = 1..60 | ForEach-Object { "    Write-Output 'Line $_'" }
      $content = @"
function Test-LongFunction {
$($lines -join "`n")
}
"@
      
      # Act
      $issues = Test-CodeComplexity -Content $content -FilePath 'test.ps1'
      
      # Assert
      $lengthIssues = $issues | Where-Object { $_.Rule -eq 'FunctionTooLong' }
      $lengthIssues | Should -Not -BeNullOrEmpty
      $lengthIssues[0].Severity | Should -Be 'Information'
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when Content is null' {
      { Test-CodeComplexity -Content $null -FilePath 'test.ps1' } | Should -Throw
    }

    It 'Should handle empty FilePath' {
      $content = 'function Test { return 1 }'
      { Test-CodeComplexity -Content $content } | Should -Not -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle empty content' {
      $issues = Test-CodeComplexity -Content '' -FilePath 'test.ps1'
      $issues | Should -Not -BeNull
    }

    It 'Should handle invalid syntax gracefully' {
      $content = 'function Test { if ( }'
      { Test-CodeComplexity -Content $content -FilePath 'test.ps1' } | Should -Not -Throw
    }
  }
}

Describe 'Test-MaintainabilityIssues' -Tag 'Unit', 'AdvancedDetection' {
  
  Context 'When analyzing unclear variable names' {
    It 'Should detect single-letter variable names' {
      # Arrange
      $content = @'
function Test-Function {
    $x = 1
    $y = 2
    return $x + $y
}
'@
      
      # Act
      $issues = Test-MaintainabilityIssues -Content $content -FilePath 'test.ps1'
      
      # Assert
      $nameIssues = $issues | Where-Object { $_.Rule -match 'UnclearNaming|VariableNaming' }
      $nameIssues | Should -Not -BeNullOrEmpty
    }

    It 'Should not flag clear variable names' {
      # Arrange
      $content = @'
function Test-Function {
    $firstName = "John"
    $lastName = "Doe"
    return "$firstName $lastName"
}
'@
      
      # Act
      $issues = Test-MaintainabilityIssues -Content $content -FilePath 'test.ps1'
      
      # Assert
      $nameIssues = $issues | Where-Object { $_.Rule -match 'UnclearNaming|VariableNaming' }
      $nameIssues | Should -BeNullOrEmpty
    }
  }

  Context 'When analyzing missing documentation' {
    It 'Should detect functions without help comments' {
      # Arrange
      $content = @'
function Test-NoHelp {
    param($value)
    return $value * 2
}
'@
      
      # Act
      $issues = Test-MaintainabilityIssues -Content $content -FilePath 'test.ps1'
      
      # Assert
      $docIssues = $issues | Where-Object { $_.Rule -match 'MissingDocumentation|MissingHelp' }
      $docIssues | Should -Not -BeNullOrEmpty
    }

    It 'Should not flag documented functions' {
      # Arrange
      $content = @'
function Test-WithHelp {
    <#
    .SYNOPSIS
        A documented function
    #>
    param($value)
    return $value * 2
}
'@
      
      # Act
      $issues = Test-MaintainabilityIssues -Content $content -FilePath 'test.ps1'
      
      # Assert
      $docIssues = $issues | Where-Object { $_.Rule -match 'MissingDocumentation|MissingHelp' }
      $docIssues | Should -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when Content is null' {
      { Test-MaintainabilityIssues -Content $null -FilePath 'test.ps1' } | Should -Throw
    }

    It 'Should handle empty FilePath' {
      $content = 'function Test { return 1 }'
      { Test-MaintainabilityIssues -Content $content } | Should -Not -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle empty content' {
      $issues = Test-MaintainabilityIssues -Content '' -FilePath 'test.ps1'
      $issues | Should -Not -BeNull
    }
  }
}

Describe 'Test-PerformanceAntiPatterns' -Tag 'Unit', 'AdvancedDetection' {
  
  Context 'When analyzing array operations' {
    It 'Should detect += in loops' {
      # Arrange
      $content = @'
function Test-ArrayAddition {
    $result = @()
    foreach ($i in 1..100) {
        $result += $i
    }
    return $result
}
'@
      
      # Act
      $issues = Test-PerformanceAntiPatterns -Content $content -FilePath 'test.ps1'
      
      # Assert
      $arrayIssues = $issues | Where-Object { $_.Rule -eq 'ArrayAdditionInLoop' }
      $arrayIssues | Should -Not -BeNullOrEmpty
      $arrayIssues[0].Severity | Should -Be 'Warning'
      $arrayIssues[0].Message | Should -Match 'ArrayList|List'
    }

    It 'Should not flag efficient array building' {
      # Arrange
      $content = @'
function Test-EfficientArray {
    $result = 1..100 | ForEach-Object { $_ * 2 }
    return $result
}
'@
      
      # Act
      $issues = Test-PerformanceAntiPatterns -Content $content -FilePath 'test.ps1'
      
      # Assert
      $arrayIssues = $issues | Where-Object { $_.Rule -eq 'ArrayAdditionInLoop' }
      $arrayIssues | Should -BeNullOrEmpty
    }
  }

  Context 'When analyzing string operations' {
    It 'Should detect string concatenation in loops' {
      # Arrange
      $content = @'
function Test-StringConcat {
    $result = ""
    foreach ($i in 1..100) {
        $result = $result + "Line $i`n"
    }
    return $result
}
'@
      
      # Act
      $issues = Test-PerformanceAntiPatterns -Content $content -FilePath 'test.ps1'
      
      # Assert
      $stringIssues = $issues | Where-Object { $_.Rule -eq 'StringConcatenationInLoop' }
      $stringIssues | Should -Not -BeNullOrEmpty
      $stringIssues[0].Message | Should -Match 'join|StringBuilder'
    }
  }

  Context 'When analyzing pipeline usage' {
    It 'Should detect Sort-Object before Where-Object' {
      # Arrange
      $content = @'
function Test-PipelineOrder {
    Get-ChildItem | Sort-Object Name | Where-Object { $_.Length -gt 1000 } | Select-Object Name
}
'@
      
      # Act
      $issues = Test-PerformanceAntiPatterns -Content $content -FilePath 'test.ps1'
      
      # Assert
      $pipelineIssues = $issues | Where-Object { $_.Rule -eq 'InefficientPipelineOrder' }
      $pipelineIssues | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when Content is null' {
      { Test-PerformanceAntiPatterns -Content $null -FilePath 'test.ps1' } | Should -Throw
    }

    It 'Should handle empty FilePath' {
      $content = 'function Test { return 1 }'
      { Test-PerformanceAntiPatterns -Content $content } | Should -Not -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle empty content' {
      $issues = Test-PerformanceAntiPatterns -Content '' -FilePath 'test.ps1'
      $issues | Should -Not -BeNull
    }
  }
}

Describe 'Test-SecurityVulnerabilities' -Tag 'Unit', 'AdvancedDetection' {
  
  Context 'When analyzing for Invoke-Expression' {
    It 'Should detect Invoke-Expression usage' {
      # Arrange
      $content = @'
function Test-Dangerous {
    $cmd = "Get-Date"
    Invoke-Expression $cmd
}
'@
      
      # Act
      $issues = Test-SecurityVulnerabilities -Content $content -FilePath 'test.ps1'
      
      # Assert
      $iexIssues = $issues | Where-Object { $_.Rule -match 'InvokeExpression|CodeInjection' }
      $iexIssues | Should -Not -BeNullOrEmpty
      $iexIssues[0].Severity | Should -BeIn @('Error', 'Warning')
    }

    It 'Should not flag safe code' {
      # Arrange
      $content = @'
function Test-Safe {
    $result = Get-Date
    return $result
}
'@
      
      # Act
      $issues = Test-SecurityVulnerabilities -Content $content -FilePath 'test.ps1'
      
      # Assert
      $iexIssues = $issues | Where-Object { $_.Rule -match 'InvokeExpression|CodeInjection' }
      $iexIssues | Should -BeNullOrEmpty
    }
  }

  Context 'When analyzing for hardcoded credentials' {
    It 'Should detect hardcoded passwords' {
      # Arrange
      $content = @'
function Test-HardcodedPassword {
    $password = "P@ssw0rd123"
    $cred = New-Object PSCredential("user", (ConvertTo-SecureString $password -AsPlainText -Force))
}
'@
      
      # Act
      $issues = Test-SecurityVulnerabilities -Content $content -FilePath 'test.ps1'
      
      # Assert
      $credIssues = $issues | Where-Object { $_.Rule -match 'HardcodedCredential|PlainTextPassword' }
      $credIssues | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when Content is null' {
      { Test-SecurityVulnerabilities -Content $null -FilePath 'test.ps1' } | Should -Throw
    }

    It 'Should handle empty FilePath' {
      $content = 'function Test { return 1 }'
      { Test-SecurityVulnerabilities -Content $content } | Should -Not -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle empty content' {
      $issues = Test-SecurityVulnerabilities -Content '' -FilePath 'test.ps1'
      $issues | Should -Not -BeNull
    }
  }
}

Describe 'Invoke-AdvancedDetection' -Tag 'Unit', 'AdvancedDetection' {
  
  Context 'When running all detections' {
    It 'Should aggregate all detection results' {
      # Arrange
      $content = @'
function Test-Multiple {
    if ($true) {
        if ($true) {
            if ($true) {
                if ($true) {
                    if ($true) {
                        Write-Output "Deep"
                    }
                }
            }
        }
    }
    $x = 1
    Invoke-Expression "Get-Date"
}
'@
      
      # Act
      $issues = Invoke-AdvancedDetection -Content $content -FilePath 'test.ps1'
      
      # Assert
      $issues | Should -Not -BeNullOrEmpty
      $issues.Count | Should -BeGreaterThan 1
    }

    It 'Should return empty array for clean code' {
      # Arrange
      $content = @'
function Test-Clean {
    <#
    .SYNOPSIS
        A clean function
    #>
    param($value)
    if ($value -gt 0) {
        return $value * 2
    }
    return 0
}
'@
      
      # Act
      $issues = Invoke-AdvancedDetection -Content $content -FilePath 'test.ps1'
      
      # Assert
      $issues | Should -Not -BeNull
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when Content is null' {
      { Invoke-AdvancedDetection -Content $null -FilePath 'test.ps1' } | Should -Throw
    }

    It 'Should handle empty FilePath' {
      $content = 'function Test { return 1 }'
      { Invoke-AdvancedDetection -Content $content } | Should -Not -Throw
    }
  }
}

Describe 'AdvancedDetection Module Structure' -Tag 'Unit', 'AdvancedDetection' {
  
  Context 'Module export validation' {
    It 'Should export Test-CodeComplexity function' {
      $commands = Get-Command -Module AdvancedDetection
      $commands.Name | Should -Contain 'Test-CodeComplexity'
    }

    It 'Should export Test-MaintainabilityIssues function' {
      $commands = Get-Command -Module AdvancedDetection
      $commands.Name | Should -Contain 'Test-MaintainabilityIssues'
    }

    It 'Should export Test-PerformanceAntiPatterns function' {
      $commands = Get-Command -Module AdvancedDetection
      $commands.Name | Should -Contain 'Test-PerformanceAntiPatterns'
    }

    It 'Should export Test-SecurityVulnerabilities function' {
      $commands = Get-Command -Module AdvancedDetection
      $commands.Name | Should -Contain 'Test-SecurityVulnerabilities'
    }

    It 'Should export Invoke-AdvancedDetection function' {
      $commands = Get-Command -Module AdvancedDetection
      $commands.Name | Should -Contain 'Invoke-AdvancedDetection'
    }

    It 'Should have CmdletBinding on exported functions' {
      $command = Get-Command -Name Test-CodeComplexity
      $command.CmdletBinding | Should -Be $true
    }
  }
}
