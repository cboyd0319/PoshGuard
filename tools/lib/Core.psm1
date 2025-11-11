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

function Clear-Backup {
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
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is used intentionally for colored CLI output')]
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
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is used intentionally for FastScan progress output')]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter()]
    [string[]]$SupportedExtensions = @('.ps1', '.psm1', '.psd1'),

    [Parameter()]
    [switch]$FastScan
  )

  if (Test-Path -Path $Path -PathType Leaf -ErrorAction Stop) {
    return @(Get-Item -Path $Path -ErrorAction Stop)
  }

  # Use RipGrep pre-filtering if FastScan is enabled
  if ($FastScan) {
    try {
      # Check if RipGrep module is available
      if (Get-Command Find-SuspiciousScripts -ErrorAction SilentlyContinue) {
        $candidateFiles = Find-SuspiciousScripts -Path $Path
        if ($candidateFiles) {
          $totalFiles = (Get-ChildItem -Path $Path -Recurse -File | Where-Object { $SupportedExtensions -contains $_.Extension }).Count
          $candidateCount = ($candidateFiles | Measure-Object).Count
          $skippedCount = $totalFiles - $candidateCount
                    
          Write-Host "  🚀 RipGrep FastScan: Found $candidateCount candidate files (skipping $skippedCount safe files)" -ForegroundColor Cyan
                    
          # Convert paths to FileInfo objects
          $files = $candidateFiles | ForEach-Object { Get-Item -Path $_ -ErrorAction SilentlyContinue } | Where-Object { $_ }
          return $files
        }
      }
    }
    catch {
      Write-Verbose "FastScan failed, falling back to normal scan: $_"
    }
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
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', 
    Justification = 'This function creates data structures in memory and does not modify system state')]
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
  'Clear-Backup',
  'Write-Log',
  'Get-PowerShellFiles',
  'New-FileBackup',
  'New-UnifiedDiff'
)