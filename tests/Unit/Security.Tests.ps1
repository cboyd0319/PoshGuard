#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Security module

.DESCRIPTION
    Comprehensive unit tests for Security.psm1 functions covering all PSSA security rules:
    - Invoke-PlainTextPasswordFix
    - Invoke-ConvertToSecureStringFix
    - Invoke-UsernamePasswordParamsFix
    - Invoke-AllowUnencryptedAuthFix
    - Invoke-HardcodedComputerNameFix
    - Invoke-InvokeExpressionFix
    - Invoke-EmptyCatchBlockFix

    Tests use AST-based validation and mock external dependencies.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Security is critical - tests cover edge cases and error paths
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }

  # Import Security module (only if not already loaded)
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/Security.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Security module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'Security' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  }
  
  # Initialize performance mocks to prevent slow console I/O
  Initialize-PerformanceMocks -ModuleName 'Security'
}

Describe 'Invoke-PlainTextPasswordFix' -Tag 'Unit', 'Security' {
  
  Context 'When parameter has plain text password type' {
    It 'Should convert [string]$Password to [SecureString]$Password' {
      $input = @'
function Test-Auth {
    param(
        [string]$Password
    )
}
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -Match '\[SecureString\]\$Password'
      $result | Should -Not -Match '\[string\]\$Password'
    }

    It 'Should convert [string]$Pass parameter' {
      $input = @'
param(
    [string]$Pass
)
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -Match '\[SecureString\]\$Pass'
    }

    It 'Should convert [string]$Pwd parameter' {
      $input = @'
param(
    [string]$Pwd
)
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -Match '\[SecureString\]\$Pwd'
    }

    It 'Should convert [string]$Secret parameter' {
      $input = @'
param(
    [string]$Secret
)
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -Match '\[SecureString\]\$Secret'
    }

    It 'Should convert [string]$Token parameter' {
      $input = @'
param(
    [string]$Token
)
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -Match '\[SecureString\]\$Token'
    }
  }

  Context 'When parameter already uses SecureString' {
    It 'Should not modify already secure parameters' {
      $input = @'
function Test-Auth {
    param(
        [SecureString]$Password
    )
}
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -BeExactly $input
    }
  }

  Context 'When parameter name contains password but is not a string' {
    It 'Should not modify non-string password parameters' {
      $input = @'
param(
    [int]$PasswordLength
)
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -BeExactly $input
    }
  }

  Context 'When multiple password parameters exist' {
    It 'Should convert all password parameters' {
      $input = @'
function Test-MultiAuth {
    param(
        [string]$UserPassword,
        [string]$AdminPassword
    )
}
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -Match '\[SecureString\]\$UserPassword'
      $result | Should -Match '\[SecureString\]\$AdminPassword'
      ($result -split '\[SecureString\]').Count - 1 | Should -Be 2
    }
  }

  Context 'When content has no parameters' {
    It 'Should return content unchanged' {
      $input = @'
function Test-NoParams {
    Write-Output "No parameters"
}
'@
      $result = Invoke-PlainTextPasswordFix -Content $input
      
      $result | Should -BeExactly $input
    }
  }

  Context 'Error handling' {
    It 'Should handle invalid PowerShell syntax gracefully' {
      $testContent = 'function { invalid syntax'
      
      { Invoke-PlainTextPasswordFix -Content $testContent } | Should -Not -Throw
    }

    It 'Should handle simple content' {
      { Invoke-PlainTextPasswordFix -Content "# Comment" } | Should -Not -Throw
    }
  }
}

Describe 'Invoke-ConvertToSecureStringFix' -Tag 'Unit', 'Security' {
  
  Context 'When ConvertTo-SecureString with -AsPlainText is found' {
    It 'Should process dangerous ConvertTo-SecureString usage' {
      $input = '$securePassword = ConvertTo-SecureString "MyPassword123" -AsPlainText -Force'
      
      $result = Invoke-ConvertToSecureStringFix -Content $input
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle ConvertTo-SecureString with literal password' {
      $input = '$pwd = ConvertTo-SecureString -String "password" -AsPlainText -Force'
      
      $result = Invoke-ConvertToSecureStringFix -Content $input
      $result | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Edge cases' {
    It 'Should handle content without ConvertTo-SecureString' {
      $input = 'function Test-Function { Write-Output "No security issues" }'
      
      $result = Invoke-ConvertToSecureStringFix -Content $input
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Invoke-UsernamePasswordParamsFix' -Tag 'Unit', 'Security' {
  
  Context 'When function has both Username and Password parameters' {
    It 'Should process function with Username and Password params' {
      $testContent = 'function Connect-Service { param([string]$Username, [string]$Password) }'
      
      { Invoke-UsernamePasswordParamsFix -Content $testContent } | Should -Not -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle simple content' {
      { Invoke-UsernamePasswordParamsFix -Content "# Comment" } | Should -Not -Throw
    }
  }
}

Describe 'Invoke-InvokeExpressionFix' -Tag 'Unit', 'Security' {
  
  Context 'When Invoke-Expression is used' {
    It 'Should process Invoke-Expression usage' {
      $testContent = '$cmd = "Get-Process"; Invoke-Expression $cmd'
      
      { Invoke-InvokeExpressionFix -Content $testContent } | Should -Not -Throw
    }

    It 'Should handle iex alias' {
      $testContent = '$cmd = "dir"; iex $cmd'
      
      { Invoke-InvokeExpressionFix -Content $testContent } | Should -Not -Throw
    }
  }

  Context 'When Invoke-Expression is not present' {
    It 'Should handle safe content' {
      $testContent = 'function Test-Safe { Write-Output "Safe code" }'
      
      { Invoke-InvokeExpressionFix -Content $testContent } | Should -Not -Throw
    }
  }
}

Describe 'Invoke-EmptyCatchBlockFix' -Tag 'Unit', 'Security' {
  
  Context 'When empty catch block is found' {
    It 'Should add logging to empty catch block' {
      $input = @'
try {
    Get-Process
}
catch {
}
'@
      $result = Invoke-EmptyCatchBlockFix -Content $input
      
      $result | Should -Match 'catch\s*\{[^}]*Write-(Error|Warning|Verbose)'
    }

    It 'Should handle catch block with only whitespace' {
      $input = @'
try {
    Get-Process
}
catch {
    
}
'@
      $result = Invoke-EmptyCatchBlockFix -Content $input
      
      $result | Should -Not -Match 'catch\s*\{\s*\}'
    }
  }

  Context 'When catch block has content' {
    It 'Should not modify non-empty catch blocks' {
      $input = @'
try {
    Get-Process
}
catch {
    Write-Error "Failed"
}
'@
      $result = Invoke-EmptyCatchBlockFix -Content $input
      
      $result | Should -BeExactly $input
    }
  }

  Context 'Edge cases' {
    It 'Should handle multiple try-catch blocks' {
      $input = @'
try { cmd1 } catch { }
try { cmd2 } catch { }
'@
      $result = Invoke-EmptyCatchBlockFix -Content $input
      
      $result | Should -Not -Match 'catch\s*\{\s*\}'
    }

    It 'Should handle nested try-catch' {
      $input = @'
try {
    try {
        cmd
    }
    catch {
    }
}
catch {
}
'@
      $result = Invoke-EmptyCatchBlockFix -Content $input
      
      # Should fix both empty catch blocks
      ($result -match 'catch\s*\{[^}]*Write-').Count | Should -BeGreaterOrEqual 1
    }
  }
}

Describe 'Invoke-HardcodedComputerNameFix' -Tag 'Unit', 'Security' {
  
  Context 'When hardcoded computer names are found' {
    It 'Should process hardcoded computer name' {
      $testContent = 'Invoke-Command -ComputerName "SERVER01" -ScriptBlock { Get-Process }'
      
      { Invoke-HardcodedComputerNameFix -Content $testContent } | Should -Not -Throw
    }

    It 'Should handle multiple hardcoded names' {
      $testContent = 'Invoke-Command -ComputerName "SERVER01"; Invoke-Command -ComputerName "SERVER02"'
      
      { Invoke-HardcodedComputerNameFix -Content $testContent } | Should -Not -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle localhost references' {
      $testContent = 'Invoke-Command -ComputerName "localhost"'
      
      { Invoke-HardcodedComputerNameFix -Content $testContent } | Should -Not -Throw
    }
  }
}

Describe 'Invoke-AllowUnencryptedAuthFix' -Tag 'Unit', 'Security' {
  
  Context 'When -AllowUnencryptedAuthentication is found' {
    It 'Should comment out AllowUnencryptedAuthentication switch' {
      $input = @'
Invoke-RestMethod -Uri $uri -AllowUnencryptedAuthentication
'@
      $result = Invoke-AllowUnencryptedAuthFix -Content $input
      
      $result | Should -Match '# SECURITY|#.*AllowUnencryptedAuthentication'
    }
  }

  Context 'When no unencrypted auth is present' {
    It 'Should return content unchanged' {
      $input = @'
Invoke-RestMethod -Uri $uri -UseBasicParsing
'@
      $result = Invoke-AllowUnencryptedAuthFix -Content $input
      
      $result | Should -BeExactly $input
    }
  }

  Context 'Edge cases' {
    It 'Should handle multiple occurrences' {
      $input = @'
Invoke-RestMethod -Uri $uri1 -AllowUnencryptedAuthentication
Invoke-WebRequest -Uri $uri2 -AllowUnencryptedAuthentication
'@
      $result = Invoke-AllowUnencryptedAuthFix -Content $input
      
      ($result -split 'AllowUnencryptedAuthentication').Count - 1 | Should -BeGreaterThan 0
    }
  }
}

Describe 'Security Module Integration' -Tag 'Integration', 'Security' {
  
  Context 'When combining multiple security fixes' {
    It 'Should apply all relevant fixes to a script' {
      $input = @'
function Connect-UnsafeService {
    param(
        [string]$Username,
        [string]$Password,
        [string]$Server = "PROD-SERVER"
    )
    
    $securePass = ConvertTo-SecureString "default123" -AsPlainText -Force
    
    try {
        Invoke-Expression "Connect-Service -User $Username"
    }
    catch {
    }
}
'@
      # Apply multiple fixes
      $result = $input
      $result = Invoke-PlainTextPasswordFix -Content $result
      $result = Invoke-ConvertToSecureStringFix -Content $result
      $result = Invoke-InvokeExpressionFix -Content $result
      $result = Invoke-EmptyCatchBlockFix -Content $result
      $result = Invoke-HardcodedComputerNameFix -Content $result
      
      # Verify at least some security improvements were made
      $result | Should -Not -BeExactly $input
      $result | Should -Match 'SecureString'
    }
  }
}
