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
    Version: 2.1.0
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

function Invoke-NullComparisonFix {
    <#
    .SYNOPSIS
        Fixes incorrect $null comparison order

    .DESCRIPTION
        PowerShell best practice requires $null to be on the left side of comparisons.
        This prevents accidental assignment and handles arrays correctly.

        FIXES:
        - $var -eq $null → $null -eq $var
        - $var -ne $null → $null -ne $var
        - Also handles: -gt, -lt, -ge, -le comparisons

    .EXAMPLE
        # BEFORE:
        if ($value -eq $null) { }

        # AFTER:
        if ($null -eq $value) { }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based null comparison fix
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all binary expression ASTs (comparisons)
            $binaryExprs = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.BinaryExpressionAst]
                }, $true)

            foreach ($expr in $binaryExprs) {
                # Check if this is a comparison with $null
                $isNullComparison = $false
                $nullOnRight = $false
                $comparisonOp = $expr.Operator

                # Check if operator is a comparison operator
                # PowerShell uses case-insensitive operators by default (Ieq, Ine, etc.)
                if ($comparisonOp -match '^(I|C)?(eq|ne|gt|lt|ge|le)$') {
                    # Check if right side is $null
                    if ($expr.Right -is [System.Management.Automation.Language.VariableExpressionAst] -and
                        $expr.Right.VariablePath.UserPath -eq 'null') {
                        $isNullComparison = $true
                        $nullOnRight = $true
                    }
                }

                # If we found a comparison with $null on the right side, swap it
                if ($isNullComparison -and $nullOnRight) {
                    # Get the text of left and right expressions
                    $leftText = $expr.Left.Extent.Text
                    $rightText = $expr.Right.Extent.Text  # This should be '$null'

                    # Map operator to its text representation - preserve case sensitivity
                    $opText = switch -Regex ($comparisonOp) {
                        '^I?eq$' { '-eq' }
                        '^Ceq$' { '-ceq' }
                        '^I?ne$' { '-ne' }
                        '^Cne$' { '-cne' }
                        '^I?gt$' { '-gt' }
                        '^Cgt$' { '-cgt' }
                        '^I?lt$' { '-lt' }
                        '^Clt$' { '-clt' }
                        '^I?ge$' { '-ge' }
                        '^Cge$' { '-cge' }
                        '^I?le$' { '-le' }
                        '^Cle$' { '-cle' }
                    }

                    # Swap: $var -eq $null → $null -eq $var
                    $newText = "$rightText $opText $leftText"

                    $replacements += @{
                        Offset      = $expr.Extent.StartOffset
                        Length      = $expr.Extent.Text.Length
                        Replacement = $newText
                    }
                }
            }

            # Apply replacements in reverse order to preserve offsets
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Fixed $($replacements.Count) null comparison(s)"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Null comparison fix failed: $_"
    }

    return $Content
}

function Invoke-SafetyFix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $fixed = $Content

    # AST-based ErrorAction addition
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

function Invoke-SemicolonFix {
    <#
    .SYNOPSIS
        Removes unnecessary trailing semicolons from PowerShell code

    .DESCRIPTION
        PowerShell doesn't require semicolons as line terminators (unlike C#).
        This function removes semicolons that are used as line terminators while
        preserving semicolons that are used as statement separators on the same line.

        REMOVES:
        - Trailing semicolons at end of lines
        - Semicolons followed only by whitespace/comments

        PRESERVES:
        - Semicolons between statements on same line: $x = 1; $y = 2
        - Semicolons in strings or comments

    .EXAMPLE
        # BEFORE:
        $x = 5;
        Write-Output "Hello";

        # AFTER:
        $x = 5
        Write-Output "Hello"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST token-based semicolon removal
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all semicolon tokens
            $semicolonTokens = $tokens | Where-Object { $_.Kind -eq 'Semi' }

            foreach ($token in $semicolonTokens) {
                # Check if this semicolon is a line terminator (not a statement separator)
                # A semicolon is a line terminator if it's followed only by whitespace/newline/comment
                $afterSemicolon = $Content.Substring($token.Extent.EndOffset)

                # Check if there's only whitespace/newline before the next statement
                if ($afterSemicolon -match '^\s*($|#)') {
                    # This is a line terminator - safe to remove
                    $replacements += @{
                        Offset = $token.Extent.StartOffset
                        Length = 1  # Length of semicolon
                    }
                }
            }

            # Apply replacements in reverse order to preserve offsets
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length)
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Removed $($replacements.Count) unnecessary trailing semicolon(s)"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Semicolon fix failed: $_"
    }

    return $Content
}

function Invoke-SingularNounFix {
    <#
    .SYNOPSIS
        Converts function names with plural nouns to singular nouns

    .DESCRIPTION
        PowerShell convention dictates that function nouns should be singular.
        This function detects function declarations with plural nouns and converts them to singular.

        CONVERTS:
        - Users → User
        - Items → Item
        - Entries → Entry
        - Children → Child
        - etc.

    .EXAMPLE
        # BEFORE:
        function Get-Users { }

        # AFTER:
        function Get-User { }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based function name detection
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all function definitions
            $functionAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            foreach ($funcAst in $functionAsts) {
                $functionName = $funcAst.Name

                # Split function name into Verb-Noun format
                if ($functionName -match '^([A-Za-z]+)-([A-Za-z]+)$') {
                    $verb = $Matches[1]
                    $noun = $Matches[2]

                    # Apply pluralization rules to get singular form
                    $singularNoun = $null

                    # Rule 1: Words ending in 'ies' → 'y' (Entries → Entry)
                    if ($noun -match '^(.+)ies$') {
                        $singularNoun = $Matches[1] + 'y'
                    }
                    # Rule 2: Words ending in 'es' (not 'ies') → remove 'es' (Processes → Process)
                    elseif ($noun -match '^(.+[^i])es$') {
                        $singularNoun = $Matches[1]
                    }
                    # Rule 3: Words ending in 'ves' → 'fe' or 'f' (Knives → Knife)
                    elseif ($noun -match '^(.+)ves$') {
                        $singularNoun = $Matches[1] + 'fe'
                    }
                    # Rule 4: Words ending in 's' (but not 'ss') → remove 's' (Users → User)
                    elseif ($noun -match '^(.+[^s])s$') {
                        $singularNoun = $Matches[1]
                    }

                    # If we found a singular form and it's different from the original
                    if ($singularNoun -and $singularNoun -ne $noun) {
                        $newFunctionName = "$verb-$singularNoun"

                        # Only replace if the new name is actually different
                        if ($newFunctionName -ne $functionName) {
                            # Find the exact location of the function name in the AST
                            $replacements += @{
                                Offset      = $funcAst.Extent.StartOffset
                                Length      = $funcAst.Extent.Text.Length
                                OldName     = $functionName
                                NewName     = $newFunctionName
                                FuncExtent  = $funcAst.Extent.Text
                            }
                        }
                    }
                }
            }

            # Apply replacements
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                # Replace the function definition
                $oldFuncText = $replacement.FuncExtent
                $newFuncText = $oldFuncText -replace [regex]::Escape($replacement.OldName), $replacement.NewName

                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $newFuncText)

                Write-Verbose "Converted function name: $($replacement.OldName) → $($replacement.NewName)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) function name(s) to singular form"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Singular noun fix failed: $_"
    }

    return $Content
}

function Invoke-ApprovedVerbFix {
    <#
    .SYNOPSIS
        Fixes function names with unapproved PowerShell verbs

    .DESCRIPTION
        PowerShell has a set of approved verbs (Get-Verb) that should be used for consistency.
        This function detects unapproved verbs and replaces them with approved alternatives.

        COMMON MAPPINGS:
        - Validate → Test
        - Check → Test
        - Verify → Test
        - Display → Show
        - Print → Write
        - Create → New
        - Delete → Remove
        - Destroy → Remove
        - Make → New
        - Build → New
        - Generate → New
        - Retrieve → Get
        - Fetch → Get
        - Obtain → Get
        - Acquire → Get
        - Change → Set
        - Modify → Set
        - Update → Set
        - Edit → Set
        - List → Get
        - Enumerate → Get

    .EXAMPLE
        PS C:\> Invoke-ApprovedVerbFix -Content $scriptContent

        Replaces unapproved verbs with approved alternatives
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based function name detection
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            # Get list of approved verbs from PowerShell
            $approvedVerbs = @{}
            try {
                Get-Verb | ForEach-Object { $approvedVerbs[$_.Verb.ToLower()] = $_.Verb }
            }
            catch {
                # If Get-Verb fails, use a hardcoded list of common approved verbs
                $commonApprovedVerbs = @(
                    'Add', 'Clear', 'Close', 'Copy', 'Enter', 'Exit', 'Find', 'Format', 'Get', 'Hide',
                    'Join', 'Lock', 'Move', 'New', 'Open', 'Optimize', 'Pop', 'Push', 'Redo', 'Remove',
                    'Rename', 'Reset', 'Resize', 'Search', 'Select', 'Set', 'Show', 'Skip', 'Split',
                    'Step', 'Switch', 'Undo', 'Unlock', 'Watch', 'Backup', 'Checkpoint', 'Compare',
                    'Compress', 'Convert', 'ConvertFrom', 'ConvertTo', 'Dismount', 'Edit', 'Expand',
                    'Export', 'Group', 'Import', 'Initialize', 'Limit', 'Merge', 'Mount', 'Out',
                    'Publish', 'Restore', 'Save', 'Sync', 'Unpublish', 'Update', 'Approve', 'Assert',
                    'Complete', 'Confirm', 'Deny', 'Disable', 'Enable', 'Install', 'Invoke', 'Register',
                    'Request', 'Restart', 'Resume', 'Start', 'Stop', 'Submit', 'Suspend', 'Uninstall',
                    'Unregister', 'Wait', 'Debug', 'Measure', 'Ping', 'Repair', 'Resolve', 'Test',
                    'Trace', 'Connect', 'Disconnect', 'Read', 'Receive', 'Send', 'Write', 'Block',
                    'Grant', 'Protect', 'Revoke', 'Unblock', 'Unprotect', 'Use'
                )
                $commonApprovedVerbs | ForEach-Object { $approvedVerbs[$_.ToLower()] = $_ }
            }

            # Common unapproved verb mappings to approved verbs
            $verbMappings = @{
                'Validate'  = 'Test'
                'Check'     = 'Test'
                'Verify'    = 'Test'
                'Display'   = 'Show'
                'Print'     = 'Write'
                'Create'    = 'New'
                'Delete'    = 'Remove'
                'Destroy'   = 'Remove'
                'Make'      = 'New'
                'Build'     = 'New'
                'Generate'  = 'New'
                'Retrieve'  = 'Get'
                'Fetch'     = 'Get'
                'Obtain'    = 'Get'
                'Acquire'   = 'Get'
                'Change'    = 'Set'
                'Modify'    = 'Set'
                'Alter'     = 'Set'
                'Edit'      = 'Edit'  # Edit is actually approved
                'List'      = 'Get'
                'Enumerate' = 'Get'
                'Query'     = 'Get'
                'Load'      = 'Import'
                'Save'      = 'Export'
                'Unload'    = 'Remove'
                'Execute'   = 'Invoke'
                'Run'       = 'Invoke'
                'Call'      = 'Invoke'
                'Launch'    = 'Start'
                'Kill'      = 'Stop'
                'Terminate' = 'Stop'
                'Quit'      = 'Exit'
                'Close'     = 'Close'  # Close is approved
                'Open'      = 'Open'   # Open is approved
            }

            $replacements = @()

            # Find all function definitions
            $functionAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            foreach ($funcAst in $functionAsts) {
                $functionName = $funcAst.Name

                # Split function name into Verb-Noun format
                if ($functionName -match '^([A-Za-z]+)-([A-Za-z]+)$') {
                    $verb = $Matches[1]
                    $noun = $Matches[2]

                    # Check if verb is approved (case-insensitive)
                    $verbLower = $verb.ToLower()

                    if (-not $approvedVerbs.ContainsKey($verbLower)) {
                        # Verb is not approved, try to find a mapping
                        $approvedVerb = $null

                        # First check our mapping table
                        if ($verbMappings.ContainsKey($verb)) {
                            $approvedVerb = $verbMappings[$verb]
                        }
                        else {
                            # Try case-insensitive lookup in mappings
                            foreach ($key in $verbMappings.Keys) {
                                if ($key -eq $verb -or $key.ToLower() -eq $verbLower) {
                                    $approvedVerb = $verbMappings[$key]
                                    break
                                }
                            }
                        }

                        if ($approvedVerb) {
                            $newFunctionName = "$approvedVerb-$noun"

                            # Only replace if the new name is different
                            if ($newFunctionName -ne $functionName) {
                                $replacements += @{
                                    Offset      = $funcAst.Extent.StartOffset
                                    Length      = $funcAst.Extent.Text.Length
                                    OldName     = $functionName
                                    NewName     = $newFunctionName
                                    FuncExtent  = $funcAst.Extent.Text
                                }
                            }
                        }
                    }
                }
            }

            # Apply replacements
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                # Replace the function definition
                $oldFuncText = $replacement.FuncExtent
                $newFuncText = $oldFuncText -replace [regex]::Escape($replacement.OldName), $replacement.NewName

                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $newFuncText)

                Write-Verbose "Converted unapproved verb: $($replacement.OldName) → $($replacement.NewName)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) function(s) to use approved verbs"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Approved verb fix failed: $_"
    }

    return $Content
}

function Invoke-SupportsShouldProcessFix {
    <#
    .SYNOPSIS
        Adds SupportsShouldProcess to CmdletBinding when ShouldProcess is used

    .DESCRIPTION
        Functions using $PSCmdlet.ShouldProcess() must declare SupportsShouldProcess
        in their CmdletBinding attribute. This fix detects such usage and adds the attribute.

    .EXAMPLE
        PS C:\> Invoke-SupportsShouldProcessFix -Content $scriptContent

        Adds SupportsShouldProcess=$true to functions using ShouldProcess
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all function definitions
            $functionAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            foreach ($funcAst in $functionAsts) {
                # Check if function uses $PSCmdlet.ShouldProcess
                $usesShouldProcess = $false

                $shouldProcessCalls = $funcAst.FindAll({
                        $args[0] -is [System.Management.Automation.Language.MemberExpressionAst] -and
                        $args[0].Member.Extent.Text -eq 'ShouldProcess'
                    }, $true)

                if ($shouldProcessCalls.Count -gt 0) {
                    $usesShouldProcess = $true
                }

                if ($usesShouldProcess) {
                    # Check if function has CmdletBinding attribute
                    $paramBlock = $funcAst.Body.ParamBlock

                    if ($paramBlock -and $paramBlock.Attributes) {
                        foreach ($attr in $paramBlock.Attributes) {
                            if ($attr.TypeName.Name -eq 'CmdletBinding') {
                                # Check if SupportsShouldProcess is already present
                                $hasSupportsShouldProcess = $false

                                foreach ($namedArg in $attr.NamedArguments) {
                                    if ($namedArg.ArgumentName -eq 'SupportsShouldProcess') {
                                        $hasSupportsShouldProcess = $true
                                        break
                                    }
                                }

                                if (-not $hasSupportsShouldProcess) {
                                    # Add SupportsShouldProcess to existing CmdletBinding
                                    $attrText = $attr.Extent.Text

                                    if ($attrText -match '^\[CmdletBinding\(\s*\)\]$') {
                                        # Empty CmdletBinding()
                                        $newAttrText = '[CmdletBinding(SupportsShouldProcess=$true)]'
                                    }
                                    else {
                                        # Has existing arguments
                                        $newAttrText = $attrText -replace '\)\]$', ', SupportsShouldProcess=$true)]'
                                    }

                                    $replacements += @{
                                        Offset      = $attr.Extent.StartOffset
                                        Length      = $attr.Extent.Text.Length
                                        Replacement = $newAttrText
                                        FuncName    = $funcAst.Name
                                    }
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
                Write-Verbose "Added SupportsShouldProcess to: $($replacement.FuncName)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Added SupportsShouldProcess to $($replacements.Count) function(s)"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "SupportsShouldProcess fix failed: $_"
    }

    return $Content
}

function Invoke-GlobalVarFix {
    <#
    .SYNOPSIS
        Converts global variables to script scope

    .DESCRIPTION
        Global variables should be avoided as they pollute the global namespace.
        This fix converts $global: variables to $script: scope.

    .EXAMPLE
        PS C:\> Invoke-GlobalVarFix -Content $scriptContent

        Converts $global:Var to $script:Var
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all variable expressions
            $varAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
                }, $true)

            foreach ($varAst in $varAsts) {
                # Check if variable uses global scope
                if ($varAst.VariablePath.DriveName -eq 'global') {
                    # Convert to script scope
                    $varName = $varAst.VariablePath.UserPath
                    $newVarText = "`$script:$varName"

                    $replacements += @{
                        Offset      = $varAst.Extent.StartOffset
                        Length      = $varAst.Extent.Text.Length
                        Replacement = $newVarText
                        VarName     = $varAst.Extent.Text
                    }
                }
            }

            # Apply replacements in reverse order
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
                Write-Verbose "Converted global variable: $($replacement.VarName) → $($replacement.Replacement)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) global variable(s) to script scope"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Global variable fix failed: $_"
    }

    return $Content
}

function Invoke-DoubleQuoteFix {
    <#
    .SYNOPSIS
        Converts double quotes to single quotes for constant strings

    .DESCRIPTION
        PowerShell best practice is to use single quotes for constant strings
        (strings without variable expansion). This improves performance slightly
        and makes the intent clearer.

    .EXAMPLE
        PS C:\> Invoke-DoubleQuoteFix -Content $scriptContent

        Converts "Hello" to 'Hello' when no variables are present
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all string literals
            $stringAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst]
                }, $true)

            foreach ($stringAst in $stringAsts) {
                # Check if it's a double-quoted string
                if ($stringAst.StringConstantType -eq 'DoubleQuoted') {
                    $stringValue = $stringAst.Value

                    # Check if string contains single quotes (would need escaping)
                    if ($stringValue -notmatch "'") {
                        # Check if string contains special characters that require double quotes
                        # Allow conversion if no variables, escape sequences, or special chars
                        if ($stringValue -notmatch '[\$`]') {
                            # Safe to convert to single quotes
                            $newStringText = "'$stringValue'"

                            $replacements += @{
                                Offset      = $stringAst.Extent.StartOffset
                                Length      = $stringAst.Extent.Text.Length
                                Replacement = $newStringText
                                Original    = $stringAst.Extent.Text
                            }
                        }
                    }
                }
            }

            # Apply replacements in reverse order
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
                Write-Verbose "Converted double quotes: $($replacement.Original) → $($replacement.Replacement)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) string(s) from double to single quotes"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Double quote fix failed: $_"
    }

    return $Content
}

function Invoke-WmiToCimFix {
    <#
    .SYNOPSIS
        Converts deprecated WMI cmdlets to CIM cmdlets

    .DESCRIPTION
        WMI cmdlets (Get-WmiObject, etc.) are deprecated in PowerShell 7+.
        This function converts them to modern CIM cmdlets with proper parameter mapping.

        CONVERSIONS:
        - Get-WmiObject → Get-CimInstance
        - Set-WmiInstance → Set-CimInstance
        - Invoke-WmiMethod → Invoke-CimMethod
        - Remove-WmiObject → Remove-CimInstance
        - Register-WmiEvent → Register-CimIndicationEvent

        PARAMETER MAPPINGS:
        - -Class → -ClassName
        - -Namespace remains -Namespace
        - -ComputerName remains -ComputerName
        - -Credential remains -Credential
        - -Filter remains -Filter
        - -Property remains -Property

    .EXAMPLE
        PS C:\> Invoke-WmiToCimFix -Content $scriptContent

        Converts Get-WmiObject -Class Win32_Process to Get-CimInstance -ClassName Win32_Process
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # WMI to CIM cmdlet mappings
            $cmdletMappings = @{
                'Get-WmiObject'      = 'Get-CimInstance'
                'Set-WmiInstance'    = 'Set-CimInstance'
                'Invoke-WmiMethod'   = 'Invoke-CimMethod'
                'Remove-WmiObject'   = 'Remove-CimInstance'
                'Register-WmiEvent'  = 'Register-CimIndicationEvent'
            }

            # Find all command ASTs
            $commandAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst]
                }, $true)

            foreach ($cmdAst in $commandAsts) {
                $cmdName = $cmdAst.GetCommandName()

                if ($cmdletMappings.ContainsKey($cmdName)) {
                    # This is a WMI cmdlet that needs conversion
                    $newCmdName = $cmdletMappings[$cmdName]

                    # Build the new command text
                    $cmdElements = $cmdAst.CommandElements
                    $newCommandParts = @()

                    # Start with the new cmdlet name
                    $newCommandParts += $newCmdName

                    # Process parameters
                    $i = 1  # Skip the command name itself
                    while ($i -lt $cmdElements.Count) {
                        $element = $cmdElements[$i]

                        if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                            # This is a parameter
                            $paramName = $element.ParameterName

                            # Map -Class to -ClassName for CIM cmdlets
                            if ($paramName -eq 'Class') {
                                $newCommandParts += '-ClassName'
                            }
                            else {
                                # Keep other parameters as-is
                                $newCommandParts += "-$paramName"
                            }

                            # Check if there's an argument for this parameter
                            if ($element.Argument) {
                                # Argument is part of the parameter (e.g., -Class:Win32_Process)
                                $newCommandParts += $element.Argument.Extent.Text
                            }
                            elseif ($i + 1 -lt $cmdElements.Count) {
                                # Check if next element is the argument
                                $nextElement = $cmdElements[$i + 1]
                                if ($nextElement -isnot [System.Management.Automation.Language.CommandParameterAst]) {
                                    # This is the parameter value
                                    $newCommandParts += $nextElement.Extent.Text
                                    $i++  # Skip the next element since we've processed it
                                }
                            }
                        }
                        else {
                            # This is a positional argument or other element
                            $newCommandParts += $element.Extent.Text
                        }

                        $i++
                    }

                    # Join all parts with spaces
                    $newCommandText = $newCommandParts -join ' '

                    $replacements += @{
                        Offset      = $cmdAst.Extent.StartOffset
                        Length      = $cmdAst.Extent.Text.Length
                        Replacement = $newCommandText
                        OldCmd      = $cmdName
                        NewCmd      = $newCmdName
                    }
                }
            }

            # Apply replacements in reverse order
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
                Write-Verbose "Converted WMI cmdlet: $($replacement.OldCmd) → $($replacement.NewCmd)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) WMI cmdlet(s) to CIM cmdlets"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "WMI to CIM conversion failed: $_"
    }

    return $Content
}

function Invoke-ReservedParamsFix {
    <#
    .SYNOPSIS
        Renames parameters that conflict with PowerShell reserved/common parameter names

    .DESCRIPTION
        PowerShell has reserved parameter names (Common Parameters) that should not be used
        as custom parameters. This function detects such conflicts and renames them.

        Common Parameters:
        - Verbose, Debug, ErrorAction, WarningAction, InformationAction
        - ErrorVariable, WarningVariable, InformationVariable
        - OutVariable, OutBuffer, PipelineVariable

        Renaming Strategy:
        - Verbose → VerboseOutput
        - Debug → DebugMode
        - ErrorAction → ErrorHandling
        - WarningAction → WarningHandling
        - InformationAction → InformationHandling
        - ErrorVariable → ErrorVar
        - WarningVariable → WarningVar
        - InformationVariable → InformationVar
        - OutVariable → OutputVariable
        - OutBuffer → OutputBuffer
        - PipelineVariable → PipelineVar

    .EXAMPLE
        PS C:\> Invoke-ReservedParamsFix -Content $scriptContent

        Renames reserved parameter names to avoid conflicts
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # Reserved parameter name mappings
    $reservedMappings = @{
        'Verbose'             = 'VerboseOutput'
        'Debug'               = 'DebugMode'
        'ErrorAction'         = 'ErrorHandling'
        'WarningAction'       = 'WarningHandling'
        'InformationAction'   = 'InformationHandling'
        'ErrorVariable'       = 'ErrorVar'
        'WarningVariable'     = 'WarningVar'
        'InformationVariable' = 'InformationVar'
        'OutVariable'         = 'OutputVariable'
        'OutBuffer'           = 'OutputBuffer'
        'PipelineVariable'    = 'PipelineVar'
        'WhatIf'              = 'WhatIfMode'
        'Confirm'             = 'ConfirmAction'
    }

    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = [System.Collections.ArrayList]::new()

            # Find all function definitions
            $functions = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

            foreach ($funcAst in $functions) {
                # Get all parameters in this function
                $parameters = $funcAst.FindAll({
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }, $true)

                foreach ($paramAst in $parameters) {
                    $paramName = $paramAst.Name.VariablePath.UserPath

                    # Check if parameter name conflicts with reserved names
                    if ($reservedMappings.ContainsKey($paramName)) {
                        $newParamName = $reservedMappings[$paramName]

                        # Find all references to this parameter within the function
                        $varRefs = $funcAst.FindAll({
                            $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
                            $args[0].VariablePath.UserPath -eq $paramName
                        }, $true)

                        # Add replacements for all references (sorted by position descending)
                        foreach ($varRef in $varRefs) {
                            $extent = $varRef.Extent
                            $oldText = $extent.Text
                            $newText = "`$$newParamName"

                            $replacements.Add([PSCustomObject]@{
                                StartOffset = $extent.StartOffset
                                EndOffset = $extent.EndOffset
                                OldText = $oldText
                                NewText = $newText
                            }) | Out-Null
                        }

                        Write-Verbose "Renaming reserved parameter: $paramName → $newParamName in function $($funcAst.Name)"
                    }
                }
            }

            # Apply replacements in reverse order (end to start)
            if ($replacements.Count -gt 0) {
                $replacements = $replacements | Sort-Object -Property StartOffset -Descending
                $fixed = $Content

                foreach ($replacement in $replacements) {
                    $before = $fixed.Substring(0, $replacement.StartOffset)
                    $after = $fixed.Substring($replacement.EndOffset)
                    $fixed = $before + $replacement.NewText + $after
                }

                Write-Verbose "Renamed $($replacements.Count) reserved parameter reference(s)"
                return $fixed
            }
        }
    }
    catch {
        Write-Verbose "Reserved params fix failed: $_"
    }

    return $Content
}

function Invoke-SwitchParameterDefaultFix {
    <#
    .SYNOPSIS
        Removes default values from [switch] parameters

    .DESCRIPTION
        Switch parameters should not have default values (= $true or = $false).
        This is a PowerShell best practice violation that can cause unexpected behavior.

        Removes:
        - [switch]$MySwitch = $true
        - [switch]$MySwitch = $false

        Converts to:
        - [switch]$MySwitch

    .EXAMPLE
        PS C:\> Invoke-SwitchParameterDefaultFix -Content $scriptContent

        Removes default values from switch parameters
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = [System.Collections.ArrayList]::new()

            # Find all parameters with [switch] type
            $parameters = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.ParameterAst]
            }, $true)

            foreach ($paramAst in $parameters) {
                # Check if parameter has [switch] attribute
                $hasSwitch = $false
                foreach ($attr in $paramAst.Attributes) {
                    if ($attr.TypeName.FullName -eq 'switch') {
                        $hasSwitch = $true
                        break
                    }
                }

                if ($hasSwitch -and $paramAst.DefaultValue) {
                    # Has a default value - remove it
                    $paramName = $paramAst.Name.VariablePath.UserPath

                    # Get the text from parameter start to default value end
                    $paramStartOffset = $paramAst.Extent.StartOffset
                    $defaultValueEndOffset = $paramAst.DefaultValue.Extent.EndOffset

                    # Find the = sign before the default value
                    $textBetween = $Content.Substring($paramAst.Name.Extent.EndOffset,
                                                      $paramAst.DefaultValue.Extent.StartOffset - $paramAst.Name.Extent.EndOffset)

                    if ($textBetween -match '\s*=\s*') {
                        # Remove everything from the end of variable name to end of default value
                        $oldText = $Content.Substring($paramAst.Name.Extent.EndOffset,
                                                      $defaultValueEndOffset - $paramAst.Name.Extent.EndOffset)

                        $replacements.Add([PSCustomObject]@{
                            StartOffset = $paramAst.Name.Extent.EndOffset
                            EndOffset = $defaultValueEndOffset
                            OldText = $oldText
                            NewText = ''
                        }) | Out-Null

                        Write-Verbose "Removing default value from switch parameter: $paramName"
                    }
                }
            }

            # Apply replacements in reverse order (end to start)
            if ($replacements.Count -gt 0) {
                $replacements = $replacements | Sort-Object -Property StartOffset -Descending
                $fixed = $Content

                foreach ($replacement in $replacements) {
                    $before = $fixed.Substring(0, $replacement.StartOffset)
                    $after = $fixed.Substring($replacement.EndOffset)
                    $fixed = $before + $replacement.NewText + $after
                }

                Write-Verbose "Removed default values from $($replacements.Count) switch parameter(s)"
                return $fixed
            }
        }
    }
    catch {
        Write-Verbose "Switch parameter default fix failed: $_"
    }

    return $Content
}

function Invoke-BrokenHashAlgorithmFix {
    <#
    .SYNOPSIS
        Replaces insecure hash algorithms with secure alternatives

    .DESCRIPTION
        Detects and replaces broken/weak cryptographic hash algorithms with secure alternatives.

        Broken Algorithms (replaced):
        - MD5 → SHA256
        - SHA1 → SHA256
        - RIPEMD160 → SHA256

        Secure Alternatives:
        - SHA256 (default replacement)
        - SHA384
        - SHA512

        This fix targets:
        - [System.Security.Cryptography.MD5]::Create()
        - [System.Security.Cryptography.SHA1]::Create()
        - New-Object System.Security.Cryptography.MD5CryptoServiceProvider
        - etc.

    .EXAMPLE
        PS C:\> Invoke-BrokenHashAlgorithmFix -Content $scriptContent

        Replaces broken hash algorithms with SHA256
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # Hash algorithm mappings (broken → secure)
    $hashMappings = @(
        @{ Pattern = 'MD5CryptoServiceProvider';         Replacement = 'SHA256CryptoServiceProvider';    Algorithm = 'MD5' }
        @{ Pattern = 'MD5Cng';                          Replacement = 'SHA256Cng';                      Algorithm = 'MD5' }
        @{ Pattern = 'MD5';                             Replacement = 'SHA256';                         Algorithm = 'MD5' }
        @{ Pattern = 'SHA1CryptoServiceProvider';       Replacement = 'SHA256CryptoServiceProvider';    Algorithm = 'SHA1' }
        @{ Pattern = 'SHA1Cng';                         Replacement = 'SHA256Cng';                      Algorithm = 'SHA1' }
        @{ Pattern = 'SHA1Managed';                     Replacement = 'SHA256Managed';                  Algorithm = 'SHA1' }
        @{ Pattern = 'SHA1';                            Replacement = 'SHA256';                         Algorithm = 'SHA1' }
        @{ Pattern = 'RIPEMD160Managed';                Replacement = 'SHA256Managed';                  Algorithm = 'RIPEMD160' }
        @{ Pattern = 'RIPEMD160';                       Replacement = 'SHA256';                         Algorithm = 'RIPEMD160' }
    )

    try {
        $fixed = $Content
        $replacementCount = 0

        foreach ($mapping in $hashMappings) {
            $pattern = $mapping.Pattern
            $replacement = $mapping.Replacement
            $algorithm = $mapping.Algorithm

            # Match patterns like:
            # [System.Security.Cryptography.MD5]::Create()
            # New-Object System.Security.Cryptography.MD5CryptoServiceProvider
            # [MD5]::Create()

            $regex = [regex]::new("(\[(?:System\.Security\.Cryptography\.)?$pattern\]|System\.Security\.Cryptography\.$pattern\b)",
                                  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

            $matches = $regex.Matches($fixed)
            if ($matches.Count -gt 0) {
                $fixed = $regex.Replace($fixed, {
                    param($match)
                    $originalText = $match.Groups[1].Value

                    # Preserve the structure (brackets, namespace, etc.)
                    if ($originalText -match '^\[') {
                        # [System.Security.Cryptography.MD5] or [MD5]
                        if ($originalText -match 'System\.Security\.Cryptography') {
                            "[System.Security.Cryptography.$replacement]"
                        } else {
                            "[$replacement]"
                        }
                    } else {
                        # System.Security.Cryptography.MD5 (no brackets)
                        "System.Security.Cryptography.$replacement"
                    }
                })

                $replacementCount += $matches.Count
                Write-Verbose "Replaced $($matches.Count) instance(s) of insecure $algorithm hash algorithm with $replacement"
            }
        }

        if ($replacementCount -gt 0) {
            Write-Verbose "Total: Replaced $replacementCount insecure hash algorithm reference(s)"
            return $fixed
        }
    }
    catch {
        Write-Verbose "Broken hash algorithm fix failed: $_"
    }

    return $Content
}

function Invoke-CommentHelpFix {
    <#
    .SYNOPSIS
        Adds basic comment-based help to functions without help

    .DESCRIPTION
        PowerShell best practice requires functions to have comment-based help.
        This function detects functions without help and adds a basic template.

        ADDS:
        - .SYNOPSIS section
        - .DESCRIPTION section
        - .EXAMPLE section

    .EXAMPLE
        PS C:\> Invoke-CommentHelpFix -Content $scriptContent

        Adds comment-based help template to functions without help
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based function detection
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $insertions = @()

            # Find all function definitions
            $functionAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            foreach ($funcAst in $functionAsts) {
                $functionName = $funcAst.Name

                # Check if function already has help
                $hasHelp = $false

                # Look for comment-based help in the function body
                if ($funcAst.Body.ParamBlock -and $funcAst.Body.ParamBlock.Extent.Text -match '<#[\s\S]*?\.SYNOPSIS[\s\S]*?#>') {
                    $hasHelp = $true
                }

                # Also check for help before the function
                $startOffset = $funcAst.Extent.StartOffset
                if ($startOffset -gt 0) {
                    $textBefore = $Content.Substring(0, $startOffset)
                    # Check last 500 characters before function for help block
                    $checkLength = [Math]::Min(500, $textBefore.Length)
                    $recentText = $textBefore.Substring($textBefore.Length - $checkLength)
                    if ($recentText -match '<#[\s\S]*?\.SYNOPSIS[\s\S]*?#>[\s\r\n]*$') {
                        $hasHelp = $true
                    }
                }

                # If no help found, add template
                if (-not $hasHelp) {
                    # Generate help template
                    $helpTemplate = @"
<#
.SYNOPSIS
    Brief description of $functionName

.DESCRIPTION
    Detailed description of $functionName

.EXAMPLE
    PS C:\> $functionName
    Example usage of $functionName
#>

"@
                    $insertions += @{
                        Offset   = $funcAst.Extent.StartOffset
                        Text     = $helpTemplate
                        FuncName = $functionName
                    }
                }
            }

            # Apply insertions in reverse order to preserve offsets
            $fixed = $Content
            foreach ($insertion in ($insertions | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Insert($insertion.Offset, $insertion.Text)
                Write-Verbose "Added comment-based help for: $($insertion.FuncName)"
            }

            if ($insertions.Count -gt 0) {
                Write-Verbose "Added help to $($insertions.Count) function(s)"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Comment help fix failed: $_"
    }

    return $Content
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
            $fixedContent = Invoke-ReservedParamsFix -Content $fixedContent
            $fixedContent = Invoke-SwitchParameterDefaultFix -Content $fixedContent
            $fixedContent = Invoke-BrokenHashAlgorithmFix -Content $fixedContent
            $fixedContent = Invoke-CommentHelpFix -Content $fixedContent
            $fixedContent = Invoke-SupportsShouldProcessFix -Content $fixedContent
            $fixedContent = Invoke-WmiToCimFix -Content $fixedContent
            $fixedContent = Invoke-FormatterFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-WhitespaceFix -Content $fixedContent
            $fixedContent = Invoke-SemicolonFix -Content $fixedContent
            $fixedContent = Invoke-ApprovedVerbFix -Content $fixedContent
            $fixedContent = Invoke-SingularNounFix -Content $fixedContent
            $fixedContent = Invoke-GlobalVarFix -Content $fixedContent
            $fixedContent = Invoke-DoubleQuoteFix -Content $fixedContent
            $fixedContent = Invoke-NullComparisonFix -Content $fixedContent
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
    Write-Host "║         PowerShell QA Auto-Fix Engine v2.1.0                  ║" -ForegroundColor Cyan
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
