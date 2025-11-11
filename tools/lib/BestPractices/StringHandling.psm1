<#
.SYNOPSIS
    PoshGuard String Handling Best Practices Module

.DESCRIPTION
    PowerShell string and collection literal handling including:
    - Double quote → single quote for constant strings
    - New-Object Hashtable → @{} literal syntax

    Ensures code uses idiomatic PowerShell string and collection patterns.

.NOTES
    Part of PoshGuard v4.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

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
    [ValidateNotNullOrEmpty()]
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
                Offset = $stringAst.Extent.StartOffset
                Length = $stringAst.Extent.Text.Length
                Replacement = $newStringText
                Original = $stringAst.Extent.Text
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

function Invoke-LiteralHashtableFix {
  <#
    .SYNOPSIS
        Converts New-Object Hashtable to @{} literal syntax

    .DESCRIPTION
        PowerShell best practice prefers @{} literal syntax over New-Object Hashtable.
        This improves readability and is more idiomatic PowerShell.

        REPLACES:
        - $hash = New-Object Hashtable → $hash = @{}
        - $hash = New-Object System.Collections.Hashtable → $hash = @{}
        - New-Object -TypeName Hashtable → @{}

    .EXAMPLE
        # BEFORE:
        $config = New-Object Hashtable
        $config['key'] = 'value'

        # AFTER:
        $config = @{}
        $config['key'] = 'value'
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    $patterns = @(
      @{
        Pattern = 'New-Object\s+Hashtable\b'
        Replacement = '@{}'
      },
      @{
        Pattern = 'New-Object\s+System\.Collections\.Hashtable\b'
        Replacement = '@{}'
      },
      @{
        Pattern = 'New-Object\s+-TypeName\s+Hashtable\b'
        Replacement = '@{}'
      },
      @{
        Pattern = 'New-Object\s+-TypeName\s+System\.Collections\.Hashtable\b'
        Replacement = '@{}'
      }
    )

    $fixed = $Content
    $totalReplacements = 0

    foreach ($patternInfo in $patterns) {
      $matches = [regex]::Matches($fixed, $patternInfo.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
      if ($matches.Count -gt 0) {
        $fixed = [regex]::Replace($fixed, $patternInfo.Pattern, $patternInfo.Replacement, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $totalReplacements += $matches.Count
      }
    }

    if ($totalReplacements -gt 0) {
      Write-Verbose "Replaced $totalReplacements New-Object Hashtable with @{}"
      return $fixed
    }
  }
  catch {
    Write-Verbose "Literal hashtable fix failed: $_"
  }

  return $Content
}

# Export all string handling fix functions
Export-ModuleMember -Function @(
  'Invoke-DoubleQuoteFix',
  'Invoke-LiteralHashtableFix'
)
