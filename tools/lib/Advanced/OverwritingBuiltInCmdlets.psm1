# OverwritingBuiltInCmdlets.psm1
# PSAvoidOverwritingBuiltInCmdlets fix - adds warning comments for functions that shadow built-ins

function Invoke-OverwritingBuiltInCmdletsFix {
  <#
    .SYNOPSIS
        Adds warning comments to functions that overwrite built-in cmdlets

    .DESCRIPTION
        PSScriptAnalyzer rule: PSAvoidOverwritingBuiltInCmdlets

        Detects function definitions that shadow built-in PowerShell cmdlets
        and adds a warning comment to alert developers.

        Since overwriting might be intentional, this fix adds a comment
        rather than renaming the function (which could break the script).

    .PARAMETER Content
        The script content to process

    .EXAMPLE
        # BEFORE:
        function Get-ChildItem {
            param($Path)
            # Custom implementation
        }

        # AFTER:
        # WARNING: Function 'Get-ChildItem' shadows built-in cmdlet. Consider renaming to avoid conflicts.
        function Get-ChildItem {
            param($Path)
            # Custom implementation
        }

    .NOTES
        Uses the current PowerShell session's command list to detect built-ins.
        This ensures compatibility with the installed PowerShell version.
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
      Write-Verbose "Parse errors, skipping OverwritingBuiltInCmdlets fix"
      return $Content
    }

    # Get list of built-in cmdlets (cache for performance)
    if (-not $script:BuiltInCmdlets) {
      Write-Verbose "Building built-in cmdlets cache..."
      $script:BuiltInCmdlets = @{}

      # Get all built-in cmdlets and functions from loaded modules
      $builtins = Get-Command -CommandType Cmdlet, Function -ErrorAction SilentlyContinue |
        Where-Object {
          $_.Source -and
          $_.Source -ne 'PSScriptAnalyzer' -and
          $_.Source -notlike '*Test*' -and
          $_.Source -notlike '*Pester*'
        } |
        Select-Object -ExpandProperty Name -Unique

      foreach ($cmdlet in $builtins) {
        $script:BuiltInCmdlets[$cmdlet.ToLower()] = $true
      }

      Write-Verbose "Cached $($script:BuiltInCmdlets.Count) built-in cmdlets"
    }

    # Find all function definitions
    $functions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)

    if ($functions.Count -eq 0) {
      return $Content
    }

    $result = $Content
    $insertions = @()

    foreach ($func in $functions) {
      $funcName = $func.Name

      # Check if function name shadows a built-in cmdlet (case-insensitive)
      if ($script:BuiltInCmdlets.ContainsKey($funcName.ToLower())) {
        # Check if warning comment already exists
        $lineStart = $func.Extent.StartLineNumber
        $lines = $Content -split "`r?`n"

        # Check the line before the function
        $hasWarning = $false
        if ($lineStart -gt 1) {
          $prevLine = $lines[$lineStart - 2]  # -2 because arrays are 0-indexed
          if ($prevLine -match "WARNING.*shadows built-in cmdlet|WARNING.*overwrites built-in") {
            $hasWarning = $true
          }
        }

        if (-not $hasWarning) {
          # Get indentation of the function line
          $funcLine = $lines[$lineStart - 1]
          $indent = ''
          if ($funcLine -match '^(\s*)') {
            $indent = $matches[1]
          }

          $warningComment = "$indent# WARNING: Function '$funcName' shadows built-in cmdlet. Consider renaming to avoid conflicts.`n"

          $insertions += [PSCustomObject]@{
            Offset = $func.Extent.StartOffset
            Text = $warningComment
            FuncName = $funcName
          }

          Write-Verbose "Found function '$funcName' that shadows built-in cmdlet"
        }
      }
    }

    if ($insertions.Count -eq 0) {
      return $Content
    }

    # Apply insertions in reverse order to maintain offsets
    foreach ($insertion in ($insertions | Sort-Object -Property Offset -Descending)) {
      $result = $result.Insert($insertion.Offset, $insertion.Text)
      Write-Verbose "Added warning comment for function: $($insertion.FuncName)"
    }

    Write-Verbose "Added $($insertions.Count) warning comment(s) for functions shadowing built-in cmdlets"

    return $result
  }
  catch {
    Write-Verbose "OverwritingBuiltInCmdlets fix failed: $_"
    return $Content
  }
}

Export-ModuleMember -Function 'Invoke-OverwritingBuiltInCmdletsFix'
