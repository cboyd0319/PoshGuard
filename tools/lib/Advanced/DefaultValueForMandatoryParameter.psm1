# DefaultValueForMandatoryParameter.psm1
# Implements PSAvoidDefaultValueForMandatoryParameter auto-fix
# Removes default values from mandatory parameters

function Invoke-DefaultValueForMandatoryParameterFix {
  <#
    .SYNOPSIS
        Removes default values from mandatory parameters.
    
    .DESCRIPTION
        Detects parameters marked as Mandatory=$true that have default values
        and removes the default value assignment. This is a logical error as
        mandatory parameters will always receive a value from the caller.
    
    .PARAMETER ScriptContent
        The PowerShell script content to analyze and fix.
    
    .EXAMPLE
        # Before:
        param(
            [Parameter(Mandatory=$true)]
            [string]$Name = "DefaultValue"
        )
        
        # After:
        param(
            [Parameter(Mandatory=$true)]
            [string]$Name
        )
    
    .NOTES
        Rule: PSAvoidDefaultValueForMandatoryParameter
        Severity: Warning
        Category: Best Practices / Parameter Management
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$ScriptContent
  )
    
  if ([string]::IsNullOrWhiteSpace($ScriptContent)) {
    return $ScriptContent
  }
    
  try {
    # Parse script into AST
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $ScriptContent,
      [ref]$null,
      [ref]$null
    )
        
    # Find all function definitions
    $functionAsts = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)
        
    if (-not $functionAsts) {
      return $ScriptContent
    }
        
    # Track changes to make (work backwards to preserve offsets)
    $changes = @()
        
    foreach ($funcAst in $functionAsts) {
      # Skip if no param block
      if (-not $funcAst.Body.ParamBlock -or 
        -not $funcAst.Body.ParamBlock.Parameters) {
        continue
      }
            
      foreach ($paramAst in $funcAst.Body.ParamBlock.Parameters) {
        # Skip if no default value
        if (-not $paramAst.DefaultValue) {
          continue
        }
                
        # Check if parameter is mandatory
        $isMandatory = Test-ParameterMandatory -ParameterAst $paramAst
                
        if ($isMandatory) {
          # Found a mandatory parameter with a default value
          # We need to remove the default value
                    
          # Get the extent of the default value assignment (including the = sign)
          $paramNameEnd = $paramAst.Name.Extent.EndOffset
          # Find the = sign (it's between the param name and default value)
                                        
          # The range to remove is from the end of param name to end of default value
          # But we need to be careful with whitespace
          $removeStart = $paramNameEnd
          $removeEnd = $paramAst.DefaultValue.Extent.EndOffset
                    
          $changes += @{
            Start = $removeStart
            End = $removeEnd
            ParamName = $paramAst.Name.VariablePath.UserPath
          }
        }
      }
    }
        
    # Apply changes in reverse order (to preserve offsets)
    $modifiedContent = $ScriptContent
    foreach ($change in ($changes | Sort-Object -Property End -Descending)) {
      $before = $modifiedContent.Substring(0, $change.Start)
      $after = $modifiedContent.Substring($change.End)
      $modifiedContent = $before + $after
    }
        
    return $modifiedContent
        
  } catch {
    Write-Warning "Failed to process DefaultValueForMandatoryParameter: $_"
    return $ScriptContent
  }
}

function Test-ParameterMandatory {
  <#
    .SYNOPSIS
        Tests if a parameter has Mandatory=$true attribute.
    
    .PARAMETER ParameterAst
        The ParameterAst to check.
    
    .OUTPUTS
        [bool] True if parameter is mandatory, False otherwise.
    #>
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.Language.ParameterAst]$ParameterAst
  )
    
  foreach ($attribute in $ParameterAst.Attributes) {
    if ($attribute -is [System.Management.Automation.Language.AttributeAst]) {
      $typeName = $attribute.TypeName.GetReflectionType()
            
      # Check if it's a Parameter attribute
      if ($typeName -eq [System.Management.Automation.ParameterAttribute] -or
        $attribute.TypeName.Name -eq 'Parameter') {
                
        # Check for Mandatory named argument
        if ($attribute.NamedArguments) {
          foreach ($namedArg in $attribute.NamedArguments) {
            if ($namedArg.ArgumentName -eq 'Mandatory') {
              # Check the value
              if ($namedArg.ExpressionOmitted) {
                # [Parameter(Mandatory)] means true
                return $true
              }
                            
              $argText = $namedArg.Argument.Extent.Text
              if ($argText -eq '$true' -or $argText -eq '1') {
                return $true
              }
                            
              # Handle numeric values (anything non-zero is true)
              $numValue = 0
              if ([int]::TryParse($argText, [ref]$numValue) -and $numValue -ne 0) {
                return $true
              }
            }
          }
        }
      }
    }
  }
    
  return $false
}

Export-ModuleMember -Function Invoke-DefaultValueForMandatoryParameterFix
