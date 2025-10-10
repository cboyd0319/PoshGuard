#!/usr/bin/env pwsh
#requires -Version 5.1

using module '../Core/Core.psm1'

<#
.SYNOPSIS
    Applies automated fixes to a file based on analysis results.

.DESCRIPTION
    Iterates through the analysis issues for a file and attempts to apply a corresponding fix.
    It supports a dry-run mode to preview changes. If fixes are applied, a backup is created first.

.PARAMETER AnalysisResult
    The PSQAResult object containing the analysis to fix.

.PARAMETER DryRun
    If set, changes will not be written to disk.

.EXAMPLE
    $fixedResult = Invoke-AutoFix -AnalysisResult $result -DryRun

.NOTES
    Returns the updated PSQAResult object with fix details.
#>
function Invoke-AutoFix {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [PSQAResult]$AnalysisResult,

        [Parameter()]
        [switch]$DryRun
    )

    if ($pscmdlet.ShouldProcess($AnalysisResult.FilePath, "Apply auto-fixes")) {
        Write-Verbose "Attempting auto-fix for: $($AnalysisResult.FilePath)"

        $fixResults = @()
        $content = Get-Content -Path $AnalysisResult.FilePath -Raw -ErrorAction Stop
        $originalContent = $content
        $backupPath = $null

        foreach ($issue in $AnalysisResult.AnalysisResults) {
            $fixResult = [PSQAFixResult]::new($issue.RuleName, "Auto-fix for $($issue.RuleName)")
            $fixResult.OriginalContent = $content

            try {
                $newContent = Set-SingleFix -Content $content -Issue $issue
                if ($newContent -ne $content) {
                    $fixResult.FixedContent = $newContent
                    $fixResult.Applied = -not $DryRun.IsPresent
                    $content = $newContent
                    Write-Verbose "Applied fix for: $($issue.RuleName)"
                }
            }
            catch {
                Write-Warning "Could not apply fix for $($issue.RuleName): $_ "
            }

            $fixResults += $fixResult
        }

        # Apply changes if not dry run and fixes were made
        if (-not $DryRun.IsPresent -and $content -ne $originalContent) {
            if (-not $DryRun.IsPresent -and $content -ne $originalContent) {
                if ($BackupEnabled) {
                    $backupPath = "$($AnalysisResult.FilePath).backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
                    Copy-Item -Path $AnalysisResult.FilePath -Destination $backupPath -Force -ErrorAction Stop
                    Write-Verbose "Backup created: $backupPath"
                }

                Set-Content -Path $AnalysisResult.FilePath -Value $content -Encoding UTF8 -ErrorAction Stop
                Write-Verbose "Fixes applied to: $($AnalysisResult.FilePath)"
            }
        }

        $AnalysisResult.FixResults = $fixResults
        return @{ Result = $AnalysisResult; BackupPath = $backupPath }
    }
}

<#
.SYNOPSIS
    Applies a single, specific fix to a string content.

.DESCRIPTION
    This function contains the logic for fixing individual PSScriptAnalyzer rule violations.
    It uses a switch statement to delegate to the correct fix based on the rule name.

.PARAMETER Content
    The string content of the script to fix.

.PARAMETER Issue
    The PSQAAnalysisResult object representing the issue to fix.

.EXAMPLE
    $newContent = Set-SingleFix -Content $scriptContent -Issue $analysisIssue

.NOTES
    This is the core of the auto-fix engine. It is designed to be extended with new fixes.
#>
function Set-SingleFix {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter(Mandatory)]
        [PSQAAnalysisResult]$Issue
    )

    if ($pscmdlet.ShouldProcess($Issue.RuleName, "Apply single fix")) {
        # Simple fixes based on rule names
        switch ($Issue.RuleName) {
            'PSAvoidTrailingWhitespace' {
                # Remove trailing whitespace from each line
                return ($Content -split "`n") -replace '\s+$', '' -join "`n"
            }
            'PSUseConsistentIndentation' {
                # Basic indentation fix - replace tabs with spaces
                return $Content -replace '\t', '    '
            }
            'PSAvoidUsingCmdletAliases' {
                # Expand common aliases
                $aliases = @{
                    'gci'     = 'Get-ChildItem'
                    'gcm'     = 'Get-Command'
                    'gm'      = 'Get-Member'
                    'iwr'     = 'Invoke-WebRequest'
                    'irm'     = 'Invoke-RestMethod'
                    'select'  = 'Select-Object'
                    'where'   = 'Where-Object'
                    'foreach' = 'ForEach-Object'
                    'sort'    = 'Sort-Object'
                    'group'   = 'Group-Object'
                    'measure' = 'Measure-Object'
                    'tee'     = 'Tee-Object'
                    '?'       = 'Where-Object'
                    '%'       = 'ForEach-Object'
                }

                foreach ($alias in $aliases.Keys) {
                    $Content = $Content -replace "\b$alias\b", $aliases[$alias]
                }
                return $Content
            }
            'PSAvoidUsingWriteHost' {
                # Replace Write-Host with Write-Output for better practices
                return $Content -replace '\bWrite-Host\b', 'Write-Output'
            }
            'PSAvoidUsingPositionalParameters' {
                # Fix common positional parameter usage - this is complex and requires careful regex
                # Note: This is a best-effort fix and may not cover all edge cases.
                $fixes = @{
                    'Set-Variable\s+([^\s]+)\s+([^\s]+)' = 'Set-Variable -Name $1 -Value $2'
                    'Join-Path\s+([^\s]+)\s+([^\s]+)'    = 'Join-Path -Path $1 -ChildPath $2'
                    'Get-ChildItem\s+([^\s]+)'           = 'Get-ChildItem -Path $1'
                    'Test-Path\s+([^\s]+)'               = 'Test-Path -Path $1'
                    'Remove-Item\s+([^\s]+)'             = 'Remove-Item -Path $1'
                    'New-Item\s+([^\s]+)'                = 'New-Item -Path $1'
                }

                foreach ($pattern in $fixes.Keys) {
                    $Content = $Content -replace $pattern, $fixes[$pattern]
                }
                return $Content
            }
            'PSUseDeclaredVarsMoreThanAssignments' {
                # Comment out unused variable assignments for manual review
                if ($Issue.Message -match "variable '(\w+)' is assigned but never used") {
                    $varName = $Matches[1]
                    $pattern = "^\s*\$$varName\s*=.*";
                    $lines = $Content -split "`n"
                    $fixedLines = @()
                    foreach ($line in $lines) {
                        if ($line -match $pattern) {
                            $fixedLines += "# FIXME: Unused variable assignment commented out by PSQA."
                            $fixedLines += "# $line"
                        }
                        else {
                            $fixedLines += $line
                        }
                    }
                    return $fixedLines -join "`n"
                }
                return $Content
            }
            'PSProvideCommentHelp' {
                # Add a comprehensive comment-based help block to functions that are missing it.
                if ($Issue.Message -match "cmdlet '([^']+)' does not have a help comment") {
                    $functionName = $Matches[1]
                    $cleanFunctionName = $functionName -replace '^global:', ''

                    # Extract parameter names from the function definition
                    $funcAst = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq $cleanFunctionName }, $true)[0]
                    $paramBlocks = ""
                    if ($funcAst.Parameters) {
                        foreach ($param in $funcAst.Parameters) {
                            $paramBlocks += ".PARAMETER $($param.Name)`n    Specifies the purpose of the `$($param.Name)` parameter.`n`n"
                        }
                    }

                    $helpBlock = @"
<#
.SYNOPSIS
    Provides a brief summary of the function's purpose.

.DESCRIPTION
    Provides a detailed description of what the function does.

$paramBlocks.EXAMPLE
    PS C:\> $cleanFunctionName -ParameterName "Value"
    Shows how to use the function.

.OUTPUTS
    [object]
    Describes the objects that the cmdlet returns.

.NOTES
    Provides additional information about the function.
#"@
                    # Add help block before the function definition
                    $Content = $Content -replace "(function\s+$([regex]::Escape($functionName)))", "$helpBlock`n`$1"
                }
                return $Content
            }
            'PSUseApprovedVerbs' {
                # Fix common unapproved verbs
                $verbFixes = @{
                    'Apply-' = 'Set-'
                    'Execute-' = 'Invoke-'
                    'Run-' = 'Start-'
                    'Launch-' = 'Start-'
                }

                foreach ($oldVerb in $verbFixes.Keys) {
                    $newVerb = $verbFixes[$oldVerb]
                    $Content = $Content -replace "\b$oldVerb", $newVerb
                }
                return $Content
            }
            'PSUseOutputTypeCorrectly' {
                # Add OutputType attribute to functions
                if ($Content -match 'function\s+([^\s\{]+)') {
                    $Content = $Content -replace "(function\s+[^\s\{]+)", "[OutputType([object])]`n`$1"
                }
                return $Content
            }
            'PSUseShouldProcessForStateChangingFunctions' {
                # Add ShouldProcess support for state-changing functions
                if ($Content -match 'function\s+([^\s\{]+).*?\{') {
                    $functionName = $Matches[1]
                    # Add CmdletBinding with SupportsShouldProcess
                    if ($Content -notmatch '\[CmdletBinding(SupportsShouldProcess)\]') {
                        if ($Content -match '\[CmdletBinding()\].*') {
                            $Content = $Content -replace '(\[CmdletBinding()\].*)', '[CmdletBinding(SupportsShouldProcess)]$1'
                        } else {
                            $Content = $Content -replace "(function\s+$functionName)", "[CmdletBinding(SupportsShouldProcess)]`n`$1"
                        }
                    }

                    # Add a placeholder ShouldProcess call
                    $shouldProcessBlock = @"

        if (`$pscmdlet.ShouldProcess("Target", "Operation")) {
            # Add state-changing code here
        }
"@
                    $Content = $Content -replace "(function\s+$functionName[^{]*\{)", "`$1$shouldProcessBlock"
                }
                return $Content
            }
            'PSReviewUnusedParameter' {
                # Comment out unused parameters for manual review.
                if ($Issue.Message -match "parameter '([^']+)' has been declared but not used") {
                    $paramName = $Matches[1]
                    $lines = $Content -split "`n"
                    $fixedLines = @()
                    $inParamBlock = $false
                    # Construct a regex pattern that looks for the parameter variable, e.g., $ParameterName
                    # The pattern needs to match a literal '$' followed by the parameter name.
                    # Word boundaries (\b) are used to avoid matching substrings.
                    $regexPattern = "\`$$($paramName)\b"

                    foreach ($line in $lines) {
                        if ($line -match '^\s*param\s*\(') { $inParamBlock = $true }
                        if ($inParamBlock -and $line -match '^\s*\)') { $inParamBlock = $false }

                        if ($inParamBlock -and $line -match $regexPattern) {
                            # Found the unused parameter, now comment it out.
                            $commentedLine = "# $line"

                            # Check if the previous line was a [Parameter(...)] attribute and comment it out too.
                            $previousLineIndex = $fixedLines.Count - 1
                            if ($previousLineIndex -ge 0 -and $fixedLines[$previousLineIndex] -match '^\s*\[Parameter') {
                                $fixedLines[$previousLineIndex] = "# $($fixedLines[$previousLineIndex])"
                            }

                            $fixedLines += "# FIXME: Unused parameter commented out by PSQA."
                            $fixedLines += $commentedLine
                        }
                        else {
                            $fixedLines += $line
                        }
                    }
                    return $fixedLines -join "`n"
                }
                return $Content
            }
            'PSUseSingularNouns' {
                # Fix common plural nouns in function names
                $pluralFixes = @{
                    'Variables'   = 'Variable'
                    'Diagnostics' = 'Diagnostic'
                    'Parameters'  = 'Parameter'
                    'Properties'  = 'Property'
                    'Settings'    = 'Setting'
                    'Items'       = 'Item'
                    'Files'       = 'File'
                    'Results'     = 'Result'
                }

                foreach ($plural in $pluralFixes.Keys) {
                    $singular = $pluralFixes[$plural]
                    $Content = $Content -replace "\b(\w+-)$plural\b", "`$1$singular"
                }
                return $Content
            }
            'PSPlaceOpenBrace' {
                # Fix brace placement - ensure newline after opening brace
                $Content = $Content -replace '(\{)\s*([^\r\n])', "`$1`n    `$2"
                return $Content
            }
            'NoUnsafeFileOperations' {
                # Add -ErrorAction Stop to file operations that are missing it.
                if ($Issue.Message -match "(Get-Content|Set-Content|Remove-Item|Copy-Item|Move-Item|Out-File|Add-Content)") {
                    $cmdlet = $Matches[1]
                    $pattern = "(\b$cmdlet\b\s+[^\n\r]*)(?<!-ErrorAction\s+\w+)"
                    return $Content -replace $pattern, "`$1 -ErrorAction Stop"
                }
                return $Content
            }
            default {
                # No auto-fix available
                return $Content
            }
        }
    }
}

Export-ModuleMember -Function Invoke-AutoFix, Set-SingleFix
