<#
.SYNOPSIS
    PoshGuard Code Analysis Module

.DESCRIPTION
    Advanced code analysis and safety improvements including:
    - Safety fixes (ErrorAction addition for IO operations)
    - Duplicate line detection and removal
    - Cmdlet parameter validation (Write-Output → Write-Host for color params)

    These functions analyze code patterns and apply safety improvements.

.NOTES
    Part of PoshGuard v2.4.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

function Invoke-SafetyFix {
  <#
    .SYNOPSIS
        Adds ErrorAction Stop to file I/O cmdlets for safer error handling

    .DESCRIPTION
        AST-based analysis that adds -ErrorAction Stop to file I/O cmdlets
        that don't already have explicit error handling. This ensures errors
        are caught rather than silently continuing.

        Targets these cmdlets:
        - Get-Content, Set-Content, Add-Content
        - Copy-Item, Move-Item, Remove-Item, New-Item

    .EXAMPLE
        # BEFORE:
        Get-Content $path

        # AFTER:
        Get-Content $path -ErrorAction Stop
    #>
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
              Text = ' -ErrorAction Stop'
            }
          }
        }
      }

      # Apply replacements in reverse order to preserve offsets
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $fixed = $fixed.Insert($replacement.Offset, $replacement.Text)
      }

      if ($replacements.Count -gt 0) {
        Write-Verbose "Added -ErrorAction Stop to $($replacements.Count) I/O cmdlet(s)"
      }
    }
  }
  catch {
    # If AST parsing fails, don't apply ErrorAction fixes
    Write-Verbose "AST-based safety fix failed: $_"
  }

  return $fixed
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

  if ($result.Count -lt $lines.Count) {
    Write-Verbose "Removed $($lines.Count - $result.Count) duplicate consecutive line(s)"
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
            Offset = $cmdName.Extent.StartOffset
            Length = $cmdName.Extent.Text.Length
            Replacement = 'Write-Host'
            Line = $cmdName.Extent.StartLineNumber
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

# Export all code analysis functions
Export-ModuleMember -Function @(
  'Invoke-SafetyFix',
  'Invoke-DuplicateLineFix',
  'Invoke-CmdletParameterFix'
)
