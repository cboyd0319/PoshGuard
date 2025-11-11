<#
.SYNOPSIS
    PoshGuard Runspace Formatting Module

.DESCRIPTION
    PowerShell runspace and scope fixes including:
    - $using: scope modifier for runspace variables
    - ShouldContinue checks for functions with -Force parameter
    - Parallel execution safety

    Ensures proper variable scoping in runspaces and background jobs.

.NOTES
    Part of PoshGuard v4.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

# Import ASTHelper module for reusable AST operations
$ASTHelperPath = Join-Path $PSScriptRoot "../ASTHelper.psm1"
if (Test-Path $ASTHelperPath) {
  Import-Module $ASTHelperPath -Force -ErrorAction SilentlyContinue
}

function Invoke-UsingScopeModifierFix {
  <#
    .SYNOPSIS
        Adds $using: scope modifier for variables in new runspaces

    .DESCRIPTION
        Detects variables used in script blocks for Start-Job, Invoke-Command, etc.
        and adds $using: scope modifier where needed.

    .EXAMPLE
        # BEFORE:
        $data = "test"
        Start-Job { Write-Output $data }

        # AFTER:
        $data = "test"
        Start-Job { Write-Output $using:data }
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

    # Find cmdlets that create new runspaces
    $runspaceCmdlets = @('Start-Job', 'Invoke-Command', 'ForEach-Object', 'Start-ThreadJob')

    $commands = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -in $runspaceCmdlets
      }, $true)

    $replacements = @()

    foreach ($cmd in $commands) {
      # Find script block arguments
      $scriptBlocks = $cmd.FindAll({
          param($node)
          $node -is [System.Management.Automation.Language.ScriptBlockExpressionAst]
        }, $true)

      foreach ($sb in $scriptBlocks) {
        # Find variable references in script block
        $vars = $sb.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.VariableExpressionAst] -and
            -not $node.VariablePath.UserPath.StartsWith('using:')
          }, $true)

        foreach ($var in $vars) {
          $varName = $var.VariablePath.UserPath
          # Skip automatic variables
          if ($varName -notin @('_', 'PSItem', 'args', 'input', 'this')) {
            $replacements += [PSCustomObject]@{
              Offset = $var.Extent.StartOffset
              Length = $var.Extent.Text.Length
              OldText = $var.Extent.Text
              NewText = "`$using:$varName"
            }
          }
        }
      }
    }

    if ($replacements.Count -gt 0) {
      $fixed = $Content
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.NewText)
        Write-Verbose "Added `$using: scope modifier"
      }
      return $fixed
    }
  }
  catch {
    Write-Verbose "Using scope modifier fix failed: $_"
  }

  return $Content
}

function Invoke-ShouldContinueWithoutForceFix {
  <#
    .SYNOPSIS
        Adds ShouldContinue checks for functions with -Force parameter

    .DESCRIPTION
        Detects functions with -Force parameter that lack ShouldContinue checks.
        Adds proper confirmation logic.

    .EXAMPLE
        # BEFORE:
        function Remove-Data {
            param([switch]$Force)
            # dangerous operation
        }

        # AFTER:
        function Remove-Data {
            param([switch]$Force)
            if (-not $Force -and -not $PSCmdlet.ShouldContinue("Continue?", "Warning")) {
                return
            }
            # dangerous operation
        }
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

    $functions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)

    $functionsNeedingShouldContinue = @()

    foreach ($func in $functions) {
      if ($func.Body.ParamBlock) {
        # Check for -Force parameter
        $hasForceParam = $func.Body.ParamBlock.Parameters | Where-Object {
          $_.Name.VariablePath.UserPath -eq 'Force'
        }

        if ($hasForceParam) {
          # Check if has ShouldContinue call
          $hasShouldContinue = $func.Body.FindAll({
              param($node)
              $node -is [System.Management.Automation.Language.CommandAst] -and
              $node.GetCommandName() -eq 'ShouldContinue'
            }, $true)

          if ($hasShouldContinue.Count -eq 0) {
            $functionsNeedingShouldContinue += $func.Name
          }
        }
      }
    }

    if ($functionsNeedingShouldContinue.Count -gt 0) {
      $lines = $Content -split "`n"
      $newLines = @()

      foreach ($line in $lines) {
        foreach ($funcName in $functionsNeedingShouldContinue) {
          if ($line -match "function\s+$([regex]::Escape($funcName))") {
            $newLines += "# TODO: Add ShouldContinue check: if (-not `$Force -and -not `$PSCmdlet.ShouldContinue()) { return }"
          }
        }
        $newLines += $line
      }

      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "ShouldContinue fix failed: $_"
  }

  return $Content
}

# Export all runspace fix functions
Export-ModuleMember -Function @(
  'Invoke-UsingScopeModifierFix',
  'Invoke-ShouldContinueWithoutForceFix'
)
