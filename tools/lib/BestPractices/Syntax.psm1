<#
.SYNOPSIS
    PoshGuard Syntax Best Practices Module

.DESCRIPTION
    PowerShell syntax improvements including:
    - Semicolon removal (unnecessary line terminators)
    - Null comparison order fixes ($null on left)
    - Exclaim operator replacement (! → -not)

    Ensures code follows PowerShell syntax conventions.

.NOTES
    Part of PoshGuard v2.4.0
    Requires PowerShell 5.1 or higher for AST functionality
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
    $null = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

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
    $null = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

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
            Offset = $expr.Extent.StartOffset
            Length = $expr.Extent.Text.Length
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

function Invoke-ExclaimOperatorFix {
  <#
    .SYNOPSIS
        Replaces ! operator with -not operator

    .DESCRIPTION
        PowerShell best practice prefers -not over ! for boolean negation.
        This improves readability and follows PowerShell conventions.

        REPLACES:
        - if (!$value) { } → if (-not $value) { }
        - while (!$condition) { } → while (-not $condition) { }
        - $result = !$test → $result = -not $test

        PRESERVES:
        - ! in strings and comments
        - ! in multi-line expressions with proper context

    .EXAMPLE
        # BEFORE:
        if (!$enabled) {
            Write-Output "Disabled"
        }

        # AFTER:
        if (-not $enabled) {
            Write-Output "Disabled"
        }
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    $null = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)
    $replacements = @()

    # Find all unary expression AST nodes with ! operator
    $unaryExpressions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.UnaryExpressionAst] -and
        $node.TokenKind -eq 'Exclaim'
      }, $true)

    foreach ($expr in $unaryExpressions) {
      # Get the extent of just the ! token
      $exclaimExtent = $expr.Extent
      $startOffset = $exclaimExtent.StartOffset

      # Find the actual ! character position
      $exclaimPos = $Content.IndexOf('!', $startOffset)
      if ($exclaimPos -ge $startOffset -and $exclaimPos -lt $exclaimExtent.EndOffset) {
        $replacements += [PSCustomObject]@{
          Offset = $exclaimPos
          Length = 1
          Replacement = '-not '
        }
      }
    }

    if ($replacements.Count -gt 0) {
      $fixed = $Content
      # Apply replacements in reverse order to maintain offsets
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
      }

      Write-Verbose "Replaced $($replacements.Count) exclaim operator(s) with -not"
      return $fixed
    }
  }
  catch {
    Write-Verbose "Exclaim operator fix failed: $_"
  }

  return $Content
}

# Export all syntax fix functions
Export-ModuleMember -Function @(
  'Invoke-SemicolonFix',
  'Invoke-NullComparisonFix',
  'Invoke-ExclaimOperatorFix'
)
