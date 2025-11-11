<#
.SYNOPSIS
    PoshGuard Parameter Management Module

.DESCRIPTION
    Parameter validation, typing, and cleanup functions.
    Handles parameter-level fixes including:
    - Reserved parameter renaming
    - Switch parameter default removal
    - Unused parameter detection
    - HelpMessage validation

.NOTES
    Part of PoshGuard v4.3.0
    Split from Advanced.psm1 for better maintainability
#>

Set-StrictMode -Version Latest

# Import ASTHelper module for reusable AST operations
$ASTHelperPath = Join-Path $PSScriptRoot '../ASTHelper.psm1'
if (Test-Path $ASTHelperPath) {
  Import-Module $ASTHelperPath -Force -ErrorAction SilentlyContinue
}

function Invoke-ReservedParamsFix {
  <#
    .SYNOPSIS
        Renames parameters that conflict with PowerShell reserved/common parameter names

    .DESCRIPTION
        PowerShell has reserved parameter names (Common Parameters) that should not be used
        as custom parameters. This function detects such conflicts and renames them.

        Common Parameters:
        - Verbose, Debug, ErrorAction, WarningAction, InformationAction
        - ErrorVariable, WarningVariable, InformationVariable
        - OutVariable, OutBuffer, PipelineVariable

        Renaming Strategy:
        - Verbose → VerboseOutput
        - Debug → DebugMode
        - ErrorAction → ErrorHandling
        - WarningAction → WarningHandling
        - InformationAction → InformationHandling
        - ErrorVariable → ErrorVar
        - WarningVariable → WarningVar
        - InformationVariable → InformationVar
        - OutVariable → OutputVariable
        - OutBuffer → OutputBuffer
        - PipelineVariable → PipelineVar

    .EXAMPLE
        PS C:\> Invoke-ReservedParamsFix -Content $scriptContent

        Renames reserved parameter names to avoid conflicts
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  # Reserved parameter name mappings
  $reservedMappings = @{
    'Verbose' = 'VerboseOutput'
    'Debug' = 'DebugMode'
    'ErrorAction' = 'ErrorHandling'
    'WarningAction' = 'WarningHandling'
    'InformationAction' = 'InformationHandling'
    'ErrorVariable' = 'ErrorVar'
    'WarningVariable' = 'WarningVar'
    'InformationVariable' = 'InformationVar'
    'OutVariable' = 'OutputVariable'
    'OutBuffer' = 'OutputBuffer'
    'PipelineVariable' = 'PipelineVar'
    'WhatIf' = 'WhatIfMode'
    'Confirm' = 'ConfirmAction'
  }

  try {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

    if ($errors.Count -eq 0) {
      $replacements = [System.Collections.ArrayList]::new()

      # Find all function definitions
      $functions = $ast.FindAll({
          $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

      foreach ($funcAst in $functions) {
        # Get all parameters in this function
        $parameters = $funcAst.FindAll({
            $args[0] -is [System.Management.Automation.Language.ParameterAst]
          }, $true)

        foreach ($paramAst in $parameters) {
          $paramName = $paramAst.Name.VariablePath.UserPath

          # Check if parameter name conflicts with reserved names
          if ($reservedMappings.ContainsKey($paramName)) {
            $newParamName = $reservedMappings[$paramName]

            # Find all references to this parameter within the function
            $varRefs = $funcAst.FindAll({
                $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
                $args[0].VariablePath.UserPath -eq $paramName
              }, $true)

            # Add replacements for all references (sorted by position descending)
            foreach ($varRef in $varRefs) {
              $extent = $varRef.Extent
              $newText = "`$$newParamName"

              $replacements.Add([PSCustomObject]@{
                  StartOffset = $extent.StartOffset
                  EndOffset = $extent.EndOffset
                  OldText = $oldText
                  NewText = $newText
                }) | Out-Null
            }

            Write-Verbose "Renaming reserved parameter: $paramName → $newParamName in function $($funcAst.Name)"
          }
        }
      }

      # Apply replacements in reverse order (end to start)
      if ($replacements.Count -gt 0) {
        $replacements = $replacements | Sort-Object -Property StartOffset -Descending
        $fixed = $Content

        foreach ($replacement in $replacements) {
          $before = $fixed.Substring(0, $replacement.StartOffset)
          $after = $fixed.Substring($replacement.EndOffset)
          $fixed = $before + $replacement.NewText + $after
        }

        Write-Verbose "Renamed $($replacements.Count) reserved parameter reference(s)"
        return $fixed
      }
    }
  }
  catch {
    Write-Verbose "Reserved params fix failed: $_"
  }

  return $Content
}

function Invoke-SwitchParameterDefaultFix {
  <#
    .SYNOPSIS
        Removes default values from [switch] parameters

    .DESCRIPTION
        Switch parameters should not have default values (= $true or = $false).
        This is a PowerShell best practice violation that can cause unexpected behavior.

        Removes:
        - [switch]$MySwitch = $true
        - [switch]$MySwitch = $false

        Converts to:
        - [switch]$MySwitch

    .EXAMPLE
        PS C:\> Invoke-SwitchParameterDefaultFix -Content $scriptContent

        Removes default values from switch parameters
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

    if ($errors.Count -eq 0) {
      $replacements = [System.Collections.ArrayList]::new()

      # Find all parameters with [switch] type
      $parameters = $ast.FindAll({
          $args[0] -is [System.Management.Automation.Language.ParameterAst]
        }, $true)

      foreach ($paramAst in $parameters) {
        # Check if parameter has [switch] attribute
        $hasSwitch = $false
        foreach ($attr in $paramAst.Attributes) {
          if ($attr.TypeName.FullName -eq 'switch') {
            $hasSwitch = $true
            break
          }
        }

        if ($hasSwitch -and $paramAst.DefaultValue) {
          # Has a default value - remove it
          $paramName = $paramAst.Name.VariablePath.UserPath

          # Get the text from parameter start to default value end
          $defaultValueEndOffset = $paramAst.DefaultValue.Extent.EndOffset

          # Find the = sign before the default value
          $textBetween = $Content.Substring($paramAst.Name.Extent.EndOffset,
            $paramAst.DefaultValue.Extent.StartOffset - $paramAst.Name.Extent.EndOffset)

          if ($textBetween -match '\s*=\s*') {
            # Remove everything from the end of variable name to end of default value
            $defaultValueEndOffset - $paramAst.Name.Extent.EndOffset)

          $replacements.Add([PSCustomObject]@{
              StartOffset = $paramAst.Name.Extent.EndOffset
              EndOffset = $defaultValueEndOffset
              OldText = $oldText
              NewText = ''
            }) | Out-Null

          Write-Verbose "Removing default value from switch parameter: $paramName"
        }
      }
    }

    # Apply replacements in reverse order (end to start)
    if ($replacements.Count -gt 0) {
      $replacements = $replacements | Sort-Object -Property StartOffset -Descending
      $fixed = $Content

      foreach ($replacement in $replacements) {
        $before = $fixed.Substring(0, $replacement.StartOffset)
        $after = $fixed.Substring($replacement.EndOffset)
        $fixed = $before + $replacement.NewText + $after
      }

      Write-Verbose "Removed default values from $($replacements.Count) switch parameter(s)"
      return $fixed
    }
  }
}
catch {
  Write-Verbose "Switch parameter default fix failed: $_"
}

return $Content
}

function Invoke-UnusedParameterFix {
  <#
    .SYNOPSIS
        Comments out unused parameters in functions

    .DESCRIPTION
        Detects parameters that are declared but never used in the function body
        and comments them out with a note explaining they were unused.

        Detection Logic:
        - Finds all ParameterAst nodes in function
        - Finds all VariableExpressionAst references in function body
        - Identifies parameters with zero references
        - Comments out unused parameters with descriptive note

        Edge Cases Handled:
        - Splatting (@PSBoundParameters)
        - $PSCmdlet automatic variable
        - Parameters used in nested functions

    .EXAMPLE
        PS C:\> Invoke-UnusedParameterFix -Content $scriptContent

        Comments out unused parameters with explanatory notes
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

    if ($errors.Count -eq 0) {
      $replacements = [System.Collections.ArrayList]::new()

      # Find all function definitions
      $functions = $ast.FindAll({
          $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

      foreach ($funcAst in $functions) {
        # Get all parameters in this function
        $parameters = $funcAst.FindAll({
            $args[0] -is [System.Management.Automation.Language.ParameterAst]
          }, $true)

        # Get all variable references in the function body
        $varRefs = $funcAst.Body.FindAll({
            $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
          }, $true)

        # Check for splatting or $PSBoundParameters usage (means all params might be used)
        $splattingRefs = @($funcAst.Body.FindAll({
              $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
              ($args[0].VariablePath.UserPath -eq 'PSBoundParameters' -or $args[0].Splatted)
            }, $true))
        $usesSplatting = $splattingRefs.Count -gt 0

        if ($usesSplatting) {
          # Skip this function - splatting means params might be used indirectly
          continue
        }

        foreach ($paramAst in $parameters) {
          $paramName = $paramAst.Name.VariablePath.UserPath

          # Count references to this parameter in function body
          $paramRefs = @($varRefs | Where-Object {
              $_.VariablePath.UserPath -eq $paramName
            })
          $refCount = $paramRefs.Count

          if ($refCount -eq 0) {
            # Parameter is unused - comment it out
            $paramExtent = $paramAst.Extent
            $paramText = $paramExtent.Text

            # Get the full line to check indentation
            $startLine = $paramExtent.StartLineNumber - 1
            $lines = $Content -split "`r?`n"
            $lineText = $lines[$startLine]

            # Preserve indentation
            if ($lineText -match '^(\s+)') {
            }

            # Create commented version with note
            $commentedParam = "# REMOVED (unused parameter): $paramText"

            $replacements.Add([PSCustomObject]@{
                StartOffset = $paramExtent.StartOffset
                EndOffset = $paramExtent.EndOffset
                OldText = $paramText
                NewText = $commentedParam
              }) | Out-Null

            Write-Verbose "Commenting out unused parameter: $paramName in function $($funcAst.Name)"
          }
        }
      }

      # Apply replacements in reverse order (end to start)
      if ($replacements.Count -gt 0) {
        $replacements = $replacements | Sort-Object -Property StartOffset -Descending
        $fixed = $Content

        foreach ($replacement in $replacements) {
          $before = $fixed.Substring(0, $replacement.StartOffset)
          $after = $fixed.Substring($replacement.EndOffset)
          $fixed = $before + $replacement.NewText + $after
        }

        Write-Verbose "Commented out $($replacements.Count) unused parameter(s)"
        return $fixed
      }
    }
  }
  catch {
    Write-Verbose "Unused parameter fix failed: $_"
  }

  return $Content
}

function Invoke-NullHelpMessageFix {
  <#
    .SYNOPSIS
        Fixes null or empty HelpMessage attributes

    .DESCRIPTION
        Detects [Parameter(HelpMessage="")] or [Parameter(HelpMessage=$null)]
        and replaces with a meaningful placeholder message.

    .EXAMPLE
        # BEFORE:
        param(
            [Parameter(HelpMessage="")]
            [string]$Name
        )

        # AFTER:
        param(
            [Parameter(HelpMessage="Please provide a value for Name")]
            [string]$Name
        )
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

    # Find all parameters with HelpMessage attribute
    $params = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ParameterAst]
      }, $true)

    foreach ($param in $params) {
      $paramName = $param.Name.VariablePath.UserPath

      # Look for Parameter attribute with HelpMessage
      foreach ($attr in $param.Attributes) {
        if ($attr -is [System.Management.Automation.Language.AttributeAst]) {
          if ($attr.TypeName.Name -eq 'Parameter') {
            # Check named arguments for HelpMessage
            foreach ($namedArg in $attr.NamedArguments) {
              if ($namedArg.ArgumentName -eq 'HelpMessage') {
                $argValue = $namedArg.Argument.Extent.Text

                # Check if HelpMessage is empty or null
                if ($argValue -match '^["'']?\s*["'']?$' -or $argValue -eq '$null') {
                  $newMessage = "Please provide a value for $paramName"
                  $newText = "HelpMessage=`"$newMessage`""

                  $replacements += [PSCustomObject]@{
                    Offset = $namedArg.Extent.StartOffset
                    Length = $namedArg.Extent.Text.Length
                    Replacement = $newText
                    ParamName = $paramName
                  }
                }
              }
            }
          }
        }
      }
    }

    if ($replacements.Count -gt 0) {
      $fixed = $Content
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
        Write-Verbose "Fixed empty HelpMessage for parameter: $($replacement.ParamName)"
      }
      return $fixed
    }
  }
  catch {
    Write-Verbose "Null help message fix failed: $_"
  }

  return $Content
}

# Export all parameter management functions
Export-ModuleMember -Function @(
  'Invoke-ReservedParamsFix',
  'Invoke-SwitchParameterDefaultFix',
  'Invoke-UnusedParameterFix',
  'Invoke-NullHelpMessageFix'
)
