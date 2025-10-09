#!/usr/bin/env pwsh
#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$engineRoot = "/Users/chadboyd/Documents/GitHub/PoshGuard/tools"

try {
    $filePath = "$engineRoot/../README.md"
    $settingsPath = "$engineRoot/../config/PSScriptAnalyzerSettings.psd1"
    
    Invoke-ScriptAnalyzer -Path $filePath -Settings $settingsPath
    
    Write-Host "Invoke-ScriptAnalyzer ran successfully"
}
catch {
    Write-Host "An error occurred:"
    Write-Host $_.Exception.Message
    exit 1
}
