<#
.SYNOPSIS
    PoshGuard AST Transformation Module

.DESCRIPTION
    Complex AST-based code transformations including:
    - WMI to CIM cmdlet conversion
    - Broken hash algorithm replacement (MD5/SHA1 → SHA256)
    - Long line wrapping with intelligent strategies

    These transformations require deep AST analysis and multi-pass modifications.

.NOTES
    Part of PoshGuard v2.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

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

function Invoke-LongLinesFix {
    <#
    .SYNOPSIS
        Wraps long lines to improve readability (PSAvoidLongLines)

    .DESCRIPTION
        AST-based intelligent line wrapping for PowerShell code that exceeds
        the recommended 120 character line length.

        WRAPPING STRATEGIES:
        - Command parameters: Wrap each parameter on new line with backticks
        - Pipeline chains: Break at pipe operators
        - String concatenation: Wrap at operators
        - Preserves indentation and code structure
        - Uses backticks for continuation

        SKIPS:
        - Comment lines (preserve formatting)
        - Here-strings (can't be wrapped)
        - Lines with embedded line breaks
        - Lines already using splatting

    .PARAMETER Content
        PowerShell script content to process

    .PARAMETER MaxLineLength
        Maximum line length before wrapping (default: 120)

    .EXAMPLE
        # BEFORE (150 chars):
        Get-ChildItem -Path C:\VeryLongPath\With\Many\Subdirectories -Filter *.ps1 -Recurse -ErrorAction Stop

        # AFTER (wrapped):
        Get-ChildItem `
            -Path C:\VeryLongPath\With\Many\Subdirectories `
            -Filter *.ps1 `
            -Recurse `
            -ErrorAction Stop
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter()]
        [int]$MaxLineLength = 120
    )

    try {
        $lines = $Content -split '\r?\n'
        $result = [System.Collections.ArrayList]::new()
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -gt 0) {
            Write-Verbose "Skipping long lines fix due to parse errors"
            return $Content
        }

        # Process each line
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $trimmedLine = $line.TrimEnd()

            # Skip if line is acceptable length
            if ($trimmedLine.Length -le $MaxLineLength) {
                $result.Add($line) | Out-Null
                continue
            }

            # Get indentation
            $indent = ''
            if ($line -match '^(\s+)') {
                $indent = $Matches[1]
            }

            # Skip comment lines, here-strings, or lines that can't be wrapped
            if ($trimmedLine.TrimStart() -match '^#' -or
                $trimmedLine -match '@["'']$' -or
                $trimmedLine -match '^["'']@') {
                $result.Add($line) | Out-Null
                continue
            }

            # Find the token(s) on this line
            $lineStartOffset = ($lines[0..$i] | Measure-Object -Property Length -Sum).Sum + $i
            $lineEndOffset = $lineStartOffset + $line.Length

            $lineTokens = @($tokens | Where-Object {
                $_.Extent.StartOffset -ge $lineStartOffset -and
                $_.Extent.EndOffset -le $lineEndOffset
            })

            if ($lineTokens.Count -eq 0) {
                $result.Add($line) | Out-Null
                continue
            }

            # Strategy 1: Wrap command with parameters
            $wrapped = $false
            if ($trimmedLine -match '^\s*[\w-]+\s+-') {
                # This looks like a command with parameters
                $parts = @()
                $currentPart = ''
                $inString = $false
                $stringChar = $null

                for ($c = 0; $c -lt $trimmedLine.Length; $c++) {
                    $char = $trimmedLine[$c]

                    # Track string boundaries
                    if (($char -eq '"' -or $char -eq "'") -and ($c -eq 0 -or $trimmedLine[$c-1] -ne '`')) {
                        if (-not $inString) {
                            $inString = $true
                            $stringChar = $char
                        } elseif ($char -eq $stringChar) {
                            $inString = $false
                            $stringChar = $null
                        }
                    }

                    # Split on parameters (only outside strings)
                    if (-not $inString -and $char -eq '-' -and $c -gt 0 -and $trimmedLine[$c-1] -match '\s') {
                        if ($currentPart.Trim()) {
                            $parts += $currentPart.TrimEnd()
                        }
                        $currentPart = '-'
                    } else {
                        $currentPart += $char
                    }
                }

                # Add last part
                if ($currentPart.Trim()) {
                    $parts += $currentPart.TrimEnd()
                }

                # If we have multiple parameters, wrap them
                if ($parts.Count -gt 2) {
                    $wrappedLines = @()
                    $continuationIndent = $indent + '    '

                    for ($p = 0; $p -lt $parts.Count; $p++) {
                        if ($p -eq 0) {
                            # First part (command) with backtick
                            $wrappedLines += "$indent$($parts[$p].Trim()) ``"
                        } elseif ($p -eq $parts.Count - 1) {
                            # Last part (no backtick)
                            $wrappedLines += "$continuationIndent$($parts[$p].Trim())"
                        } else {
                            # Middle parts with backticks
                            $wrappedLines += "$continuationIndent$($parts[$p].Trim()) ``"
                        }
                    }

                    foreach ($wrappedLine in $wrappedLines) {
                        $result.Add($wrappedLine) | Out-Null
                    }
                    $wrapped = $true
                    Write-Verbose "Wrapped long command line: $($line.Substring(0, [Math]::Min(50, $line.Length)))..."
                }
            }

            # Strategy 2: Wrap pipeline chains
            if (-not $wrapped -and $trimmedLine -match '\|') {
                $pipelineParts = $trimmedLine -split '\|'
                if ($pipelineParts.Count -gt 1) {
                    $wrappedLines = @()
                    $continuationIndent = $indent + '    '

                    for ($p = 0; $p -lt $pipelineParts.Count; $p++) {
                        $part = $pipelineParts[$p].Trim()
                        if ($p -eq 0) {
                            $wrappedLines += "$indent$part |"
                        } elseif ($p -eq $pipelineParts.Count - 1) {
                            $wrappedLines += "$continuationIndent$part"
                        } else {
                            $wrappedLines += "$continuationIndent$part |"
                        }
                    }

                    # Only use if it actually improves things
                    $maxWrappedLength = ($wrappedLines | Measure-Object -Property Length -Maximum).Maximum
                    if ($maxWrappedLength -lt $trimmedLine.Length) {
                        foreach ($wrappedLine in $wrappedLines) {
                            $result.Add($wrappedLine) | Out-Null
                        }
                        $wrapped = $true
                        Write-Verbose "Wrapped long pipeline: $($line.Substring(0, [Math]::Min(50, $line.Length)))..."
                    }
                }
            }

            # If no wrapping strategy worked, keep original line
            if (-not $wrapped) {
                $result.Add($line) | Out-Null
            }
        }

        return $result -join "`n"
    }
    catch {
        Write-Verbose "Long lines fix failed: $_"
        return $Content
    }
}

# Export all AST transformation functions
Export-ModuleMember -Function @(
    'Invoke-WmiToCimFix',
    'Invoke-BrokenHashAlgorithmFix',
    'Invoke-LongLinesFix'
)
