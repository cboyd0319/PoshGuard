#requires -Version 5.1

<#
.SYNOPSIS
    Rollback automation system for PowerShell QA auto-fixes.

.DESCRIPTION
    Safe, idempotent rollback system that restores files from .psqa-backup:
    - Lists available backups with timestamps
    - Selective or batch restore
    - Verification before restore
    - Maintains backup history
    - Safe rollback with confirmation

.PARAMETER Path
    Path to directory or file to restore backups for

.PARAMETER ListOnly
    Only list available backups without restoring

.PARAMETER BackupTimestamp
    Specific backup timestamp to restore (format: yyyyMMddHHmmss)

.PARAMETER Latest
    Restore the most recent backup

.PARAMETER Force
    Skip confirmation prompts

.PARAMETER WhatIf
    Preview what would be restored

.EXAMPLE
    .\Restore-Backup.ps1 -Path ./src -ListOnly
    List all available backups in ./src

.EXAMPLE
    .\Restore-Backup.ps1 -Path ./script.ps1 -Latest
    Restore latest backup of script.ps1

.EXAMPLE
    .\Restore-Backup.ps1 -Path ./src -BackupTimestamp 20251008010203
    Restore specific backup version

.NOTES
    Author: https://github.com/cboyd0319
    Version: 4.3.0
    Safe: Confirms before restore, keeps backup history
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidateScript({ Test-Path -Path $_ })]
  [string]$Path,

  [Parameter()]
  [switch]$ListOnly,

  [Parameter()]
  [ValidatePattern('^\d{14}$')]
  [string]$BackupTimestamp,

  [Parameter()]
  [switch]$Latest,

  [Parameter()]
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helper Functions

<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Write-ColorOutput -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Write-ColorOutput {
  param(
    [Parameter(Mandatory)]
    [string]$Message,

    [Parameter()]
    [ValidateSet('Info', 'Success', 'Warning', 'Error')]
    [string]$Level = 'Info'
  )

  $color = switch ($Level) {
    'Info' { 'Cyan' }
    'Success' { 'Green' }
    'Warning' { 'Yellow' }
    'Error' { 'Red' }
  }

  $prefix = switch ($Level) {
    'Info' { '[INFO]' }
    'Success' { '[OK]' }
    'Warning' { '[WARN]' }
    'Error' { '[ERROR]' }
  }

  Write-Host "$prefix $Message" -ForegroundColor $color
}

<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Get-BackupFiles -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Get-BackupFile {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', `n  Justification = 'Write-Host is used intentionally for colored CLI output')]
[CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param(
    [Parameter(Mandatory)]
    [string]$SearchPath
  )

  $backups = @()

  # Find all .psqa-backup directories
  $backupDirs = Get-ChildItem -Path $SearchPath -Directory -Recurse -Filter '.psqa-backup' -ErrorAction SilentlyContinue

  foreach ($backupDir in $backupDirs) {
    $backupFiles = Get-ChildItem -Path $backupDir.FullName -File -Filter '*.bak'

    foreach ($backupFile in $backupFiles) {
      # Parse filename: original.ext.timestamp.bak
      if ($backupFile.Name -match '(.+)\.(\d{14})\.bak$') {
        $originalName = $Matches[1]
        $timestamp = $Matches[2]

        # Construct original file path
        $originalPath = Join-Path -Path $backupDir.Parent.FullName -ChildPath $originalName

        $backups += [PSCustomObject]@{
          OriginalFile = $originalPath
          BackupFile = $backupFile.FullName
          Timestamp = $timestamp
          DateTime = [DateTime]::ParseExact($timestamp, 'yyyyMMddHHmmss', $null)
          size = $backupFile.Length
          OriginalExists = (Test-Path -Path $originalPath)
        }
      }
    }
  }

  return $backups | Sort-Object -Property DateTime -Descending
}

<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Show-BackupList -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Show-BackupList {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', `n  Justification = 'Write-Host is used intentionally for colored CLI output')]
[CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [PSCustomObject[]]$Backups
  )

  Write-ColorOutput "`nAvailable Backups:" -Level Info
  Write-Host ("=" * 100) -ForegroundColor Gray

  $Backups | Format-Table -AutoSize -Property `
  @{Label = 'Timestamp'; Expression = { $_.Timestamp } },
  @{Label = 'Date/Time'; Expression = { $_.DateTime.ToString('yyyy-MM-dd HH:mm:ss') } },
  @{Label = 'Original File'; Expression = { Split-Path -Path $_.OriginalFile -Leaf } },
  @{Label = 'Size (KB)'; Expression = { [Math]::Round($_.size / 1KB, 2) } },
  @{Label = 'Current Exists'; Expression = { if ($_.OriginalExists) { 'Yes' } else { 'No' } } }

  Write-Host ("=" * 100) -ForegroundColor Gray
  Write-ColorOutput "Total backups found: $($Backups.Count)" -Level Info
}

<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Restore-BackupFile -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Restore-BackupFile {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Backup,

    [Parameter()]
    [switch]$Force
  )

  $originalFile = $Backup.OriginalFile
  $backupFile = $Backup.BackupFile

  Write-ColorOutput "`nRestoring backup:" -Level Info
  Write-Host "  From: $backupFile" -ForegroundColor Gray
  Write-Host "  To:   $originalFile" -ForegroundColor Gray
  Write-Host "  Date: $($Backup.DateTime)" -ForegroundColor Gray

  # Confirm if not forced
  if (-not $Force -and -not $PSCmdlet.ShouldProcess($originalFile, 'Restore from backup')) {
    $response = Read-Host "`nRestore this file? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
      Write-ColorOutput "Skipped: $originalFile" -Level Warning
      return $false
    }
  }

  try {
    # Create safety backup of current file if it exists
    if (Test-Path -Path $originalFile) {
      $safetyBackup = "$originalFile.before-restore.$(Get-Date -Format 'yyyyMMddHHmmss')"
      Copy-Item -Path $originalFile -Destination $safetyBackup -Force -ErrorAction Stop
      Write-ColorOutput "Safety backup created: $safetyBackup" -Level Info
    }

    # Restore from backup
    Copy-Item -Path $backupFile -Destination $originalFile -Force -ErrorAction Stop

    Write-ColorOutput "Successfully restored: $originalFile" -Level Success
    return $true

  }
  catch {
    Write-ColorOutput "Failed to restore $originalFile : $_" -Level Error
    return $false
  }
}

#endregion

#region Main Execution

try {
  Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║      PowerShell QA Rollback System v4.3.0                     ║" -ForegroundColor Cyan
  Write-Host "║      Safe Restore from .psqa-backup                           ║" -ForegroundColor Cyan
  Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

  # Resolve path
  $resolvedPath = Resolve-Path -Path $Path

  Write-ColorOutput "Scanning for backups in: $resolvedPath" -Level Info

  # Find all backups
  $backups = @(Get-BackupFiles -SearchPath $resolvedPath.Path)

  if ($backups.Count -eq 0) {
    Write-ColorOutput "No backups found in .psqa-backup directories" -Level Warning
    exit 0
  }

  # List only mode
  if ($ListOnly) {
    Show-BackupList -Backups $backups
    exit 0
  }

  # Filter backups based on parameters
  $backupsToRestore = $backups

  if ($BackupTimestamp) {
    $backupsToRestore = $backups | Where-Object { $_.Timestamp -eq $BackupTimestamp }
    if ($backupsToRestore.Count -eq 0) {
      Write-ColorOutput "No backups found with timestamp: $BackupTimestamp" -Level Error
      exit 1
    }
  }
  elseif ($Latest) {
    # Group by original file and get latest for each
    $backupsToRestore = $backups | Group-Object -Property OriginalFile | ForEach-Object {
      $_.group | Sort-Object -Property DateTime -Descending | Select-Object -First 1
    }
    Write-ColorOutput "Restoring latest backup for each file" -Level Info
  }

  # Show what will be restored
  Show-BackupList -Backups $backupsToRestore

  # Confirm batch restore
  if ($backupsToRestore.Count -gt 1 -and -not $Force) {
    Write-Output ""
    $response = Read-Host "Restore $($backupsToRestore.Count) file(s)? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
      Write-ColorOutput "Rollback cancelled by user" -Level Warning
      exit 0
    }
  }

  # Perform restores
  $restoredCount = 0
  $failedCount = 0

  foreach ($backup in $backupsToRestore) {
    if (Restore-BackupFile -Backup $backup -Force:$Force) {
      $restoredCount++
    }
    else {
      $failedCount++
    }
  }

  # Summary
  Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║                         SUMMARY                                ║" -ForegroundColor Cyan
  Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

  Write-ColorOutput "Backups found: $($backups.Count)" -Level Info
  Write-ColorOutput "Files restored: $restoredCount" -Level Success

  if ($failedCount -gt 0) {
    Write-ColorOutput "Failed restores: $failedCount" -Level Error
  }

  Write-Host "`n[SUCCESS] Rollback complete!`n" -ForegroundColor Green

  exit 0

}
catch {
  Write-ColorOutput "Fatal error during rollback: $_" -Level Error
  Write-Host "`nStack Trace:" -ForegroundColor Red
  Write-Host $_.ScriptStackTrace -ForegroundColor Red
  exit 1
}

#endregion

