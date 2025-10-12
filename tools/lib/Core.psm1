<#
.SYNOPSIS
    Core helper functions for PowerShell QA Engine

.DESCRIPTION
    Common utility functions used across all auto-fix modules:
    - Backup management
    - Logging
    - File discovery
    - Diff generation

.NOTES
    Module: Core
    Version: 2.3.0
    Author: https://github.com/cboyd0319
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Clean-Backups {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    if ($pscmdlet.ShouldProcess("Target", "Operation")) {
        $backupDir = Join-Path -Path $PSScriptRoot -ChildPath '../.psqa-backup'
        if (-not (Test-Path -Path $backupDir -ErrorAction SilentlyContinue)) {
            return
        }

        $cutoffDate = (Get-Date).AddDays(-1)
        Get-ChildItem -Path $backupDir -Recurse -File | Where-Object { $_.LastWriteTime -lt $cutoffDate } | ForEach-Object {
            Write-Verbose "Deleting old backup: $($_.FullName)"
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
        }
    }
}

function Write-Log {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Warn', 'Error', 'Success', 'Critical', 'Debug')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [switch]$NoTimestamp,
        
        [Parameter()]
        [switch]$NoIcon
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    # Enhanced icons and colors for better visual hierarchy
    $iconAndColor = switch ($Level) {
        'Info' { @{ Icon = 'ℹ️'; Color = 'Cyan'; Prefix = 'INFO' } }
        'Warn' { @{ Icon = '⚠️'; Color = 'Yellow'; Prefix = 'WARN' } }
        'Error' { @{ Icon = '❌'; Color = 'Red'; Prefix = 'ERROR' } }
        'Success' { @{ Icon = '✅'; Color = 'Green'; Prefix = 'SUCCESS' } }
        'Critical' { @{ Icon = '🔴'; Color = 'Red'; Prefix = 'CRITICAL' } }
        'Debug' { @{ Icon = '🔍'; Color = 'Gray'; Prefix = 'DEBUG' } }
    }

    $icon = if (-not $NoIcon) { $iconAndColor.Icon + ' ' } else { '' }
    $timestampStr = if (-not $NoTimestamp) { "$timestamp " } else { '' }
    $prefix = "[$($iconAndColor.Prefix)]"

    Write-Host "${timestampStr}${icon}${prefix} ${Message}" -ForegroundColor $iconAndColor.Color
}

function Get-PowerShellFiles {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [string[]]$SupportedExtensions = @('.ps1', '.psm1', '.psd1')
    )

    if (Test-Path -Path $Path -PathType Leaf -ErrorAction Stop) {
        return @(Get-Item -Path $Path -ErrorAction Stop)
    }

    $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
        $SupportedExtensions -contains $_.Extension
    }

    return $files
}

function New-FileBackup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    if ($pscmdlet.ShouldProcess($FilePath, "Backup")) {
        $fileDir = Split-Path -Path $FilePath -Parent
        $backupDir = Join-Path -Path $fileDir -ChildPath '.psqa-backup'

        if (-not (Test-Path -Path $backupDir -ErrorAction SilentlyContinue)) {
            New-Item -Path $backupDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $fileName = Split-Path -Path $FilePath -Leaf
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $backupPath = Join-Path -Path $backupDir -ChildPath "$fileName.$timestamp.bak"

        Copy-Item -Path $FilePath -Destination $backupPath -Force -ErrorAction Stop

        return $backupPath
    }
}

function New-UnifiedDiff {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Original,

        [Parameter(Mandatory)]
        [string]$Modified,

        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $diff = Compare-Object -ReferenceObject ($Original -split '\r?\n') -DifferenceObject ($Modified -split '\r?\n') -IncludeEqual

    $lines = @()
    $lines += "--- a/$FilePath"
    $lines += "+++ b/$FilePath"

    foreach ($line in $diff) {
        $indicator = switch ($line.SideIndicator) {
            '==' { ' ' }
            '<=' { '-' }
            '=>' { '+' }
        }
        $lines += "$($indicator)$($line.InputObject)"
    }

    if ($lines.Count -eq 2) {
        return ""
    }

    return ($lines -join "`n")
}

Export-ModuleMember -Function @(
    'Clean-Backups',
    'Write-Log',
    'Get-PowerShellFiles',
    'New-FileBackup',
    'New-UnifiedDiff'
)
