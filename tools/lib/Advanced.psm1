<#
.SYNOPSIS
    PoshGuard Advanced Auto-Fix Module

.DESCRIPTION
    Complex AST-based analysis and transformation functions requiring
    deep PowerShell parsing and multi-pass transformations.
    
    Functions in this module handle:
    - Unused parameter detection and removal
    - Long line wrapping with intelligent strategies
    - Comment-based help generation
    - WMI to CIM cmdlet conversion
    - SupportsShouldProcess detection and addition
    - Reserved parameter renaming
    - Switch parameter default value removal
    - Broken hash algorithm replacement
    - Duplicate line detection
    - Cmdlet parameter validation
    - Safety improvements (ErrorAction addition)

.NOTES
    Part of PoshGuard v2.3.0
    These functions are the most computationally expensive
    and require careful AST manipulation.
#>

Set-StrictMode -Version Latest

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

function Invoke-UnusedParameterFix {
    <#
    .SYNOPSIS
        Comments out unused parameters in functions

    .DESCRIPTION
        Detects parameters that are declared but never used in the function body
        and comments them out with a note explaining they were unused.

        Detection Logic:
        - Finds all ParameterAst nodes in function
        - Finds all VariableExpressionAst references in function body
        - Identifies parameters with zero references
        - Comments out unused parameters with descriptive note

        Edge Cases Handled:
        - Splatting (@PSBoundParameters)
        - $PSCmdlet automatic variable
        - Parameters used in nested functions

    .EXAMPLE
        PS C:\> Invoke-UnusedParameterFix -Content $scriptContent

        Comments out unused parameters with explanatory notes
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

            # Find all function definitions
            $functions = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

            foreach ($funcAst in $functions) {
                # Get all parameters in this function
                $parameters = $funcAst.FindAll({
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }, $true)

                # Get all variable references in the function body
                $varRefs = $funcAst.Body.FindAll({
                    $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
                }, $true)

                # Check for splatting or $PSBoundParameters usage (means all params might be used)
                $splattingRefs = @($funcAst.Body.FindAll({
                    $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
                    ($args[0].VariablePath.UserPath -eq 'PSBoundParameters' -or $args[0].Splatted)
                }, $true))
                $usesSplatting = $splattingRefs.Count -gt 0

                if ($usesSplatting) {
                    # Skip this function - splatting means params might be used indirectly
                    continue
                }

                foreach ($paramAst in $parameters) {
                    $paramName = $paramAst.Name.VariablePath.UserPath

                    # Count references to this parameter in function body
                    $paramRefs = @($varRefs | Where-Object {
                        $_.VariablePath.UserPath -eq $paramName
                    })
                    $refCount = $paramRefs.Count

                    if ($refCount -eq 0) {
                        # Parameter is unused - comment it out
                        $paramExtent = $paramAst.Extent
                        $paramText = $paramExtent.Text

                        # Get the full line to check indentation
                        $startLine = $paramExtent.StartLineNumber - 1
                        $lines = $Content -split "`r?`n"
                        $lineText = $lines[$startLine]

                        # Preserve indentation
                        $indent = ''
                        if ($lineText -match '^(\s+)') {
                            $indent = $Matches[1]
                        }

                        # Create commented version with note
                        $commentedParam = "# REMOVED (unused parameter): $paramText"

                        $replacements.Add([PSCustomObject]@{
                            StartOffset = $paramExtent.StartOffset
                            EndOffset = $paramExtent.EndOffset
                            OldText = $paramText
                            NewText = $commentedParam
                        }) | Out-Null

                        Write-Verbose "Commenting out unused parameter: $paramName in function $($funcAst.Name)"
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

                Write-Verbose "Commented out $($replacements.Count) unused parameter(s)"
                return $fixed
            }
        }
    }
    catch {
        Write-Verbose "Unused parameter fix failed: $_"
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

# Export all advanced fix functions
Export-ModuleMember -Function @(
    'Invoke-SafetyFix',
    'Invoke-SupportsShouldProcessFix',
    'Invoke-WmiToCimFix',
    'Invoke-ReservedParamsFix',
    'Invoke-SwitchParameterDefaultFix',
    'Invoke-BrokenHashAlgorithmFix',
    'Invoke-UnusedParameterFix',
    'Invoke-CommentHelpFix',
    'Invoke-DuplicateLineFix',
    'Invoke-CmdletParameterFix',
    'Invoke-LongLinesFix'
)
