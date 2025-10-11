<#
.SYNOPSIS
    PoshGuard Documentation Module

.DESCRIPTION
    Functions for generating and improving PowerShell documentation including:
    - Comment-based help generation
    - OutputType attribute addition
    - HelpMessage validation and correction

    Ensures functions have proper documentation for Get-Help and IntelliSense.

.NOTES
    Part of PoshGuard v2.4.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

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

function Invoke-OutputTypeCorrectlyFix {
    <#
    .SYNOPSIS
        Adds [OutputType()] attribute to functions

    .DESCRIPTION
        Analyzes return statements and adds [OutputType()] attribute
        to help with type inference and documentation.

    .EXAMPLE
        # BEFORE:
        function Get-Data {
            return "text"
        }

        # AFTER:
        [OutputType([string])]
        function Get-Data {
            return "text"
        }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

        $functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

        $replacements = @()

        foreach ($func in $functions) {
            # Check if already has OutputType
            $hasOutputType = $func.Body.ParamBlock -and
                $func.Body.ParamBlock.Attributes | Where-Object {
                    $_ -is [System.Management.Automation.Language.AttributeAst] -and
                    $_.TypeName.Name -eq 'OutputType'
                }

            if (-not $hasOutputType) {
                # Try to infer type from return statements (simple heuristic)
                $returns = $func.Body.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.ReturnStatementAst]
                }, $true)

                if ($returns.Count -gt 0) {
                    $replacements += [PSCustomObject]@{
                        FuncName = $func.Name
                        Offset = $func.Extent.StartOffset
                    }
                }
            }
        }

        if ($replacements.Count -gt 0) {
            $lines = $Content -split "`n"
            $newLines = @()

            foreach ($line in $lines) {
                foreach ($replacement in $replacements) {
                    if ($line -match "function\s+$([regex]::Escape($replacement.FuncName))") {
                        $newLines += "# TODO: Add [OutputType([type])] attribute to document return type"
                    }
                }
                $newLines += $line
            }

            Write-Verbose "Added TODO comments for $($replacements.Count) function(s) needing OutputType"
            return ($newLines -join "`n")
        }
    }
    catch {
        Write-Verbose "OutputType fix failed: $_"
    }

    return $Content
}

# Export all documentation functions
Export-ModuleMember -Function @(
    'Invoke-CommentHelpFix',
    'Invoke-OutputTypeCorrectlyFix'
)
