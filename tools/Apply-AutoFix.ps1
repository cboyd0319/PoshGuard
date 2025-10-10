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
    .\Apply-AutoFix.ps1 -Path ./src -DryRun
    Preview fixes without applying

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./script.ps1 -ShowDiff
    Apply fixes and show unified diffs

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./src
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
    [ValidateScript({ Test-Path -Path $_ -ErrorAction Stop })]
    [string]$Path,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$NoBackup,

    [Parameter()]
    [switch]$ShowDiff,

    [Parameter()]
    [switch]$CleanBackups,

    [Parameter()]
    [ValidateSet('Default', 'UTF8', 'UTF8BOM')]
    [string]$Encoding = 'Default'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Configuration

$script:Config = @{
    SupportedExtensions = @('.ps1', '.psm1', '.psd1')
    BackupDirectory     = '.psqa-backup'
    LogDirectory        = './logs'
    MaxFileSizeBytes    = 10485760  # 10MB
    TraceId             = (New-Guid).ToString()
    BackupRetentionDays = 1
}

#endregion

#region Helper Functions

function Clean-Backups {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    if ($pscmdlet.ShouldProcess("Target", "Operation")) {
        $backupDir = Join-Path -Path $PSScriptRoot -ChildPath $script:Config.BackupDirectory
        if (-not (Test-Path -Path $backupDir -ErrorAction Stop)) {
            return
        }

        $cutoffDate = (Get-Date).AddDays(-$script:Config.BackupRetentionDays)
        Get-ChildItem -Path $backupDir -Recurse -File | Where-Object { $_.LastWriteTime -lt $cutoffDate } | ForEach-Object {
            Write-Log -Level Info -Message "Deleting old backup: $($_.FullName)"
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
        }
    }
}

function Write-Log {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Warn', 'Error', 'Success')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Info' { 'Cyan' }
        'Warn' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
    }

    $prefix = switch ($Level) {
        'Info' { '[INFO]' }
        'Warn' { '[WARN]' }
        'Error' { '[ERROR]' }
        'Success' { '[OK]' }
    }

    Write-Host "$timestamp $prefix $Message" -ForegroundColor $color
}

function Get-PowerShellFiles {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -Path $Path -PathType Leaf -ErrorAction Stop) {
        return @(Get-Item -Path $Path -ErrorAction Stop)
    }

    $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
        $script:Config.SupportedExtensions -contains $_.Extension
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
        $backupDir = Join-Path -Path $fileDir -ChildPath $script:Config.BackupDirectory

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
    [CmdletBinding(SupportsShouldProcess)]
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

    # This is a simplified diff generator, not a full-fidelity one.
    foreach ($line in $diff) {
        $indicator = switch ($line.SideIndicator) {
            '==' { ' ' }
            '<=' { '-' }
            '=>' { '+' }
        }
        $lines += "$($indicator)$($line.InputObject)"
    }

    if ($lines.Count -eq 2) {
        return "" # No changes
    }

    return ($lines -join "`n")
}

#endregion

#region Fix Functions

function Invoke-FormatterFix {
    [CmdletBinding()]
    [OutputType([string])]
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
    }
    catch {
        Write-Log -Level Warn -Message "Invoke-Formatter failed: $_ "
    }

    return $Content
}

function Invoke-WhitespaceFix {
    [CmdletBinding()]
    [OutputType([string])]
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

function Invoke-AliasFix {
    [CmdletBinding()]
    [OutputType([string])]
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

function Invoke-AliasFixAst {
    [CmdletBinding()]
    [OutputType([string])]
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
                Length      = $extent.EndOffset - $extent.StartOffset
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

function Invoke-SafetyFix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $fixed = $Content

    # Fix $null comparison order (safe regex)
    # Only fix when variable is on the left side of comparison
    $fixed = $fixed -replace '(\$\w+)\s+(-eq|-ne)\s+\$null\b', '$null $2 $1'

    # AST-based ErrorAction addition (MUCH safer than regex)
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($fixed, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            # Find all command ASTs
            $commandAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst]
                }, $true)

            $ioCmdlets = @('Get-Content', 'Set-Content', 'Add-Content', 'Copy-Item', 'Move-Item', 'Remove-Item', 'New-Item')
            $replacements = @()

            foreach ($cmdAst in $commandAsts) {
                $cmdName = $cmdAst.GetCommandName()
                if ($cmdName -in $ioCmdlets) {
                    # Check if -ErrorAction parameter already exists
                    $hasErrorAction = $false
                    foreach ($element in $cmdAst.CommandElements) {
                        if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and
                            $element.ParameterName -eq 'ErrorAction') {
                            $hasErrorAction = $true
                            break
                        }
                    }

                    if (-not $hasErrorAction) {
                        # Add to replacements list (we'll apply them in reverse order)
                        $replacements += @{
                            Offset = $cmdAst.Extent.EndOffset
                            Text   = ' -ErrorAction Stop'
                        }
                    }
                }
            }

            # Apply replacements in reverse order to preserve offsets
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Insert($replacement.Offset, $replacement.Text)
            }
        }
    }
    catch {
        # If AST parsing fails, don't apply ErrorAction fixes
        Write-Verbose "AST-based safety fix failed: $_"
    }

    return $fixed
}

function Invoke-CasingFix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based cmdlet/parameter casing fix
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all command elements and fix casing
            foreach ($token in $tokens) {
                if ($token.Kind -eq 'Generic' -or $token.Kind -eq 'Identifier') {
                    # Check if this is a known cmdlet with wrong casing
                    try {
                        $cmd = Get-Command -Name $token.Text -ErrorAction SilentlyContinue
                        if ($cmd -and $cmd.Name -cne $token.Text) {
                            # Found a casing mismatch
                            $replacements += @{
                                Offset      = $token.Extent.StartOffset
                                Length      = $token.Extent.EndOffset - $token.Extent.StartOffset
                                Replacement = $cmd.Name
                            }
                        }
                    }
                    catch {
                        # Ignore - not a valid cmdlet
                    }
                }
                elseif ($token.Kind -eq 'Parameter') {
                    # Fix parameter casing (e.g., -pathType -> -PathType)
                    $paramName = $token.Text
                    if ($paramName -match '^-(.+)$') {
                        $paramWithoutDash = $Matches[1]
                        # Common parameter names with correct casing
                        $correctCasing = @{
                            'path'          = 'Path'
                            'pathtype'      = 'PathType'
                            'force'         = 'Force'
                            'recurse'       = 'Recurse'
                            'filter'        = 'Filter'
                            'include'       = 'Include'
                            'exclude'       = 'Exclude'
                            'erroraction'   = 'ErrorAction'
                            'warningaction' = 'WarningAction'
                            'verbose'       = 'Verbose'
                            'debug'         = 'Debug'
                            'whatif'        = 'WhatIf'
                            'confirm'       = 'Confirm'
                            'completed'     = 'Completed'
                        }

                        $lowerParam = $paramWithoutDash.ToLower()
                        if ($correctCasing.ContainsKey($lowerParam)) {
                            $correctParam = "-$($correctCasing[$lowerParam])"
                            if ($correctParam -cne $paramName) {
                                $replacements += @{
                                    Offset      = $token.Extent.StartOffset
                                    Length      = $token.Extent.EndOffset - $token.Extent.StartOffset
                                    Replacement = $correctParam
                                }
                            }
                        }
                    }
                }
            }

            # Apply replacements in reverse order
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
            }
            return $fixed
        }
    }
    catch {
        Write-Verbose "Casing fix failed: $_"
    }

    return $Content
}

function Invoke-WriteHostFix {
    <#
    .SYNOPSIS
        Smart Write-Host replacement that preserves UI/display components

    .DESCRIPTION
        Intelligently replaces Write-Host with Write-Output ONLY when it's not a UI component.

        KEEPS Write-Host (UI components) when:
        - Uses -ForegroundColor or -BackgroundColor (colored output)
        - Uses -NoNewline (progress indicators, spinners)
        - Contains emojis (✅⚠️❌🔍⏳🎯📊💡)
        - Contains box-drawing characters (╔║╚═─│┌┐└┘)
        - Contains special formatting (ASCII art, tables, banners)

        REPLACES with Write-Output when:
        - Plain text output with no formatting
        - No colors, emojis, or special formatting
        - Appears to be debugging/logging output

    .EXAMPLE
        # UI component - KEPT:
        Write-Host "✅ Success!" -ForegroundColor Green

        # Plain output - REPLACED:
        Write-Host "Processing file..."  # → Write-Output "Processing file..."
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $fixed = $Content

    # AST-based Write-Host analysis
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            # Find all command ASTs for Write-Host
            $writeHostAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].GetCommandName() -eq 'Write-Host'
                }, $true)

            $replacements = @()

            foreach ($cmdAst in $writeHostAsts) {
                $shouldReplace = $true

                # Check for UI indicators that mean we should KEEP Write-Host
                $cmdText = $cmdAst.Extent.Text

                # Check for color parameters
                if ($cmdText -match '-ForegroundColor|-BackgroundColor') {
                    $shouldReplace = $false
                }

                # Check for -NoNewline (progress indicators)
                if ($cmdText -match '-NoNewline') {
                    $shouldReplace = $false
                }

                # Check for emojis in the output string
                if ($cmdText -match '[✅⚠️❌🔍⏳🎯📊💡🚀🔥💻🌟⭐🎉]') {
                    $shouldReplace = $false
                }

                # Check for box-drawing characters (tables, banners)
                if ($cmdText -match '[╔║╚╗╝═─│┌┐└┘┬┴├┤┼▀▄█▌▐░▒▓]') {
                    $shouldReplace = $false
                }

                # If none of the UI indicators were found, replace Write-Host → Write-Output
                if ($shouldReplace) {
                    $replacements += @{
                        Offset      = $cmdAst.Extent.StartOffset
                        Length      = 10  # Length of "Write-Host"
                        Replacement = 'Write-Output'
                    }
                }
            }

            # Apply replacements in reverse order to preserve offsets
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
            }
        }
    }
    catch {
        Write-Verbose "Write-Host fix failed: $_"
    }

    return $fixed
}

function Invoke-DuplicateLineFix {
    <#
    .SYNOPSIS
        Removes duplicate consecutive lines

    .DESCRIPTION
        Detects and removes duplicate consecutive non-empty lines.
        This catches common copy-paste errors and duplicate import statements.

        REMOVES:
        - Duplicate consecutive lines (exact match)
        - Preserves blank lines
        - Case-sensitive comparison

    .EXAMPLE
        # BEFORE:
        Import-Module Foo

        # AFTER:
        Import-Module Foo
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $lines = $Content -split '\r?\n'
    $result = @()
    $previousLine = $null

    foreach ($line in $lines) {
        # Always keep blank lines and lines different from previous
        if ([string]::IsNullOrWhiteSpace($line) -or $line -ne $previousLine) {
            $result += $line
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $previousLine = $line
            }
        }
        # Skip duplicate consecutive non-empty lines
    }

    return $result -join "`n"
}

function Invoke-CmdletParameterFix {
    <#
    .SYNOPSIS
        Fixes cmdlets with invalid parameter combinations

    .DESCRIPTION
        AST-based detection and correction of cmdlet parameter mismatches:

        FIXES:
        - Write-Output -ForegroundColor → Write-Host -ForegroundColor
        - Write-Output -BackgroundColor → Write-Host -BackgroundColor
        - Write-Output -NoNewline → Write-Host -NoNewline

        These are RUNTIME errors that don't cause parse failures but fail when executed.
        Write-Output doesn't support color or formatting parameters.

    .EXAMPLE
        # BEFORE (runtime error):
        Write-Output "Success!" -ForegroundColor Green

        # AFTER (fixed):
        Write-Host "Success!" -ForegroundColor Green
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $fixed = $Content

    # AST-based cmdlet parameter validation
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            # Find all Write-Output commands
            $writeOutputAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].GetCommandName() -eq 'Write-Output'
                }, $true)

            $replacements = @()

            foreach ($cmdAst in $writeOutputAsts) {
                $hasInvalidParam = $false

                # Check for parameters that Write-Output doesn't support
                $invalidParams = @('ForegroundColor', 'BackgroundColor', 'NoNewline')

                foreach ($element in $cmdAst.CommandElements) {
                    if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                        if ($invalidParams -contains $element.ParameterName) {
                            $hasInvalidParam = $true
                            break
                        }
                    }
                }

                # If Write-Output has invalid parameters, replace with Write-Host
                if ($hasInvalidParam) {
                    # Find the exact position of "Write-Output" in the command
                    $cmdName = $cmdAst.CommandElements[0]
                    $replacements += @{
                        Offset      = $cmdName.Extent.StartOffset
                        Length      = $cmdName.Extent.Text.Length
                        Replacement = 'Write-Host'
                        Line        = $cmdName.Extent.StartLineNumber
                    }
                }
            }

            # Apply replacements in reverse order to preserve offsets
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
                Write-Verbose "Fixed Write-Output → Write-Host at line $($replacement.Line)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Fixed $($replacements.Count) Write-Output cmdlet(s) with invalid parameters"
            }
        }
    }
    catch {
        Write-Verbose "Cmdlet parameter fix failed: $_"
    }

    return $fixed
}

function Invoke-StructureFix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # Skip for module manifests (PSD1) or if already compliant
    if ($Content.Trim().StartsWith('@{ ') -or $Content -match '(?s)^\s*\[CmdletBinding\(\]') {
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

function Invoke-FileFix {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File
    )

    if ($pscmdlet.ShouldProcess($File.FullName, 'Analyzing file')) {
        Write-Log -Level Info -Message "Processing: $($File.Name)"

        if ($File.Length -gt $script:Config.MaxFileSizeBytes) {
            Write-Log -Level Warn -Message "Skipping (file too large): $($File.Name)"
            return $null
        }

        try {
            $originalContent = Get-Content -Path $File.FullName -Raw -ErrorAction Stop

            # Check for BOM (cross-platform compatible)
            $hasBom = $false
            try {
                $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
                if ($bytes.Length -ge 3) {
                    $hasBom = $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
                }
            }
            catch {
                Write-Verbose "Could not read bytes for BOM detection: $_"
            }

            if (-not $originalContent.Trim()) {
                Write-Log -Level Warn -Message "Skipping (empty file): $($File.Name)"
                return $null
            }

            $fixedContent = $originalContent
            # DISABLED: Invoke-StructureFix adds duplicate [CmdletBinding()] blocks - needs AST fix
            # $fixedContent = Invoke-StructureFix -Content $fixedContent
            $fixedContent = Invoke-FormatterFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-WhitespaceFix -Content $fixedContent
            $fixedContent = Invoke-DuplicateLineFix -Content $fixedContent
            $fixedContent = Invoke-AliasFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-CasingFix -Content $fixedContent
            $fixedContent = Invoke-CmdletParameterFix -Content $fixedContent
            $fixedContent = Invoke-WriteHostFix -Content $fixedContent
            $fixedContent = Invoke-SafetyFix -Content $fixedContent

            $finalEncoding = $Encoding
            if ($Encoding -eq 'Default') {
                $containsNonAscii = $fixedContent | Select-String -Pattern '[^\u0000-\u007F]' -Quiet
                if ($containsNonAscii -and -not $hasBom) {
                    $finalEncoding = 'utf8BOM'
                    Write-Log -Level Info -Message 'File contains non-ASCII characters, ensuring UTF8-BOM encoding.'
                }
            }

            if (($fixedContent -eq $originalContent) -and ($finalEncoding -ne 'utf8BOM')) {
                Write-Log -Level Info -Message "No changes needed: $($File.Name)"
                return $null
            }

            if ($ShowDiff) {
                $diff = New-UnifiedDiff -Original $originalContent -Modified $fixedContent -FilePath $File.Name
                if ($diff) {
                    Write-Host "`n--- Unified Diff for $($File.Name) ---" -ForegroundColor Magenta
                    Write-Host $diff -ForegroundColor Gray
                    Write-Host "--- End Diff ---
" -ForegroundColor Magenta
                }
            }

            if (-not $DryRun) {
                if (-not $NoBackup) {
                    $backupPath = New-FileBackup -FilePath $File.FullName
                    Write-Log -Level Info -Message "Backup created: $(Split-Path -Path $backupPath -Leaf)"
                }

                $tempPath = "$($File.FullName).tmp"
                Set-Content -Path $tempPath -Value $fixedContent -Encoding $finalEncoding -NoNewline -ErrorAction Stop
                Move-Item -Path $tempPath -Destination $File.FullName -Force -ErrorAction Stop

                Write-Log -Level Success -Message "Fixes applied: $($File.Name)"
            }
            else {
                Write-Log -Level Info -Message "Would fix: $($File.Name) (dry-run)"
            }

            return @{
                file    = $File.Name
                Changed = $true
            }

        }
        catch {
            Write-Log -Level Error -Message "Failed to process $($File.Name): $_ "
            return $null
        }
    }
}

#endregion

#region Main Execution

try {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         PowerShell QA Auto-Fix Engine v4.0.0                  ║" -ForegroundColor Cyan
    Write-Host "║         Idempotent - Safe - Production-Grade                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

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

    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                         SUMMARY                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Log -Level Info -Message "Files processed: $($files.Count)"
    Write-Log -Level Success -Message "Files $(if ($DryRun) { 'that would be ' })fixed: $fixedCount"
    Write-Log -Level Info -Message "Files unchanged: $($files.Count - $fixedCount)"

    if ($DryRun) {
        Write-Host "`n[DRY RUN MODE] No changes were applied." -ForegroundColor Yellow
        Write-Host "Run without -DryRun to apply fixes.`n" -ForegroundColor Yellow
    }
    else {
        Write-Host "`n[SUCCESS] Auto-fix complete!`n" -ForegroundColor Green
    }

    if ($CleanBackups) {
        Clean-Backups
    }

    exit 0

}
catch {
    Write-Log -Level Error -Message "Fatal error: $_ "
    Write-Host "`nStack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion
