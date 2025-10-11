<#
.SYNOPSIS
    PoshGuard Output Formatting Module

.DESCRIPTION
    PowerShell output and redirection fixes including:
    - Write-Host → Write-Output (for non-UI output)
    - Redirection operator normalization (1> → >)
    - Smart UI component preservation

    Ensures proper output handling and redirection usage.

.NOTES
    Part of PoshGuard v2.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

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

function Invoke-RedirectionOperatorFix {
    <#
    .SYNOPSIS
        Fixes incorrect redirection operator usage

    .DESCRIPTION
        Normalizes redirection operators (>, >>, 2>, 2>&1, etc.)
        Fixes common mistakes like 1> instead of > or incorrect stream numbers.

    .EXAMPLE
        # BEFORE:
        command 1> output.txt

        # AFTER:
        command > output.txt
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        # Normalize 1> to >
        $fixed = $Content -replace '\b1\s*>', ' >'

        # Normalize 1>> to >>
        $fixed = $fixed -replace '\b1\s*>>', ' >>'

        # Ensure proper spacing for redirection operators
        $fixed = $fixed -replace '(\w)\s*([2-6]?>)', '$1 $2'

        if ($fixed -ne $Content) {
            Write-Verbose "Normalized redirection operators"
            return $fixed
        }
    }
    catch {
        Write-Verbose "Redirection operator fix failed: $_"
    }

    return $Content
}

# Export all output fix functions
Export-ModuleMember -Function @(
    'Invoke-WriteHostFix',
    'Invoke-RedirectionOperatorFix'
)
