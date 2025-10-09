#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Standalone idempotent auto-fix script for PowerShell code quality.

.DESCRIPTION
    Self-contained, idempotent script that applies safe automated fixes to PowerShell code:
    - Formats with Invoke-Formatter (if available)
    - Removes trailing whitespace
    - Expands cmdlet aliases
    - Normalizes line endings
    - Fixes common security issues
    - Creates backups automatically
    - Generates unified diffs
    - Safe to run multiple times (idempotent)

.PARAMETER Path
    Path to PowerShell file(s) or directory to fix

.PARAMETER DryRun
    Preview changes without applying them

.PARAMETER NoBackup
    Skip creating backups (not recommended)

.PARAMETER ShowDiff
    Display unified diffs of changes

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    .\Set-AutoFix.ps1 -Path ./src -DryRun
    Preview fixes without applying

.EXAMPLE
    .\Set-AutoFix.ps1 -Path ./script.ps1 -ShowDiff
    Apply fixes and show unified diffs

.EXAMPLE
    .\Set-AutoFix.ps1 -Path ./src
    Apply all safe fixes to directory

.NOTES
    Author: PowerShell QA Engine
    Version: 4.0.0
    Idempotent: Safe to run multiple times
    Compatible: PowerShell 5.1+, PowerShell 7.x
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ Test-Path -Path $_ })]
# FIXME: Unused parameter commented out by PSQA.
#     [string]$Path,

#     [Parameter()]
# FIXME: Unused parameter commented out by PSQA.
#     [switch]$DryRun,

#     [Parameter()]
# FIXME: Unused parameter commented out by PSQA.
#     [switch]$NoBackup,

#     [Parameter()]
# FIXME: Unused parameter commented out by PSQA.
#     [switch]$ShowDiff,

#     [Parameter()]
# FIXME: Unused parameter commented out by PSQA.
#     [switch]$CleanBackups,

    [Parameter()]
    [ValidateSet('Default', 'UTF8', 'UTF8BOM')]
# FIXME: Unused parameter commented out by PSQA.
#     [string]$Encoding = 'Default'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Configuration

$script:Config = @{
    SupportedExtensions = @('.ps1', '.psm1', '.psd1')
    BackupDirectory = '.psqa-backup'
    LogDirectory = './logs'
    MaxFileSizeBytes = 10485760  # 10MB
    TraceId = (New-Guid).ToString()
    BackupRetentionDays = 1
}

#endregion

#region Helper Functions

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding(SupportsShouldProcess)]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Clean-Backups -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Clean-Backups {
        if ($pscmdlet.ShouldProcess("Target", "Operation")) {
            # Add state-changing code here
        }
        if ($pscmdlet.ShouldProcess("Target", "Operation")) {
            # Add state-changing code here
        }
    [CmdletBinding()]
    param()

    $backupDir = Join-Path -Path $PSScriptRoot -ChildPath $script:Config.BackupDirectory
    if (-not (Test-Path -Path $backupDir)) {
        return
    }

    $cutoffDate = (Get-Date).AddDays(-$script:Config.BackupRetentionDays)
    Get-ChildItem -Path $backupDir -Recurse -File | Where-Object { $_.LastWriteTime -lt $cutoffDate } | ForEach-Object {
        Write-Log -Level Info -Message "Deleting old backup: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force
    }
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Write-Log -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Warn', 'Error', 'Success')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Warn'    { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }

    $prefix = switch ($Level) {
        'Info'    { '[INFO]' }
        'Warn'    { '[WARN]' }
        'Error'   { '[ERROR]' }
        'Success' { '[OK]' }
    }

    Write-Output "$timestamp $prefix $Message" -ForegroundColor $color
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Get-PowerShellFiles -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Get-PowerShellFiles {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
#         [Parameter(Mandatory)]
# FIXME: Unused parameter commented out by PSQA.
#         [string]$Path
    )

    if (Test-Path -Path $Path -PathType Leaf) {
        return @((Get-Item -Path $Path))
    }

    $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
        $script:Config.SupportedExtensions -contains $_.Extension
    }

    return $files
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> New-FileBackup -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function New-FileBackup {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $fileDir = Split-Path -Path $FilePath -Parent
    $backupDir = Join-Path -Path $fileDir -ChildPath $script:Config.BackupDirectory

    if (-not (Test-Path -Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }

    $fileName = Split-Path -Path $FilePath -Leaf
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $backupPath = Join-Path -Path $backupDir -ChildPath "$fileName.$timestamp.bak"

    Copy-Item -Path $FilePath -Destination $backupPath -Force

    return $backupPath
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> New-UnifiedDiff -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
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
    $lines += "---    a/$FilePath"
    $lines += "+++    b/$FilePath"

    # This is a simplified diff generator, not a full-fidelity one.
    foreach ($line in $diff) {
        $indicator = switch ($line.SideIndicator) {
            '==' { ' ' }
            '<=' { '-' }
            '=>' { '+' }
        }
        $lines += "$indicator$($line.InputObject)"
    }

    if ($lines.Count -eq 2) {
        return "" # No changes
    }

    return ($lines -join "`n")
}

#endregion

#region Fix Functions

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Invoke-FormatterFix -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Invoke-FormatterFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [Parameter()]
        [string]$FilePath = ''
    )

    if ($FilePath -match 'PSQAAutoFixer\.psm1$') {
        Write-Verbose "Skipping Invoke-Formatter on PSQAAutoFixer to prevent self-corruption"
        return $Content
    }

    if (-not (Get-Command -Name Invoke-Formatter -ErrorAction SilentlyContinue)) {
        Write-Log -Level Warn -Message "Invoke-Formatter not available (PSScriptAnalyzer not installed)"
        return $Content
    }

    try {
        return Invoke-Formatter -ScriptDefinition $Content
    } catch {
        Write-Log -Level Warn -Message "Invoke-Formatter failed: $_ "
    }

    return $Content
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Invoke-WhitespaceFix -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Invoke-WhitespaceFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $lines = $Content -split "`r?`n"
    $fixed = $lines | ForEach-Object { $_.TrimEnd() }
    $result = $fixed -join "`n"

    if (-not $result.EndsWith("`n")) {
        $result += "`n"
    }

    return $result
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Invoke-AliasFix -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Invoke-AliasFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [Parameter()]
        [string]$FilePath = ''
    )

    if ($FilePath -match 'PSQAAutoFixer\.psm1$') {
        Write-Verbose "Skipping alias expansion on PSQAAutoFixer to prevent self-corruption"
        return $Content
    }

    return Invoke-AliasFixAst -Content $Content
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Invoke-AliasFix -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Invoke-AliasFixAst -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Invoke-AliasFixAst {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $aliasMap = @{
        'gci' = 'Get-ChildItem'; 'gcm' = 'Get-Command'; 'gm' = 'Get-Member'; 'iwr' = 'Invoke-WebRequest';
        'irm' = 'Invoke-RestMethod'; 'cat' = 'Get-Content'; 'cp' = 'Copy-Item'; 'mv' = 'Move-Item';
        'rm' = 'Remove-Item'; 'ls' = 'Get-ChildItem'; 'pwd' = 'Get-Location'; 'cd' = 'Set-Location';
        'cls' = 'Clear-Host'; 'echo' = 'Write-Output'; 'kill' = 'Stop-Process'; 'ps' = 'Get-Process';
        'sleep' = 'Start-Sleep'; 'fl' = 'Format-List'; 'ft' = 'Format-Table'; 'fw' = 'Format-Wide';
        'tee' = 'Tee-Object'; 'curl' = 'Invoke-WebRequest'; 'wget' = 'Invoke-WebRequest'; 'diff' = 'Compare-Object'
    }

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

    if ($errors.Count -gt 0) {
        # Cannot safely fix aliases in a script with parsing errors
        return $Content
    }

    $commandAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
    $fixes = @{}

    foreach ($commandAst in $commandAsts) {
        $commandName = $commandAst.GetCommandName()
        if ($aliasMap.ContainsKey($commandName)) {
            $extent = $commandAst.Extent
            $fixes[$extent.StartOffset] = @{
                Length = $extent.EndOffset - $extent.StartOffset
                Replacement = $aliasMap[$commandName]
            }
        }
    }

    $newContent = $Content
    $offset = 0

    foreach ($startOffset in $fixes.Keys | Sort-Object) {
        $fix = $fixes[$startOffset]
        $length = $fix.Length
        $replacement = $fix.Replacement

        $newContent = $newContent.Remove($startOffset + $offset, $length).Insert($startOffset + $offset, $replacement)
        $offset += $replacement.Length - $length
    }

    return $newContent
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> Invoke-SafetyFix -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
function Invoke-SafetyFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $fixed = $Content
    # Use single quotes for regex patterns
    $fixed = $fixed -replace '(?m)^\s*Write-Output\s+(["\'\$][^-\r\n]+)$', 'Write-Output $1'
    $fixed = $fixed -replace '(\S*)\s+(-eq|-ne)\s+\$null\b', '$null $2 $1'

    $ioCmdlets = @('Get-Content', 'Set-Content', 'Add-Content', 'Copy-Item', 'Move-Item', 'Remove-Item', 'New-Item')
    foreach ($cmdlet in $ioCmdlets) {
        $pattern = "(?i)(\b$cmdlet\b(?!.*-ErrorAction))"
        $fixed = $fixed -replace $pattern, "$1 -ErrorAction Stop"
    }

    return $fixed
}

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
function Invoke-StructureFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # Skip for module manifests (PSD1) or if already compliant
    if ($Content.Trim().StartsWith("@{ ") -or $Content -match '(?s)^\s*\[CmdletBinding\(\]') {
        return $Content
    }

    $lines = $Content -split '\r?\n'
    $insertionIndex = 0
    $inCommentBlock = $false
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i].Trim()
        if ($line.StartsWith('<#')) { $inCommentBlock = $true }
        if ($inCommentBlock -and $line.EndsWith('#>')) {
            $insertionIndex = $i + 1
            $inCommentBlock = $false
            continue
        }
        if (-not $inCommentBlock -and -not $line.StartsWith('#') -and -not ([string]::IsNullOrWhiteSpace($line))) {
            $insertionIndex = $i
            break
        }
        if ($i -eq ($lines.Length - 1)) {
            $insertionIndex = $i + 1
        }
    }

    $injection = "[CmdletBinding()]`nparam()`n`n"
    $newLines = $lines[0..($insertionIndex - 1)] + $injection + $lines[$insertionIndex..($lines.Length - 1)]
    return $newLines -join "`n"
}

#endregion

#region Main Processing

[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
[OutputType([object])]
function Invoke-FileFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File
    )

    Write-Log -Level Info -Message "Processing: $($File.Name)"

    if ($File.Length -gt $script:Config.MaxFileSizeBytes) {
        Write-Log -Level Warn -Message "Skipping (file too large): $($File.Name)"
        return $null
    }

    try {
        $originalContent = Get-Content -Path $File.FullName -Raw -Encoding Default
        $originalEncodingBytes = Get-Content -Path $File.FullName -Encoding Byte -ReadCount 4
        $hasBom = $false
        if ($originalEncodingBytes.Length -ge 3) {
            $hasBom = $originalEncodingBytes[0] -eq 0xEF -and $originalEncodingBytes[1] -eq 0xBB -and $originalEncodingBytes[2] -eq 0xBF
        }

        if (-not $originalContent.Trim()) {
            Write-Log -Level Warn -Message "Skipping (empty file): $($File.Name)"
            return $null
        }

        $fixedContent = $originalContent
        $fixedContent = Invoke-StructureFix -Content $fixedContent
        $fixedContent = Invoke-FormatterFix -Content $fixedContent -FilePath $File.FullName
        $fixedContent = Invoke-WhitespaceFix -Content $fixedContent
        $fixedContent = Invoke-AliasFix -Content $fixedContent -FilePath $File.FullName
        $fixedContent = Invoke-SafetyFix -Content $fixedContent

        $finalEncoding = $Encoding
        if ($Encoding -eq 'Default') {
            $containsNonAscii = $fixedContent | Select-String -Pattern '[^\u0000-\u007F]' -Quiet
            if ($containsNonAscii -and -not $hasBom) {
                $finalEncoding = 'utf8BOM'
                Write-Log -Level Info -Message "File contains non-ASCII characters, ensuring UTF8-BOM encoding."
            }
        }

        if (($fixedContent -eq $originalContent) -and ($finalEncoding -ne 'utf8BOM')) {
            Write-Log -Level Info -Message "No changes needed: $($File.Name)"
            return $null
        }

        if ($ShowDiff) {
            $diff = New-UnifiedDiff -Original $originalContent -Modified $fixedContent -FilePath $File.Name
            if ($diff) {
                Write-Output "`n--- Unified Diff for $($File.Name) ---" -ForegroundColor Magenta
                Write-Output $diff -ForegroundColor Gray
                Write-Output "--- End Diff ---`n" -ForegroundColor Magenta
            }
        }

        if (-not $DryRun) {
            if (-not $NoBackup) {
                $backupPath = New-FileBackup -FilePath $File.FullName
                Write-Log -Level Info -Message "Backup created: $(Split-Path -Path $backupPath -Leaf)"
            }

            $tempPath = "$($File.FullName).tmp"
            Set-Content -Path $tempPath -Value $fixedContent -Encoding $finalEncoding -NoNewline
            Move-Item -Path $tempPath -Destination $File.FullName -Force

            Write-Log -Level Success -Message "Fixes applied: $($File.Name)"
        } else {
            Write-Log -Level Info -Message "Would fix: $($File.Name) (dry-run)"
        }

        return @{
            File = $File.Name
            Changed = $true
        }

    } catch {
        Write-Log -Level Error -Message "Failed to process $($File.Name): $_ "
        return $null
    }
}

#endregion

#region Main Execution

try {
    Write-Output "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Output "║         PowerShell QA Auto-Fix Engine v4.0.0                  ║" -ForegroundColor Cyan
    Write-Output "║         Idempotent - Safe - Production-Grade                  ║" -ForegroundColor Cyan
    Write-Output "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Log -Level Info -Message "Trace ID: $($script:Config.TraceId)"
    Write-Log -Level Info -Message "Mode: $(if ($DryRun) { 'DRY RUN (Preview)' } else { 'APPLY FIXES' })"
    Write-Log -Level Info -Message "Backups: $(if ($NoBackup) { 'Disabled' } else { 'Enabled' })"
    Write-Log -Level Info -Message "Target: $Path"

    $files = @(Get-PowerShellFiles -Path $Path)
    Write-Log -Level Info -Message "Found $($files.Count) PowerShell file(s) to process`n"

    if ($files.Count -eq 0) {
        Write-Log -Level Warn -Message "No PowerShell files found"
        exit 0
    }

    $results = @()
    $fixedCount = 0

    foreach ($file in $files) {
        $result = Invoke-FileFix -File $file
        if ($result) {
            $results += $result
            if ($result.Changed) {
                $fixedCount++
            }
        }
    }

    Write-Output "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Output "║                         SUMMARY                                ║" -ForegroundColor Cyan
    Write-Output "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Log -Level Info -Message "Files processed: $($files.Count)"
    Write-Log -Level Success -Message "Files $(if ($DryRun) { 'that would be ' })fixed: $fixedCount"
    Write-Log -Level Info -Message "Files unchanged: $($files.Count - $fixedCount)"

    if ($DryRun) {
        Write-Output "`n[DRY RUN MODE] No changes were applied." -ForegroundColor Yellow
        Write-Output "Run without -DryRun to apply fixes.`n" -ForegroundColor Yellow
    } else {
        Write-Output "`n[SUCCESS] Auto-fix complete!`n" -ForegroundColor Green
    }

    if ($CleanBackups) {
        Clean-Backups
    }

    exit 0

} catch {
    Write-Log -Level Error -Message "Fatal error: $_ "
    Write-Output "`nStack Trace:" -ForegroundColor Red
    Write-Output $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion


