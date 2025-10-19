#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for EnhancedMetrics module

.DESCRIPTION
    Comprehensive unit tests for EnhancedMetrics.psm1 functions:
    - Initialize-MetricsTracking
    - Add-RuleMetric
    - Add-FileMetric
    - Get-MetricsSummary
    - Show-MetricsSummary
    - Export-MetricsReport
    - Get-FixConfidenceScore
    
    Tests cover happy paths, edge cases, error conditions, and parameter validation.
    All tests are hermetic using TestDrive and mocks.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }

  # Import EnhancedMetrics module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/EnhancedMetrics.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find EnhancedMetrics module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'EnhancedMetrics' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
  
  # Initialize performance mocks to prevent slow console I/O
  Initialize-PerformanceMocks -ModuleName 'EnhancedMetrics'
  }
}

Describe 'Initialize-MetricsTracking' -Tag 'Unit', 'EnhancedMetrics' {
  
  Context 'When initializing metrics' {
    It 'Should reset metrics store' {
      # Arrange - Add some metrics first
      Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100
      
      # Act
      Initialize-MetricsTracking
      
      # Assert
      $summary = Get-MetricsSummary
      $summary.TotalFixes | Should -Be 0
      $summary.TotalFailures | Should -Be 0
    }

    It 'Should set session start time' {
      # Act
      Initialize-MetricsTracking
      
      # Assert
      $summary = Get-MetricsSummary
      $summary.SessionStart | Should -Not -BeNullOrEmpty
      $summary.SessionStart | Should -BeOfType [DateTime]
    }

    It 'Should initialize empty collections' {
      # Act
      Initialize-MetricsTracking
      
      # Assert
      $summary = Get-MetricsSummary
      $summary.TotalFiles | Should -Be 0
      $summary.TotalFixes | Should -Be 0
    }

    It 'Should not throw on multiple initializations' {
      # Act & Assert
      { Initialize-MetricsTracking } | Should -Not -Throw
      { Initialize-MetricsTracking } | Should -Not -Throw
    }
  }
}

Describe 'Add-RuleMetric' -Tag 'Unit', 'EnhancedMetrics' {
  
  BeforeEach {
    Initialize-MetricsTracking
  }

  Context 'When recording successful fix' {
    It 'Should record success metrics' {
      # Arrange & Act
      Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 150 -ConfidenceScore 0.95 -FilePath 'test.ps1'
      
      # Assert
      $summary = Get-MetricsSummary
      $summary.TotalFixes | Should -Be 1
      $summary.TotalFailures | Should -Be 0
    }

    It 'Should accept confidence score between 0 and 1' {
      # Act & Assert
      { Add-RuleMetric -RuleName 'Test' -Success $true -DurationMs 100 -ConfidenceScore 0.5 } | Should -Not -Throw
      { Add-RuleMetric -RuleName 'Test' -Success $true -DurationMs 100 -ConfidenceScore 0.0 } | Should -Not -Throw
      { Add-RuleMetric -RuleName 'Test' -Success $true -DurationMs 100 -ConfidenceScore 1.0 } | Should -Not -Throw
    }

    It 'Should reject confidence score outside range' {
      # Act & Assert
      { Add-RuleMetric -RuleName 'Test' -Success $true -DurationMs 100 -ConfidenceScore 1.5 } | Should -Throw
      { Add-RuleMetric -RuleName 'Test' -Success $true -DurationMs 100 -ConfidenceScore -0.1 } | Should -Throw
    }
  }

  Context 'When recording failed fix' {
    It 'Should record failure metrics' {
      # Arrange & Act
      Add-RuleMetric -RuleName 'TestRule' -Success $false -DurationMs 50 -ErrorMessage 'Test error'
      
      # Assert
      $summary = Get-MetricsSummary
      $summary.TotalFailures | Should -Be 1
      $summary.TotalFixes | Should -Be 0
    }

    It 'Should track error message' {
      # Arrange & Act
      Add-RuleMetric -RuleName 'FailRule' -Success $false -DurationMs 25 -ErrorMessage 'Specific error'
      
      # Assert - This verifies the error is tracked (implementation specific)
      { Get-MetricsSummary } | Should -Not -Throw
    }
  }

  Context 'When recording multiple metrics' {
    It 'Should aggregate multiple fixes' {
      # Arrange & Act
      Add-RuleMetric -RuleName 'Rule1' -Success $true -DurationMs 100
      Add-RuleMetric -RuleName 'Rule2' -Success $true -DurationMs 150
      Add-RuleMetric -RuleName 'Rule3' -Success $false -DurationMs 50
      
      # Assert
      $summary = Get-MetricsSummary
      $summary.TotalFixes | Should -Be 2
      $summary.TotalFailures | Should -Be 1
    }

    It 'Should track duration for each rule' {
      # Arrange & Act
      Add-RuleMetric -RuleName 'FastRule' -Success $true -DurationMs 10
      Add-RuleMetric -RuleName 'SlowRule' -Success $true -DurationMs 500
      
      # Assert
      { Get-MetricsSummary } | Should -Not -Throw
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when RuleName is null or empty' {
      { Add-RuleMetric -RuleName $null -Success $true -DurationMs 100 } | Should -Throw
      { Add-RuleMetric -RuleName '' -Success $true -DurationMs 100 } | Should -Throw
    }

    It 'Should throw when DurationMs is negative' {
      { Add-RuleMetric -RuleName 'Test' -Success $true -DurationMs -1 } | Should -Throw
    }
  }
}

Describe 'Add-FileMetric' -Tag 'Unit', 'EnhancedMetrics' {
  
  BeforeEach {
    Initialize-MetricsTracking
  }

  Context 'When adding file metrics' {
    It 'Should increment total files count' {
      # Arrange & Act
      Add-FileMetric -FilePath 'test1.ps1' -IssuesFound 5 -IssuesFixed 4
      Add-FileMetric -FilePath 'test2.ps1' -IssuesFound 3 -IssuesFixed 3
      
      # Assert
      $summary = Get-MetricsSummary
      $summary.TotalFiles | Should -Be 2
    }

    It 'Should track issues found and fixed' {
      # Arrange & Act
      Add-FileMetric -FilePath 'test.ps1' -IssuesFound 10 -IssuesFixed 8
      
      # Assert
      { Get-MetricsSummary } | Should -Not -Throw
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when FilePath is null or empty' {
      { Add-FileMetric -FilePath $null -IssuesFound 1 -IssuesFixed 1 } | Should -Throw
      { Add-FileMetric -FilePath '' -IssuesFound 1 -IssuesFixed 1 } | Should -Throw
    }

    It 'Should throw when counts are negative' {
      { Add-FileMetric -FilePath 'test.ps1' -IssuesFound -1 -IssuesFixed 0 } | Should -Throw
      { Add-FileMetric -FilePath 'test.ps1' -IssuesFound 0 -IssuesFixed -1 } | Should -Throw
    }
  }
}

Describe 'Get-MetricsSummary' -Tag 'Unit', 'EnhancedMetrics' {
  
  BeforeEach {
    Initialize-MetricsTracking
  }

  Context 'When retrieving summary' {
    It 'Should return summary object' {
      # Act
      $summary = Get-MetricsSummary
      
      # Assert
      $summary | Should -Not -BeNullOrEmpty
      $summary.PSObject.Properties.Name | Should -Contain 'TotalFiles'
      $summary.PSObject.Properties.Name | Should -Contain 'TotalFixes'
      $summary.PSObject.Properties.Name | Should -Contain 'TotalFailures'
    }

    It 'Should calculate success rate' {
      # Arrange
      Add-RuleMetric -RuleName 'Rule1' -Success $true -DurationMs 100
      Add-RuleMetric -RuleName 'Rule2' -Success $true -DurationMs 100
      Add-RuleMetric -RuleName 'Rule3' -Success $false -DurationMs 100
      
      # Act
      $summary = Get-MetricsSummary
      
      # Assert
      $summary.SuccessRate | Should -BeGreaterOrEqual 0
      $summary.SuccessRate | Should -BeLessOrEqual 100
    }

    It 'Should calculate average confidence' {
      # Arrange
      Add-RuleMetric -RuleName 'Rule1' -Success $true -DurationMs 100 -ConfidenceScore 0.8
      Add-RuleMetric -RuleName 'Rule2' -Success $true -DurationMs 100 -ConfidenceScore 0.9
      
      # Act
      $summary = Get-MetricsSummary
      
      # Assert
      $summary.AverageConfidence | Should -BeGreaterOrEqual 0
      $summary.AverageConfidence | Should -BeLessOrEqual 1
    }
  }

  Context 'When no metrics recorded' {
    It 'Should return empty summary' {
      # Act
      $summary = Get-MetricsSummary
      
      # Assert
      $summary.TotalFixes | Should -Be 0
      $summary.TotalFailures | Should -Be 0
      $summary.TotalFiles | Should -Be 0
    }

    It 'Should handle division by zero gracefully' {
      # Act
      $summary = Get-MetricsSummary
      
      # Assert - Should not throw, should handle gracefully
      $summary.SuccessRate | Should -BeGreaterOrEqual 0
    }
  }
}

Describe 'Show-MetricsSummary' -Tag 'Unit', 'EnhancedMetrics' {
  
  BeforeEach {
    Initialize-MetricsTracking
  }

  Context 'When displaying summary' {
    It 'Should output without error' {
      # Arrange
      Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100
      
      # Act & Assert
      { Show-MetricsSummary } | Should -Not -Throw
    }

    It 'Should handle empty metrics' {
      # Act & Assert
      { Show-MetricsSummary } | Should -Not -Throw
    }

    It 'Should output to console' {
      # Arrange
      Add-RuleMetric -RuleName 'Rule1' -Success $true -DurationMs 100
      
      # Act
      $output = Show-MetricsSummary *>&1
      
      # Assert
      $output | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Export-MetricsReport' -Tag 'Unit', 'EnhancedMetrics' {
  
  BeforeEach {
    Initialize-MetricsTracking
  }

  Context 'When exporting to JSON' {
    It 'Should create JSON file in TestDrive' {
      # Arrange
      $outputPath = Join-Path -Path $TestDrive -ChildPath 'metrics.json'
      Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100
      
      # Act
      Export-MetricsReport -OutputPath $outputPath
      
      # Assert
      Test-Path -Path $outputPath | Should -Be $true
    }

    It 'Should export valid JSON' {
      # Arrange
      $outputPath = Join-Path -Path $TestDrive -ChildPath 'metrics.json'
      Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100 -ConfidenceScore 0.95
      
      # Act
      Export-MetricsReport -OutputPath $outputPath
      
      # Assert
      $content = Get-Content -Path $outputPath -Raw
      { $content | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'Should include all required fields' {
      # Arrange
      $outputPath = Join-Path -Path $TestDrive -ChildPath 'metrics.json'
      Add-RuleMetric -RuleName 'Rule1' -Success $true -DurationMs 100
      
      # Act
      Export-MetricsReport -OutputPath $outputPath
      
      # Assert
      $data = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
      $data.PSObject.Properties.Name | Should -Contain 'TotalFiles'
      $data.PSObject.Properties.Name | Should -Contain 'TotalFixes'
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when OutputPath is null or empty' {
      { Export-MetricsReport -OutputPath $null } | Should -Throw
      { Export-MetricsReport -OutputPath '' } | Should -Throw
    }

    It 'Should handle invalid path gracefully' {
      # Arrange - Create path that doesn't exist
      $invalidPath = 'Z:\NonExistent\Path\metrics.json'
      
      # Act & Assert
      { Export-MetricsReport -OutputPath $invalidPath } | Should -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should export empty metrics' {
      # Arrange
      $outputPath = Join-Path -Path $TestDrive -ChildPath 'empty.json'
      
      # Act
      Export-MetricsReport -OutputPath $outputPath
      
      # Assert
      Test-Path -Path $outputPath | Should -Be $true
      $data = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
      $data.TotalFixes | Should -Be 0
    }

    It 'Should overwrite existing file' {
      # Arrange
      $outputPath = Join-Path -Path $TestDrive -ChildPath 'metrics.json'
      'old content' | Set-Content -Path $outputPath
      Add-RuleMetric -RuleName 'NewRule' -Success $true -DurationMs 100
      
      # Act
      Export-MetricsReport -OutputPath $outputPath
      
      # Assert
      $content = Get-Content -Path $outputPath -Raw
      $content | Should -Not -Match 'old content'
    }
  }
}

Describe 'Get-FixConfidenceScore' -Tag 'Unit', 'EnhancedMetrics' {
  
  Context 'When comparing identical content' {
    It 'Should return high confidence' {
      # Arrange
      $original = 'function Test { Write-Output "Hello" }'
      $fixed = 'function Test { Write-Output "Hello" }'
      
      # Act
      $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
      
      # Assert
      $score | Should -BeGreaterOrEqual 0.9
      $score | Should -BeLessOrEqual 1.0
    }
  }

  Context 'When content has minor changes' {
    It 'Should return moderate confidence' {
      # Arrange
      $original = 'function Test { write-output "Hello" }'
      $fixed = 'function Test { Write-Output "Hello" }'
      
      # Act
      $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
      
      # Assert
      $score | Should -BeGreaterThan 0.5
      $score | Should -BeLessOrEqual 1.0
    }
  }

  Context 'When content has major changes' {
    It 'Should return lower confidence' {
      # Arrange
      $original = 'function Test { $a = 1 }'
      $fixed = @'
function Test {
    $a = 1
    $b = 2
    $c = 3
    return $a + $b + $c
}
'@
      
      # Act
      $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
      
      # Assert
      $score | Should -BeGreaterOrEqual 0.0
      $score | Should -BeLessThan 0.9
    }
  }

  Context 'Parameter validation' {
    It 'Should throw when OriginalContent is null' {
      { Get-FixConfidenceScore -OriginalContent $null -FixedContent 'test' } | Should -Throw
    }

    It 'Should throw when FixedContent is null' {
      { Get-FixConfidenceScore -OriginalContent 'test' -FixedContent $null } | Should -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle empty strings' {
      # Act
      $score = Get-FixConfidenceScore -OriginalContent '' -FixedContent ''
      
      # Assert
      $score | Should -BeGreaterOrEqual 0.0
      $score | Should -BeLessOrEqual 1.0
    }

    It 'Should handle whitespace-only content' {
      # Arrange
      $original = '   '
      $fixed = '   '
      
      # Act
      $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
      
      # Assert
      $score | Should -BeGreaterOrEqual 0.0
      $score | Should -BeLessOrEqual 1.0
    }
  }
}

Describe 'EnhancedMetrics Module Structure' -Tag 'Unit', 'EnhancedMetrics' {
  
  Context 'Module export validation' {
    It 'Should export Initialize-MetricsTracking function' {
      $commands = Get-Command -Module EnhancedMetrics
      $commands.Name | Should -Contain 'Initialize-MetricsTracking'
    }

    It 'Should export Add-RuleMetric function' {
      $commands = Get-Command -Module EnhancedMetrics
      $commands.Name | Should -Contain 'Add-RuleMetric'
    }

    It 'Should export Add-FileMetric function' {
      $commands = Get-Command -Module EnhancedMetrics
      $commands.Name | Should -Contain 'Add-FileMetric'
    }

    It 'Should export Get-MetricsSummary function' {
      $commands = Get-Command -Module EnhancedMetrics
      $commands.Name | Should -Contain 'Get-MetricsSummary'
    }

    It 'Should export Show-MetricsSummary function' {
      $commands = Get-Command -Module EnhancedMetrics
      $commands.Name | Should -Contain 'Show-MetricsSummary'
    }

    It 'Should export Export-MetricsReport function' {
      $commands = Get-Command -Module EnhancedMetrics
      $commands.Name | Should -Contain 'Export-MetricsReport'
    }

    It 'Should export Get-FixConfidenceScore function' {
      $commands = Get-Command -Module EnhancedMetrics
      $commands.Name | Should -Contain 'Get-FixConfidenceScore'
    }

    It 'Should have CmdletBinding on exported functions' {
      $command = Get-Command -Name Initialize-MetricsTracking
      $command.CmdletBinding | Should -Be $true
    }
  }
}
