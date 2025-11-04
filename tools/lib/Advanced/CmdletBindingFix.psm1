# CmdletBindingFix.psm1
# Fixed implementation of PSUseCmdletCorrectly - places [CmdletBinding()] inside param block

function Invoke-CmdletBindingFix {
  <#
    .SYNOPSIS
        Adds [CmdletBinding()] to functions using advanced features (FIXED VERSION).
    
    .DESCRIPTION
        Detects functions using $PSCmdlet or other advanced features and adds
        [CmdletBinding()] inside the param() block if missing.
        
        This is the FIXED version that correctly places [CmdletBinding()] inside
        the param block, not outside the function definition.
    
    .PARAMETER Content
        The PowerShell script content to analyze and fix.
    
    .EXAMPLE
        # Before:
        function Test-Feature {
            param($Name)
            $PSCmdlet.WriteVerbose("test")
        }
        
        # After:
        function Test-Feature {
            [CmdletBinding()]
            param($Name)
            $PSCmdlet.WriteVerbose("test")
        }
    
    .NOTES
        Rule: PSUseCmdletCorrectly
        Severity: Warning
        Bug Fix: This replaces the broken Invoke-CmdletCorrectlyFix
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Content
  )
    
  if ([string]::IsNullOrWhiteSpace($Content)) {
    return $Content
  }
    
  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$null,
      [ref]$null
    )
        
    $functions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)
        
    if (-not $functions) {
      return $Content
    }
        
    $replacements = @()
        
    foreach ($func in $functions) {
      # Check if function uses $PSCmdlet
      $usesPSCmdlet = $func.Body.FindAll({
          param($node)
          $node -is [System.Management.Automation.Language.VariableExpressionAst] -and
          $node.VariablePath.UserPath -eq 'PSCmdlet'
        }, $true)
            
      if ($usesPSCmdlet.Count -eq 0) {
        continue
      }
            
      # Check if already has CmdletBinding
      $hasCmdletBinding = $false
      if ($func.Body.ParamBlock -and $func.Body.ParamBlock.Attributes) {
        $hasCmdletBinding = $func.Body.ParamBlock.Attributes | Where-Object {
          $_ -is [System.Management.Automation.Language.AttributeAst] -and
          $_.TypeName.Name -eq 'CmdletBinding'
        }
      }
            
      if ($hasCmdletBinding) {
        continue
      }
            
      # Need to add [CmdletBinding()]
      if ($func.Body.ParamBlock) {
        # Has param block - add [CmdletBinding()] right before param keyword
        $paramBlockStart = $func.Body.ParamBlock.Extent.StartOffset
                
        $replacements += @{
          Offset = $paramBlockStart
          Length = 0
          NewText = "[CmdletBinding()]`n    "
          FuncName = $func.Name
        }
      } else {
        # No param block - add param block with [CmdletBinding()]
        # Insert after function signature, before body
        $bodyStart = $func.Body.Extent.StartOffset + 1  # After opening brace
                
        $replacements += @{
          Offset = $bodyStart
          Length = 0
          NewText = "`n    [CmdletBinding()]`n    param()`n"
          FuncName = $func.Name
        }
      }
    }
        
    if ($replacements.Count -eq 0) {
      return $Content
    }
        
    # Apply replacements in reverse order
    $fixed = $Content
    foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
      $before = $fixed.Substring(0, $replacement.Offset)
      $after = $fixed.Substring($replacement.Offset + $replacement.Length)
      $fixed = $before + $replacement.NewText + $after
            
      Write-Verbose "Added [CmdletBinding()] to function: $($replacement.FuncName)"
    }
        
    return $fixed
        
  } catch {
    Write-Warning "CmdletBinding fix failed: $_"
    return $Content
  }
}

Export-ModuleMember -Function Invoke-CmdletBindingFix
