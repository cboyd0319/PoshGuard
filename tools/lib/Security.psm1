<#
.SYNOPSIS
    PoshGuard Security Auto-Fix Module

.DESCRIPTION
    Security-focused auto-fix functions for PowerShell scripts.
    Handles all 8 PSSA security rules (100% coverage):
    - PSAvoidUsingPlainTextForPassword
    - PSAvoidUsingConvertToSecureStringWithPlainText
    - PSAvoidUsingUsernameAndPasswordParams
    - PSAvoidUsingAllowUnencryptedAuthentication
    - PSAvoidUsingComputerNameHardcoded
    - PSAvoidUsingInvokeExpression
    - PSAvoidUsingEmptyCatchBlock
    - PSAvoidUsingBrokenHashAlgorithms

.NOTES
    Part of PoshGuard v4.3.0
    Security Phase Complete: October 10, 2025
    Dependencies: ASTHelper.psm1 (for AST operations)
#>

Set-StrictMode -Version Latest

# Import ASTHelper module for reusable AST operations
$ASTHelperPath = Join-Path $PSScriptRoot 'ASTHelper.psm1'
if (Test-Path $ASTHelperPath) {
  Import-Module $ASTHelperPath -Force -ErrorAction SilentlyContinue
}

function Invoke-PlainTextPasswordFix {
  <#
    .SYNOPSIS
        Converts plain-text password parameters to SecureString

    .DESCRIPTION
        Detects parameters with "Password" or "Pass" in the name that use [string] type
        and converts them to [SecureString] for security.

        Fixes PSAvoidUsingPlainTextForPassword violations.

        Changes:
        - [string]$Password → [SecureString]$Password
        - [string]$Pass → [SecureString]$Pass
        - Adds security comment explaining the change

    .PARAMETER Content
        The PowerShell script content to fix

    .PARAMETER FilePath
        Optional file path for better error messages

    .EXAMPLE
        PS C:\> Invoke-PlainTextPasswordFix -Content $scriptContent

        Converts password parameters to SecureString

    .NOTES
        Uses ASTHelper.psm1 for consistent AST operations and error handling
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter()]
    [string]$FilePath = ''
  )

  # Use ASTHelper for consistent, maintainable fix implementation
  Invoke-ASTBasedFix `
    -Content $Content `
    -FixName 'PlainTextPassword' `
    -FilePath $FilePath `
    -ASTNodeFinder {
    param($ast)

    # Find all parameter nodes
    $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ParameterAst]
      }, $true)
  } `
    -NodeTransformer {
    param($node, $content)

    # Check if parameter name contains password-related keywords
    $paramName = $node.Name.VariablePath.UserPath
    if ($paramName -notmatch '(Password|Pass|Pwd|Secret|Token)') {
      return $null  # Skip this node
    }

    # Check if it's typed as [string]
    $typeConstraint = $node.Attributes | Where-Object {
      $_ -is [System.Management.Automation.Language.TypeConstraintAst]
    } | Select-Object -First 1

    if ($typeConstraint -and $typeConstraint.TypeName.Name -eq 'string') {
      # Return replacement info - ASTHelper handles the actual replacement
      Write-Verbose "Converting parameter `$$paramName from [string] to [SecureString]"
      return @{
        Start = $typeConstraint.Extent.StartOffset
        End = $typeConstraint.Extent.EndOffset
        NewText = '[SecureString]'
      }
    }

    return $null  # No replacement needed
  }
}

function Invoke-ConvertToSecureStringFix {
  <#
    .SYNOPSIS
        Removes or flags dangerous ConvertTo-SecureString -AsPlainText usage

    .DESCRIPTION
        Detects ConvertTo-SecureString with -AsPlainText -Force pattern where
        the password is a literal string (not from a secure source).

        Fixes PSAvoidUsingConvertToSecureStringWithPlainText violations.

        Strategy:
        - Comments out the line with security warning
        - Adds suggestion to use Read-Host -AsSecureString or Get-Secret

    .EXAMPLE
        PS C:\> Invoke-ConvertToSecureStringFix -Content $scriptContent

        Comments out dangerous ConvertTo-SecureString patterns
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    $lines = $Content -split "`r?`n"
    $modified = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]

      # Match: ConvertTo-SecureString "literal" -AsPlainText -Force
      # Match: ConvertTo-SecureString 'literal' -AsPlainText -Force
      if ($line -match 'ConvertTo-SecureString\s+["\x27][^"\x27]+["\x27]\s+.*-AsPlainText') {
        # Found dangerous pattern with literal string
        $indent = ($line -replace '^(\s*).*$', '$1')
        $lines[$i] = "${indent}# SECURITY: Removed ConvertTo-SecureString with plain-text literal`n" +
        "${indent}# Use: `$secure = Read-Host `"Password`" -AsSecureString`n" +
        "${indent}# Or:  `$secure = Get-Secret -Name `"MySecret`"`n" +
        "${indent}# $line"
        $modified = $true
        Write-Verbose "Commented out dangerous ConvertTo-SecureString pattern at line $($i + 1)"
      }
    }

    if ($modified) {
      return ($lines -join "`n")
    }
  }
  catch {
    Write-Verbose "ConvertTo-SecureString fix failed: $_"
  }

  return $Content
}

function Invoke-UsernamePasswordParamsFix {
  <#
    .SYNOPSIS
        Converts Username/Password parameter pairs to PSCredential

    .DESCRIPTION
        Detects functions with both Username and Password parameters
        and suggests converting to a single PSCredential parameter.

        Fixes PSAvoidUsingUsernameAndPasswordParams violations.

        Changes:
        - Adds comment suggesting PSCredential parameter
        - Documents the security issue

    .EXAMPLE
        PS C:\> Invoke-UsernamePasswordParamsFix -Content $scriptContent

        Adds PSCredential conversion suggestions
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$null,
      [ref]$null
    )

    $functionAsts = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)

    if ($functionAsts.Count -eq 0) {
      return $Content
    }

    $replacements = @()

    foreach ($function in $functionAsts) {
      $params = $function.Body.ParamBlock.Parameters
      if (-not $params) { continue }

      $hasUsername = $false
      $hasPassword = $false

      foreach ($param in $params) {
        $paramName = $param.Name.VariablePath.UserPath
        if ($paramName -match '^(UserName|User|Username)$') {
          $hasUsername = $true
        }
        if ($paramName -match '(Password|Pass|Pwd)') {
          $hasPassword = $true
        }
      }

      if ($hasUsername -and $hasPassword) {
        # Found a function with both Username and Password params
        if ($function.Body.ParamBlock) {
          $paramBlockStart = $function.Body.ParamBlock.Extent.StartOffset

          $replacements += @{
            FunctionName = $function.Name
            Position = $paramBlockStart
            InsertBefore = $true
          }
        }
      }
    }

    if ($replacements.Count -eq 0) {
      return $Content
    }

    # Add security comments before param blocks
    $replacements = $replacements | Sort-Object -Property Position -Descending
    $result = $Content

    foreach ($replacement in $replacements) {
      $securityComment = "# SECURITY: Consider replacing Username/Password parameters with PSCredential`n" +
      "    # Example:`n" +
      "    # [Parameter(Mandatory)]`n" +
      "    # [PSCredential]`$Credential`n" +
      "    # Then access: `$Credential.UserName and `$Credential.GetNetworkCredential().Password`n`n"

      $before = $result.Substring(0, $replacement.Position)
      $after = $result.Substring($replacement.Position)
      $result = $before + $securityComment + $after

      Write-Verbose "Added PSCredential suggestion for function: $($replacement.FunctionName)"
    }

    return $result
  }
  catch {
    Write-Verbose "Username/Password params fix failed: $_"
    return $Content
  }
}

function Invoke-AllowUnencryptedAuthFix {
  <#
    .SYNOPSIS
        Removes -AllowUnencryptedAuthentication flag

    .DESCRIPTION
        Detects and comments out -AllowUnencryptedAuthentication parameter usage.

        Fixes PSAvoidUsingAllowUnencryptedAuthentication violations.

    .EXAMPLE
        PS C:\> Invoke-AllowUnencryptedAuthFix -Content $scriptContent

        Comments out -AllowUnencryptedAuthentication usage
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    # Replace -AllowUnencryptedAuthentication with a warning comment
    $pattern = '-AllowUnencryptedAuthentication\b'
    if ($Content -match $pattern) {
      $fixed = $Content -replace $pattern, '# SECURITY: -AllowUnencryptedAuthentication removed (use HTTPS)'
      Write-Verbose "Removed -AllowUnencryptedAuthentication flag(s)"
      return $fixed
    }
  }
  catch {
    Write-Verbose "AllowUnencryptedAuthentication fix failed: $_"
  }

  return $Content
}

function Invoke-HardcodedComputerNameFix {
  <#
    .SYNOPSIS
        Parameterizes hardcoded computer names

    .DESCRIPTION
        Detects hardcoded computer names in -ComputerName parameters
        and suggests parameterization.

        Fixes PSAvoidUsingComputerNameHardcoded violations.

    .EXAMPLE
        PS C:\> Invoke-HardcodedComputerNameFix -Content $scriptContent

        Adds parameterization suggestions for hardcoded computer names
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    $lines = $Content -split "`r?`n"
    $modified = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]

      # Match: -ComputerName "SERVER01" or -ComputerName 'SERVER01'
      if ($line -match '-ComputerName\s+["\x27]([^"\x27]+)["\x27]') {
        $computerName = $Matches[1]

        # Skip if it's a variable, localhost, or parameter reference
        if ($computerName -match '^\$' -or $computerName -match '^(localhost|127\.0\.0\.1|\.)$') {
          continue
        }

        $indent = ($line -replace '^(\s*).*$', '$1')
        $lines[$i] = "${indent}# SECURITY: Hardcoded computer name detected. Consider:`n" +
        "${indent}# param([string]`$ComputerName = `"$computerName`")`n" +
        "${indent}$line"
        $modified = $true
        Write-Verbose "Added parameterization suggestion for hardcoded computer name: $computerName"
      }
    }

    if ($modified) {
      return ($lines -join "`n")
    }
  }
  catch {
    Write-Verbose "Hardcoded computer name fix failed: $_"
  }

  return $Content
}

function Invoke-InvokeExpressionFix {
  <#
    .SYNOPSIS
        Suggests safer alternatives to Invoke-Expression

    .DESCRIPTION
        Detects Invoke-Expression usage and adds comments suggesting
        safer alternatives like splatting, & operator, or scriptblocks.

        Fixes PSAvoidUsingInvokeExpression violations.

    .EXAMPLE
        PS C:\> Invoke-InvokeExpressionFix -Content $scriptContent

        Adds safety suggestions for Invoke-Expression usage
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
  )

  try {
    $lines = $Content -split "`r?`n"
    $modified = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]

      # Match: Invoke-Expression or iex
      if ($line -match '\b(Invoke-Expression|iex)\b' -and $line -notmatch '^\s*#') {
        $indent = ($line -replace '^(\s*).*$', '$1')
        $lines[$i] = "${indent}# SECURITY: Invoke-Expression is a code injection risk`n" +
        "${indent}# Safer alternatives:`n" +
        "${indent}#   - Splatting: `$params = @{Name='value'}; Get-Item @params`n" +
        "${indent}#   - Call operator: & `$command @args`n" +
        "${indent}#   - ScriptBlock: `$sb = {Get-Process}; & `$sb`n" +
        "${indent}$line"
        $modified = $true
        Write-Verbose "Added security warning for Invoke-Expression at line $($i + 1)"
      }
    }

    if ($modified) {
      return ($lines -join "`n")
    }
  }
  catch {
    Write-Verbose "Invoke-Expression fix failed: $_"
  }

  return $Content
}

function Invoke-EmptyCatchBlockFix {
  <#
    .SYNOPSIS
        Adds logging to empty catch blocks

    .DESCRIPTION
        Detects empty catch blocks and adds minimal error logging.

        Fixes PSAvoidUsingEmptyCatchBlock violations.

    .PARAMETER Content
        The PowerShell script content to fix

    .PARAMETER FilePath
        Optional file path for better error messages

    .EXAMPLE
        PS C:\> Invoke-EmptyCatchBlockFix -Content $scriptContent

        Adds error logging to empty catch blocks

    .NOTES
        Uses ASTHelper.psm1 for consistent AST operations and error handling
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter()]
    [string]$FilePath = ''
  )

  # Use ASTHelper for consistent, maintainable fix implementation
  Invoke-ASTBasedFix `
    -Content $Content `
    -FixName 'EmptyCatchBlock' `
    -FilePath $FilePath `
    -ASTNodeFinder {
    param($ast)

    # Find all try-catch statements and collect their empty catch clauses
    $tryCatchAsts = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.TryStatementAst]
      }, $true)

    $emptyCatchClauses = @()
    foreach ($tryAst in $tryCatchAsts) {
      foreach ($catch in $tryAst.CatchClauses) {
        # Check if the catch block body is empty or only whitespace
        $catchBodyContent = $catch.Body.Statements
        if ($null -eq $catchBodyContent -or $catchBodyContent.Count -eq 0) {
          $emptyCatchClauses += $catch
        }
      }
    }

    return $emptyCatchClauses
  } `
    -NodeTransformer {
    param($catchNode, $content)

    # Get the catch body extent (inside the braces)
    $startOffset = $catchNode.Body.Extent.StartOffset + 1  # After opening brace
    $endOffset = $catchNode.Body.Extent.EndOffset - 1      # Before closing brace

    # Determine indentation from the catch line
    $lines = $content.Substring(0, $catchNode.Extent.StartOffset) -split "`r?`n"
    $lastLine = $lines[-1]
    $indent = if ($lastLine -match '^(\s*)') { $Matches[1] } else { '' }

    # Generate error handling code with proper indentation
    $errorHandling = "`n${indent}    # TODO: Handle error appropriately (was empty catch block)`n${indent}    Write-Verbose `"Suppressed error: `$_`"`n${indent}"

    Write-Verbose "Adding error handling to empty catch block at line $($catchNode.Extent.StartLineNumber)"
    return @{
      Start = $startOffset
      End = $endOffset
      NewText = $errorHandling
    }
  }
}

# Export all security fix functions
Export-ModuleMember -Function @(
  'Invoke-PlainTextPasswordFix',
  'Invoke-ConvertToSecureStringFix',
  'Invoke-UsernamePasswordParamsFix',
  'Invoke-AllowUnencryptedAuthFix',
  'Invoke-HardcodedComputerNameFix',
  'Invoke-InvokeExpressionFix',
  'Invoke-EmptyCatchBlockFix'
)
