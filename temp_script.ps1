#!/usr/bin/env pwsh
#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$engineRoot = "/Users/chadboyd/Documents/GitHub/PoshGuard/tools"

try {
    Import-Module "$engineRoot/../modules/Core/Core.psm1" -Force
    Get-Command Get-Command -ErrorAction Stop | Out-Null
    Write-Host "Core module loaded successfully"

    Import-Module "$engineRoot/../modules/Configuration/Configuration.psm1"
    Get-Command Get-Command -ErrorAction Stop | Out-Null
    Write-Host "Configuration module loaded successfully"

    Import-Module "$engineRoot/../modules/FileSystem/FileSystem.psm1"
    Get-Command Get-Command -ErrorAction Stop | Out-Null
    Write-Host "FileSystem module loaded successfully"

    Import-Module "$engineRoot/../modules/Analysis/Analysis.psm1"
    Get-Command Get-Command -ErrorAction Stop | Out-Null
    Write-Host "Analysis module loaded successfully"

    Import-Module "$engineRoot/../modules/Fixing/Fixing.psm1"
    Get-Command Get-Command -ErrorAction Stop | Out-Null
    Write-Host "Fixing module loaded successfully"

    Import-Module "$engineRoot/../modules/Reporting/Reporting.psm1"
    Get-Command Get-Command -ErrorAction Stop | Out-Null
    Write-Host "Reporting module loaded successfully"

    Import-Module "$engineRoot/../modules/Analyzers/PSQAASTAnalyzer.psm1" -Force
    Get-Command Get-Command -ErrorAction Stop | Out-Null
    Write-Host "PSQAASTAnalyzer module loaded successfully"

    Write-Host "All modules loaded successfully"
}
catch {
    Write-Host "A module failed to load or broke Get-Command:"
    Write-Host $_.Exception.Message
    exit 1
}
