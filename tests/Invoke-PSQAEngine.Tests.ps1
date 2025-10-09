#requires -Version 5.1

BeforeAll {
    $script:enginePath = Join-Path -Path $PSScriptRoot -ChildPath '../tools/Invoke-PSQAEngine.ps1'
    $script:testFile = Join-Path -Path $PSScriptRoot -ChildPath 'temp_script.ps1'
    $script:TempTestScript = Join-Path -Path $PSScriptRoot -ChildPath 'temp_script.test.ps1'
}

Describe 'Invoke-PSQAEngine Script' -Tags 'Integration' {

    BeforeEach {
        Copy-Item -Path $script:testFile -Destination $script:TempTestScript -Force
    }

    AfterEach {
        if (Test-Path $script:TempTestScript) {
            Remove-Item $script:TempTestScript -Force
        }
    }

    Context 'Analyze Mode' {
        It 'Should analyze a file and return results' {
            $results = & $script:enginePath -Path $script:TempTestScript -Mode 'Analyze' | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.AnalysisResults | Should -Not -BeNullOrEmpty
        }

        It 'Should detect alias usage' {
            $results = & $script:enginePath -Path $script:TempTestScript -Mode 'Analyze' | ConvertFrom-Json
            $analysisResults = $results.AnalysisResults | Where-Object { $_.RuleName -eq 'PSAvoidUsingCmdletAliases' }
            $analysisResults | Should -Not -BeNullOrEmpty
        }

        It 'Should detect Write-Host usage' {
            $results = & $script:enginePath -Path $script:TempTestScript -Mode 'Analyze' | ConvertFrom-Json
            $analysisResults = $results.AnalysisResults | Where-Object { $_.RuleName -eq 'PSAvoidUsingWriteHost' }
            $analysisResults | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Fix Mode (DryRun)' {
        It 'Should show proposed fixes in dry run mode' {
            $results = & $script:enginePath -Path $script:TempTestScript -Mode 'Fix' -DryRun | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.FixResults | Should -Not -BeNullOrEmpty
            $results.FixResults.Applied | Should -Not -Contain $true
        }
    }

    Context 'Fix Mode (Live)' {
        It 'should fix the test script and reduce the number of issues' {
            $initialResults = & $script:enginePath -Path $script:TempTestScript -Mode Analyze | ConvertFrom-Json
            $initialIssueCount = ($initialResults.AnalysisResults | Measure-Object).Count

            & $script:enginePath -Path $script:TempTestScript -Mode Fix

            $fixedResults = & $script:enginePath -Path $script:TempTestScript -Mode Analyze | ConvertFrom-Json
            $fixedIssueCount = ($fixedResults.AnalysisResults | Measure-Object).Count

            $fixedIssueCount | Should -BeLessThan $initialIssueCount
        }
    }
}