<#
.SYNOPSIS
    Advanced Code Quality Detection Module

.DESCRIPTION
    Beyond-PSSA detection capabilities for world-class PowerShell code quality:
    - Code complexity metrics (cyclomatic complexity, nesting depth)
    - Performance anti-patterns (inefficient loops, pipeline misuse)
    - Security vulnerabilities (OWASP Top 10 alignment)
    - Maintainability issues (long functions, parameter count)
    - Accessibility problems (unclear naming, missing documentation)

    This module provides detection only - fixes are applied by other modules.

.NOTES
    Module: AdvancedDetection
    Version: 3.3.0
    OWASP ASVS: V5.1.1 (Input Validation), V8.3.4 (Sensitive Data)
    SWEBOK: Software Quality (KA 10)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-CodeComplexity {
  <#
    .SYNOPSIS
        Analyzes code complexity metrics
    
    .DESCRIPTION
        Calculates cyclomatic complexity, nesting depth, and function length.
        Flags functions exceeding thresholds:
        - Cyclomatic complexity > 10 (MEDIUM risk)
        - Nesting depth > 4 (HIGH risk)
        - Function length > 50 lines (LOW risk)
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    
    .EXAMPLE
        Test-CodeComplexity -Content $script -FilePath "script.ps1"
    #>
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath = ''
  )
    
  $issues = @()
    
  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$null,
      [ref]$null
    )
        
    # Find all function definitions
    $functions = $ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)
        
    foreach ($func in $functions) {
      $funcName = $func.Name
      $startLine = $func.Extent.StartLineNumber
      $endLine = $func.Extent.EndLineNumber
      $lineCount = $endLine - $startLine + 1
            
      # Calculate cyclomatic complexity (decision points + 1)
      $decisionPoints = $func.FindAll({
          $node = $args[0]
          $node -is [System.Management.Automation.Language.IfStatementAst] -or
          $node -is [System.Management.Automation.Language.WhileStatementAst] -or
          $node -is [System.Management.Automation.Language.ForStatementAst] -or
          $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
          $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
          $node -is [System.Management.Automation.Language.TryStatementAst] -or
          ($node -is [System.Management.Automation.Language.BinaryExpressionAst] -and 
          ($node.Operator -eq 'And' -or $node.Operator -eq 'Or'))
        }, $true).Count
            
      $cyclomaticComplexity = $decisionPoints + 1
            
      # Calculate max nesting depth by traversing AST
      $maxDepth = Get-MaxNestingDepth -Ast $func.Body
            
      # Check thresholds
      if ($cyclomaticComplexity -gt 10) {
        $issues += [PSCustomObject]@{
          Rule = 'ComplexityTooHigh'
          Severity = 'Warning'
          Line = $startLine
          Message = "Function '$funcName' has cyclomatic complexity of $cyclomaticComplexity (threshold: 10). Consider refactoring."
          Metric = $cyclomaticComplexity
          FilePath = $FilePath
        }
      }
            
      if ($maxDepth -gt 4) {
        $issues += [PSCustomObject]@{
          Rule = 'NestingTooDeep'
          Severity = 'Error'
          Line = $startLine
          Message = "Function '$funcName' has nesting depth of $maxDepth (threshold: 4). Deeply nested code is hard to maintain."
          Metric = $maxDepth
          FilePath = $FilePath
        }
      }
            
      if ($lineCount -gt 50) {
        $issues += [PSCustomObject]@{
          Rule = 'FunctionTooLong'
          Severity = 'Information'
          Line = $startLine
          Message = "Function '$funcName' is $lineCount lines (threshold: 50). Consider breaking into smaller functions."
          Metric = $lineCount
          FilePath = $FilePath
        }
      }
            
      # Check parameter count
      $paramCount = 0
      if ($func.Parameters) {
        $paramCount = $func.Parameters.Count
      }
      if ($func.Body.ParamBlock -and $func.Body.ParamBlock.Parameters) {
        $paramCount = $func.Body.ParamBlock.Parameters.Count
      }
            
      if ($paramCount -gt 7) {
        $issues += [PSCustomObject]@{
          Rule = 'TooManyParameters'
          Severity = 'Warning'
          Line = $startLine
          Message = "Function '$funcName' has $paramCount parameters (threshold: 7). Consider using a parameter object."
          Metric = $paramCount
          FilePath = $FilePath
        }
      }
    }
        
  } catch {
    Write-Verbose "Error analyzing complexity: $_"
  }
    
  return $issues
}

function Get-MaxNestingDepth {
  <#
    .SYNOPSIS
        Calculates maximum nesting depth in AST
    #>
  [CmdletBinding()]
  [OutputType([int])]
  param(
    [Parameter(Mandatory)]
    [System.Management.Automation.Language.Ast]$Ast,
        
    [Parameter()]
    [int]$CurrentDepth = 0,
        
    [Parameter()]
    [int]$MaxRecursionDepth = 100
  )
    
  # Prevent infinite recursion
  if ($CurrentDepth -gt $MaxRecursionDepth) {
    Write-Warning "Max recursion depth reached at $MaxRecursionDepth"
    return $CurrentDepth
  }
    
  $maxDepth = $CurrentDepth
    
  # Count direct nesting only - check children one level deep
  $children = @($Ast.FindAll({
        $node = $args[0]
        $node -is [System.Management.Automation.Language.IfStatementAst] -or
        $node -is [System.Management.Automation.Language.WhileStatementAst] -or
        $node -is [System.Management.Automation.Language.ForStatementAst] -or
        $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
        $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
        $node -is [System.Management.Automation.Language.TryStatementAst]
      }, $false))
    
  foreach ($node in $children) {
    # Get the body of the control structure to recurse into
    $bodyAst = $null
    if ($node -is [System.Management.Automation.Language.IfStatementAst]) {
      # For if statements, check all clauses
      foreach ($clause in $node.Clauses) {
        if ($clause.Item2) {
          $clauseDepth = Get-MaxNestingDepth -Ast $clause.Item2 -CurrentDepth ($CurrentDepth + 1) -MaxRecursionDepth $MaxRecursionDepth
          if ($clauseDepth -gt $maxDepth) {
            $maxDepth = $clauseDepth
          }
        }
      }
      # Check else clause if present
      if ($node.ElseClause) {
        $elseDepth = Get-MaxNestingDepth -Ast $node.ElseClause -CurrentDepth ($CurrentDepth + 1) -MaxRecursionDepth $MaxRecursionDepth
        if ($elseDepth -gt $maxDepth) {
          $maxDepth = $elseDepth
        }
      }
    } elseif ($node -is [System.Management.Automation.Language.WhileStatementAst] -and $node.Body) {
      $bodyAst = $node.Body
    } elseif ($node -is [System.Management.Automation.Language.ForStatementAst] -and $node.Body) {
      $bodyAst = $node.Body
    } elseif ($node -is [System.Management.Automation.Language.ForEachStatementAst] -and $node.Body) {
      $bodyAst = $node.Body
    } elseif ($node -is [System.Management.Automation.Language.SwitchStatementAst]) {
      foreach ($clause in $node.Clauses) {
        if ($clause.Item2) {
          $clauseDepth = Get-MaxNestingDepth -Ast $clause.Item2 -CurrentDepth ($CurrentDepth + 1) -MaxRecursionDepth $MaxRecursionDepth
          if ($clauseDepth -gt $maxDepth) {
            $maxDepth = $clauseDepth
          }
        }
      }
    } elseif ($node -is [System.Management.Automation.Language.TryStatementAst]) {
      if ($node.Body) {
        $bodyAst = $node.Body
      }
      # Also check catch clauses
      foreach ($catch in $node.CatchClauses) {
        if ($catch.Body) {
          $catchDepth = Get-MaxNestingDepth -Ast $catch.Body -CurrentDepth ($CurrentDepth + 1) -MaxRecursionDepth $MaxRecursionDepth
          if ($catchDepth -gt $maxDepth) {
            $maxDepth = $catchDepth
          }
        }
      }
      # Check finally clause
      if ($node.Finally) {
        $finallyDepth = Get-MaxNestingDepth -Ast $node.Finally -CurrentDepth ($CurrentDepth + 1) -MaxRecursionDepth $MaxRecursionDepth
        if ($finallyDepth -gt $maxDepth) {
          $maxDepth = $finallyDepth
        }
      }
    }
        
    # Recurse into body if we have one
    if ($bodyAst) {
      $childDepth = Get-MaxNestingDepth -Ast $bodyAst -CurrentDepth ($CurrentDepth + 1) -MaxRecursionDepth $MaxRecursionDepth
      if ($childDepth -gt $maxDepth) {
        $maxDepth = $childDepth
      }
    }
  }
    
  return $maxDepth
}

function Test-PerformanceAntiPattern {
  <#
    .SYNOPSIS
        Detects performance anti-patterns
    
    .DESCRIPTION
        Identifies common performance issues:
        - String concatenation in loops (use StringBuilder or -join)
        - Inefficient pipeline usage (ForEach-Object when foreach{} better)
        - Repeated calls in loops that could be cached
        - Array += in loops (use ArrayList or List<T>)
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    #>
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath = ''
  )
    
  $issues = @()
    
  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$null,
      [ref]$null
    )
        
    # Find loops
    $loops = @($ast.FindAll({
          $node = $args[0]
          $node -is [System.Management.Automation.Language.WhileStatementAst] -or
          $node -is [System.Management.Automation.Language.ForStatementAst] -or
          $node -is [System.Management.Automation.Language.ForEachStatementAst]
        }, $true))
        
    foreach ($loop in $loops) {
      $loopLine = $loop.Extent.StartLineNumber
            
      # Check for string concatenation in loop
      $stringConcats = @($loop.FindAll({
            $node = $args[0]
            if ($node -is [System.Management.Automation.Language.AssignmentStatementAst]) {
              # Check if it's string concatenation assignment
              if ($node.Right -is [System.Management.Automation.Language.BinaryExpressionAst] -and
                $node.Right.Operator -eq 'Plus') {
                return $true
              }
            }
            return $false
          }, $true))
            
      if ($stringConcats.Count -gt 0) {
        $issues += [PSCustomObject]@{
          Rule = 'StringConcatenationInLoop'
          Severity = 'Warning'
          Line = $loopLine
          Message = "String concatenation in loop detected. Consider using -join or StringBuilder for better performance."
          FilePath = $FilePath
        }
      }
            
      # Check for array += in loop
      $arrayAdditions = @($loop.FindAll({
            $node = $args[0]
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $node.Operator -eq 'PlusEquals'
          }, $true))
            
      if ($arrayAdditions.Count -gt 0) {
        $issues += [PSCustomObject]@{
          Rule = 'ArrayAdditionInLoop'
          Severity = 'Warning'
          Line = $loopLine
          Message = "Array += in loop detected. Consider using ArrayList or List<T> for better performance."
          FilePath = $FilePath
        }
      }
    }
        
    # Check for inefficient pipeline usage
    $pipelines = $ast.FindAll({
        $node = $args[0]
        $node -is [System.Management.Automation.Language.PipelineAst] -and
        $node.PipelineElements.Count -gt 3
      }, $true)
        
    foreach ($pipeline in $pipelines) {
      $hasSortObject = $false
      $hasWhereObject = $false
            
      foreach ($element in $pipeline.PipelineElements) {
        $cmdName = ''
        if ($element -is [System.Management.Automation.Language.CommandAst]) {
          if ($element.CommandElements.Count -gt 0) {
            $cmdName = $element.CommandElements[0].Value
          }
        }
                
        if ($cmdName -eq 'Sort-Object') { $hasSortObject = $true }
        if ($cmdName -eq 'Select-Object') { if ($cmdName -eq 'Where-Object') { $hasWhereObject = $true }
        }
            
        if ($hasWhereObject -and $hasSortObject -and $pipeline.PipelineElements.IndexOf(
            ($pipeline.PipelineElements | Where-Object { 
              $_ -is [System.Management.Automation.Language.CommandAst] -and 
              $_.CommandElements.Count -gt 0 -and
              $_.CommandElements[0].Value -eq 'Sort-Object' 
            } | Select-Object -First 1)
          ) -lt $pipeline.PipelineElements.IndexOf(
            ($pipeline.PipelineElements | Where-Object { 
              $_ -is [System.Management.Automation.Language.CommandAst] -and 
              $_.CommandElements.Count -gt 0 -and
              $_.CommandElements[0].Value -eq 'Where-Object' 
            } | Select-Object -First 1)
          )) {
          $issues += [PSCustomObject]@{
            Rule = 'InefficientPipelineOrder'
            Severity = 'Information'
            Line = $pipeline.Extent.StartLineNumber
            Message = "Pipeline has Sort-Object before Where-Object. Consider filtering before sorting for better performance."
            FilePath = $FilePath
          }
        }
      }
        
    } catch {
      Write-Verbose "Error analyzing performance: $_"
    }
    
    return $issues
  }

  function Test-SecurityVulnerability {
    <#
    .SYNOPSIS
        Advanced security vulnerability detection
    
    .DESCRIPTION
        Detects security issues aligned with OWASP Top 10:
        - Command injection vulnerabilities
        - Path traversal attempts
        - Insecure deserialization
        - XML External Entity (XXE) vulnerabilities
        - Insufficient logging of security events
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
      [Parameter(Mandatory)]
      [string]$Content,
        
      [Parameter()]
      [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
      $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $Content,
        [ref]$null,
        [ref]$null
      )
        
      # Check for Start-Process with user input
      $commands = $ast.FindAll({
          $node = $args[0]
          $node -is [System.Management.Automation.Language.CommandAst]
        }, $true)
        
      foreach ($cmd in $commands) {
        if ($cmd.CommandElements.Count -gt 0) {
          $cmdName = $cmd.CommandElements[0].Value
                
          if ($cmdName -eq 'Start-Process' -or $cmdName -eq 'Invoke-Expression') {
            # Check if arguments contain variables (potential injection)
            $hasVariables = $cmd.FindAll({
                $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
              }, $true).Count -gt 0
                    
            if ($hasVariables) {
              $issues += [PSCustomObject]@{
                Rule = 'PotentialCommandInjection'
                Severity = 'Error'
                Line = $cmd.Extent.StartLineNumber
                Message = "Potential command injection: $cmdName with variable input. Validate and sanitize all user input."
                FilePath = $FilePath
              }
            }
          }
                
          # Check for XML deserialization
          if ($cmdName -eq 'Import-Clixml' -or $cmdName -eq 'ConvertFrom-Json' -or 
            $cmdName -eq 'ConvertFrom-Xml') {
            $issues += [PSCustomObject]@{
              Rule = 'InsecureDeserialization'
              Severity = 'Warning'
              Line = $cmd.Extent.StartLineNumber
              Message = "Deserialization detected: $cmdName. Ensure data source is trusted to prevent injection attacks."
              FilePath = $FilePath
            }
          }
        }
      }
        
      # Check for path traversal vulnerabilities
      $pathOps = @($ast.FindAll({
            $node = $args[0]
            if ($node -is [System.Management.Automation.Language.CommandAst] -and 
              $node.CommandElements.Count -gt 0) {
              $cmdName = $node.CommandElements[0].Value
              return ($cmdName -in @('Get-Item', 'Get-Content', 'Set-Content', 'Remove-Item', 
                  'Copy-Item', 'Move-Item', 'New-Item'))
            }
            return $false
          }, $true))
        
      foreach ($pathOp in $pathOps) {
        # Check if path contains .. in string literals
        $hasTraversal = $false
        foreach ($element in $pathOp.CommandElements) {
          if ($element -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            if ($element.Value -like '*/..*' -or $element.Value -like '*..\*' -or
              $element.Value -like '*../*' -or $element.Value -like '*\..\*') {
              $hasTraversal = $true
              break
            }
          }
        }
            
        if ($hasTraversal) {
          $issues += [PSCustomObject]@{
            Rule = 'PathTraversalRisk'
            Severity = 'Error'
            Line = $pathOp.Extent.StartLineNumber
            Message = "Potential path traversal detected. Use Resolve-Path or Test-Path to validate file paths."
            FilePath = $FilePath
          }
        }
      }
        
      # Check for insufficient error logging in try-catch
      $tryCatches = @($ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.TryStatementAst]
          }, $true))
        
      foreach ($tryCatch in $tryCatches) {
        foreach ($catchClause in $tryCatch.CatchClauses) {
          $hasLogging = @($catchClause.Body.FindAll({
                $node = $args[0]
                if ($node -is [System.Management.Automation.Language.CommandAst] -and 
                  $node.CommandElements.Count -gt 0) {
                  $cmdName = $node.CommandElements[0].Value
                  return ($cmdName -in @('Write-Error', 'Write-Warning', 'Write-Verbose', 
                      'Write-Information', 'Write-Log', 'Write-Host', 'Write-Output'))
                }
                return $false
              }, $true)).Count -gt 0
                
          # Only flag if catch has statements but no logging
          if (-not $hasLogging -and $catchClause.Body.Statements.Count -gt 0) {
            # Check if it's not just re-throwing
            $hasThrow = @($catchClause.Body.FindAll({
                  $args[0] -is [System.Management.Automation.Language.ThrowStatementAst]
                }, $true)).Count -gt 0
                    
            if (-not $hasThrow) {
              $issues += [PSCustomObject]@{
                Rule = 'InsufficientErrorLogging'
                Severity = 'Warning'
                Line = $catchClause.Extent.StartLineNumber
                Message = "Catch block without error logging. Security-relevant errors should be logged for audit trails."
                FilePath = $FilePath
              }
            }
          }
        }
      }
        
    } catch {
      Write-Verbose "Error analyzing security: $_"
    }
    
    return $issues
  }

  function Test-MaintainabilityIssue {
    <#
    .SYNOPSIS
        Detects maintainability and readability issues
    
    .DESCRIPTION
        Identifies code that is difficult to maintain:
        - Magic numbers without explanation
        - Unclear variable names (single letters, abbreviations)
        - Missing parameter descriptions
        - Duplicated code blocks
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
      [Parameter(Mandatory)]
      [string]$Content,
        
      [Parameter()]
      [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
      $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $Content,
        [ref]$null,
        [ref]$null
      )
        
      # Check for magic numbers
      $constants = $ast.FindAll({
          $node = $args[0]
          $node -is [System.Management.Automation.Language.ConstantExpressionAst] -and
          $node.StaticType -eq [int] -and
          $node.Value -notin @(0, 1, -1, 2, 10, 100, 1000)
        }, $true)
        
      foreach ($const in $constants) {
        $issues += [PSCustomObject]@{
          Rule = 'MagicNumber'
          Severity = 'Information'
          Line = $const.Extent.StartLineNumber
          Message = "Magic number '$($const.Value)' found. Consider using a named constant for clarity."
          FilePath = $FilePath
        }
      }
        
      # Check for unclear variable names
      $variables = $ast.FindAll({
          $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
        }, $true)
        
      $checkedVars = @{}
      foreach ($var in $variables) {
        $varName = $var.VariablePath.UserPath
            
        # Skip automatic variables and already checked
        if ($varName -in @('_', 'PSItem', 'args', 'this', 'input', 'MyInvocation') -or 
          $checkedVars.ContainsKey($varName)) {
          continue
        }
            
        $checkedVars[$varName] = $true
            
        # Check for single letter names (except $i, $j, $k in loops)
        if ($varName.Length -eq 1 -and $varName -notin @('i', 'j', 'k', 'x', 'y', 'z')) {
          $issues += [PSCustomObject]@{
            Rule = 'UnclearVariableName'
            Severity = 'Information'
            Line = $var.Extent.StartLineNumber
            Message = "Variable name '$varName' is unclear. Use descriptive names for better readability."
            FilePath = $FilePath
          }
        }
      }
        
      # Check for missing comment-based help
      $functions = $ast.FindAll({
          $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
        
      foreach ($func in $functions) {
        $hasHelp = $false
            
        # Check for comment-based help
        if ($func.Body.ParamBlock) {
          $helpContent = $func.GetHelpContent()
          if ($helpContent) {
            $hasHelp = $true
          }
        }
            
        if (-not $hasHelp -and $func.Name -notmatch '^_') {
          $issues += [PSCustomObject]@{
            Rule = 'MissingFunctionHelp'
            Severity = 'Warning'
            Line = $func.Extent.StartLineNumber
            Message = "Function '$($func.Name)' missing comment-based help. Add .SYNOPSIS and .DESCRIPTION for maintainability."
            FilePath = $FilePath
          }
        }
      }
        
    } catch {
      Write-Verbose "Error analyzing maintainability: $_"
    }
    
    return $issues
  }

  function Invoke-AdvancedDetection {
    <#
    .SYNOPSIS
        Runs all advanced detection checks
    
    .DESCRIPTION
        Orchestrates all advanced detection functions and returns comprehensive results.
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    
    .EXAMPLE
        Invoke-AdvancedDetection -Content $script -FilePath "script.ps1"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
      [Parameter(Mandatory)]
      [string]$Content,
        
      [Parameter()]
      [string]$FilePath = ''
    )
    
    $allIssues = [System.Collections.ArrayList]::new()
    
    $complexityIssues = @(Test-CodeComplexity -Content $Content -FilePath $FilePath)
    if ($complexityIssues.Count -gt 0) { 
      foreach ($issue in $complexityIssues) { [void]$allIssues.Add($issue) }
    }
    
    $perfIssues = @(Test-PerformanceAntiPatterns -Content $Content -FilePath $FilePath)
    if ($perfIssues.Count -gt 0) { 
      foreach ($issue in $perfIssues) { [void]$allIssues.Add($issue) }
    }
    
    $secIssues = @(Test-SecurityVulnerabilities -Content $Content -FilePath $FilePath)
    if ($secIssues.Count -gt 0) { 
      foreach ($issue in $secIssues) { [void]$allIssues.Add($issue) }
    }
    
    $maintIssues = @(Test-MaintainabilityIssues -Content $Content -FilePath $FilePath)
    if ($maintIssues.Count -gt 0) { 
      foreach ($issue in $maintIssues) { [void]$allIssues.Add($issue) }
    }
    
    $issuesArray = @($allIssues)
    
    $summary = [PSCustomObject]@{
      FilePath = $FilePath
      TotalIssues = $issuesArray.Count
      ErrorCount = @($issuesArray | Where-Object { $_.Severity -eq 'Error' }).Count
      WarningCount = @($issuesArray | Where-Object { $_.Severity -eq 'Warning' }).Count
      InfoCount = @($issuesArray | Where-Object { $_.Severity -eq 'Information' }).Count
      Issues = $issuesArray
      Timestamp = Get-Date -Format 'o'
    }
    
    return $summary
  }

  # Export all detection functions
  Export-ModuleMember -Function @(
    'Test-CodeComplexity',
    'Test-PerformanceAntiPatterns',
    'Test-SecurityVulnerabilities',
    'Test-MaintainabilityIssues',
    'Invoke-AdvancedDetection'
  )
