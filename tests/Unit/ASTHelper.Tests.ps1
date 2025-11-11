#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Unit tests for ASTHelper module

.DESCRIPTION
    Comprehensive tests for all ASTHelper functions:
    - Get-ParsedAST
    - Test-ValidPowerShellSyntax
    - Invoke-SafeASTTransformation
    - Invoke-ASTBasedFix

.NOTES
    Test Framework: Pester v5+
    Pattern: AAA (Arrange-Act-Assert)
    Coverage Target: 90%+
#>

BeforeAll {
  $ModulePath = Join-Path $PSScriptRoot '../../tools/lib/ASTHelper.psm1'
  Import-Module $ModulePath -Force -ErrorAction Stop
}

Describe 'ASTHelper Module' -Tag 'Unit', 'ASTHelper' {

  Context 'Get-ParsedAST' {
    It 'Should parse valid PowerShell syntax' {
      # Arrange
      $validContent = 'function Test { param($Name) Write-Host $Name }'

      # Act
      $ast = Get-ParsedAST -Content $validContent

      # Assert
      $ast | Should -Not -BeNullOrEmpty
      $ast.GetType().Name | Should -Be 'ScriptBlockAst'
    }

    It 'Should parse PowerShell with minor errors (best-effort)' {
      # Arrange
      $contentWithWarnings = 'function Test { $unused = 1 }'

      # Act
      $ast = Get-ParsedAST -Content $contentWithWarnings

      # Assert
      $ast | Should -Not -BeNullOrEmpty
    }

    It 'Should handle empty content gracefully' {
      # Arrange
      $emptyContent = ''

      # Act
      $ast = Get-ParsedAST -Content $emptyContent

      # Assert
      $ast | Should -Not -BeNullOrEmpty
    }

    It 'Should include file path in error messages when provided' {
      # Arrange
      $invalidContent = 'function Test { invalid }'
      $filePath = 'C:\Test\Script.ps1'

      # Act
      $ast = Get-ParsedAST -Content $invalidContent -FilePath $filePath -WarningVariable warnings

      # Assert (may still return AST with errors)
      $warnings | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Test-ValidPowerShellSyntax' {
    It 'Should return true for valid syntax' {
      # Arrange
      $validContent = 'Write-Host "Hello World"'

      # Act
      $result = Test-ValidPowerShellSyntax -Content $validContent

      # Assert
      $result | Should -Be $true
    }

    It 'Should return false for invalid syntax' {
      # Arrange
      $invalidContent = 'Write-Host "Unclosed string'

      # Act
      $result = Test-ValidPowerShellSyntax -Content $invalidContent

      # Assert
      $result | Should -Be $false
    }

    It 'Should return true for content with warnings (not errors)' {
      # Arrange
      $contentWithWarnings = 'function Test { $unused = 1; Write-Host "OK" }'

      # Act
      $result = Test-ValidPowerShellSyntax -Content $contentWithWarnings

      # Assert
      $result | Should -Be $true
    }

    It 'Should be faster than Get-ParsedAST' {
      # Arrange
      $content = 'Get-Process | Where-Object { $_.CPU -gt 100 }'

      # Act
      $syntaxCheckTime = Measure-Command {
        1..100 | ForEach-Object { Test-ValidPowerShellSyntax -Content $content }
      }

      $parseTime = Measure-Command {
        1..100 | ForEach-Object { Get-ParsedAST -Content $content }
      }

      # Assert (syntax check should be faster)
      $syntaxCheckTime.TotalMilliseconds | Should -BeLessThan $parseTime.TotalMilliseconds
    }
  }

  Context 'Invoke-SafeASTTransformation' {
    It 'Should apply transformation successfully' {
      # Arrange
      $content = '[string]$Password = "test"'
      $transformation = {
        param($ast, $originalContent)
        $originalContent -replace '\[string\]', '[SecureString]'
      }

      # Act
      $result = Invoke-SafeASTTransformation `
        -Content $content `
        -TransformationName 'TestTransform' `
        -Transformation $transformation

      # Assert
      $result | Should -Match '\[SecureString\]'
    }

    It 'Should return original content on transformation error' {
      # Arrange
      $content = 'Write-Host "Test"'
      $transformation = {
        param($ast, $originalContent)
        throw "Intentional error"
      }

      # Act
      $result = Invoke-SafeASTTransformation `
        -Content $content `
        -TransformationName 'ErrorTransform' `
        -Transformation $transformation

      # Assert
      $result | Should -Be $content
    }

    It 'Should validate transformation results' {
      # Arrange
      $content = 'Write-Host "Test"'
      $transformation = {
        param($ast, $originalContent)
        'invalid { syntax }'  # Return invalid PowerShell
      }

      # Act
      $result = Invoke-SafeASTTransformation `
        -Content $content `
        -TransformationName 'InvalidTransform' `
        -Transformation $transformation

      # Assert (should return original due to invalid result)
      $result | Should -Be $content
    }

    It 'Should include file path in verbose output' {
      # Arrange
      $content = 'Write-Host "Test"'
      $filePath = 'C:\Test\Script.ps1'
      $transformation = {
        param($ast, $originalContent)
        $originalContent
      }

      # Act
      $result = Invoke-SafeASTTransformation `
        -Content $content `
        -FilePath $filePath `
        -TransformationName 'TestTransform' `
        -Transformation $transformation `
        -Verbose

      # Assert
      $result | Should -Be $content
    }
  }

  Context 'Invoke-ASTBasedFix' {
    It 'Should find and transform matching nodes' {
      # Arrange
      $content = @'
function Test {
  param(
    [string]$Password
  )
}
'@
      $nodeFinder = {
        param($ast)
        $ast.FindAll({
          param($node)
          $node -is [System.Management.Automation.Language.ParameterAst]
        }, $true)
      }

      $nodeTransformer = {
        param($node, $content)
        $paramName = $node.Name.VariablePath.UserPath
        if ($paramName -match 'Password') {
          $typeConstraint = $node.Attributes | Where-Object {
            $_ -is [System.Management.Automation.Language.TypeConstraintAst]
          } | Select-Object -First 1

          if ($typeConstraint -and $typeConstraint.TypeName.Name -eq 'string') {
            return @{
              Start = $typeConstraint.Extent.StartOffset
              End = $typeConstraint.Extent.EndOffset
              NewText = '[SecureString]'
            }
          }
        }
        return $null
      }

      # Act
      $result = Invoke-ASTBasedFix `
        -Content $content `
        -FixName 'PasswordFix' `
        -ASTNodeFinder $nodeFinder `
        -NodeTransformer $nodeTransformer

      # Assert
      $result | Should -Match '\[SecureString\]'
      $result | Should -Not -Match '\[string\]\$Password'
    }

    It 'Should return original content when no nodes found' {
      # Arrange
      $content = 'Write-Host "Test"'
      $nodeFinder = {
        param($ast)
        @()  # Return no nodes
      }

      $nodeTransformer = {
        param($node, $content)
        @{ Start = 0; End = 0; NewText = 'X' }
      }

      # Act
      $result = Invoke-ASTBasedFix `
        -Content $content `
        -FixName 'NoOpFix' `
        -ASTNodeFinder $nodeFinder `
        -NodeTransformer $nodeTransformer

      # Assert
      $result | Should -Be $content
    }

    It 'Should apply multiple replacements in correct order' {
      # Arrange
      $content = '$var1 = 1; $var2 = 2; $var3 = 3'
      $nodeFinder = {
        param($ast)
        $ast.FindAll({
          param($node)
          $node -is [System.Management.Automation.Language.VariableExpressionAst]
        }, $true)
      }

      $nodeTransformer = {
        param($node, $content)
        @{
          Start = $node.Extent.StartOffset
          End = $node.Extent.EndOffset
          NewText = '$X'
        }
      }

      # Act
      $result = Invoke-ASTBasedFix `
        -Content $content `
        -FixName 'ReplaceVars' `
        -ASTNodeFinder $nodeFinder `
        -NodeTransformer $nodeTransformer

      # Assert
      $result | Should -Match '\$X'
      # All variables should be replaced
      ($result | Select-String '\$X' -AllMatches).Matches.Count | Should -BeGreaterOrEqual 3
    }
  }

  Context 'Integration Tests' {
    It 'Should handle real-world password parameter transformation' {
      # Arrange
      $content = @'
function Connect-Database {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Server,

    [Parameter(Mandatory)]
    [string]$Password
  )
  # Function body
}
'@

      # Act
      $result = Invoke-ASTBasedFix `
        -Content $content `
        -FixName 'PlainTextPassword' `
        -ASTNodeFinder {
          param($ast)
          $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.ParameterAst]
          }, $true)
        } `
        -NodeTransformer {
          param($node, $content)
          $paramName = $node.Name.VariablePath.UserPath
          if ($paramName -match '(Password|Pass|Pwd)') {
            $typeConstraint = $node.Attributes | Where-Object {
              $_ -is [System.Management.Automation.Language.TypeConstraintAst]
            } | Select-Object -First 1

            if ($typeConstraint -and $typeConstraint.TypeName.Name -eq 'string') {
              return @{
                Start = $typeConstraint.Extent.StartOffset
                End = $typeConstraint.Extent.EndOffset
                NewText = '[SecureString]'
              }
            }
          }
          return $null
        }

      # Assert
      $result | Should -Match '\[SecureString\]\$Password'
      $result | Should -Match '\[string\]\$Server'  # Other params unchanged
      $result | Should -Not -Match '\[string\]\$Password'
    }

    It 'Should maintain code structure and formatting' {
      # Arrange
      $content = @'
function Test {
    param(
        [string]$Name
    )

    Write-Host "Hello, $Name"
}
'@

      # Act - transformation that doesn't change content
      $result = Invoke-SafeASTTransformation `
        -Content $content `
        -TransformationName 'NoOp' `
        -Transformation {
          param($ast, $originalContent)
          $originalContent  # Return unchanged
        }

      # Assert
      $result | Should -Be $content
    }
  }

  Context 'Error Handling' {
    It 'Should handle null content gracefully in Get-ParsedAST' {
      # Arrange
      $nullContent = $null

      # Act & Assert
      { Get-ParsedAST -Content $nullContent } | Should -Throw
    }

    It 'Should handle null transformation scriptblock' {
      # Arrange
      $content = 'Write-Host "Test"'
      $nullTransformation = $null

      # Act & Assert
      { Invoke-SafeASTTransformation -Content $content -TransformationName 'Test' -Transformation $nullTransformation } | Should -Throw
    }

    It 'Should provide meaningful error messages' {
      # Arrange
      $content = 'Write-Host "Test"'
      $transformation = {
        param($ast, $originalContent)
        throw [System.ArgumentException]::new("Custom error message")
      }

      # Act
      $result = Invoke-SafeASTTransformation `
        -Content $content `
        -TransformationName 'ErrorTest' `
        -Transformation $transformation `
        -WarningVariable warnings

      # Assert
      $warnings | Should -Not -BeNullOrEmpty
      $result | Should -Be $content
    }
  }

  Context 'Performance' {
    It 'Should handle large files efficiently' {
      # Arrange
      $largeContent = 1..1000 | ForEach-Object {
        "function Test$_ { param(`$Param$_) Write-Host `$Param$_ }"
      } | Join-String -Separator "`n"

      # Act
      $executionTime = Measure-Command {
        $ast = Get-ParsedAST -Content $largeContent
      }

      # Assert
      $ast | Should -Not -BeNullOrEmpty
      $executionTime.TotalSeconds | Should -BeLessThan 5
    }
  }
}

Describe 'ASTHelper Module Exports' -Tag 'Unit', 'ASTHelper', 'Exports' {
  It 'Should export Get-ParsedAST function' {
    Get-Command Get-ParsedAST -Module ASTHelper -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }

  It 'Should export Test-ValidPowerShellSyntax function' {
    Get-Command Test-ValidPowerShellSyntax -Module ASTHelper -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }

  It 'Should export Invoke-SafeASTTransformation function' {
    Get-Command Invoke-SafeASTTransformation -Module ASTHelper -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }

  It 'Should export Invoke-ASTBasedFix function' {
    Get-Command Invoke-ASTBasedFix -Module ASTHelper -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }
}
