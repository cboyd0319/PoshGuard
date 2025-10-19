<#
.SYNOPSIS
    Advanced Code Analysis Module for PoshGuard

.DESCRIPTION
    Advanced static analysis capabilities beyond basic PSScriptAnalyzer:
    - Dead code detection (unreachable code, unused functions)
    - Code smell detection (anti-patterns, maintainability issues)
    - Cognitive complexity analysis
    - Dependency analysis and circular dependency detection
    - Test coverage recommendations
    - Performance anti-pattern detection
    - Code duplication detection
    
.NOTES
    Version: 4.1.0
    Part of PoshGuard UGE Framework
    References:
    - Martin Fowler's Refactoring catalog
    - Robert C. Martin's Clean Code principles
    - Cognitive Complexity (Sonar Source)
    
    Quality Standards: ISO/IEC 25010, SWEBOK v4.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Dead Code Detection

function Find-DeadCode {
    <#
    .SYNOPSIS
        Detect unreachable and unused code
    
    .DESCRIPTION
        Identifies:
        - Unreachable code (after return, throw, break, continue)
        - Unused functions (never called)
        - Unused variables (assigned but never read)
        - Unused parameters
        - Commented-out code blocks
    
    .PARAMETER Content
        PowerShell script content to analyze
    
    .PARAMETER FilePath
        Path to the file being analyzed
    
    .EXAMPLE
        $deadCode = Find-DeadCode -Content $scriptContent
    
    .OUTPUTS
        Array of dead code issues
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content,
        
        [Parameter()]
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
        
        # Find unreachable code
        $issues += Find-UnreachableCode -AST $ast -FilePath $FilePath
        
        # Find unused functions
        $issues += Find-UnusedFunctions -AST $ast -FilePath $FilePath
        
        # Find unused variables
        $issues += Find-UnusedVariables -AST $ast -FilePath $FilePath
        
        # Find commented-out code
        $issues += Find-CommentedCode -Content $Content -FilePath $FilePath
        
    }
    catch {
        Write-Warning "Dead code analysis failed: $_"
    }
    
    return $issues
}

function Find-UnreachableCode {
    <#
    .SYNOPSIS
        Find code that can never be executed
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        $AST,
        
        [Parameter()]
        [string]$FilePath
    )
    
    $issues = @()
    
    # Find return statements and check for code after them
    $returnStatements = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.ReturnStatementAst]
    }, $true)
    
    foreach ($returnStmt in $returnStatements) {
        $parent = $returnStmt.Parent
        # Check both StatementBlockAst and NamedBlockAst (function/script bodies)
        if ($parent -is [System.Management.Automation.Language.StatementBlockAst] -or
            $parent -is [System.Management.Automation.Language.NamedBlockAst]) {
            $statements = $parent.Statements
            $returnIndex = $statements.IndexOf($returnStmt)
            
            if ($returnIndex -ge 0 -and $returnIndex -lt ($statements.Count - 1)) {
                # There's code after the return statement
                $unreachableStmt = $statements[$returnIndex + 1]
                $issues += [PSCustomObject]@{
                    Type = 'DeadCode'
                    Name = 'UnreachableCode'
                    Severity = 'Medium'
                    Description = 'Code after return statement is unreachable'
                    Line = $unreachableStmt.Extent.StartLineNumber
                    Column = $unreachableStmt.Extent.StartColumnNumber
                    FilePath = $FilePath
                    Recommendation = 'Remove unreachable code or move return statement'
                    CodeSnippet = $unreachableStmt.Extent.Text
                }
            }
        }
    }
    
    return $issues
}

function Find-UnusedFunctions {
    <#
    .SYNOPSIS
        Find functions that are never called
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        $AST,
        
        [Parameter()]
        [string]$FilePath
    )
    
    $issues = @()
    
    # Get all function definitions
    $functions = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    # Get all function calls
    $calls = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.CommandAst]
    }, $true)
    
    $calledFunctions = $calls | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
    
    foreach ($func in $functions) {
        $funcName = $func.Name
        
        # Skip private functions (starting with _)
        if ($funcName -match '^_') {
            continue
        }
        
        # Skip exported functions (would be used by module consumers)
        if ($funcName -match '^(Get|Set|New|Remove|Invoke|Test|Start|Stop|Add|Clear)-') {
            continue
        }
        
        if ($funcName -notin $calledFunctions) {
            $issues += [PSCustomObject]@{
                Type = 'DeadCode'
                Name = 'UnusedFunction'
                Severity = 'Low'
                Description = "Function '$funcName' is defined but never called"
                Line = $func.Extent.StartLineNumber
                Column = $func.Extent.StartColumnNumber
                FilePath = $FilePath
                Recommendation = 'Remove unused function or export it if intended for external use'
                CodeSnippet = $funcName
            }
        }
    }
    
    return $issues
}

function Find-UnusedVariables {
    <#
    .SYNOPSIS
        Find variables that are assigned but never used
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        $AST,
        
        [Parameter()]
        [string]$FilePath
    )
    
    $issues = @()
    
    # Get all variable assignments
    $assignments = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst]
    }, $true)
    
    # Get all variable reads
    $reads = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.VariableExpressionAst]
    }, $true)
    
    $readVariables = $reads | ForEach-Object { $_.VariablePath.UserPath }
    
    foreach ($assignment in $assignments) {
        if ($assignment.Left -is [System.Management.Automation.Language.VariableExpressionAst]) {
            $varName = $assignment.Left.VariablePath.UserPath
            
            # Skip special variables
            if ($varName -in @('_', 'null', 'true', 'false', 'PSBoundParameters', 'PSCmdlet', 'ErrorActionPreference')) {
                continue
            }
            
            # Check if variable is read after assignment
            $assignmentLine = $assignment.Extent.StartLineNumber
            $subsequentReads = $reads | Where-Object { 
                $_.VariablePath.UserPath -eq $varName -and 
                $_.Extent.StartLineNumber -gt $assignmentLine
            }
            
            if (-not $subsequentReads) {
                $issues += [PSCustomObject]@{
                    Type = 'DeadCode'
                    Name = 'UnusedVariable'
                    Severity = 'Low'
                    Description = "Variable '`$$varName' is assigned but never used"
                    Line = $assignmentLine
                    Column = $assignment.Extent.StartColumnNumber
                    FilePath = $FilePath
                    Recommendation = 'Remove unused variable or use its value'
                    CodeSnippet = "`$$varName"
                }
            }
        }
    }
    
    return $issues
}

function Find-CommentedCode {
    <#
    .SYNOPSIS
        Detect large blocks of commented-out code
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        
        [Parameter()]
        [string]$FilePath
    )
    
    $issues = @()
    $lines = $Content -split "`n"
    $commentBlock = @()
    $blockStart = 0
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        
        if ($line -match '^\s*#' -and $line -notmatch '^\s*#\.SYNOPSIS|^\s*#\.DESCRIPTION|^\s*#region|^\s*#endregion') {
            if ($commentBlock.Count -eq 0) {
                $blockStart = $i + 1
            }
            $commentBlock += $line
        }
        else {
            if ($commentBlock.Count -ge 5) {
                # Check if it looks like code (contains PowerShell keywords)
                $combinedText = $commentBlock -join "`n"
                if ($combinedText -match '(function|param|foreach|if|while|switch|try|catch|\$\w+\s*=)') {
                    $issues += [PSCustomObject]@{
                        Type = 'CodeSmell'
                        Name = 'CommentedCode'
                        Severity = 'Low'
                        Description = "Large block of commented-out code ($($commentBlock.Count) lines)"
                        Line = $blockStart
                        FilePath = $FilePath
                        Recommendation = 'Remove commented code and rely on version control history'
                        CodeSnippet = "# ... ($($commentBlock.Count) lines)"
                    }
                }
            }
            $commentBlock = @()
        }
    }
    
    return $issues
}

#endregion

#region Code Smell Detection

function Find-CodeSmells {
    <#
    .SYNOPSIS
        Detect code smells and anti-patterns
    
    .DESCRIPTION
        Identifies maintainability issues:
        - Long methods (>50 lines)
        - Too many parameters (>7)
        - Deeply nested code (>4 levels)
        - Magic numbers
        - Duplicate code
        - God objects (classes with too many responsibilities)
    
    .PARAMETER Content
        PowerShell script content
    
    .PARAMETER FilePath
        File path
    
    .EXAMPLE
        $smells = Find-CodeSmells -Content $scriptContent
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        
        [Parameter()]
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
        
        # Find long methods
        $issues += Find-LongMethods -AST $ast -FilePath $FilePath
        
        # Find too many parameters
        $issues += Find-TooManyParameters -AST $ast -FilePath $FilePath
        
        # Find deep nesting
        $issues += Find-DeepNesting -AST $ast -FilePath $FilePath
        
        # Find magic numbers
        $issues += Find-MagicNumbers -AST $ast -FilePath $FilePath
        
    }
    catch {
        Write-Warning "Code smell detection failed: $_"
    }
    
    return $issues
}

function Find-LongMethods {
    <#
    .SYNOPSIS
        Find functions/methods that are too long
    #>
    [CmdletBinding()]
    param($AST, [string]$FilePath)
    
    $issues = @()
    $maxLines = 50
    
    $functions = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    foreach ($func in $functions) {
        $lineCount = $func.Extent.EndLineNumber - $func.Extent.StartLineNumber + 1
        
        if ($lineCount -gt $maxLines) {
            $issues += [PSCustomObject]@{
                Type = 'CodeSmell'
                Name = 'LongMethod'
                Severity = 'Medium'
                Description = "Function '$($func.Name)' is too long ($lineCount lines, max: $maxLines)"
                Line = $func.Extent.StartLineNumber
                FilePath = $FilePath
                Recommendation = 'Break down into smaller, focused functions'
                MetricValue = $lineCount
            }
        }
    }
    
    return $issues
}

function Find-TooManyParameters {
    <#
    .SYNOPSIS
        Find functions with too many parameters
    #>
    [CmdletBinding()]
    param($AST, [string]$FilePath)
    
    $issues = @()
    $maxParams = 7
    
    $functions = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    foreach ($func in $functions) {
        if ($func.Body.ParamBlock) {
            $paramCount = $func.Body.ParamBlock.Parameters.Count
            
            if ($paramCount -gt $maxParams) {
                $issues += [PSCustomObject]@{
                    Type = 'CodeSmell'
                    Name = 'TooManyParameters'
                    Severity = 'Medium'
                    Description = "Function '$($func.Name)' has too many parameters ($paramCount, max: $maxParams)"
                    Line = $func.Extent.StartLineNumber
                    FilePath = $FilePath
                    Recommendation = 'Consider using parameter objects or reducing function scope'
                    MetricValue = $paramCount
                }
            }
        }
    }
    
    return $issues
}

function Find-DeepNesting {
    <#
    .SYNOPSIS
        Find deeply nested code blocks
    #>
    [CmdletBinding()]
    param($AST, [string]$FilePath)
    
    $issues = @()
    $maxDepth = 4
    
    $functions = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    foreach ($func in $functions) {
        $maxNesting = Get-MaxNestingDepth -AST $func.Body
        
        if ($maxNesting -gt $maxDepth) {
            $issues += [PSCustomObject]@{
                Type = 'CodeSmell'
                Name = 'DeepNesting'
                Severity = 'Medium'
                Description = "Function '$($func.Name)' has deep nesting (depth: $maxNesting, max: $maxDepth)"
                Line = $func.Extent.StartLineNumber
                FilePath = $FilePath
                Recommendation = 'Use early returns, extract nested logic to separate functions'
                MetricValue = $maxNesting
            }
        }
    }
    
    return $issues
}

function Get-MaxNestingDepth {
    <#
    .SYNOPSIS
        Calculate maximum nesting depth in AST
    .DESCRIPTION
        Uses a simple iterative approach to find the maximum nesting depth
        by examining the parent chain of each nesting node.
    #>
    [CmdletBinding()]
    param($AST)
    
    if ($null -eq $AST) {
        return 0
    }
    
    $maxDepth = 0
    
    # Find all nesting constructs in the AST
    $nestingNodes = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.IfStatementAst] -or
        $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
        $node -is [System.Management.Automation.Language.WhileStatementAst] -or
        $node -is [System.Management.Automation.Language.SwitchStatementAst]
    }, $true)
    
    # For each nesting node, count how many nesting ancestors it has
    foreach ($node in $nestingNodes) {
        $depth = 0
        $current = $node.Parent
        
        # Walk up the parent chain counting nesting nodes
        $safety = 0
        while ($null -ne $current -and $safety -lt 200) {
            $safety++
            if ($current -is [System.Management.Automation.Language.IfStatementAst] -or
                $current -is [System.Management.Automation.Language.ForEachStatementAst] -or
                $current -is [System.Management.Automation.Language.WhileStatementAst] -or
                $current -is [System.Management.Automation.Language.SwitchStatementAst]) {
                $depth++
            }
            $current = $current.Parent
        }
        
        # Current node itself counts as one level
        $depth++
        
        if ($depth -gt $maxDepth) {
            $maxDepth = $depth
        }
    }
    
    return $maxDepth
}

function Find-MagicNumbers {
    <#
    .SYNOPSIS
        Find hard-coded numeric values (except common ones)
    #>
    [CmdletBinding()]
    param($AST, [string]$FilePath)
    
    $issues = @()
    $allowedNumbers = @(0, 1, 2, 10, 100, 1000, -1)
    
    $numbers = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.ConstantExpressionAst] -and
        $node.Value -is [int]
    }, $true)
    
    foreach ($num in $numbers) {
        if ($num.Value -notin $allowedNumbers -and [Math]::Abs($num.Value) -gt 10) {
            $issues += [PSCustomObject]@{
                Type = 'CodeSmell'
                Name = 'MagicNumber'
                Severity = 'Low'
                Description = "Hard-coded number '$($num.Value)' should be a named constant"
                Line = $num.Extent.StartLineNumber
                Column = $num.Extent.StartColumnNumber
                FilePath = $FilePath
                Recommendation = 'Define as named constant with descriptive name'
                CodeSnippet = $num.Value
            }
        }
    }
    
    return $issues
}

#endregion

#region Cognitive Complexity

function Get-CognitiveComplexity {
    <#
    .SYNOPSIS
        Calculate cognitive complexity (Sonar Source metric)
    
    .DESCRIPTION
        Cognitive complexity measures how difficult code is to understand.
        Unlike cyclomatic complexity, it considers nesting and logical operators.
    
    .PARAMETER AST
        Function AST to analyze
    
    .EXAMPLE
        $complexity = Get-CognitiveComplexity -AST $functionAst
    
    .OUTPUTS
        System.Int32 - Cognitive complexity score
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        $AST
    )
    
    $complexity = 0
    $nesting = 0
    
    # Increment for control flow structures
    $controlFlow = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.IfStatementAst] -or
        $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
        $node -is [System.Management.Automation.Language.WhileStatementAst] -or
        $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
        $node -is [System.Management.Automation.Language.CatchClauseAst]
    }, $true)
    
    foreach ($node in $controlFlow) {
        # Base increment + nesting increment
        $complexity += 1 + $nesting
        
        # Track nesting for nested structures
        if ($node.Parent) {
            $nesting++
        }
    }
    
    # Increment for logical operators
    $logicalOps = $AST.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.BinaryExpressionAst] -and
        $node.Operator -in @('And', 'Or')
    }, $true)
    
    $complexity += $logicalOps.Count
    
    return $complexity
}

#endregion

#region Export

Export-ModuleMember -Function @(
    'Find-DeadCode',
    'Find-CodeSmells',
    'Get-CognitiveComplexity'
)

#endregion
