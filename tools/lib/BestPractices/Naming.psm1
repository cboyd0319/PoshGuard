<#
.SYNOPSIS
    PoshGuard Naming Best Practices Module

.DESCRIPTION
    PowerShell function naming conventions including:
    - Singular noun enforcement (Users → User)
    - Approved verb enforcement (Validate → Test)
    - Reserved character removal from function names

    Ensures function names follow PowerShell naming standards.

.NOTES
    Part of PoshGuard v4.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

# Import ASTHelper module for reusable AST operations
$ASTHelperPath = Join-Path $PSScriptRoot '../ASTHelper.psm1'
if (Test-Path $ASTHelperPath) {
  Import-Module $ASTHelperPath -Force -ErrorAction SilentlyContinue
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
    [ValidateNotNullOrEmpty()]
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
                Offset = $funcAst.Extent.StartOffset
                Length = $funcAst.Extent.Text.Length
                OldName = $functionName
                NewName = $newFunctionName
                FuncExtent = $funcAst.Extent.Text
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
        - Validate → Test, Check → Test, Verify → Test
        - Display → Show, Print → Write
        - Create → New, Delete → Remove, Destroy → Remove
        - Make → New, Build → New, Generate → New
        - Retrieve → Get, Fetch → Get, Obtain → Get
        - Change → Set, Modify → Set, Update → Set
        - List → Get, Enumerate → Get

    .EXAMPLE
        PS C:\> Invoke-ApprovedVerbFix -Content $scriptContent

        Replaces unapproved verbs with approved alternatives
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
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
        'Validate' = 'Test'
        'Check' = 'Test'
        'Verify' = 'Test'
        'Display' = 'Show'
        'Print' = 'Write'
        'Create' = 'New'
        'Delete' = 'Remove'
        'Destroy' = 'Remove'
        'Make' = 'New'
        'Build' = 'New'
        'Generate' = 'New'
        'Retrieve' = 'Get'
        'Fetch' = 'Get'
        'Obtain' = 'Get'
        'Acquire' = 'Get'
        'Change' = 'Set'
        'Modify' = 'Set'
        'Alter' = 'Set'
        'Edit' = 'Edit'  # Edit is actually approved
        'List' = 'Get'
        'Enumerate' = 'Get'
        'Query' = 'Get'
        'Load' = 'Import'
        'Save' = 'Export'
        'Unload' = 'Remove'
        'Execute' = 'Invoke'
        'Run' = 'Invoke'
        'Call' = 'Invoke'
        'Launch' = 'Start'
        'Kill' = 'Stop'
        'Terminate' = 'Stop'
        'Quit' = 'Exit'
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
                  Offset = $funcAst.Extent.StartOffset
                  Length = $funcAst.Extent.Text.Length
                  OldName = $functionName
                  NewName = $newFunctionName
                  FuncExtent = $funcAst.Extent.Text
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

function Invoke-ReservedCmdletCharFix {
  <#
    .SYNOPSIS
        Removes invalid characters from function names

    .DESCRIPTION
        PowerShell function names cannot contain certain reserved characters.
        This function detects and suggests cleaned function names.

        Invalid characters: # @ ! $ % ^ & * ( ) + = [ ] { } | \ : ; " ' < > , . / ?

    .EXAMPLE
        # BEFORE:
        function Get-My#Function { }

        # AFTER:
        # FIXED: Removed invalid character '#' from function name
        function Get-MyFunction { }
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
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
    $invalidChars = '[#@!$%^&*()+={}\[\]|\\:;"''<>,./? ]'

    foreach ($func in $functions) {
      $funcName = $func.Name
      if ($funcName -match $invalidChars) {
        $cleanName = $funcName -replace $invalidChars, ''
        $replacements += [PSCustomObject]@{
          Offset = $func.Extent.StartOffset
          Length = $func.Extent.Text.Length
          OldName = $funcName
          NewName = $cleanName
          FullText = $func.Extent.Text
        }
      }
    }

    if ($replacements.Count -gt 0) {
      $fixed = $Content
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $newText = $replacement.FullText -replace [regex]::Escape($replacement.OldName), $replacement.NewName
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $newText)
        Write-Verbose "Fixed function name: $($replacement.OldName) → $($replacement.NewName)"
      }
      return $fixed
    }
  }
  catch {
    Write-Verbose "Reserved cmdlet char fix failed: $_"
  }

  return $Content
}

# Export all naming fix functions
Export-ModuleMember -Function @(
  'Invoke-SingularNounFix',
  'Invoke-ApprovedVerbFix',
  'Invoke-ReservedCmdletCharFix'
)
