#requires -Version 5.1

[CmdletBinding()]
param()


BeforeAll {
    # Import module under test
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../modules/Loggers/PSQALogger.psm1'
    Import-Module $modulePath -Force
}

Describe 'PSQALogger Module' -Tags 'Unit' {

    Context 'Module Initialization' {
        It 'Should export expected functions' {
            $commands = Get-Command -Module PSQALogger
            $commands.Name | Should -Contain 'Initialize-PSQALogger'
            $commands.Name | Should -Contain 'Write-PSQALog'
            $commands.Name | Should -Contain 'Write-PSQAInfo'
            $commands.Name | Should -Contain 'Write-PSQAWarning'
            $commands.Name | Should -Contain 'Write-PSQAError'
        }

        It 'Should initialize with default configuration' {
            { Initialize-PSQALogger } | Should -Not -Throw
        }

        It 'Should accept custom configuration' {
            $config = @{ Level = 'Debug'; EnableConsole = $false }
            { Initialize-PSQALogger -Config $config } | Should -Not -Throw
        }
    }

    Context 'Write-PSQALog' {
        BeforeEach {
            $traceId = (New-Guid).ToString()
        }

        It 'Should write log entry without throwing' {
            { Write-PSQALog -Level Info -Message 'Test message' -TraceId $traceId } | Should -Not -Throw
        }

        It 'Should accept all valid log levels' {
            'Trace', 'Debug', 'Info', 'Warn', 'Error', 'Fatal' | ForEach-Object {
                { Write-PSQALog -Level $_ -Message "Test $_" -TraceId $traceId } | Should -Not -Throw
            }
        }

        It 'Should include optional parameters' {
            { Write-PSQALog -Level Error -Message 'Test' -TraceId $traceId -Code 'E001' -Hint 'Fix it' -Action 'Do this' } | Should -Not -Throw
        }
    }

    Context 'Convenience Functions' {
        BeforeEach {
            $traceId = (New-Guid).ToString()
        }

        It 'Write-PSQAInfo should work' {
            { Write-PSQAInfo -Message 'Info message' -TraceId $traceId } | Should -Not -Throw
        }

        It 'Write-PSQAWarning should work' {
            { Write-PSQAWarning -Message 'Warning' -TraceId $traceId } | Should -Not -Throw
        }

        It 'Write-PSQAError should work' {
            { Write-PSQAError -Message 'Error' -TraceId $traceId -Code 'E001' } | Should -Not -Throw
        }
    }

    Context 'Log File Creation' {
        It 'Should create log directory if missing' {
            $testLogDir = Join-Path -Path $TestDrive -ChildPath 'test-logs'
            $config = @{
                FilePath       = Join-Path -Path $testLogDir -ChildPath 'test.log'
                StructuredPath = Join-Path -Path $testLogDir -ChildPath 'test.jsonl'
            }

            Initialize-PSQALogger -Config $config
            Test-Path -Path $testLogDir | Should -Be $true -ErrorAction Stop
        }
    }
}

AfterAll {
    Remove-Module PSQALogger -Force -ErrorAction SilentlyContinue
}
