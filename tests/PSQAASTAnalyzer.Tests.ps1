#requires -Version 5.1

using module '../modules/Core/Core.psm1'

BeforeAll {
    # Import module under test
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../modules/Analyzers/PSQAASTAnalyzer.psm1'
    Import-Module $modulePath -Force

    # Create test file
    $script:testFile = Join-Path -Path $TestDrive -ChildPath 'test.ps1'
}

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
            Set-Content -Path $script:testFile1 -Value $content

            $issues = Invoke-PSQAASTAnalysis -FilePath $script:testFile1
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
            Set-Content -Path $script:testFile1 -Value $content

            $issues = Invoke-PSQAASTAnalysis -FilePath $script:testFile1
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
                            }
                        }
                    }
                }
            }
        }
    }
}
'@
            Set-Content -Path $script:testFile1 -Value $content

            $issues = Invoke-PSQAASTAnalysis -FilePath $script:testFile1
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
            Set-Content -Path $script:testFile1 -Value $content

            $issues = Invoke-PSQAASTAnalysis -FilePath $script:testFile1
            $iexIssues = $issues | Where-Object { $_.RuleName -eq 'UnsafeInvokeExpression' }

            $iexIssues | Should -Not -BeNullOrEmpty
            $iexIssues[0].Severity | Should -Be 'Error'
        }

        It 'Should detect global variables' {
            $content = @'
$global:myVar = "test"
'@
            Set-Content -Path $script:testFile1 -Value $content

            $issues = Invoke-PSQAASTAnalysis -FilePath $script:testFile1
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
            Set-Content -Path $script:testFile1 -Value $content

            $issues = Invoke-PSQAASTAnalysis -FilePath $script:testFile1
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
            Set-Content -Path $script:testFile1 -Value $content

            $issues = Invoke-PSQAASTAnalysis -FilePath $script:testFile1
            $parseErrors = $issues | Where-Object { $_.RuleName -eq 'ParseError' }

            $parseErrors | Should -Not -BeNullOrEmpty
            $parseErrors[0].Severity | Should -Be 'Error'
        }
    }
}

AfterAll {
    Remove-Module PSQAASTAnalyzer -Force -ErrorAction SilentlyContinue
}
