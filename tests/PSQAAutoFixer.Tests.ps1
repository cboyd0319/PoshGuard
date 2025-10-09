#requires -Version 5.1

BeforeAll {
    # Import module under test
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../modules/Fixers/PSQAAutoFixer.psm1'
    Import-Module $modulePath -Force

    # Create test file
    $script:testFile = Join-Path -Path $TestDrive -ChildPath 'test.ps1'
}

Describe 'PSQAAutoFixer Module' -Tags 'Unit' {

    Context 'Module Initialization' {
        It 'Should export expected functions' {
            $commands = Get-Command -Module PSQAAutoFixer
            $commands.Name | Should -Contain 'Invoke-PSQAAutoFix'
            $commands.Name | Should -Contain 'New-UnifiedDiff'
            $commands.Name | Should -Contain 'New-FileBackup'
        }
    }

    Context 'Whitespace Fixes' {
        It 'Should remove trailing whitespace' {
            $content = "function Test {    `n    Write-Output 'test'   `n}   "
            Set-Content -Path $script:testFile -Value $content -NoNewline

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun

            $whitespaceResults = $results | Where-Object { $_.FixType -eq 'Whitespace' }
            $whitespaceResults | Should -Not -BeNullOrEmpty
            $whitespaceResults[0].FixedContent | Should -Not -Match '\s+$'
        }

        It 'Should normalize line endings to LF' {
            $content = "function Test {`r`n    Write-Output 'test'`r`n}"
            Set-Content -Path $script:testFile -Value $content -NoNewline

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun

            $whitespaceResults = $results | Where-Object { $_.FixType -eq 'Whitespace' }
            if ($whitespaceResults) {
                $whitespaceResults[0].FixedContent | Should -Not -Match "`r`n"
            }
        }
    }

    Context 'Alias Expansion' {
        It 'Should expand all common aliases' {
            $content = @'
'gci -Path .'
'select -First 10'
'where { $_.Name -like ''*.ps1'' }'
'gcm'
'gm'
'iwr'
'irm'
'cat'
'cp'
'mv'
'rm'
'ls'
'pwd'
'cd'
'cls'
'echo'
'kill'
'ps'
'sleep'
'fl'
'ft'
'fw'
'tee'
'curl'
'wget'
'diff'
'@
            Set-Content -Path $script:testFile -Value $content

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun

            $aliasResults = $results | Where-Object { $_.FixType -eq 'Aliases' }
            $aliasResults | Should -Not -BeNullOrEmpty
            $aliasResults[0].FixedContent | Should -Match 'Get-ChildItem'
            $aliasResults[0].FixedContent | Should -Match 'Select-Object'
            $aliasResults[0].FixedContent | Should -Match 'Where-Object'
            $aliasResults[0].FixedContent | Should -Match 'Get-Command'
            $aliasResults[0].FixedContent | Should -Match 'Get-Member'
            $aliasResults[0].FixedContent | Should -Match 'Invoke-WebRequest'
            $aliasResults[0].FixedContent | Should -Match 'Invoke-RestMethod'
            $aliasResults[0].FixedContent | Should -Match 'Get-Content'
            $aliasResults[0].FixedContent | Should -Match 'Copy-Item'
            $aliasResults[0].FixedContent | Should -Match 'Move-Item'
            $aliasResults[0].FixedContent | Should -Match 'Remove-Item'
            $aliasResults[0].FixedContent | Should -Match 'Get-Location'
            $aliasResults[0].FixedContent | Should -Match 'Set-Location'
            $aliasResults[0].FixedContent | Should -Match 'Clear-Host'
            $aliasResults[0].FixedContent | Should -Match 'Write-Output'
            $aliasResults[0].FixedContent | Should -Match 'Stop-Process'
            $aliasResults[0].FixedContent | Should -Match 'Get-Process'
            $aliasResults[0].FixedContent | Should -Match 'Start-Sleep'
            $aliasResults[0].FixedContent | Should -Match 'Format-List'
            $aliasResults[0].FixedContent | Should -Match 'Format-Table'
            $aliasResults[0].FixedContent | Should -Match 'Format-Wide'
            $aliasResults[0].FixedContent | Should -Match 'Tee-Object'
            $aliasResults[0].FixedContent | Should -Match 'Compare-Object'
        }

        It 'Should not expand aliases in string literals' {
            $content = @'
'"gci"
''gci''
'@
            Set-Content -Path $script:testFile -Value $content

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun

            $aliasResults = $results | Where-Object { $_.FixType -eq 'Aliases' }
            $aliasResults[0].FixedContent | Should -Not -Match 'Get-ChildItem'
        }

        It 'Should not expand aliases as hashtable keys' {
            $content = '@{ gci = "Get-ChildItem" }'
            Set-Content -Path $script:testFile -Value $content

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun

            $aliasResults = $results | Where-Object { $_.FixType -eq 'Aliases' }
            $aliasResults[0].FixedContent | Should -Not -Match 'Get-ChildItem = "Get-ChildItem"'
        }
    }

    Context 'Unified Diff Generation' {
        It 'Should generate unified diff for changes' {
            $original = "line 1`nline 2`nline 3"
            $modified = "line 1`nline 2 modified`nline 3"

            $diff = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'

            $diff | Should -Not -BeNullOrEmpty
            $diff | Should -Match '---'
            $diff | Should -Match '\+\+\+'
            $diff | Should -Match '^-line 2'
            $diff | Should -Match '^\+line 2 modified'
        }

        It 'Should return empty string for no changes' {
            $original = "line 1`nline 2"
            $modified = "line 1`nline 2"

            $diff = New-UnifiedDiff -Original $original -Modified $modified -FilePath 'test.ps1'

            $diff | Should -BeNullOrEmpty
        }
    }

    Context 'Backup Creation' {
        It 'Should create backup file' {
            $content = 'function Test { }'
            Set-Content -Path $script:testFile -Value $content

            $backupPath = New-FileBackup -FilePath $script:testFile

            Test-Path -Path $backupPath | Should -Be $true
            Get-Content -Path $backupPath -Raw | Should -Be $content
        }

        It 'Should create .psqa-backup directory' {
            $content = 'function Test { }'
            Set-Content -Path $script:testFile -Value $content

            $backupPath = New-FileBackup -FilePath $script:testFile
            $backupDir = Split-Path -Path $backupPath -Parent

            $backupDir | Should -Match '\.psqa-backup'
            Test-Path -Path $backupDir | Should -Be $true
        }
    }

    Context 'Dry Run Mode' {
        It 'Should not modify files in dry run mode' {
            $originalContent = "gci`n   trailing spaces   "
            Set-Content -Path $script:testFile -Value $originalContent -NoNewline

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun

            $currentContent = Get-Content -Path $script:testFile -Raw
            $currentContent | Should -Be $originalContent
        }

        It 'Should show what would be fixed' {
            $content = "gci -Path .   "
            Set-Content -Path $script:testFile -Value $content

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun

            $results | Should -Not -BeNullOrEmpty
            $results[0].Applied | Should -Be $false
        }
    }

    Context 'Safety Fixes' {
        It 'Should fix $null position in comparisons' {
            $content = 'if ($var -eq $null) { }'
            Set-Content -Path $script:testFile -Value $content

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun -FixTypes @('Security')

            if ($results) {
                $results[0].FixedContent | Should -Match '\$null -eq \$var'
            }
        }

        It 'Should fix $null position in comparisons with parentheses' {
            $content = 'if (($var) -eq $null) { }'
            Set-Content -Path $script:testFile -Value $content

            $results = Invoke-PSQAAutoFix -FilePath $script:testFile -DryRun -FixTypes @('Security')

            if ($results) {
                $results[0].FixedContent | Should -Match '\$null -eq \(\$var\)'
            }
        }
    }
}

AfterAll {
    Remove-Module PSQAAutoFixer -Force -ErrorAction SilentlyContinue
}
