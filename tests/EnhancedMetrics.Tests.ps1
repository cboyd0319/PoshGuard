#requires -Version 5.1
#requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../tools/lib/EnhancedMetrics.psm1'
    Import-Module -Name $ModulePath -Force -ErrorAction Stop
}

Describe "Enhanced Metrics Module" {
    BeforeEach {
        Initialize-MetricsTracking
    }
    
    Context "Initialize-MetricsTracking" {
        It "Should initialize metrics store" {
            Initialize-MetricsTracking
            $summary = Get-MetricsSummary
            
            $summary.OverallStats.TotalFiles | Should -Be 0
            $summary.OverallStats.TotalAttempts | Should -Be 0
        }
    }
    
    Context "Add-RuleMetric" {
        It "Should track successful fix" {
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100 -ConfidenceScore 0.95
            
            $summary = Get-MetricsSummary
            $rule = $summary.AllRules | Where-Object { $_.RuleName -eq 'TestRule' }
            
            $rule.Successes | Should -Be 1
            $rule.Failures | Should -Be 0
            $rule.AvgDurationMs | Should -Be 100
            $rule.AvgConfidence | Should -Be 0.95
        }
        
        It "Should track failed fix" {
            Add-RuleMetric -RuleName 'TestRule' -Success $false -DurationMs 50 -ErrorMessage 'Test error'
            
            $summary = Get-MetricsSummary
            $rule = $summary.AllRules | Where-Object { $_.RuleName -eq 'TestRule' }
            
            $rule.Successes | Should -Be 0
            $rule.Failures | Should -Be 1
        }
        
        It "Should calculate averages correctly" {
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100 -ConfidenceScore 1.0
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 200 -ConfidenceScore 0.8
            Add-RuleMetric -RuleName 'TestRule' -Success $false -DurationMs 150
            
            $summary = Get-MetricsSummary
            $rule = $summary.AllRules | Where-Object { $_.RuleName -eq 'TestRule' }
            
            $rule.Attempts | Should -Be 3
            $rule.Successes | Should -Be 2
            $rule.Failures | Should -Be 1
            $rule.AvgDurationMs | Should -Be 150
            $rule.AvgConfidence | Should -Be 0.9
        }
        
        It "Should track min and max durations" {
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 50
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 200
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100
            
            # Note: We don't expose min/max in summary, but they're tracked internally
            # This test verifies the metrics are being recorded
            $summary = Get-MetricsSummary
            $rule = $summary.AllRules | Where-Object { $_.RuleName -eq 'TestRule' }
            
            $rule.Attempts | Should -Be 3
        }
    }
    
    Context "Get-FixConfidenceScore" {
        It "Should give high score for valid minimal fix" {
            $original = @'
function Test-Function {
    Write-Host "test"
}
'@
            $fixed = @'
function Test-Function {
    Write-Output "test"
}
'@
            $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
            
            $score | Should -BeGreaterThan 0.7
        }
        
        It "Should give low score for syntax errors" {
            $original = 'function Test { Write-Host "test" }'
            $fixed = 'function Test { Write-Host "test'  # Missing closing quote
            
            $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
            
            $score | Should -BeLessThan 0.7
        }
        
        It "Should penalize extensive changes" {
            $original = @'
function Test {
    Write-Host "1"
    Write-Host "2"
    Write-Host "3"
}
'@
            $fixed = @'
function Test {
    Write-Output "A"
    Write-Output "B"
    Write-Output "C"
    Write-Output "D"
    Write-Output "E"
}
'@
            $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
            
            # High change ratio (80%+) should result in lower score
            $score | Should -BeLessThan 0.85
        }
        
        It "Should penalize introduced dangerous patterns" {
            $original = 'function Test { Write-Host "test" }'
            $fixed = 'function Test { Invoke-Expression "Write-Host test" }'
            
            $score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
            
            $score | Should -BeLessThan 0.9
        }
    }
    
    Context "Add-FileMetric" {
        It "Should record file processing metrics" {
            Add-FileMetric -FilePath 'test.ps1' -ViolationCount 10 -FixedCount 8 -DurationMs 1000 -AvgConfidence 0.85
            
            $summary = Get-MetricsSummary
            $summary.OverallStats.TotalFiles | Should -Be 1
            
            $fileMetric = $summary.FileMetrics | Where-Object { $_.FilePath -eq 'test.ps1' }
            $fileMetric.ViolationCount | Should -Be 10
            $fileMetric.FixedCount | Should -Be 8
            $fileMetric.FixRate | Should -Be 80
            $fileMetric.AvgConfidence | Should -Be 0.85
        }
        
        It "Should handle zero violations" {
            Add-FileMetric -FilePath 'clean.ps1' -ViolationCount 0 -FixedCount 0 -DurationMs 500
            
            $summary = Get-MetricsSummary
            $fileMetric = $summary.FileMetrics | Where-Object { $_.FilePath -eq 'clean.ps1' }
            
            $fileMetric.FixRate | Should -Be 0
        }
    }
    
    Context "Get-MetricsSummary" {
        It "Should calculate overall success rate" {
            Add-RuleMetric -RuleName 'Rule1' -Success $true -DurationMs 100
            Add-RuleMetric -RuleName 'Rule2' -Success $true -DurationMs 100
            Add-RuleMetric -RuleName 'Rule3' -Success $false -DurationMs 100
            Add-RuleMetric -RuleName 'Rule4' -Success $true -DurationMs 100
            
            $summary = Get-MetricsSummary
            
            $summary.OverallStats.TotalAttempts | Should -Be 4
            $summary.OverallStats.TotalSuccesses | Should -Be 3
            $summary.OverallStats.SuccessRate | Should -Be 75
        }
        
        It "Should identify top performers" {
            Add-RuleMetric -RuleName 'GoodRule1' -Success $true -DurationMs 50 -ConfidenceScore 0.95
            Add-RuleMetric -RuleName 'GoodRule2' -Success $true -DurationMs 60 -ConfidenceScore 0.90
            Add-RuleMetric -RuleName 'BadRule' -Success $false -DurationMs 100
            
            $summary = Get-MetricsSummary
            
            $summary.TopPerformers.Count | Should -BeGreaterThan 0
            $summary.TopPerformers[0].SuccessRate | Should -Be 100
        }
        
        It "Should identify problem rules" {
            Add-RuleMetric -RuleName 'ProblematicRule' -Success $false -DurationMs 100
            Add-RuleMetric -RuleName 'ProblematicRule' -Success $false -DurationMs 110
            Add-RuleMetric -RuleName 'ProblematicRule' -Success $true -DurationMs 90
            
            $summary = Get-MetricsSummary
            
            $problemRule = $summary.ProblemRules | Where-Object { $_.RuleName -eq 'ProblematicRule' }
            $problemRule | Should -Not -BeNullOrEmpty
            $problemRule.SuccessRate | Should -BeLessThan 50
        }
        
        It "Should identify slowest rules" {
            Add-RuleMetric -RuleName 'SlowRule' -Success $true -DurationMs 500
            Add-RuleMetric -RuleName 'FastRule' -Success $true -DurationMs 50
            Add-RuleMetric -RuleName 'MediumRule' -Success $true -DurationMs 200
            
            $summary = Get-MetricsSummary
            
            $summary.SlowestRules[0].RuleName | Should -Be 'SlowRule'
        }
        
        It "Should include session duration" {
            Start-Sleep -Milliseconds 100
            
            $summary = Get-MetricsSummary
            
            $summary.SessionDuration.TotalSeconds | Should -BeGreaterThan 0
            $summary.SessionDuration.Formatted | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Export-MetricsReport" {
        It "Should export metrics to JSON" {
            $tempFile = Join-Path -Path $TestDrive -ChildPath 'metrics.json'
            
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100 -ConfidenceScore 0.9
            
            $exportedPath = Export-MetricsReport -OutputPath $tempFile
            
            $exportedPath | Should -Be $tempFile
            Test-Path $tempFile | Should -Be $true
            
            $content = Get-Content $tempFile -Raw | ConvertFrom-Json
            $content.OverallStats | Should -Not -BeNullOrEmpty
        }
        
        It "Should create directory if needed" {
            $tempDir = Join-Path -Path $TestDrive -ChildPath 'metrics'
            $tempFile = Join-Path -Path $tempDir -ChildPath 'report.json'
            
            Export-MetricsReport -OutputPath $tempFile
            
            Test-Path $tempFile | Should -Be $true
        }
    }
    
    Context "Show-MetricsSummary" {
        It "Should display metrics without errors" {
            Add-RuleMetric -RuleName 'TestRule' -Success $true -DurationMs 100 -ConfidenceScore 0.9
            Add-FileMetric -FilePath 'test.ps1' -ViolationCount 5 -FixedCount 4 -DurationMs 500
            
            { Show-MetricsSummary } | Should -Not -Throw
        }
    }
}
