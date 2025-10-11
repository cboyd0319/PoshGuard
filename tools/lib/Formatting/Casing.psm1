<#
.SYNOPSIS
    PoshGuard Casing Formatting Module

.DESCRIPTION
    PowerShell cmdlet and parameter casing fixes including:
    - Cmdlet name casing (get-childitem → Get-ChildItem)
    - Parameter name casing (-path → -Path)
    - Common parameter casing standardization

    Ensures consistent PascalCase for cmdlets and parameters.

.NOTES
    Part of PoshGuard v2.4.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

function Invoke-CasingFix {
    <#
    .SYNOPSIS
        Fixes cmdlet and parameter casing

    .DESCRIPTION
        AST-based cmdlet/parameter casing fix using token analysis.
        Corrects cmdlet names and common parameters to proper PascalCase.

    .EXAMPLE
        # BEFORE:
        get-childitem -path C:\ -force

        # AFTER:
        Get-ChildItem -Path C:\ -Force
    #>
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

# Export all casing fix functions
Export-ModuleMember -Function @(
    'Invoke-CasingFix'
)
