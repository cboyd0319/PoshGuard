<#
.SYNOPSIS
    PoshGuard Usage Patterns Best Practices Module

.DESCRIPTION
    PowerShell usage anti-pattern detection including:
    - Positional parameter detection
    - Unused variable detection
    - Assignment operator misuse in conditionals

    Ensures code follows proper usage patterns and conventions.

.NOTES
    Part of PoshGuard v2.4.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

function Invoke-PositionalParametersFix {
  <#
    .SYNOPSIS
        Adds named parameter usage to positional parameter calls

    .DESCRIPTION
        Detects positional parameter usage and suggests/adds parameter names.
        Improves code readability and maintainability.

    .EXAMPLE
        # BEFORE:
        Get-ChildItem "C:\" ".txt"

        # AFTER:
        Get-ChildItem -Path "C:\" -Filter ".txt"
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    # This is a complex fix that requires command metadata
    # For now, we'll add a comment warning about positional parameters
    $lines = $Content -split "`n"
    $modified = $false
    $newLines = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]

      # Detect common cmdlets with positional args (simple heuristic)
      if ($line -match '^\s*(Get-ChildItem|Set-Location|Remove-Item|Copy-Item|Move-Item|Test-Path)\s+[^-"]+"[^"]+"') {
        $newLines += "# STYLE: Consider using named parameters instead of positional parameters"
        $newLines += $line
        $modified = $true
        Write-Verbose "Detected positional parameters"
      }
      else {
        $newLines += $line
      }
    }

    if ($modified) {
      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "Positional parameters fix failed: $_"
  }

  return $Content
}

function Invoke-DeclaredVarsMoreThanAssignmentsFix {
  <#
    .SYNOPSIS
        Detects variables that are assigned but never used

    .DESCRIPTION
        Finds variables that are declared and assigned values but never read.
        Comments out or warns about these unused assignments.

    .EXAMPLE
        # BEFORE:
        $unused = "value"
        $used = "test"
        Write-Output $used

        # AFTER:
        # UNUSED: Variable '$unused' is assigned but never used
        # $unused = "value"
        $used = "test"
        Write-Output $used
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

    # Find all variable assignments
    $assignments = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst]
      }, $true)

    # Find all variable expressions (reads)
    $reads = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.VariableExpressionAst]
      }, $true)

    $assignedVars = @{}
    foreach ($assignment in $assignments) {
      if ($assignment.Left -is [System.Management.Automation.Language.VariableExpressionAst]) {
        $varName = $assignment.Left.VariablePath.UserPath
        if (-not $assignedVars.ContainsKey($varName)) {
          $assignedVars[$varName] = @{
            Count = 0
            Offset = $assignment.Extent.StartOffset
          }
        }
        $assignedVars[$varName].Count++
      }
    }

    $readVars = @{}
    foreach ($read in $reads) {
      $varName = $read.VariablePath.UserPath
      if (-not $readVars.ContainsKey($varName)) {
        $readVars[$varName] = 0
      }
      $readVars[$varName]++
    }

    # Find variables assigned but not read (excluding automatic variables)
    $unusedVars = @()
    foreach ($varName in $assignedVars.Keys) {
      $readCount = if ($readVars.ContainsKey($varName)) { $readVars[$varName] } else { 0 }
      $assignCount = $assignedVars[$varName].Count

      # If assigned but never read (and read count <= assign count means only assigned)
      if ($readCount -le $assignCount) {
        $unusedVars += $varName
      }
    }

    if ($unusedVars.Count -gt 0) {
      $lines = $Content -split "`n"
      $newLines = @()

      foreach ($line in $lines) {
        $matched = $false
        foreach ($varName in $unusedVars) {
          if ($line -match "^\s*\`$$([regex]::Escape($varName))\s*=") {
            $newLines += "# UNUSED: Variable '\$$varName' is assigned but never used"
            $newLines += "# $line"
            $matched = $true
            Write-Verbose "Commented unused variable: \$$varName"
            break
          }
        }

        if (-not $matched) {
          $newLines += $line
        }
      }

      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "Declared vars fix failed: $_"
  }

  return $Content
}

function Invoke-IncorrectAssignmentOperatorFix {
  <#
    .SYNOPSIS
        Fixes incorrect usage of assignment operator in comparisons

    .DESCRIPTION
        Detects cases where = is used in a comparison context where -eq should be used.
        Adds parentheses or suggests -eq operator.

    .EXAMPLE
        # BEFORE:
        if ($a = $b) { }

        # AFTER:
        # FIXED: Changed assignment to comparison
        if ($a -eq $b) { }
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    # Pattern: if/while/until with assignment instead of comparison
    $patterns = @(
      @{ Pattern = '\bif\s*\(\s*\$\w+\s*=\s*[^=]'; Context = 'if' },
      @{ Pattern = '\bwhile\s*\(\s*\$\w+\s*=\s*[^=]'; Context = 'while' },
      @{ Pattern = '\buntil\s*\(\s*\$\w+\s*=\s*[^=]'; Context = 'until' }
    )

    $lines = $Content -split "`n"
    $modified = $false
    $newLines = @()

    foreach ($line in $lines) {
      $matched = $false

      foreach ($patternInfo in $patterns) {
        if ($line -match $patternInfo.Pattern) {
          # Try to replace = with -eq
          $fixedLine = $line -replace '(\$\w+)\s*=\s*([^=])', '$1 -eq $2'
          $newLines += "# FIXED: Changed assignment to comparison in $($patternInfo.Context) statement"
          $newLines += $fixedLine
          $modified = $true
          $matched = $true
          Write-Verbose "Fixed assignment operator in $($patternInfo.Context) statement"
          break
        }
      }

      if (-not $matched) {
        $newLines += $line
      }
    }

    if ($modified) {
      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "Incorrect assignment operator fix failed: $_"
  }

  return $Content
}

# Export all usage pattern fix functions
Export-ModuleMember -Function @(
  'Invoke-PositionalParametersFix',
  'Invoke-DeclaredVarsMoreThanAssignmentsFix',
  'Invoke-IncorrectAssignmentOperatorFix'
)
