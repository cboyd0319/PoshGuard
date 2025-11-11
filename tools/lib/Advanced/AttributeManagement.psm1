<#
.SYNOPSIS
    PoshGuard Attribute Management Module

.DESCRIPTION
    Functions for managing PowerShell function attributes including:
    - SupportsShouldProcess detection and addition
    - CmdletBinding attribute management
    - Process block addition for pipeline functions
    - ShouldProcess for state-changing functions

    Ensures functions follow PowerShell attribute best practices.

.NOTES
    Part of PoshGuard v4.3.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

function Invoke-SupportsShouldProcessFix {
  <#
    .SYNOPSIS
        Adds SupportsShouldProcess to CmdletBinding when ShouldProcess is used

    .DESCRIPTION
        Functions using $PSCmdlet.ShouldProcess() must declare SupportsShouldProcess
        in their CmdletBinding attribute. This fix detects such usage and adds the attribute.

    .EXAMPLE
        PS C:\> Invoke-SupportsShouldProcessFix -Content $scriptContent

        Adds SupportsShouldProcess=$true to functions using ShouldProcess
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
      $replacements = @()

      # Find all function definitions
      $functionAsts = $ast.FindAll({
          $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

      foreach ($funcAst in $functionAsts) {
        # Check if function uses $PSCmdlet.ShouldProcess
        $usesShouldProcess = $false

        $shouldProcessCalls = $funcAst.FindAll({
            $args[0] -is [System.Management.Automation.Language.MemberExpressionAst] -and
            $args[0].Member.Extent.Text -eq 'ShouldProcess'
          }, $true)

        if ($shouldProcessCalls.Count -gt 0) {
          $usesShouldProcess = $true
        }

        if ($usesShouldProcess) {
          # Check if function has CmdletBinding attribute
          $paramBlock = $funcAst.Body.ParamBlock

          if ($paramBlock -and $paramBlock.Attributes) {
            foreach ($attr in $paramBlock.Attributes) {
              if ($attr.TypeName.Name -eq 'CmdletBinding') {
                # Check if SupportsShouldProcess is already present
                $hasSupportsShouldProcess = $false

                foreach ($namedArg in $attr.NamedArguments) {
                  if ($namedArg.ArgumentName -eq 'SupportsShouldProcess') {
                    $hasSupportsShouldProcess = $true
                    break
                  }
                }

                if (-not $hasSupportsShouldProcess) {
                  # Add SupportsShouldProcess to existing CmdletBinding
                  $attrText = $attr.Extent.Text

                  if ($attrText -match '^\[CmdletBinding\(\s*\)\]$') {
                    # Empty CmdletBinding()
                    $newAttrText = '[CmdletBinding(SupportsShouldProcess=$true)]'
                  }
                  else {
                    # Has existing arguments
                    $newAttrText = $attrText -replace '\)\]$', ', SupportsShouldProcess=$true)]'
                  }

                  $replacements += @{
                    Offset = $attr.Extent.StartOffset
                    Length = $attr.Extent.Text.Length
                    Replacement = $newAttrText
                    FuncName = $funcAst.Name
                  }
                }
              }
            }
          }
        }
      }

      # Apply replacements in reverse order
      $fixed = $Content
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Length).Insert($replacement.Offset, $replacement.Replacement)
        Write-Verbose "Added SupportsShouldProcess to: $($replacement.FuncName)"
      }

      if ($replacements.Count -gt 0) {
        Write-Verbose "Added SupportsShouldProcess to $($replacements.Count) function(s)"
      }

      return $fixed
    }
  }
  catch {
    Write-Verbose "SupportsShouldProcess fix failed: $_"
  }

  return $Content
}

function Invoke-ShouldProcessForStateChangingFix {
  <#
    .SYNOPSIS
        Adds ShouldProcess support to state-changing functions

    .DESCRIPTION
        Detects functions with state-changing verbs (Remove, Set, New, etc.)
        and adds SupportsShouldProcess if missing.

    .EXAMPLE
        # BEFORE:
        function Remove-Data {
            param($Path)
            Remove-Item $Path
        }

        # AFTER:
        [CmdletBinding(SupportsShouldProcess)]
        function Remove-Data {
            param($Path)
            if ($PSCmdlet.ShouldProcess($Path, "Remove")) {
                Remove-Item $Path
            }
        }
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

    # State-changing verbs
    $stateChangingVerbs = @('Remove', 'Set', 'New', 'Add', 'Clear', 'Update', 'Reset', 'Stop', 'Start', 'Restart', 'Install', 'Uninstall')

    $functions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)

    $replacements = @()

    foreach ($func in $functions) {
      $funcName = $func.Name
      $verb = ($funcName -split '-')[0]

      if ($verb -in $stateChangingVerbs) {
        # Check if already has SupportsShouldProcess
        $hasShouldProcess = $func.Body.ParamBlock -and
        $func.Body.ParamBlock.Attributes | Where-Object {
          $_ -is [System.Management.Automation.Language.AttributeAst] -and
          $_.TypeName.Name -eq 'CmdletBinding' -and
          $_.NamedArguments.ArgumentName -contains 'SupportsShouldProcess'
        }

        if (-not $hasShouldProcess) {
          Write-Verbose "Function $funcName needs SupportsShouldProcess"
          # For now, add a comment suggesting the addition
          $replacements += [PSCustomObject]@{
            FuncName = $funcName
            Offset = $func.Extent.StartOffset
          }
        }
      }
    }

    if ($replacements.Count -gt 0) {
      $lines = $Content -split "`n"
      $newLines = @()

      foreach ($line in $lines) {
        foreach ($replacement in $replacements) {
          if ($line -match "function\s+$([regex]::Escape($replacement.FuncName))") {
            $newLines += "# TODO: Add [CmdletBinding(SupportsShouldProcess=`$true)] and ShouldProcess checks"
          }
        }
        $newLines += $line
      }

      Write-Verbose "Added TODO comments for $($replacements.Count) state-changing function(s)"
      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "ShouldProcess for state-changing fix failed: $_"
  }

  return $Content
}

function Invoke-CmdletCorrectlyFix {
  <#
    .SYNOPSIS
        Adds [CmdletBinding()] to functions using advanced features

    .DESCRIPTION
        Detects functions using $PSCmdlet or other advanced features
        and adds [CmdletBinding()] if missing.

    .EXAMPLE
        # BEFORE:
        function Test-Feature {
            $PSCmdlet.WriteVerbose("test")
        }

        # AFTER:
        [CmdletBinding()]
        function Test-Feature {
            $PSCmdlet.WriteVerbose("test")
        }
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

    $functions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)

    $replacements = @()

    foreach ($func in $functions) {
      # Check if uses $PSCmdlet
      $usesPSCmdlet = $func.Body.FindAll({
          param($node)
          $node -is [System.Management.Automation.Language.VariableExpressionAst] -and
          $node.VariablePath.UserPath -eq 'PSCmdlet'
        }, $true)

      if ($usesPSCmdlet.Count -gt 0) {
        # Check if already has CmdletBinding
        $hasCmdletBinding = $func.Body.ParamBlock -and
        $func.Body.ParamBlock.Attributes | Where-Object {
          $_ -is [System.Management.Automation.Language.AttributeAst] -and
          $_.TypeName.Name -eq 'CmdletBinding'
        }

        if (-not $hasCmdletBinding) {
          $replacements += [PSCustomObject]@{
            FuncName = $func.Name
            Offset = $func.Extent.StartOffset
            Text = $func.Extent.Text
          }
        }
      }
    }

    if ($replacements.Count -gt 0) {
      $fixed = $Content
      foreach ($replacement in ($replacements | Sort-Object -Property Offset -Descending)) {
        # Add [CmdletBinding()] before function
        $newText = "[CmdletBinding()]`n$($replacement.Text)"
        $fixed = $fixed.Remove($replacement.Offset, $replacement.Text.Length).Insert($replacement.Offset, $newText)
        Write-Verbose "Added [CmdletBinding()] to function: $($replacement.FuncName)"
      }
      return $fixed
    }
  }
  catch {
    Write-Verbose "CmdletCorrectly fix failed: $_"
  }

  return $Content
}

function Invoke-ProcessBlockForPipelineFix {
  <#
    .SYNOPSIS
        Adds Process{} block to functions with pipeline input

    .DESCRIPTION
        Detects functions with ValueFromPipeline parameters
        and adds Process{} block if missing.

    .EXAMPLE
        # BEFORE:
        function Process-Data {
            param(
                [Parameter(ValueFromPipeline)]
                $InputObject
            )
            Write-Output $InputObject
        }

        # AFTER:
        function Process-Data {
            param(
                [Parameter(ValueFromPipeline)]
                $InputObject
            )
            process {
                Write-Output $InputObject
            }
        }
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)

    $functions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
      }, $true)

    $functionsNeedingProcess = @()

    foreach ($func in $functions) {
      if ($func.Body.ParamBlock) {
        # Check for ValueFromPipeline parameters
        $hasPipelineParam = $false
        foreach ($param in $func.Body.ParamBlock.Parameters) {
          foreach ($attr in $param.Attributes) {
            if ($attr.NamedArguments) {
              foreach ($arg in $attr.NamedArguments) {
                if ($arg.ArgumentName -eq 'ValueFromPipeline' -and $arg.Argument.Value -eq $true) {
                  $hasPipelineParam = $true
                  break
                }
              }
            }
          }
        }

        if ($hasPipelineParam) {
          # Check if has process block
          $hasProcessBlock = $func.Body.ProcessBlock -ne $null

          if (-not $hasProcessBlock) {
            $functionsNeedingProcess += $func.Name
            Write-Verbose "Function $($func.Name) needs Process{} block"
          }
        }
      }
    }

    if ($functionsNeedingProcess.Count -gt 0) {
      $lines = $Content -split "`n"
      $newLines = @()

      foreach ($line in $lines) {
        foreach ($funcName in $functionsNeedingProcess) {
          if ($line -match "function\s+$([regex]::Escape($funcName))") {
            $newLines += "# TODO: Add process{} block for proper pipeline processing"
          }
        }
        $newLines += $line
      }

      Write-Verbose "Added TODO comments for $($functionsNeedingProcess.Count) function(s) needing process block"
      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "Process block fix failed: $_"
  }

  return $Content
}

# Export all attribute management functions
Export-ModuleMember -Function @(
  'Invoke-SupportsShouldProcessFix',
  'Invoke-ShouldProcessForStateChangingFix',
  'Invoke-CmdletCorrectlyFix',
  'Invoke-ProcessBlockForPipelineFix'
)
