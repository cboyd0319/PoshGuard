#!/usr/bin/env pwsh
#requires -Version 5.1

using module '../modules/Core/Core.psm1'
using module '../modules/Fixing/Fixing.psm1'

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,

    [Parameter()]
    [ValidateSet('Analyze', 'Fix', 'Test', 'Report', 'CI', 'All')]
    [string]$Mode = 'Analyze',

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [ValidateScript({ Test-Path -Path $_ -IsValid })]
    [string]$ConfigPath = "$PSScriptRoot/../config",

    [Parameter()]
    [ValidateSet('Console', 'JSON', 'HTML', 'All')]
    [string]$OutputFormat = 'Console'
)

$script:EngineVersion = '4.0.0'

. "$PSScriptRoot/Import-Modules.ps1"

try {
    Write-Verbose "Starting PowerShell QA Engine v$($script:EngineVersion)"

    # Initialize configuration
    Initialize-Configuration -ConfigPath $ConfigPath

    # Discover files
    $files = Get-PSFile -Path $Path

    if ($files.Count -eq 0) {
        Write-Warning "No PowerShell files found to analyze"
        return
    }

    # Process files
    $results = @()
    foreach ($file in $files) {
        $fileResult = Invoke-FileAnalysis -File $file -TraceId (New-Guid)

        if (($Mode -in 'Fix', 'All') -and $fileResult.AnalysisResults.Count -gt 0) {
            $fixup = Invoke-AutoFix -AnalysisResult $fileResult -DryRun:$DryRun.IsPresent
            $fileResult = $fixup.Result
        }

        $results += $fileResult
    }

    # Run tests
    if ($Mode -in 'Test', 'All') {
        Write-Verbose "Running Pester tests..."
        Invoke-Pester -Path './tests' -CI
    }

    # Generate report
    if (($Mode -in 'Report', 'All') -or $OutputFormat -ne 'Console') {
        New-QAReport -Results $results -OutputFormat $OutputFormat
    }

    Write-Verbose "QA Engine execution completed successfully"

if ($Mode -ne 'CI') {
    $results | ConvertTo-Json -Depth 5
}
} catch {
    $errorMessage = "PowerShell QA Engine failed: $_"
    Write-Error $errorMessage
    throw
}