<#
.SYNOPSIS
    PoshGuard Scoping Best Practices Module

.DESCRIPTION
    PowerShell variable and function scoping including:
    - Global variable → script scope conversion
    - Global function scoping (adds script: prefix)
    - $using: scope modifier for runspaces

    Ensures proper scoping prevents namespace pollution.

.NOTES
    Part of PoshGuard v2.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

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

function Invoke-GlobalFunctionsFix {
    <#
    .SYNOPSIS
        Adds explicit scope to global functions

    .DESCRIPTION
        Functions without explicit scope are global by default in scripts.
        This function adds script: scope to make the scope explicit.

        CHANGES:
        - function Get-Data { } → function script:Get-Data { }

        PRESERVES:
        - Functions already with scope (global:, script:, private:)
        - Functions in modules (already scoped)

    .EXAMPLE
        # BEFORE:
        function Get-Data {
            return "data"
        }

        # AFTER:
        function script:Get-Data {
            return "data"
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

        # Find all function definitions
        $functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

        $replacements = @()

        foreach ($func in $functions) {
            $funcName = $func.Name

            # Check if function already has explicit scope
            if ($funcName -notmatch '^(global|script|private|local):') {
                # Find the position of the function name in the declaration
                $funcText = $func.Extent.Text
                $namePattern = "function\s+$([regex]::Escape($funcName))\b"

                if ($funcText -match $namePattern) {
                    $newFuncText = $funcText -replace $namePattern, "function script:$funcName"

                    $replacements += [PSCustomObject]@{
                        Offset = $func.Extent.StartOffset
                        Length = $func.Extent.Text.Length
                        Replacement = $newFuncText
                        FuncName = $funcName
                    }
                }
            }
        }

        if ($replacements.Count -gt 0) {
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
                Write-Verbose "Added script: scope to function: $($replacement.FuncName)"
            }
            return $fixed
        }
    }
    catch {
        Write-Verbose "Global functions fix failed: $_"
    }

    return $Content
}

# Export all scoping fix functions
Export-ModuleMember -Function @(
    'Invoke-GlobalVarFix',
    'Invoke-GlobalFunctionsFix'
)
