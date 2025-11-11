<#
.SYNOPSIS
    PoshGuard Type Safety Best Practices Module

.DESCRIPTION
    PowerShell type safety and validation including:
    - Automatic variable protection
    - Multiple type attribute cleanup
    - PSCredential type enforcement

    Ensures proper type usage and prevents type-related issues.

.NOTES
    Part of PoshGuard v4.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

function Invoke-AutomaticVariableFix {
  <#
    .SYNOPSIS
        Prevents assignment to PowerShell automatic variables

    .DESCRIPTION
        PowerShell automatic variables are read-only or should not be assigned.
        This function detects and comments out assignments to automatic variables.

        Automatic variables include:
        - $? (last command status)
        - $^ (first token of last line)
        - $$ (last token of last line)
        - $_ / $PSItem (current pipeline object)
        - $Args, $Error, $ExecutionContext, $false, $true, $null
        - $HOME, $Host, $PID, $PSVersionTable, etc.

    .EXAMPLE
        # BEFORE:
        $? = $true
        $PSItem = "test"

        # AFTER:
        # ERROR: Cannot assign to automatic variable '$?'
        # $? = $true
        # ERROR: Cannot assign to automatic variable '$PSItem'
        # $PSItem = "test"
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  # List of automatic variables that should not be assigned
  $automaticVars = @(
    '\$\?', '\$\^', '\$\$\$',
    '\$_', '\$PSItem',
    '\$Args', '\$Error', '\$ExecutionContext',
    '\$false', '\$true', '\$null',
    '\$HOME', '\$Host', '\$PID', '\$PSVersionTable',
    '\$PWD', '\$ShellId', '\$StackTrace',
    '\$ConsoleFileName', '\$EnabledExperimentalFeatures',
    '\$foreach', '\$input', '\$IsCoreCLR', '\$IsLinux',
    '\$IsMacOS', '\$IsWindows', '\$LastExitCode',
    '\$Matches', '\$MyInvocation', '\$NestedPromptLevel',
    '\$OFS', '\$PSBoundParameters', '\$PSCmdlet',
    '\$PSCommandPath', '\$PSCulture', '\$PSDebugContext',
    '\$PSHOME', '\$PSScriptRoot', '\$PSUICulture',
    '\$PSVersionTable', '\$switch', '\$this'
  )

  try {
    $lines = $Content -split "`n"
    $modified = $false
    $newLines = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]
      $matched = $false

      # Check for assignment to automatic variables
      foreach ($autoVar in $automaticVars) {
        # Pattern: $var = value (with optional whitespace)
        if ($line -match "^\s*($autoVar)\s*=\s*") {
          $varName = $matches[1]
          $newLines += "# ERROR: Cannot assign to automatic variable '$varName'"
          $newLines += "# $line"
          $matched = $true
          $modified = $true
          Write-Verbose "Commented out assignment to automatic variable: $varName"
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
    Write-Verbose "Automatic variable fix failed: $_"
  }

  return $Content
}

function Invoke-MultipleTypeAttributesFix {
  <#
    .SYNOPSIS
        Removes conflicting type attributes from variables

    .DESCRIPTION
        PowerShell variables cannot have multiple type constraints.
        This function keeps only the first type attribute or most specific type.

        REMOVES:
        - [string][int]$var → [int]$var (keeps more specific)
        - [object][string]$var → [string]$var (keeps more specific)

    .EXAMPLE
        # BEFORE:
        [string][int]$value = 5

        # AFTER:
        # FIXED: Removed conflicting type attribute [string]
        [int]$value = 5
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    # Pattern to match multiple type attributes: [type1][type2]$var
    $pattern = '\[([^\]]+)\]\s*\[([^\]]+)\]\s*\$(\w+)'

    $matches = [regex]::Matches($Content, $pattern)
    if ($matches.Count -gt 0) {
      $fixed = $Content
      $replacements = @()

      foreach ($match in $matches) {
        $type1 = $match.Groups[1].Value
        $type2 = $match.Groups[2].Value
        $varName = $match.Groups[3].Value

        # Heuristic: Keep more specific type (e.g., int over object, string over object)
        $keepType = $type2  # Default to second (usually more specific when chained)

        # If first type is more specific than second, keep first
        if ($type1 -in @('int', 'string', 'double', 'datetime', 'bool') -and
          $type2 -in @('object', 'psobject')) {
          $keepType = $type1
        }

        $replacements += [PSCustomObject]@{
          Offset = $match.Index
          Length = $match.Length
          Replacement = "[$keepType]`$$varName"
          RemovedType = if ($keepType -eq $type1) { $type2 } else { $type1 }
        }
      }

      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
        Write-Verbose "Removed conflicting type attribute: $($replacement.RemovedType)"
      }

      return $fixed
    }
  }
  catch {
    Write-Verbose "Multiple type attributes fix failed: $_"
  }

  return $Content
}

function Invoke-PSCredentialTypeFix {
  <#
    .SYNOPSIS
        Adds [PSCredential] type to credential parameters

    .DESCRIPTION
        Parameters with names suggesting credentials should be typed as [PSCredential].
        This function detects credential-related parameters and adds proper typing.

        Detects parameters named:
        - Credential, Cred
        - UserCredential, ServiceCredential
        - AdminCredential, etc.

    .EXAMPLE
        # BEFORE:
        param($Credential)

        # AFTER:
        param([PSCredential]$Credential)
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

    # Find all parameters
    $params = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ParameterAst]
      }, $true)

    $replacements = @()
    $credentialPatterns = @('Credential', 'Cred')

    foreach ($param in $params) {
      $paramName = $param.Name.VariablePath.UserPath

      # Check if parameter name suggests it's a credential
      $isCredentialParam = $false
      foreach ($pattern in $credentialPatterns) {
        if ($paramName -match $pattern) {
          $isCredentialParam = $true
          break
        }
      }

      if ($isCredentialParam) {
        # Check if it already has a type
        $hasType = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.Language.TypeConstraintAst] }

        if (-not $hasType) {
          # Add [PSCredential] type
          $paramText = $param.Extent.Text
          $newParamText = "[PSCredential]$paramText"

          $replacements += [PSCustomObject]@{
            Offset = $param.Extent.StartOffset
            Length = $param.Extent.Text.Length
            Replacement = $newParamText
            ParamName = $paramName
          }
        }
      }
    }

    if ($replacements.Count -gt 0) {
      $fixed = $Content
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
        Write-Verbose "Added [PSCredential] type to parameter: $($replacement.ParamName)"
      }
      return $fixed
    }
  }
  catch {
    Write-Verbose "PSCredential type fix failed: $_"
  }

  return $Content
}

# Export all type safety fix functions
Export-ModuleMember -Function @(
  'Invoke-AutomaticVariableFix',
  'Invoke-MultipleTypeAttributesFix',
  'Invoke-PSCredentialTypeFix'
)
