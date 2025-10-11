# ShouldProcessTransformation.psm1
# Full PSShouldProcess implementation - wraps function bodies with ShouldProcess logic

function Invoke-PSShouldProcessFix {
    <#
    .SYNOPSIS
        Implements complete PSShouldProcess support for functions with SupportsShouldProcess

    .DESCRIPTION
        PSScriptAnalyzer rule: PSShouldProcess
        This is the HARDEST auto-fix. It:
        1. Detects functions with [CmdletBinding(SupportsShouldProcess)] but no ShouldProcess call
        2. Wraps the entire function body in if ($PSCmdlet.ShouldProcess(...)) {}
        3. Intelligently determines target and action parameters

    .PARAMETER Content
        The script content to process

    .EXAMPLE
        # BEFORE:
        [CmdletBinding(SupportsShouldProcess=$true)]
        function Remove-Data {
            param($Path)
            Remove-Item $Path
        }

        # AFTER:
        [CmdletBinding(SupportsShouldProcess=$true)]
        function Remove-Data {
            param($Path)
            if ($PSCmdlet.ShouldProcess($Path, "Remove data")) {
                Remove-Item $Path
            }
        }

    .NOTES
        This is extremely complex because:
        - Must parse and understand function structure
        - Must identify the "target" (what's being acted upon)
        - Must wrap all statements while preserving formatting
        - Must handle edge cases (multiple returns, complex control flow)
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

        if ($errors.Count -gt 0) {
            Write-Verbose "Parse errors, skipping PSShouldProcess fix"
            return $Content
        }

        # Find all functions with SupportsShouldProcess but no ShouldProcess call
        $functions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

        $result = $Content
        $offsetAdjustment = 0

        foreach ($func in $functions) {
            # Check if has SupportsShouldProcess attribute (check both param block and function body)
            $hasSupportsShouldProcess = $false

            # Check param block attributes (most common location)
            if ($func.Body.ParamBlock) {
                foreach ($attr in $func.Body.ParamBlock.Attributes) {
                    if ($attr.TypeName.Name -eq 'CmdletBinding') {
                        foreach ($namedArg in $attr.NamedArguments) {
                            if ($namedArg.ArgumentName -eq 'SupportsShouldProcess') {
                                # Check for both VariableExpressionAst ($true) and other boolean representations
                                $argValue = $null
                                if ($namedArg.Argument -is [System.Management.Automation.Language.VariableExpressionAst]) {
                                    $argValue = $namedArg.Argument.VariablePath.UserPath
                                } else {
                                    $argValue = $namedArg.Argument.ToString()
                                }
                                if ($argValue -in @('true', 'True', '$true')) {
                                    $hasSupportsShouldProcess = $true
                                    break
                                }
                            }
                        }
                    }
                }
            }

            # Also check function body attributes (alternative syntax)
            if (-not $hasSupportsShouldProcess) {
                foreach ($attr in $func.Body.Attributes) {
                    if ($attr.TypeName.Name -eq 'CmdletBinding') {
                        foreach ($namedArg in $attr.NamedArguments) {
                            if ($namedArg.ArgumentName -eq 'SupportsShouldProcess') {
                                $argValue = $null
                                if ($namedArg.Argument -is [System.Management.Automation.Language.VariableExpressionAst]) {
                                    $argValue = $namedArg.Argument.VariablePath.UserPath
                                } else {
                                    $argValue = $namedArg.Argument.ToString()
                                }
                                if ($argValue -in @('true', 'True', '$true')) {
                                    $hasSupportsShouldProcess = $true
                                    break
                                }
                            }
                        }
                    }
                }
            }

            if (-not $hasSupportsShouldProcess) {
                continue
            }

            # Check if already has ShouldProcess call
            $hasShouldProcessCall = $func.Body.Find({
                param($node)
                $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
                $node.Member.Value -eq 'ShouldProcess'
            }, $true)

            if ($hasShouldProcessCall) {
                Write-Verbose "Function $($func.Name) already has ShouldProcess call"
                continue
            }

            Write-Verbose "Function $($func.Name) needs ShouldProcess wrapping"

            # Extract function verb and noun
            $funcName = $func.Name
            $parts = $funcName -split '-'
            $verb = if ($parts.Count -ge 2) { $parts[0] } else { "Modify" }
            $noun = if ($parts.Count -ge 2) { $parts[1..($parts.Count-1)] -join '-' } else { "item" }

            # Try to identify the target parameter (usually first mandatory param or Path/Name param)
            $targetParam = $null
            if ($func.Body.ParamBlock -and $func.Body.ParamBlock.Parameters) {
                # Look for common target parameters
                $commonTargetNames = @('Path', 'Name', 'Identity', 'Id', 'File', 'Target', 'Object')
                foreach ($paramName in $commonTargetNames) {
                    $param = $func.Body.ParamBlock.Parameters | Where-Object {
                        $_.Name.VariablePath.UserPath -eq $paramName
                    } | Select-Object -First 1
                    if ($param) {
                        $targetParam = "`$$($param.Name.VariablePath.UserPath)"
                        break
                    }
                }

                # If no common name found, use first mandatory parameter
                if (-not $targetParam) {
                    $mandatoryParam = $func.Body.ParamBlock.Parameters | Where-Object {
                        $_.Attributes | Where-Object {
                            $_.TypeName.Name -eq 'Parameter' -and
                            ($_.NamedArguments | Where-Object { $_.ArgumentName -eq 'Mandatory' -and $_.Argument.VariablePath.UserPath -eq 'true' })
                        }
                    } | Select-Object -First 1

                    if ($mandatoryParam) {
                        $targetParam = "`$$($mandatoryParam.Name.VariablePath.UserPath)"
                    }
                }

                # Fallback: use first parameter
                if (-not $targetParam -and $func.Body.ParamBlock.Parameters.Count -gt 0) {
                    $targetParam = "`$$($func.Body.ParamBlock.Parameters[0].Name.VariablePath.UserPath)"
                }
            }

            # Default target if nothing found
            if (-not $targetParam) {
                $targetParam = '"target"'
            }

            # Create action description
            $action = "$verb $noun"

            # Find the function body (after param block)
            $bodyStart = if ($func.Body.ParamBlock) {
                $func.Body.ParamBlock.Extent.EndOffset
            } else {
                $func.Body.Extent.StartOffset + 1  # After opening brace
            }

            $bodyEnd = $func.Body.Extent.EndOffset - 1  # Before closing brace

            # Extract the body content
            $originalBody = $result.Substring($bodyStart + $offsetAdjustment, $bodyEnd - $bodyStart)

            # Skip if body is empty or only whitespace
            if ([string]::IsNullOrWhiteSpace($originalBody)) {
                continue
            }

            # Determine indentation
            $lines = $originalBody -split "`r?`n"
            $firstNonEmptyLine = $lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1
            $indent = if ($firstNonEmptyLine -match '^(\s+)') { $matches[1] } else { "    " }

            # Create the wrapped body
            $wrappedBody = @"

$indent`if (`$PSCmdlet.ShouldProcess($targetParam, "$action")) {
$originalBody
$indent}
"@

            # Replace the body
            $result = $result.Remove($bodyStart + $offsetAdjustment, $bodyEnd - $bodyStart)
            $result = $result.Insert($bodyStart + $offsetAdjustment, $wrappedBody)

            # Adjust offset for next iteration
            $offsetAdjustment += $wrappedBody.Length - ($bodyEnd - $bodyStart)

            Write-Verbose "Wrapped function $funcName with ShouldProcess (target: $targetParam, action: $action)"
        }

        return $result
    }
    catch {
        Write-Verbose "PSShouldProcess fix failed: $_"
        return $Content
    }
}

Export-ModuleMember -Function 'Invoke-PSShouldProcessFix'
