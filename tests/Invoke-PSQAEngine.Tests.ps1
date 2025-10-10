#requires -Version 5.1

[CmdletBinding()]
param()


Describe 'Invoke-PSQAEngine Integration Tests' -Tags 'Integration' {

    Context 'Analyze Mode' {
        It 'Should analyze a file and report issues' {
            $enginePath = Join-Path -Path $PSScriptRoot -ChildPath '../tools/Invoke-PSQAEngine.ps1'
            $testScript = Join-Path -Path $PSScriptRoot -ChildPath 'temp_script.ps1'
            $results = & pwsh -File $enginePath -Path $testScript -Mode 'Analyze'

            $results | Should -Not -BeNullOrEmpty
        } }
}


