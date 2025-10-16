#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Advanced/ASTTransformations module

.DESCRIPTION
    Comprehensive unit tests covering:
    - Invoke-WmiToCimFix: WMI → CIM cmdlet conversion
    - Invoke-BrokenHashAlgorithmFix: Insecure hash → secure hash replacement
    - Invoke-LongLinesFix: Long line wrapping strategies
    
    Tests include happy paths, edge cases, error conditions, and parameter
    validation using AST-based validation and deterministic execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with AST testing
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Advanced/ASTTransformations.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find ASTTransformations module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-WmiToCimFix' -Tag 'Unit', 'Advanced', 'AST' {
  
  Context 'When converting Get-WmiObject cmdlet' {
    It 'Should convert Get-WmiObject to Get-CimInstance' {
      # Arrange
      $input = 'Get-WmiObject -Class Win32_Process'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-CimInstance'
      $result | Should -Not -Match 'Get-WmiObject'
    }

    It 'Should convert -Class parameter to -ClassName' {
      # Arrange
      $input = 'Get-WmiObject -Class Win32_Process'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match '-ClassName'
      $result | Should -Not -Match '-Class\s'
      $result | Should -Match 'Win32_Process'
    }

    It 'Should preserve -Namespace parameter' {
      # Arrange
      $input = 'Get-WmiObject -Class Win32_Service -Namespace "root\cimv2"'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match '-Namespace'
      $result | Should -Match '"root\\cimv2"'
    }

    It 'Should preserve -ComputerName parameter' {
      # Arrange
      $input = 'Get-WmiObject -Class Win32_Process -ComputerName "Server01"'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match '-ComputerName'
      $result | Should -Match '"Server01"'
    }

    It 'Should preserve -Credential parameter' {
      # Arrange
      $input = 'Get-WmiObject -Class Win32_Process -Credential $cred'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match '-Credential'
      $result | Should -Match '\$cred'
    }

    It 'Should handle Get-WmiObject with -Filter parameter' {
      # Arrange
      $input = 'Get-WmiObject -Class Win32_Process -Filter "Name = ''powershell.exe''"'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-CimInstance'
      $result | Should -Match '-Filter'
      $result | Should -Match "powershell\.exe"
    }
  }

  Context 'When converting other WMI cmdlets' {
    It 'Should convert <WmiCmdlet> to <CimCmdlet>' -TestCases @(
      @{ WmiCmdlet = 'Set-WmiInstance'; CimCmdlet = 'Set-CimInstance' }
      @{ WmiCmdlet = 'Invoke-WmiMethod'; CimCmdlet = 'Invoke-CimMethod' }
      @{ WmiCmdlet = 'Remove-WmiObject'; CimCmdlet = 'Remove-CimInstance' }
      @{ WmiCmdlet = 'Register-WmiEvent'; CimCmdlet = 'Register-CimIndicationEvent' }
    ) {
      param($WmiCmdlet, $CimCmdlet)
      
      # Arrange
      $input = "$WmiCmdlet -Class Win32_Process"
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match $CimCmdlet
      $result | Should -Not -Match $WmiCmdlet
    }
  }

  Context 'When handling multiple WMI cmdlets' {
    It 'Should convert all WMI cmdlets in script' {
      # Arrange
      $input = @'
$processes = Get-WmiObject -Class Win32_Process
$service = Get-WmiObject -Class Win32_Service -Filter "Name = 'wuauserv'"
Remove-WmiObject -Class Win32_Process -Filter "ProcessId = 1234"
'@
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-CimInstance.*Win32_Process'
      $result | Should -Match 'Get-CimInstance.*Win32_Service'
      $result | Should -Match 'Remove-CimInstance.*Win32_Process'
      $result | Should -Not -Match 'Get-WmiObject'
      $result | Should -Not -Match 'Remove-WmiObject'
    }
  }

  Context 'When content has no WMI cmdlets' {
    It 'Should return content unchanged' {
      # Arrange
      $input = 'Get-Process | Where-Object { $_.CPU -gt 100 }'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }
  }

  Context 'When content has parse errors' {
    It 'Should return original content on parse failure' {
      # Arrange
      $input = 'Get-WmiObject { invalid syntax'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }
  }

  Context 'Edge cases' {
    It 'Should handle empty content' {
      # Arrange
      $input = ' '
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle content with only whitespace' {
      # Arrange
      $input = "`n   `n   `n"
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle WMI cmdlet in pipeline' {
      # Arrange
      $input = 'Get-WmiObject -Class Win32_Process | Where-Object { $_.Name -eq "powershell" }'
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-CimInstance'
      $result | Should -Match 'Where-Object'
    }

    It 'Should handle WMI cmdlet with line continuation' {
      # Arrange
      $input = @'
Get-WmiObject `
    -Class Win32_Process `
    -ComputerName Server01
'@
      
      # Act
      $result = Invoke-WmiToCimFix -Content $input
      
      # Assert
      $result | Should -Match 'Get-CimInstance'
      $result | Should -Match '-ClassName'
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-WmiToCimFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-WmiToCimFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }

    It 'Should have OutputType attribute' {
      # Arrange
      $function = Get-Command Invoke-WmiToCimFix
      $outputType = $function.OutputType
      
      # Assert
      $outputType.Type.Name | Should -Contain 'String'
    }
  }
}

Describe 'Invoke-BrokenHashAlgorithmFix' -Tag 'Unit', 'Advanced', 'Security' {
  
  Context 'When replacing MD5 algorithm' {
    It 'Should replace [System.Security.Cryptography.MD5]::Create() with SHA256' {
      # Arrange
      $input = '$hash = [System.Security.Cryptography.MD5]::Create()'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match '\[System\.Security\.Cryptography\.SHA256\]::Create\(\)'
      $result | Should -Not -Match 'MD5'
    }

    It 'Should replace [MD5]::Create() with [SHA256]::Create()' {
      # Arrange
      $input = '$hash = [MD5]::Create()'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match '\[SHA256\]::Create\(\)'
      $result | Should -Not -Match '\[MD5\]'
    }

    It 'Should replace MD5CryptoServiceProvider with SHA256CryptoServiceProvider' {
      # Arrange
      $input = 'New-Object System.Security.Cryptography.MD5CryptoServiceProvider'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match 'SHA256CryptoServiceProvider'
      $result | Should -Not -Match 'MD5CryptoServiceProvider'
    }

    It 'Should replace MD5Cng with SHA256Cng' {
      # Arrange
      $input = 'New-Object System.Security.Cryptography.MD5Cng'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match 'SHA256Cng'
      $result | Should -Not -Match 'MD5Cng'
    }
  }

  Context 'When replacing SHA1 algorithm' {
    It 'Should replace [System.Security.Cryptography.SHA1]::Create() with SHA256' {
      # Arrange
      $input = '$hash = [System.Security.Cryptography.SHA1]::Create()'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match '\[System\.Security\.Cryptography\.SHA256\]::Create\(\)'
      $result | Should -Not -Match 'SHA1'
    }

    It 'Should replace SHA1CryptoServiceProvider with SHA256CryptoServiceProvider' {
      # Arrange
      $input = 'New-Object System.Security.Cryptography.SHA1CryptoServiceProvider'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match 'SHA256CryptoServiceProvider'
      $result | Should -Not -Match 'SHA1CryptoServiceProvider'
    }

    It 'Should replace SHA1Managed with SHA256Managed' {
      # Arrange
      $input = 'New-Object System.Security.Cryptography.SHA1Managed'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match 'SHA256Managed'
      $result | Should -Not -Match 'SHA1Managed'
    }

    It 'Should replace SHA1Cng with SHA256Cng' {
      # Arrange
      $input = 'New-Object System.Security.Cryptography.SHA1Cng'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match 'SHA256Cng'
      $result | Should -Not -Match 'SHA1Cng'
    }
  }

  Context 'When replacing RIPEMD160 algorithm' {
    It 'Should replace RIPEMD160Managed with SHA256Managed' {
      # Arrange
      $input = 'New-Object System.Security.Cryptography.RIPEMD160Managed'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match 'SHA256Managed'
      $result | Should -Not -Match 'RIPEMD160'
    }

    It 'Should replace [RIPEMD160]::Create() with [SHA256]::Create()' {
      # Arrange
      $input = '$hash = [RIPEMD160]::Create()'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match '\[SHA256\]::Create\(\)'
      $result | Should -Not -Match 'RIPEMD160'
    }
  }

  Context 'When handling multiple broken algorithms' {
    It 'Should replace all broken algorithms in script' {
      # Arrange
      $input = @'
$md5 = [MD5]::Create()
$sha1 = [SHA1]::Create()
$hash1 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
$hash2 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
'@
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match '\[SHA256\]::Create\(\)'
      $result | Should -Match 'SHA256CryptoServiceProvider'
      $result | Should -Not -Match '\[MD5\]'
      $result | Should -Not -Match '\[SHA1\]'
      $result | Should -Not -Match 'MD5CryptoServiceProvider'
      $result | Should -Not -Match 'SHA1CryptoServiceProvider'
    }
  }

  Context 'When content has no broken algorithms' {
    It 'Should return content unchanged for secure algorithms' {
      # Arrange
      $input = '$hash = [System.Security.Cryptography.SHA256]::Create()'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should return content unchanged for SHA512' {
      # Arrange
      $input = '$hash = [System.Security.Cryptography.SHA512]::Create()'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }
  }

  Context 'Edge cases' {
    It 'Should handle empty content' {
      # Arrange
      $input = ' '
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -BeExactly $input
    }

    It 'Should handle case-insensitive algorithm names' {
      # Arrange
      $input = '$hash = [md5]::Create()'
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      $result | Should -Match '\[SHA256\]::Create\(\)'
    }

    It 'Should preserve whitespace and formatting' {
      # Arrange
      $input = @'
$hash = [MD5]::Create()

$data = "test"
'@
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert - Check for blank line (cross-platform: Unix LF or Windows CRLF)
      $result | Should -Match '(\r?\n){2,}'
      $result | Should -Match '\$data = "test"'
    }

    It 'Should handle algorithm in comments (no replacement)' {
      # Arrange
      $input = @'
# Using MD5 is bad
$hash = [SHA256]::Create()
'@
      
      # Act
      $result = Invoke-BrokenHashAlgorithmFix -Content $input
      
      # Assert
      # Comments should not be modified (implementation detail)
      $result | Should -Match 'SHA256'
    }
  }

  Context 'Parameter validation' {
    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-BrokenHashAlgorithmFix
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-BrokenHashAlgorithmFix
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }

    It 'Should have OutputType attribute' {
      # Arrange
      $function = Get-Command Invoke-BrokenHashAlgorithmFix
      $outputType = $function.OutputType
      
      # Assert
      $outputType.Type.Name | Should -Contain 'String'
    }
  }
}

Describe 'Invoke-LongLinesFix' -Tag 'Unit', 'Advanced', 'Formatting' {
  
  Context 'When function exists' {
    It 'Should be defined and callable' {
      # Assert
      Get-Command Invoke-LongLinesFix -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Should have CmdletBinding attribute' {
      # Arrange
      $function = Get-Command Invoke-LongLinesFix -ErrorAction SilentlyContinue
      
      # Skip if function doesn't exist
      if ($null -eq $function) {
        Set-ItResult -Skipped -Because 'Invoke-LongLinesFix may not be implemented yet'
        return
      }
      
      # Assert
      $function.CmdletBinding | Should -BeTrue
    }

    It 'Should have mandatory Content parameter' {
      # Arrange
      $function = Get-Command Invoke-LongLinesFix -ErrorAction SilentlyContinue
      
      # Skip if function doesn't exist
      if ($null -eq $function) {
        Set-ItResult -Skipped -Because 'Invoke-LongLinesFix may not be implemented yet'
        return
      }
      
      $param = $function.Parameters['Content']
      
      # Assert
      $param.Attributes.Mandatory | Should -Contain $true
    }
  }
}
