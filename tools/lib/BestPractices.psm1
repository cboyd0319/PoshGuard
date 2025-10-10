<#
.SYNOPSIS
    PoshGuard Best Practices Auto-Fix Module

.DESCRIPTION
    PowerShell coding standard and best practice enforcement functions.
    Handles semicolons, function naming, variable scoping, quoting, and more.

.NOTES
    Part of PoshGuard v2.3.0
#>

Set-StrictMode -Version Latest

function Invoke-SemicolonFix {
    <#
    .SYNOPSIS
        Removes unnecessary trailing semicolons from PowerShell code

    .DESCRIPTION
        PowerShell doesn't require semicolons as line terminators (unlike C#).
        This function removes semicolons that are used as line terminators while
        preserving semicolons that are used as statement separators on the same line.

        REMOVES:
        - Trailing semicolons at end of lines
        - Semicolons followed only by whitespace/comments

        PRESERVES:
        - Semicolons between statements on same line: $x = 1; $y = 2
        - Semicolons in strings or comments

    .EXAMPLE
        # BEFORE:
        $x = 5;
        Write-Output "Hello";

        # AFTER:
        $x = 5
        Write-Output "Hello"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST token-based semicolon removal
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all semicolon tokens
            $semicolonTokens = $tokens | Where-Object { $_.Kind -eq 'Semi' }

            foreach ($token in $semicolonTokens) {
                # Check if this semicolon is a line terminator (not a statement separator)
                # A semicolon is a line terminator if it's followed only by whitespace/newline/comment
                $afterSemicolon = $Content.Substring($token.Extent.EndOffset)

                # Check if there's only whitespace/newline before the next statement
                if ($afterSemicolon -match '^\s*($|#)') {
                    # This is a line terminator - safe to remove
                    $replacements += @{
                        Offset = $token.Extent.StartOffset
                        Length = 1  # Length of semicolon
                    }
                }
            }

            # Apply replacements in reverse order to preserve offsets
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length)
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Removed $($replacements.Count) unnecessary trailing semicolon(s)"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Semicolon fix failed: $_"
    }

    return $Content
}

function Invoke-SingularNounFix {
    <#
    .SYNOPSIS
        Converts function names with plural nouns to singular nouns

    .DESCRIPTION
        PowerShell convention dictates that function nouns should be singular.
        This function detects function declarations with plural nouns and converts them to singular.

        CONVERTS:
        - Users → User
        - Items → Item
        - Entries → Entry
        - Children → Child
        - etc.

    .EXAMPLE
        # BEFORE:
        function Get-Users { }

        # AFTER:
        function Get-User { }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based function name detection
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
                $functionName = $funcAst.Name

                # Split function name into Verb-Noun format
                if ($functionName -match '^([A-Za-z]+)-([A-Za-z]+)$') {
                    $verb = $Matches[1]
                    $noun = $Matches[2]

                    # Apply pluralization rules to get singular form
                    $singularNoun = $null

                    # Rule 1: Words ending in 'ies' → 'y' (Entries → Entry)
                    if ($noun -match '^(.+)ies$') {
                        $singularNoun = $Matches[1] + 'y'
                    }
                    # Rule 2: Words ending in 'es' (not 'ies') → remove 'es' (Processes → Process)
                    elseif ($noun -match '^(.+[^i])es$') {
                        $singularNoun = $Matches[1]
                    }
                    # Rule 3: Words ending in 'ves' → 'fe' or 'f' (Knives → Knife)
                    elseif ($noun -match '^(.+)ves$') {
                        $singularNoun = $Matches[1] + 'fe'
                    }
                    # Rule 4: Words ending in 's' (but not 'ss') → remove 's' (Users → User)
                    elseif ($noun -match '^(.+[^s])s$') {
                        $singularNoun = $Matches[1]
                    }

                    # If we found a singular form and it's different from the original
                    if ($singularNoun -and $singularNoun -ne $noun) {
                        $newFunctionName = "$verb-$singularNoun"

                        # Only replace if the new name is actually different
                        if ($newFunctionName -ne $functionName) {
                            # Find the exact location of the function name in the AST
                            $replacements += @{
                                Offset      = $funcAst.Extent.StartOffset
                                Length      = $funcAst.Extent.Text.Length
                                OldName     = $functionName
                                NewName     = $newFunctionName
                                FuncExtent  = $funcAst.Extent.Text
                            }
                        }
                    }
                }
            }

            # Apply replacements
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                # Replace the function definition
                $oldFuncText = $replacement.FuncExtent
                $newFuncText = $oldFuncText -replace [regex]::Escape($replacement.OldName), $replacement.NewName

                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $newFuncText)

                Write-Verbose "Converted function name: $($replacement.OldName) → $($replacement.NewName)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) function name(s) to singular form"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Singular noun fix failed: $_"
    }

    return $Content
}

function Invoke-ApprovedVerbFix {
    <#
    .SYNOPSIS
        Fixes function names with unapproved PowerShell verbs

    .DESCRIPTION
        PowerShell has a set of approved verbs (Get-Verb) that should be used for consistency.
        This function detects unapproved verbs and replaces them with approved alternatives.

        COMMON MAPPINGS:
        - Validate → Test
        - Check → Test
        - Verify → Test
        - Display → Show
        - Print → Write
        - Create → New
        - Delete → Remove
        - Destroy → Remove
        - Make → New
        - Build → New
        - Generate → New
        - Retrieve → Get
        - Fetch → Get
        - Obtain → Get
        - Acquire → Get
        - Change → Set
        - Modify → Set
        - Update → Set
        - Edit → Set
        - List → Get
        - Enumerate → Get

    .EXAMPLE
        PS C:\> Invoke-ApprovedVerbFix -Content $scriptContent

        Replaces unapproved verbs with approved alternatives
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based function name detection
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            # Get list of approved verbs from PowerShell
            $approvedVerbs = @{}
            try {
                Get-Verb | ForEach-Object { $approvedVerbs[$_.Verb.ToLower()] = $_.Verb }
            }
            catch {
                # If Get-Verb fails, use a hardcoded list of common approved verbs
                $commonApprovedVerbs = @(
                    'Add', 'Clear', 'Close', 'Copy', 'Enter', 'Exit', 'Find', 'Format', 'Get', 'Hide',
                    'Join', 'Lock', 'Move', 'New', 'Open', 'Optimize', 'Pop', 'Push', 'Redo', 'Remove',
                    'Rename', 'Reset', 'Resize', 'Search', 'Select', 'Set', 'Show', 'Skip', 'Split',
                    'Step', 'Switch', 'Undo', 'Unlock', 'Watch', 'Backup', 'Checkpoint', 'Compare',
                    'Compress', 'Convert', 'ConvertFrom', 'ConvertTo', 'Dismount', 'Edit', 'Expand',
                    'Export', 'Group', 'Import', 'Initialize', 'Limit', 'Merge', 'Mount', 'Out',
                    'Publish', 'Restore', 'Save', 'Sync', 'Unpublish', 'Update', 'Approve', 'Assert',
                    'Complete', 'Confirm', 'Deny', 'Disable', 'Enable', 'Install', 'Invoke', 'Register',
                    'Request', 'Restart', 'Resume', 'Start', 'Stop', 'Submit', 'Suspend', 'Uninstall',
                    'Unregister', 'Wait', 'Debug', 'Measure', 'Ping', 'Repair', 'Resolve', 'Test',
                    'Trace', 'Connect', 'Disconnect', 'Read', 'Receive', 'Send', 'Write', 'Block',
                    'Grant', 'Protect', 'Revoke', 'Unblock', 'Unprotect', 'Use'
                )
                $commonApprovedVerbs | ForEach-Object { $approvedVerbs[$_.ToLower()] = $_ }
            }

            # Common unapproved verb mappings to approved verbs
            $verbMappings = @{
                'Validate'  = 'Test'
                'Check'     = 'Test'
                'Verify'    = 'Test'
                'Display'   = 'Show'
                'Print'     = 'Write'
                'Create'    = 'New'
                'Delete'    = 'Remove'
                'Destroy'   = 'Remove'
                'Make'      = 'New'
                'Build'     = 'New'
                'Generate'  = 'New'
                'Retrieve'  = 'Get'
                'Fetch'     = 'Get'
                'Obtain'    = 'Get'
                'Acquire'   = 'Get'
                'Change'    = 'Set'
                'Modify'    = 'Set'
                'Alter'     = 'Set'
                'Edit'      = 'Edit'  # Edit is actually approved
                'List'      = 'Get'
                'Enumerate' = 'Get'
                'Query'     = 'Get'
                'Load'      = 'Import'
                'Save'      = 'Export'
                'Unload'    = 'Remove'
                'Execute'   = 'Invoke'
                'Run'       = 'Invoke'
                'Call'      = 'Invoke'
                'Launch'    = 'Start'
                'Kill'      = 'Stop'
                'Terminate' = 'Stop'
                'Quit'      = 'Exit'
                'Close'     = 'Close'  # Close is approved
                'Open'      = 'Open'   # Open is approved
            }

            $replacements = @()

            # Find all function definitions
            $functionAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            foreach ($funcAst in $functionAsts) {
                $functionName = $funcAst.Name

                # Split function name into Verb-Noun format
                if ($functionName -match '^([A-Za-z]+)-([A-Za-z]+)$') {
                    $verb = $Matches[1]
                    $noun = $Matches[2]

                    # Check if verb is approved (case-insensitive)
                    $verbLower = $verb.ToLower()

                    if (-not $approvedVerbs.ContainsKey($verbLower)) {
                        # Verb is not approved, try to find a mapping
                        $approvedVerb = $null

                        # First check our mapping table
                        if ($verbMappings.ContainsKey($verb)) {
                            $approvedVerb = $verbMappings[$verb]
                        }
                        else {
                            # Try case-insensitive lookup in mappings
                            foreach ($key in $verbMappings.Keys) {
                                if ($key -eq $verb -or $key.ToLower() -eq $verbLower) {
                                    $approvedVerb = $verbMappings[$key]
                                    break
                                }
                            }
                        }

                        if ($approvedVerb) {
                            $newFunctionName = "$approvedVerb-$noun"

                            # Only replace if the new name is different
                            if ($newFunctionName -ne $functionName) {
                                $replacements += @{
                                    Offset      = $funcAst.Extent.StartOffset
                                    Length      = $funcAst.Extent.Text.Length
                                    OldName     = $functionName
                                    NewName     = $newFunctionName
                                    FuncExtent  = $funcAst.Extent.Text
                                }
                            }
                        }
                    }
                }
            }

            # Apply replacements
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                # Replace the function definition
                $oldFuncText = $replacement.FuncExtent
                $newFuncText = $oldFuncText -replace [regex]::Escape($replacement.OldName), $replacement.NewName

                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $newFuncText)

                Write-Verbose "Converted unapproved verb: $($replacement.OldName) → $($replacement.NewName)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) function(s) to use approved verbs"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Approved verb fix failed: $_"
    }

    return $Content
}

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

function Invoke-DoubleQuoteFix {
    <#
    .SYNOPSIS
        Converts double quotes to single quotes for constant strings

    .DESCRIPTION
        PowerShell best practice is to use single quotes for constant strings
        (strings without variable expansion). This improves performance slightly
        and makes the intent clearer.

    .EXAMPLE
        PS C:\> Invoke-DoubleQuoteFix -Content $scriptContent

        Converts "Hello" to 'Hello' when no variables are present
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

            # Find all string literals
            $stringAsts = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst]
                }, $true)

            foreach ($stringAst in $stringAsts) {
                # Check if it's a double-quoted string
                if ($stringAst.StringConstantType -eq 'DoubleQuoted') {
                    $stringValue = $stringAst.Value

                    # Check if string contains single quotes (would need escaping)
                    if ($stringValue -notmatch "'") {
                        # Check if string contains special characters that require double quotes
                        # Allow conversion if no variables, escape sequences, or special chars
                        if ($stringValue -notmatch '[\$`]') {
                            # Safe to convert to single quotes
                            $newStringText = "'$stringValue'"

                            $replacements += @{
                                Offset      = $stringAst.Extent.StartOffset
                                Length      = $stringAst.Extent.Text.Length
                                Replacement = $newStringText
                                Original    = $stringAst.Extent.Text
                            }
                        }
                    }
                }
            }

            # Apply replacements in reverse order
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
                Write-Verbose "Converted double quotes: $($replacement.Original) → $($replacement.Replacement)"
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Converted $($replacements.Count) string(s) from double to single quotes"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Double quote fix failed: $_"
    }

    return $Content
}

function Invoke-NullComparisonFix {
    <#
    .SYNOPSIS
        Fixes incorrect $null comparison order

    .DESCRIPTION
        PowerShell best practice requires $null to be on the left side of comparisons.
        This prevents accidental assignment and handles arrays correctly.

        FIXES:
        - $var -eq $null → $null -eq $var
        - $var -ne $null → $null -ne $var
        - Also handles: -gt, -lt, -ge, -le comparisons

    .EXAMPLE
        # BEFORE:
        if ($value -eq $null) { }

        # AFTER:
        if ($null -eq $value) { }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # AST-based null comparison fix
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

        if ($errors.Count -eq 0) {
            $replacements = @()

            # Find all binary expression ASTs (comparisons)
            $binaryExprs = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.BinaryExpressionAst]
                }, $true)

            foreach ($expr in $binaryExprs) {
                # Check if this is a comparison with $null
                $isNullComparison = $false
                $nullOnRight = $false
                $comparisonOp = $expr.Operator

                # Check if operator is a comparison operator
                # PowerShell uses case-insensitive operators by default (Ieq, Ine, etc.)
                if ($comparisonOp -match '^(I|C)?(eq|ne|gt|lt|ge|le)$') {
                    # Check if right side is $null
                    if ($expr.Right -is [System.Management.Automation.Language.VariableExpressionAst] -and
                        $expr.Right.VariablePath.UserPath -eq 'null') {
                        $isNullComparison = $true
                        $nullOnRight = $true
                    }
                }

                # If we found a comparison with $null on the right side, swap it
                if ($isNullComparison -and $nullOnRight) {
                    # Get the text of left and right expressions
                    $leftText = $expr.Left.Extent.Text
                    $rightText = $expr.Right.Extent.Text  # This should be '$null'

                    # Map operator to its text representation - preserve case sensitivity
                    $opText = switch -Regex ($comparisonOp) {
                        '^I?eq$' { '-eq' }
                        '^Ceq$' { '-ceq' }
                        '^I?ne$' { '-ne' }
                        '^Cne$' { '-cne' }
                        '^I?gt$' { '-gt' }
                        '^Cgt$' { '-cgt' }
                        '^I?lt$' { '-lt' }
                        '^Clt$' { '-clt' }
                        '^I?ge$' { '-ge' }
                        '^Cge$' { '-cge' }
                        '^I?le$' { '-le' }
                        '^Cle$' { '-cle' }
                    }

                    # Swap: $var -eq $null → $null -eq $var
                    $newText = "$rightText $opText $leftText"

                    $replacements += @{
                        Offset      = $expr.Extent.StartOffset
                        Length      = $expr.Extent.Text.Length
                        Replacement = $newText
                    }
                }
            }

            # Apply replacements in reverse order to preserve offsets
            $fixed = $Content
            foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
                $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
            }

            if ($replacements.Count -gt 0) {
                Write-Verbose "Fixed $($replacements.Count) null comparison(s)"
            }

            return $fixed
        }
    }
    catch {
        Write-Verbose "Null comparison fix failed: $_"
    }

    return $Content
}

# Export all best practices fix functions
Export-ModuleMember -Function @(
    'Invoke-SemicolonFix',
    'Invoke-SingularNounFix',
    'Invoke-ApprovedVerbFix',
    'Invoke-GlobalVarFix',
    'Invoke-DoubleQuoteFix',
    'Invoke-NullComparisonFix'
)
