#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for Phase 2 auto-fix implementations

.DESCRIPTION
    Tests for:
    - PSAvoidLongLines (Invoke-LongLinesFix)
    - PSReviewUnusedParameter (Invoke-UnusedParameterFix)
#>

BeforeAll {
    # Load only the function definitions without executing the script
    $autoFixScript = Join-Path $PSScriptRoot '../tools/Apply-AutoFix.ps1'
    $scriptContent = Get-Content -Path $autoFixScript -Raw
    
    # Extract and define Invoke-LongLinesFix function
    if ($scriptContent -match '(?ms)(function Invoke-LongLinesFix \{.*?\n\}(?=\n\nfunction |\n\n#|\n\nparam|\z))') {
        Invoke-Expression $Matches[1]
    } else {
        throw "Could not extract Invoke-LongLinesFix function"
    }
    
    # Extract and define Invoke-UnusedParameterFix function
    if ($scriptContent -match '(?ms)(function Invoke-UnusedParameterFix \{.*?\n\}(?=\n\nfunction |\n\n#|\n\nparam|\z))') {
        Invoke-Expression $Matches[1]
    } else {
        throw "Could not extract Invoke-UnusedParameterFix function"
    }
}

Describe 'Phase 2 Auto-Fix Tests' {
    
    Context 'PSAvoidLongLines - Invoke-LongLinesFix' {
        
        It 'Should wrap long command with multiple parameters' {
            $input = @'
Get-ChildItem -Path C:\VeryLongPath\With\Many\Subdirectories\That\Exceeds\OneHundredTwentyCharacters -Filter *.ps1 -Recurse -ErrorAction Stop
'@
            $result = Invoke-LongLinesFix -Content $input
            $lines = $result -split '\r?\n'
            
            # Should have multiple lines now
            $lines.Count | Should -BeGreaterThan 1
            
            # Each line should be under 120 chars (or close to it)
            foreach ($line in $lines) {
                if ($line -match '``\s*$') {
                    # Continuation lines are allowed to be slightly longer
                    $line.Length | Should -BeLessOrEqual 130
                }
            }
            
            # Should contain backticks for continuation
            $result | Should -Match '``'
        }
        
        It 'Should wrap pipeline chains' {
            $input = @'
Get-Process | Where-Object { $_.CPU -gt 100 } | Sort-Object -Property CPU -Descending | Select-Object -First 10 | Format-Table -AutoSize
'@
            $result = Invoke-LongLinesFix -Content $input
            $lines = $result -split '\r?\n'
            
            # Should break at pipe operators
            $lines.Count | Should -BeGreaterThan 1
            
            # Should contain pipe operators on appropriate lines
            $pipeCount = ($result -split '\|').Count - 1
            $pipeCount | Should -BeGreaterThan 1
        }
        
        It 'Should preserve short lines' {
            $input = @'
$x = 1
Write-Host "Hello"
Get-Process
'@
            $result = Invoke-LongLinesFix -Content $input
            
            # Should be unchanged
            $result | Should -BeExactly $input
        }
        
        It 'Should preserve comment lines even if long' {
            $input = @'
# This is a very long comment line that exceeds one hundred and twenty characters but should not be wrapped because comments have different formatting rules
$x = 1
'@
            $result = Invoke-LongLinesFix -Content $input
            
            # Comment line should be preserved
            $result | Should -Match '# This is a very long comment'
        }
        
        It 'Should preserve here-strings' {
            $input = @'
$text = @"
This is a very long here-string line that exceeds one hundred and twenty characters but should not be wrapped because here-strings are literal
"@
'@
            $result = Invoke-LongLinesFix -Content $input
            
            # Should be unchanged
            $result | Should -Match 'This is a very long here-string'
        }
        
        It 'Should preserve indentation when wrapping' {
            $input = @'
function Test-Function {
    Get-ChildItem -Path C:\VeryLongPath\With\Many\Subdirectories\That\Exceeds\OneHundredTwentyCharacters -Filter *.ps1 -Recurse -ErrorAction Stop
}
'@
            $result = Invoke-LongLinesFix -Content $input
            $lines = $result -split '\r?\n'
            
            # Wrapped lines should maintain or increase indentation
            $wrappedLines = $lines | Where-Object { $_ -match 'Path|Filter|Recurse|ErrorAction' }
            foreach ($line in $wrappedLines) {
                $line | Should -Match '^\s{4,}'  # At least 4 spaces
            }
        }
    }
    
    Context 'PSReviewUnusedParameter - Invoke-UnusedParameterFix' {
        
        It 'Should comment out unused parameters' {
            $input = @'
function Test-Function {
    param(
        $UsedParam,
        $UnusedParam
    )
    
    Write-Host $UsedParam
}
'@
            $result = Invoke-UnusedParameterFix -Content $input
            
            # Should comment out the unused parameter
            $result | Should -Match '# REMOVED \(unused parameter\).*UnusedParam'
            
            # Should keep the used parameter
            $result | Should -Match '\$UsedParam' -Not -Match '# REMOVED.*UsedParam'
        }
        
        It 'Should preserve parameters when splatting is used' {
            $input = @'
function Test-Function {
    param(
        $Param1,
        $Param2
    )
    
    $params = @{
        Name = $Param1
    }
    
    Get-Something @PSBoundParameters
}
'@
            $result = Invoke-UnusedParameterFix -Content $input
            
            # Should NOT comment out parameters when splatting is used
            $result | Should -Not -Match '# REMOVED'
        }
        
        It 'Should handle multiple unused parameters' {
            $input = @'
function Test-Function {
    param(
        $Used,
        $Unused1,
        $Unused2,
        $Unused3
    )
    
    Write-Host $Used
}
'@
            $result = Invoke-UnusedParameterFix -Content $input
            
            # Should comment out all unused parameters
            $result | Should -Match '# REMOVED.*Unused1'
            $result | Should -Match '# REMOVED.*Unused2'
            $result | Should -Match '# REMOVED.*Unused3'
            
            # Should preserve used parameter
            $result | Should -Match '\$Used' -Not -Match '# REMOVED.*\$Used'
        }
        
        It 'Should not affect functions with all parameters used' {
            $input = @'
function Test-Function {
    param(
        $Param1,
        $Param2
    )
    
    Write-Host "$Param1 and $Param2"
}
'@
            $result = Invoke-UnusedParameterFix -Content $input
            
            # Should be unchanged (no unused params)
            $result | Should -Not -Match '# REMOVED'
        }
        
        It 'Should handle parameters in different scopes correctly' {
            $input = @'
function Test-Outer {
    param($OuterParam)
    
    function Test-Inner {
        param($InnerParam)
        Write-Host $InnerParam
    }
    
    Test-Inner -InnerParam "test"
}
'@
            $result = Invoke-UnusedParameterFix -Content $input
            
            # Should comment out OuterParam (unused in outer function)
            $result | Should -Match '# REMOVED.*OuterParam'
            
            # Should NOT comment out InnerParam (used in inner function)
            $result | Should -Not -Match '# REMOVED.*InnerParam'
        }
    }
    
    Context 'Integration Tests - Phase 2' {
        
        It 'Should handle both fixes in sequence' {
            $input = @'
function Test-LongFunction {
    param(
        $UsedParam,
        $UnusedParam
    )
    
    Get-ChildItem -Path C:\VeryLongPath\With\Many\Subdirectories\That\Exceeds\OneHundredTwentyCharacters -Filter *.ps1 -Recurse -ErrorAction Stop | Where-Object { $UsedParam }
}
'@
            # Apply both fixes
            $result = Invoke-UnusedParameterFix -Content $input
            $result = Invoke-LongLinesFix -Content $result
            
            # Should have commented out unused parameter
            $result | Should -Match '# REMOVED.*UnusedParam'
            
            # Should have wrapped long line
            $lines = $result -split '\r?\n'
            $lines.Count | Should -BeGreaterThan 6  # Original was ~7 lines
            
            # Verify it parses correctly
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($result, [ref]$tokens, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
}
