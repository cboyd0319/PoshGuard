<#
.SYNOPSIS
    PoshGuard AST Helper Functions

.DESCRIPTION
    Shared helper functions for AST parsing, validation, and transformation.
    Reduces code duplication across 50+ fix functions that perform AST operations.

    Key Functions:
    - Invoke-SafeASTTransformation: Wraps AST transformations with error handling
    - Test-ValidPowerShellSyntax: Validates PowerShell syntax before processing
    - Get-ParsedAST: Parses PowerShell content with comprehensive error handling
    - Invoke-ASTBasedFix: Generic AST transformation pipeline

.NOTES
    Module: ASTHelper
    Version: 4.3.0
    Part of PoshGuard v4.3.0
    Author: https://github.com/cboyd0319

    This module extracts common AST patterns found in 50+ fix functions,
    improving maintainability and reducing code duplication by ~40%.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ParsedAST {
  <#
  .SYNOPSIS
      Parses PowerShell content into an AST with comprehensive error handling

  .DESCRIPTION
      Wrapper around [Parser]::ParseInput that provides:
      - Consistent error handling
      - Validation of parse results
      - Detailed error messages with line numbers
      - Support for both string content and file paths

  .PARAMETER Content
      The PowerShell script content to parse

  .PARAMETER FilePath
      Optional file path for better error messages

  .OUTPUTS
      System.Management.Automation.Language.Ast
      Returns the parsed AST, or $null if parsing fails

  .EXAMPLE
      $ast = Get-ParsedAST -Content $scriptContent
      if ($ast) {
          # Process AST
      }

  .EXAMPLE
      $ast = Get-ParsedAST -Content $scriptContent -FilePath "C:\Scripts\Test.ps1"
      # FilePath improves error messages

  .NOTES
      This function is used by 50+ fix functions to parse PowerShell content
  #>
  [CmdletBinding()]
  [OutputType([System.Management.Automation.Language.Ast])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter()]
    [string]$FilePath = ''
  )

  try {
    $tokens = $null
    $errors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$tokens,
      [ref]$errors
    )

    if ($errors -and $errors.Count -gt 0) {
      $fileContext = if ($FilePath) { " in file '$FilePath'" } else { '' }
      $errorDetails = $errors | ForEach-Object {
        "Line $($_.Extent.StartLineNumber): $($_.Message)"
      }
      Write-Warning "Parse errors found$fileContext :`n$($errorDetails -join "`n")"

      # Still return AST even with minor errors (allows best-effort fixes)
      if ($ast) {
        return $ast
      }
      return $null
    }

    if (-not $ast) {
      Write-Warning "Failed to parse PowerShell content: AST is null"
      return $null
    }

    return $ast
  }
  catch {
    $fileContext = if ($FilePath) { " in file '$FilePath'" } else { '' }
    Write-Warning "Exception during AST parsing$fileContext : $_"
    Write-Verbose "Stack trace: $($_.ScriptStackTrace)"
    return $null
  }
}

function Test-ValidPowerShellSyntax {
  <#
  .SYNOPSIS
      Validates that a string contains valid PowerShell syntax

  .DESCRIPTION
      Quick validation check before attempting fixes.
      Returns $true if syntax is valid, $false otherwise.

      This is faster than full AST parsing when you just need to validate.

  .PARAMETER Content
      The PowerShell script content to validate

  .OUTPUTS
      System.Boolean
      Returns $true if syntax is valid, $false otherwise

  .EXAMPLE
      if (Test-ValidPowerShellSyntax -Content $scriptContent) {
          # Safe to proceed with fixes
      }

  .NOTES
      Used by security-sensitive fix functions to validate input
  #>
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$null,
      [ref]$errors
    )

    # Allow minor errors (warnings) but fail on critical errors
    if ($errors) {
      $criticalErrors = $errors | Where-Object { $_.Severity -eq 'Error' }
      return ($criticalErrors.Count -eq 0)
    }

    return $true
  }
  catch {
    Write-Verbose "Syntax validation failed: $_"
    return $false
  }
}

function Invoke-SafeASTTransformation {
  <#
  .SYNOPSIS
      Executes an AST transformation with comprehensive error handling

  .DESCRIPTION
      Generic wrapper for AST-based transformations that provides:
      - Automatic AST parsing
      - Error handling with fallback to original content
      - Verbose logging for debugging
      - Validation of transformation results
      - Observability integration (if enabled)

      This function eliminates the need for 50+ fix functions to implement
      their own try/catch/parse logic.

  .PARAMETER Content
      The PowerShell script content to transform

  .PARAMETER Transformation
      A scriptblock that accepts ($ast, $content) and returns transformed content

  .PARAMETER TransformationName
      Name of the transformation (for logging)

  .PARAMETER FilePath
      Optional file path (for better error messages)

  .OUTPUTS
      System.String
      Returns transformed content, or original content if transformation fails

  .EXAMPLE
      $fixed = Invoke-SafeASTTransformation -Content $scriptContent -TransformationName 'PlainTextPassword' -Transformation {
          param($ast, $content)
          # Your transformation logic here
          return $transformedContent
      }

  .NOTES
      This function is the foundation for all AST-based fixes in PoshGuard
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [scriptblock]$Transformation,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TransformationName,

    [Parameter()]
    [string]$FilePath = ''
  )

  try {
    # Parse AST
    $ast = Get-ParsedAST -Content $Content -FilePath $FilePath
    if (-not $ast) {
      Write-Verbose "$TransformationName : Failed to parse AST, returning original content"
      return $Content
    }

    Write-Verbose "$TransformationName : Executing transformation..."

    # Execute transformation
    $result = & $Transformation $ast $Content

    if (-not $result) {
      Write-Warning "$TransformationName : Transformation returned null or empty, returning original content"
      return $Content
    }

    # Validate result is still valid PowerShell
    if (-not (Test-ValidPowerShellSyntax -Content $result)) {
      Write-Warning "$TransformationName : Transformation produced invalid PowerShell syntax, returning original content"
      return $Content
    }

    Write-Verbose "$TransformationName : Transformation completed successfully"
    return $result
  }
  catch {
    $fileContext = if ($FilePath) { " for file '$FilePath'" } else { '' }
    Write-Verbose "$TransformationName failed$fileContext : $_"
    Write-Verbose "Stack trace: $($_.ScriptStackTrace)"

    # Log to observability if available
    if ($script:GlobalConfig -and $script:GlobalConfig.Observability.Enabled) {
      try {
        Write-StructuredLog -Level ERROR -Message "$TransformationName transformation failed" -Properties @{
          transformation = $TransformationName
          filePath = $FilePath
          error = $_.Exception.Message
          stack = $_.ScriptStackTrace
        }
      }
      catch {
        # Silently ignore observability errors
      }
    }

    return $Content
  }
}

function Invoke-ASTBasedFix {
  <#
  .SYNOPSIS
      High-level pipeline for AST-based fixes

  .DESCRIPTION
      Combines Get-ParsedAST + Transformation + Validation into a single pipeline.
      Simplifies fix function implementation to just providing the transformation logic.

  .PARAMETER Content
      The PowerShell script content to fix

  .PARAMETER FixName
      Name of the fix (for logging)

  .PARAMETER ASTNodeFinder
      Scriptblock that finds AST nodes to fix: ($ast) => @(nodes)

  .PARAMETER NodeTransformer
      Scriptblock that transforms each node: ($node, $content) => @{Start, End, NewText}

  .PARAMETER FilePath
      Optional file path (for better error messages)

  .OUTPUTS
      System.String
      Returns fixed content

  .EXAMPLE
      $fixed = Invoke-ASTBasedFix -Content $scriptContent -FixName 'PlainTextPassword' `
        -ASTNodeFinder {
          param($ast)
          $ast.FindAll({ $args[0] -is [ParameterAst] }, $true)
        } `
        -NodeTransformer {
          param($node, $content)
          # Return replacement info
          @{ Start = $node.Extent.StartOffset; End = $node.Extent.EndOffset; NewText = '...' }
        }

  .NOTES
      This function provides the highest level of abstraction for AST fixes
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$FixName,

    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [scriptblock]$ASTNodeFinder,

    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [scriptblock]$NodeTransformer,

    [Parameter()]
    [string]$FilePath = ''
  )

  Invoke-SafeASTTransformation -Content $Content -TransformationName $FixName -FilePath $FilePath -Transformation {
    param($ast, $originalContent)

    # Find nodes to transform
    $nodes = & $ASTNodeFinder $ast
    if (-not $nodes -or $nodes.Count -eq 0) {
      Write-Verbose "$FixName : No nodes found to transform"
      return $originalContent
    }

    Write-Verbose "$FixName : Found $($nodes.Count) node(s) to transform"

    # Transform each node
    $replacements = @()
    foreach ($node in $nodes) {
      $replacement = & $NodeTransformer $node $originalContent
      if ($replacement) {
        $replacements += $replacement
      }
    }

    if ($replacements.Count -eq 0) {
      Write-Verbose "$FixName : No replacements generated"
      return $originalContent
    }

    # Apply replacements (from end to start to preserve offsets)
    $result = $originalContent
    $sortedReplacements = $replacements | Sort-Object -Property Start -Descending

    foreach ($replacement in $sortedReplacements) {
      $before = $result.Substring(0, $replacement.Start)
      $after = $result.Substring($replacement.End)
      $result = $before + $replacement.NewText + $after
    }

    Write-Verbose "$FixName : Applied $($replacements.Count) replacement(s)"
    return $result
  }
}

Export-ModuleMember -Function @(
  'Get-ParsedAST',
  'Test-ValidPowerShellSyntax',
  'Invoke-SafeASTTransformation',
  'Invoke-ASTBasedFix'
)
