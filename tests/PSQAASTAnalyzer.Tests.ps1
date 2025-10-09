#requires -Version 5.1

using module '../modules/Core/Core.psm1'
using module '../modules/Analyzers/PSQAASTAnalyzer.psm1'

Describe 'PSQAASTAnalyzer Module' -Tags 'Unit' {

    Context 'Module Initialization' {
        It 'Should export Invoke-PSQAASTAnalysis function' {
            $commands = Get-Command -Module PSQAASTAnalyzer
            $commands.Name | Should -Contain 'Invoke-PSQAASTAnalysis'
        }
    }

    Context 'Unbound Variable Detection' {
        It 'Should detect unbound variables' {
            $content = @'
function Test-Function {
    Write-Output $unboundVariable
}
'@
            $testFile = New-TemporaryFile
            Set-Content -Path $testFile -Value $content
            $issues = Invoke-PSQAASTAnalysis -Path $testFile
            $unboundIssues = $issues | Where-Object { $_.RuleName -eq 'UnboundVariable' }

            $unboundIssues | Should -Not -BeNullOrEmpty
        }

        It 'Should not flag automatic variables as unbound' {
            $content = @'
function Test-Function {
    Write-Output $PSScriptRoot
    Write-Output $PSCommandPath
}
'@
            $testFile = New-TemporaryFile
            Set-Content -Path $testFile -Value $content
            $issues = Invoke-PSQAASTAnalysis -Path $testFile
            $unboundIssues = $issues | Where-Object { $_.RuleName -eq 'UnboundVariable' }

            $unboundIssues | Should -BeNullOrEmpty
        }
    }

    Context 'Cognitive Complexity Detection' {
        It 'Should detect high cognitive complexity' {
            $content = @'
function Test-ComplexFunction {
    if ($true) {
        if ($true) {
            if ($true) {
                if ($true) {
                    foreach ($i in 1..10) {
                        while ($true) {
                            switch ($i) {
                                1 { break }
                                2 { break }
                                3 { break }
                                4 { break }
                                5 { break }
                                6 { break }
                                7 { break }
                                8 { break }
                                9 { break }
                                10 { break }
                                11 { break }
                                12 { break }
                                13 { break }
                                14 { break }
                                15 { break }
                                16 { break }
                            }
                        }
                    }
                }
            }
        }
    }
}
'@
            $testFile = New-TemporaryFile
            Set-Content -Path $testFile -Value $content
            $issues = Invoke-PSQAASTAnalysis -Path $testFile
            $complexityIssues = $issues | Where-Object { $_.RuleName -eq 'HighCognitiveComplexity' }

            $complexityIssues | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Unsafe Pattern Detection' {
        It 'Should detect Invoke-Expression usage' {
            $content = @'
$command = "Get-Process"
Invoke-Expression $command
'@
            $testFile = New-TemporaryFile
            Set-Content -Path $testFile -Value $content
            $issues = Invoke-PSQAASTAnalysis -Path $testFile
            $iexIssues = $issues | Where-Object { $_.RuleName -eq 'UnsafeInvokeExpression' }

            $iexIssues | Should -Not -BeNullOrEmpty
            $iexIssues[0].Severity | Should -Be 'Error'
        }

        It 'Should detect global variables' {
            $content = @'
$global:myVar = "test"
'@
            $testFile = New-TemporaryFile
            Set-Content -Path $testFile -Value $content
            $issues = Invoke-PSQAASTAnalysis -Path $testFile
            $globalIssues = $issues | Where-Object { $_.RuleName -eq 'GlobalVariableUsage' }

            $globalIssues | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Empty Catch Block Detection' {
        It 'Should detect empty catch blocks' {
            $content = @'
try {
    Get-Process
} catch {
}
'@
            $testFile = New-TemporaryFile
            Set-Content -Path $testFile -Value $content
            $issues = Invoke-PSQAASTAnalysis -Path $testFile
            $catchIssues = $issues | Where-Object { $_.RuleName -eq 'EmptyCatchBlock' }

            $catchIssues | Should -Not -BeNullOrEmpty
            $catchIssues[0].Severity | Should -Be 'Warning'
        }
    }

    Context 'Parse Error Handling' {
        It 'Should return parse errors for invalid syntax' {
            $content = @'
function Test-Function {
    if ($true {
        Write-Output "Missing closing paren"
    }
}
'@
            $testFile = New-TemporaryFile
            Set-Content -Path $testFile -Value $content
            $issues = Invoke-PSQAASTAnalysis -Path $testFile
            $parseErrors = $issues | Where-Object { $_.RuleName -eq 'ParseError' }

            $parseErrors | Should -Not -BeNullOrEmpty
            $parseErrors[0].Severity | Should -Be 'Error'
        }
    }
}
