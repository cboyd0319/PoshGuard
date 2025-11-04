# InvokingEmptyMembers.psm1
# PSAvoidInvokingEmptyMembers fix - replaces non-constant member access with constants

function Invoke-InvokingEmptyMembersFix {
  <#
    .SYNOPSIS
        Fixes non-constant member invocations by converting them to constant member access

    .DESCRIPTION
        PSScriptAnalyzer rule: PSAvoidInvokingEmptyMembers

        Detects and fixes member access patterns like:
        - $obj.('property')  # Parenthesized expression as member name
        - $obj.('prop'+'erty')  # String concatenation as member name

        These are converted to direct member access:
        - $obj.property

    .PARAMETER Content
        The script content to process

    .EXAMPLE
        # BEFORE:
        $MyString = 'abc'
        $MyString.('len'+'gth')  # Non-constant member

        # AFTER:
        $MyString = 'abc'
        $MyString.length  # Constant member

    .NOTES
        This pattern is uncommon but can appear in dynamically generated code.
        The fix attempts to statically evaluate the expression.
        If evaluation fails, adds a comment warning.
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
      Write-Verbose "Parse errors, skipping InvokingEmptyMembers fix"
      return $Content
    }

    # Find all member expressions with non-constant members
    $memberExprs = $ast.FindAll({
        param($node)
        if ($node -is [System.Management.Automation.Language.MemberExpressionAst]) {
          # Check if member is NOT a simple string constant
          $member = $node.Member

          # Violation: Member is a ParenExpressionAst or other non-constant expression
          if ($member -is [System.Management.Automation.Language.ParenExpressionAst] -or
            ($member -isnot [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $member -isnot [System.Management.Automation.Language.VariableExpressionAst])) {
            return $true
          }
        }
        return $false
      }, $true)

    if ($memberExprs.Count -eq 0) {
      return $Content
    }

    $result = $Content
    $replacements = @()

    foreach ($memberExpr in $memberExprs) {
      $member = $memberExpr.Member

      # Try to statically evaluate the member expression
      $evaluatedMember = $null

      if ($member -is [System.Management.Automation.Language.ParenExpressionAst]) {
        $pipeline = $member.Pipeline

        # Check if it's a simple string expression we can evaluate
        if ($pipeline.PipelineElements.Count -eq 1) {
          $expr = $pipeline.PipelineElements[0].Expression

          # String concatenation: 'a'+'b'
          if ($expr -is [System.Management.Automation.Language.BinaryExpressionAst] -and
            $expr.Operator -eq 'Plus') {

            $leftValue = Get-StaticStringValue -Ast $expr.Left
            $rightValue = Get-StaticStringValue -Ast $expr.Right

            if ($leftValue -and $rightValue) {
              $evaluatedMember = $leftValue + $rightValue
              Write-Verbose "Evaluated '$($member.Extent.Text)' to '$evaluatedMember'"
            }
          }
          # Simple string constant in parens: ('property')
          elseif ($expr -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $evaluatedMember = $expr.Value
            Write-Verbose "Extracted string '$evaluatedMember' from parentheses"
          }
        }
      }

      if ($evaluatedMember) {
        # Create the replacement
        $originalText = $memberExpr.Extent.Text
        $objectExpr = $memberExpr.Expression.Extent.Text

        # Replace $obj.('member') with $obj.member
        $newText = "$objectExpr.$evaluatedMember"

        $replacements += [PSCustomObject]@{
          Offset = $memberExpr.Extent.StartOffset
          Length = $memberExpr.Extent.Text.Length
          Replacement = $newText
          Original = $originalText
        }

        Write-Verbose "Will replace '$originalText' with '$newText'"
      }
      else {
        Write-Verbose "Could not statically evaluate member: $($member.Extent.Text)"
      }
    }

    # Apply replacements in reverse order to maintain offsets
    foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
      $result = $result.Remove($replacement.Offset, $replacement.Length)
      $result = $result.Insert($replacement.Offset, $replacement.Replacement)
    }

    if ($replacements.Count -gt 0) {
      Write-Verbose "Fixed $($replacements.Count) non-constant member access(es)"
    }

    return $result
  }
  catch {
    Write-Verbose "InvokingEmptyMembers fix failed: $_"
    return $Content
  }
}

function Get-StaticStringValue {
  <#
    .SYNOPSIS
        Helper to extract static string values from AST nodes
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    $Ast
  )

  if ($Ast -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
    return $Ast.Value
  }

  return $null
}

Export-ModuleMember -Function 'Invoke-InvokingEmptyMembersFix'
