<#
.SYNOPSIS
    PoshGuard Alignment Formatting Module

.DESCRIPTION
    PowerShell code alignment functionality including:
    - Assignment statement alignment
    - Consecutive variable alignment
    - Visual structure enhancement

    Improves code readability through consistent alignment.

.NOTES
    Part of PoshGuard v4.3.0
    Requires PowerShell 5.1 or higher
#>

Set-StrictMode -Version Latest

function Invoke-AlignAssignmentFix {
  <#
    .SYNOPSIS
        Aligns equals signs in consecutive assignment statements

    .DESCRIPTION
        Improves readability by aligning = signs in consecutive variable assignments.
        Only aligns assignments that are on consecutive lines without gaps.

    .EXAMPLE
        # BEFORE:
        $x = 1
        $longer = 2
        $y = 3

        # AFTER:
        $x      = 1
        $longer = 2
        $y      = 3
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    $lines = $Content -split "`n"
    $newLines = @()
    $assignmentBlock = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]

      # Check if line is a simple assignment: $var = value
      if ($line -match '^\s*\$(\w+)\s*=\s*(.+)$') {
        $assignmentBlock += @{
          Index = $i
          Line = $line
          VarName = $matches[1]
          Value = $matches[2]
          IndentLength = ($line -replace '^\s*', '').Length - $line.TrimStart().Length
        }
      }
      else {
        # Process accumulated block if we have 2+ assignments
        if ($assignmentBlock.Count -ge 2) {
          # Find max variable name length in block
          $maxLength = ($assignmentBlock | ForEach-Object { $_.VarName.Length } | Measure-Object -Maximum).Maximum

          foreach ($assignment in $assignmentBlock) {
            $indent = ' ' * $assignment.IndentLength
            $padding = ' ' * ($maxLength - $assignment.VarName.Length)
            $alignedLine = "$indent`$$($assignment.VarName)$padding = $($assignment.Value)"
            $newLines += $alignedLine
          }

          Write-Verbose "Aligned $($assignmentBlock.Count) consecutive assignments"
        }
        else {
          # Add assignments without alignment
          foreach ($assignment in $assignmentBlock) {
            $newLines += $assignment.Line
          }
        }

        $assignmentBlock = @()
        $newLines += $line
      }
    }

    # Handle remaining block at end of file
    if ($assignmentBlock.Count -ge 2) {
      $maxLength = ($assignmentBlock | ForEach-Object { $_.VarName.Length } | Measure-Object -Maximum).Maximum

      foreach ($assignment in $assignmentBlock) {
        $indent = ' ' * $assignment.IndentLength
        $padding = ' ' * ($maxLength - $assignment.VarName.Length)
        $alignedLine = "$indent`$$($assignment.VarName)$padding = $($assignment.Value)"
        $newLines += $alignedLine
      }
    }
    else {
      foreach ($assignment in $assignmentBlock) {
        $newLines += $assignment.Line
      }
    }

    return ($newLines -join "`n")
  }
  catch {
    Write-Verbose "Align assignment fix failed: $_"
  }

  return $Content
}

# Export all alignment fix functions
Export-ModuleMember -Function @(
  'Invoke-AlignAssignmentFix'
)
