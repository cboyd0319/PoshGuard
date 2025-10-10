<#
.SYNOPSIS
    PoshGuard Formatting Auto-Fix Module

.DESCRIPTION
    Code formatting and style enforcement functions.
    Handles whitespace, aliases, casing, and Write-Host replacements.

.NOTES
    Part of PoshGuard v2.3.0
#>

Set-StrictMode -Version Latest

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
        Write-Verbose "Invoke-Formatter not available (PSScriptAnalyzer not installed)"
        return $Content
    }

    try {
        return Invoke-Formatter -ScriptDefinition $Content
    }
    catch {
        Write-Verbose "Invoke-Formatter failed: $_"
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

# Export all formatting fix functions
Export-ModuleMember -Function @(
    'Invoke-FormatterFix',
    'Invoke-WhitespaceFix',
    'Invoke-AliasFix',
    'Invoke-AliasFixAst',
    'Invoke-CasingFix',
    'Invoke-WriteHostFix'
)
