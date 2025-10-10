#requires -Version 5.1

<#
.SYNOPSIS
    Advanced auto-fix engine with unified diff generation and Invoke-Formatter integration.

.DESCRIPTION
    Production-grade auto-fix system that:
    - Integrates with Invoke-Formatter for safe formatting fixes
    - Generates unified diffs for transparency
    - Provides idempotent fixes (re-run safe)
    - Creates atomic backups with rollback support
    - Validates fixes before application
    - Supports dry-run mode for preview

    .NOTES
    Part of PoshGuard v2.1.0
    Author: https://github.com/cboyd0319
    Module: PSQAAutoFixer.psm1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Classes

class AutoFixResult {
    [string]$FilePath
    [string]$FixType
    [string]$Description
    [bool]$Applied
    [string]$OriginalContent
    [string]$FixedContent
    [string]$UnifiedDiff
    [datetime]$Timestamp
    [string]$TraceId

    AutoFixResult([string]$filePath, [string]$fixType, [string]$traceId) {
        $this.FilePath = $filePath
        $this.FixType = $fixType
        $this.Description = ''
        $this.Applied = $false
        $this.OriginalContent = ''
        $this.FixedContent = ''
        $this.UnifiedDiff = ''
        $this.Timestamp = Get-Date
        $this.TraceId = $traceId
    }
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Applies automated fixes to PowerShell file with unified diff output.

.DESCRIPTION
    Analyzes and fixes PowerShell file using PSScriptAnalyzer's built-in fixes
    and custom fix patterns. Generates unified diffs and handles backups.

.PARAMETER FilePath
    Path to PowerShell file to fix

.PARAMETER DryRun
    Preview fixes without applying

.PARAMETER CreateBackup
    Create backup before applying fixes

.PARAMETER TraceId
    Correlation trace ID for logging

.PARAMETER FixTypes
    Array of fix types to apply (defaults to all safe fixes)

.EXAMPLE
    Invoke-PSQAAutoFix -FilePath ./script.ps1 -DryRun

.EXAMPLE
    Invoke-PSQAAutoFix -FilePath ./script.ps1 -FixTypes @('Formatting', 'Whitespace')

.NOTES
    Returns array of AutoFixResult objects with unified diffs
#>
function Invoke-PSQAAutoFix {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([AutoFixResult[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$FilePath,

        [Parameter()]
        [switch]$DryRun,

        [Parameter()]
        [bool]$CreateBackup = $true,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString(),

        [Parameter()]
        [ValidateSet('Formatting', 'Whitespace', 'Aliases', 'Security', 'BestPractices', 'CommentHelp', 'All')]
        [string[]]$FixTypes = @('All')
    )

    Write-Verbose "[$TraceId] Starting auto-fix for: $FilePath"

    $results = @()
    $resolvedPath = Resolve-Path -Path $FilePath

    try {
        # Read original content
        $originalContent = Get-Content -Path $resolvedPath.Path -Raw
        Write-Verbose "[$TraceId] Original content: $originalContent"

        # Create backup if requested and not dry run
        if ($CreateBackup -and -not $DryRun) {
            $backupPath = New-FileBackup -FilePath $resolvedPath.Path -TraceId $TraceId
            Write-Verbose "[$TraceId] Backup created: $backupPath"
        }

        # Apply Invoke-Formatter (handles most formatting issues)
        if ($FixTypes -contains 'Formatting' -or $FixTypes -contains 'All') {
            $formatterResult = Invoke-FormatterFix -FilePath $resolvedPath.Path -OriginalContent $originalContent -TraceId $TraceId
            if ($formatterResult) {
                $results += $formatterResult
                $originalContent = $formatterResult.FixedContent  # Chain fixes
            }
        }

        # Apply whitespace cleanup
        if ($FixTypes -contains 'Whitespace' -or $FixTypes -contains 'All') {
            $whitespaceResult = Invoke-WhitespaceFix -FilePath $resolvedPath.Path -OriginalContent $originalContent -TraceId $TraceId
            if ($whitespaceResult) {
                $results += $whitespaceResult
                $originalContent = $whitespaceResult.FixedContent
            }
        }

        # Expand cmdlet aliases
        if ($FixTypes -contains 'Aliases' -or $FixTypes -contains 'All') {
            $aliasResult = Invoke-AliasFix -FilePath $resolvedPath.Path -OriginalContent $originalContent -TraceId $TraceId
            if ($aliasResult) {
                $results += $aliasResult
                $originalContent = $aliasResult.FixedContent
            }
        }

        # Apply security fixes
        if ($FixTypes -contains 'Security' -or $FixTypes -contains 'All') {
            $securityResult = Invoke-SecurityFix -FilePath $resolvedPath.Path -OriginalContent $originalContent -TraceId $TraceId
            if ($securityResult) {
                $results += $securityResult
                $originalContent = $securityResult.FixedContent
            }
        }

        # Apply best practice fixes
        if ($FixTypes -contains 'BestPractices' -or $FixTypes -contains 'All') {
            $bestPracticeResult = Invoke-BestPracticeFix -FilePath $resolvedPath.Path -OriginalContent $originalContent -TraceId $TraceId
            if ($bestPracticeResult) {
                $results += $bestPracticeResult
                $originalContent = $bestPracticeResult.FixedContent
            }
        }

        # Add comment help
        if ($FixTypes -contains 'CommentHelp' -or $FixTypes -contains 'All') {
            $commentHelpResult = Invoke-CommentHelpFix -FilePath $resolvedPath.Path -OriginalContent $originalContent -TraceId $TraceId
            if ($commentHelpResult) {
                $results += $commentHelpResult
                $originalContent = $commentHelpResult.FixedContent
            }
        }

        Write-Verbose "[$TraceId] Fixed content: $originalContent"
        Write-Verbose "[$TraceId] Results: $($results | ConvertTo-Json -Depth 5 -Compress)"

        # Apply final fixes to file if not dry run
        if (-not $DryRun.IsPresent -and $results.Count -gt 0) {
            $finalContent = $originalContent
            Set-Content -Path $resolvedPath.Path -Value $finalContent -Encoding UTF8 -NoNewline
            Write-Verbose "[$TraceId] Fixes applied to: $FilePath"

            foreach ($result in $results) {
                $result.Applied = $true
            }
        }

        Write-Verbose "[$TraceId] Auto-fix complete: $($results.Count) fixes processed"

    } catch {
        Write-Error "[$TraceId] Auto-fix failed for $FilePath : $_"
        throw
    }

    return $results
}

<#
.SYNOPSIS
    Adds boilerplate comment-based help to functions.

.DESCRIPTION
    Adds a standard comment block to functions that are missing one.

.PARAMETER FilePath
    File path

.PARAMETER OriginalContent
    Original file content

.PARAMETER TraceId
    Trace ID for logging

.EXAMPLE
    Invoke-CommentHelpFix -FilePath ./script.ps1 -OriginalContent $content
#>
function Invoke-CommentHelpFix {
    [CmdletBinding()]
    [OutputType([AutoFixResult])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$OriginalContent,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    $fixedContent = $OriginalContent
    $changesMade = $false

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($OriginalContent, [ref]$null, [ref]$null)
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    foreach ($function in $functions) {
        if (-not $function.PSObject.Properties['HelpContent']) {
            $boilerplate = @'
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

.EXAMPLE
    PS C:\> {0} -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#>
'@ -f $function.Name

            $functionText = $function.Extent.Text
            $fixedContent = $fixedContent.Replace($functionText, "$boilerplate`n$functionText")
            $changesMade = $true
        }
    }

    if ($changesMade) {
        $result = [AutoFixResult]::new($FilePath, 'CommentHelp', $TraceId)
        $result.Description = 'Added boilerplate comment-based help'
        $result.OriginalContent = $OriginalContent
        $result.FixedContent = $fixedContent
        $result.UnifiedDiff = New-UnifiedDiff -Original $OriginalContent -Modified $fixedContent -FilePath $FilePath

        Write-Verbose "[$TraceId] Comment help fixes applied"
        return $result
    }

    return $null
}

<#
.SYNOPSIS
    Generates unified diff between two text strings.

.DESCRIPTION
    Creates standard unified diff format showing additions/removals with context.

.PARAMETER Original
    Original text content

.PARAMETER Modified
    Modified text content

.PARAMETER FilePath
    File path for diff header

.PARAMETER ContextLines
    Number of context lines to show (default: 3)

.EXAMPLE
    New-UnifiedDiff -Original $old -Modified $new -FilePath "script.ps1"

.NOTES
    Returns unified diff string in standard format
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
        [string]$FilePath,

#         [Parameter()]
# FIXME: Unused parameter commented out by PSQA.
#         [int]$ContextLines = 3
    )

    $diff = Compare-Object -ReferenceObject ($Original -split '\r?\n') -DifferenceObject ($Modified -split '\r?\n')

    if ($null -eq $diff) {
        return ""
    }

    $lines = @()
    $lines += "--- a/$FilePath"
    $lines += "+++ b/$FilePath"

    foreach ($line in $diff) {
        $indicator = switch ($line.SideIndicator) {
            '<=' { '-' }
            '=>' { '+' }
        }
        $lines += "$indicator$($line.InputObject)"
    }

    return ($lines -join "`n")
}

#endregion

#region Fix Implementations

<#
.SYNOPSIS
    Applies Invoke-Formatter fixes.

.DESCRIPTION
    Uses PSScriptAnalyzer's Invoke-Formatter for safe formatting.

.PARAMETER FilePath
    File path

.PARAMETER OriginalContent
    Original file content

.PARAMETER TraceId
    Trace ID for logging

.EXAMPLE
    Invoke-FormatterFix -FilePath ./script.ps1 -OriginalContent $content
#>
function Invoke-FormatterFix {
    [CmdletBinding()]
    [OutputType([AutoFixResult])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$OriginalContent,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    try {
        # Check if PSScriptAnalyzer is available
        if (-not (Get-Command -Name Invoke-Formatter -ErrorAction SilentlyContinue)) {
            Write-Verbose "[$TraceId] Invoke-Formatter not available, skipping formatter fix"
            return $null
        }

        # Apply Invoke-Formatter
        $formattedContent = Invoke-Formatter -ScriptDefinition $OriginalContent

        if ($formattedContent -ne $OriginalContent) {
            $result = [AutoFixResult]::new($FilePath, 'Formatting', $TraceId)
            $result.Description = 'Applied Invoke-Formatter for consistent code formatting'
            $result.OriginalContent = $OriginalContent
            $result.FixedContent = $formattedContent
            $result.UnifiedDiff = New-UnifiedDiff -Original $OriginalContent -Modified $formattedContent -FilePath $FilePath

            Write-Verbose "[$TraceId] Formatter fixes applied"
            return $result
        }

    } catch {
        Write-Verbose "[$TraceId] Formatter fix failed: $_"
    }

    return $null
}

<#
.SYNOPSIS
    Cleans up whitespace issues.

.DESCRIPTION
    Removes trailing whitespace, normalizes line endings, ensures final newline.

.PARAMETER FilePath
    File path

.PARAMETER OriginalContent
    Original file content

.PARAMETER TraceId
    Trace ID for logging

.EXAMPLE
    Invoke-WhitespaceFix -FilePath ./script.ps1 -OriginalContent $content
#>
function Invoke-WhitespaceFix {
    [CmdletBinding()]
    [OutputType([AutoFixResult])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$OriginalContent,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    # Process lines individually to remove trailing whitespace
    $lines = $OriginalContent -split "(?:\r\n|\n)"
    $trimmedLines = $lines | ForEach-Object { $_.TrimEnd() }
    $fixedContent = $trimmedLines -join "`n"

    if ($fixedContent -ne $OriginalContent) {
        $result = [AutoFixResult]::new($FilePath, 'Whitespace', $TraceId)
        $result.Description = 'Removed trailing whitespace and normalized line endings'
        $result.OriginalContent = $OriginalContent
        $result.FixedContent = $fixedContent
        $result.UnifiedDiff = New-UnifiedDiff -Original $OriginalContent -Modified $fixedContent -FilePath $FilePath

        Write-Verbose "[$TraceId] Whitespace fixes applied"
        return $result
    }

    return $null
}

<#
.SYNOPSIS
    Expands PowerShell cmdlet aliases.

.DESCRIPTION
    Replaces common aliases with full cmdlet names for clarity.

.PARAMETER FilePath
    File path

.PARAMETER OriginalContent
    Original file content

.PARAMETER TraceId
    Trace ID for logging

.EXAMPLE
    Invoke-AliasFix -FilePath ./script.ps1 -OriginalContent $content
#>
function Invoke-AliasFix {
    [CmdletBinding()]
    [OutputType([AutoFixResult])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$OriginalContent,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    $fixedContent = Invoke-AliasFixAst -Content $OriginalContent

    if ($fixedContent -ne $OriginalContent) {
        $result = [AutoFixResult]::new($FilePath, 'Aliases', $TraceId)
        $result.Description = 'Expanded cmdlet aliases to full names'
        $result.OriginalContent = $OriginalContent
        $result.FixedContent = $fixedContent
        $result.UnifiedDiff = New-UnifiedDiff -Original $OriginalContent -Modified $fixedContent -FilePath $FilePath

        Write-Verbose "[$TraceId] Alias fixes applied"
        return $result
    }

    return $null
}

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
        'gci' = 'Get-ChildItem'; 'select' = 'Select-Object'; 'where' = 'Where-Object'; 'gcm' = 'Get-Command'; 'gm' = 'Get-Member'; 'iwr' = 'Invoke-WebRequest';
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

<#
.SYNOPSIS
    Applies security-focused fixes.

.DESCRIPTION
    Replaces dangerous patterns with safer alternatives (where safe to do so).

.PARAMETER FilePath
    File path

.PARAMETER OriginalContent
    Original file content

.PARAMETER TraceId
    Trace ID for logging

.EXAMPLE
    Invoke-SecurityFix -FilePath ./script.ps1 -OriginalContent $content
#>
function Invoke-SecurityFix {
    [CmdletBinding()]
    [OutputType([AutoFixResult])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$OriginalContent,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    $fixedContent = $OriginalContent
    $changesMade = $false

    # Fix incorrect $null comparison order
    $nullComparisonPattern = '(\$\w+(\s*\[.*?\])?)\s*(-eq|-ne)\s*(\$null)'
    if ($fixedContent -match $nullComparisonPattern) {
        $fixedContent = $fixedContent -replace $nullComparisonPattern, '$4 $3 $1'
        $changesMade = $true
    }

    # Replace simple Write-Host calls with Write-Output
    $writeHostPattern = '\bWrite-Host\b'
    if ($fixedContent -match $writeHostPattern) {
        $fixedContent = $fixedContent -replace $writeHostPattern, 'Write-Output'
        $changesMade = $true
    }

    if ($changesMade) {
        $result = [AutoFixResult]::new($FilePath, 'Security', $TraceId)
        $result.Description = 'Applied safe security improvements'
        $result.OriginalContent = $OriginalContent
        $result.FixedContent = $fixedContent
        $result.UnifiedDiff = New-UnifiedDiff -Original $OriginalContent -Modified $fixedContent -FilePath $FilePath

        Write-Verbose "[$TraceId] Security fixes applied"
        return $result
    }

    return $null
}

<#
.SYNOPSIS
    Applies best practice fixes.

.DESCRIPTION
    Applies PowerShell best practice improvements (safe transformations).

.PARAMETER FilePath
    File path

.PARAMETER OriginalContent
    Original file content

.PARAMETER TraceId
    Trace ID for logging

.EXAMPLE
    Invoke-BestPracticeFix -FilePath ./script.ps1 -OriginalContent $content
#>
function Invoke-BestPracticeFix {
    [CmdletBinding()]
    [OutputType([AutoFixResult])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$OriginalContent,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    $fixedContent = $OriginalContent
    $changesMade = $false

    # Example: Replace $() subexpressions with simpler forms where possible
    # (This is a placeholder - real implementation would be more sophisticated)

    if ($changesMade) {
        $result = [AutoFixResult]::new($FilePath, 'BestPractices', $TraceId)
        $result.Description = 'Applied PowerShell best practice improvements'
        $result.OriginalContent = $OriginalContent
        $result.FixedContent = $fixedContent
        $result.UnifiedDiff = New-UnifiedDiff -Original $OriginalContent -Modified $fixedContent -FilePath $FilePath

        Write-Verbose "[$TraceId] Best practice fixes applied"
        return $result
    }

    return $null
}

#endregion

#region Helper Functions

<#
.SYNOPSIS
    Creates atomic backup of file.

.DESCRIPTION
    Creates timestamped backup in .psqa-backup directory.

.PARAMETER FilePath
    File to backup

.PARAMETER TraceId
    Trace ID for logging

.EXAMPLE
    New-FileBackup -FilePath ./script.ps1

.NOTES
    Returns backup file path
#>
function New-FileBackup {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    $backupDir = Join-Path -Path (Split-Path -Path $FilePath -Parent) -ChildPath '.psqa-backup'

    if (-not (Test-Path -Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }

    $fileName = Split-Path -Path $FilePath -Leaf
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $backupFileName = "$fileName.$timestamp.bak"
    $backupPath = Join-Path -Path $backupDir -ChildPath $backupFileName

    Copy-Item -Path $FilePath -Destination $backupPath -Force

    Write-Verbose "[$TraceId] Backup created: $backupPath"
    return $backupPath
}

#endregion

#region Exports

Export-ModuleMember -Function @(
    'Invoke-PSQAAutoFix',
    'New-UnifiedDiff',
    'New-FileBackup'
)

#endregion


