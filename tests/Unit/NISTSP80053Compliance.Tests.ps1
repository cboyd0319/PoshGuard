#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard NISTSP80053Compliance module

.DESCRIPTION
    Comprehensive unit tests for NISTSP80053Compliance.psm1 functions covering:
    - Access Control (AC) checks
    - Audit and Accountability (AU) checks
    - Configuration Management (CM) checks
    - Identification and Authentication (IA) checks
    - System and Communications Protection (SC) checks
    
    Tests verify NIST SP 800-53 Rev 5 compliance checking.
    All tests are hermetic with mocked external dependencies.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }

  # Import NISTSP80053Compliance module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/NISTSP80053Compliance.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find NISTSP80053Compliance module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'NISTSP80053Compliance' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  
  # Initialize performance mocks to prevent slow console I/O
  Initialize-PerformanceMocks -ModuleName 'NISTSP80053Compliance'
  }
}

Describe 'Test-AccountManagement' -Tag 'Unit', 'NIST', 'AC' {
  
  Context 'When checking account management practices' {
    It 'Should pass for code with proper account management' {
      $code = @'
function New-UserAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username,
        [Parameter(Mandatory)]
        [SecureString]$Password
    )
    if ($PSCmdlet.ShouldProcess($Username, "Create user account")) {
        New-LocalUser -Name $Username -Password $Password
    }
}
'@
      
      $result = Test-AccountManagement -Content $code
      
      $result | Should -Not -BeNullOrEmpty
      $result.Passed | Should -Be $true
    }

    It 'Should warn about hardcoded accounts' {
      $code = "New-LocalUser -Name 'admin' -Password '12345'"
      
      $result = Test-AccountManagement -Content $code
      
      $result.Issues | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-AccessEnforcement' -Tag 'Unit', 'NIST', 'AC' {
  
  Context 'When checking access control enforcement' {
    It 'Should detect lack of access checks' {
      $code = @'
function Get-SensitiveData {
    Get-Content -Path "C:\Secrets\data.txt"
}
'@
      
      $result = Test-AccessEnforcement -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should pass for code with access checks' {
      $code = @'
function Get-SensitiveData {
    param([string]$User)
    if (Test-UserAuthorization -User $User) {
        Get-Content -Path "C:\Secrets\data.txt"
    }
}
'@
      
      $result = Test-AccessEnforcement -Content $code
      
      $result.Passed | Should -Be $true
    }
  }
}

Describe 'Test-LeastPrivilege' -Tag 'Unit', 'NIST', 'AC' {
  
  Context 'When checking least privilege principle' {
    It 'Should detect admin-only operations without checks' {
      $code = @'
function Do-AdminTask {
    Remove-Item -Path "C:\Windows\System32\file.dll" -Force
}
'@
      
      $result = Test-LeastPrivilege -Content $code
      
      $result.Issues | Should -Not -BeNullOrEmpty
    }

    It 'Should pass for privilege-checked operations' {
      $code = @'
function Do-AdminTask {
    if (Test-IsAdmin) {
        Remove-Item -Path $File -Force
    } else {
        throw "Administrator privileges required"
    }
}
'@
      
      $result = Test-LeastPrivilege -Content $code
      
      $result.Passed | Should -Be $true
    }
  }
}

Describe 'Test-EventLogging' -Tag 'Unit', 'NIST', 'AU' {
  
  Context 'When checking audit logging' {
    It 'Should detect missing logging in security-sensitive operations' {
      $code = @'
function Remove-UserAccount {
    param($Username)
    Remove-LocalUser -Name $Username
}
'@
      
      $result = Test-EventLogging -Content $code
      
      $result.Issues | Should -Not -BeNullOrEmpty
    }

    It 'Should pass for code with audit logging' {
      $code = @'
function Remove-UserAccount {
    param($Username)
    Write-EventLog -LogName Application -Source "MyApp" -EventId 1001 -Message "Removing user $Username"
    Remove-LocalUser -Name $Username
}
'@
      
      $result = Test-EventLogging -Content $code
      
      $result.Passed | Should -Be $true
    }
  }
}

Describe 'Test-AuditRecordContent' -Tag 'Unit', 'NIST', 'AU' {
  
  Context 'When checking audit record content' {
    It 'Should verify audit records contain required information' {
      $code = @'
Write-EventLog -LogName Application -Source "App" -EventId 1 -Message "Action performed"
'@
      
      $result = Test-AuditRecordContent -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should recommend including timestamp and user' {
      $code = @'
Write-EventLog -LogName Application -Source "App" -EventId 1 -Message "User: $env:USERNAME, Time: $(Get-Date), Action: Login"
'@
      
      $result = Test-AuditRecordContent -Content $code
      
      $result.Passed | Should -Be $true
    }
  }
}

Describe 'Test-AuditProtection' -Tag 'Unit', 'NIST', 'AU' {
  
  Context 'When checking audit log protection' {
    It 'Should detect unprotected audit log access' {
      $code = "Get-Content -Path 'C:\Logs\audit.log'"
      
      $result = Test-AuditProtection -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-BaselineConfiguration' -Tag 'Unit', 'NIST', 'CM' {
  
  Context 'When checking configuration baselines' {
    It 'Should verify configuration documentation' {
      $code = @'
$Config = @{
    Setting1 = "Value1"
    Setting2 = "Value2"
}
'@
      
      $result = Test-BaselineConfiguration -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-ChangeControl' -Tag 'Unit', 'NIST', 'CM' {
  
  Context 'When checking change control' {
    It 'Should detect uncontrolled configuration changes' {
      $code = "Set-ItemProperty -Path 'HKLM:\Software\MyApp' -Name 'Setting' -Value 'NewValue'"
      
      $result = Test-ChangeControl -Content $code
      
      $result.Issues | Should -Not -BeNullOrEmpty
    }

    It 'Should pass for approved changes' {
      $code = @'
if ($ApprovalTicket -and (Test-ChangeApproval -Ticket $ApprovalTicket)) {
    Set-ItemProperty -Path $Path -Name $Name -Value $Value
}
'@
      
      $result = Test-ChangeControl -Content $code
      
      $result.Passed | Should -Be $true
    }
  }
}

Describe 'Test-ConfigurationSettings' -Tag 'Unit', 'NIST', 'CM' {
  
  Context 'When checking configuration settings' {
    It 'Should verify documented settings' {
      $code = @'
# Configuration: Database connection
$ConnectionString = "Server=localhost;Database=mydb"
'@
      
      $result = Test-ConfigurationSettings -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-Authentication' -Tag 'Unit', 'NIST', 'IA' {
  
  Context 'When checking authentication' {
    It 'Should detect weak authentication' {
      $code = "if (`$username -eq 'admin' -and `$password -eq 'password') { }"
      
      $result = Test-Authentication -Content $code
      
      $result.Issues | Should -Not -BeNullOrEmpty
    }

    It 'Should pass for strong authentication' {
      $code = @'
$cred = Get-Credential
if (Test-Credential -Credential $cred) {
    # Authenticated action
}
'@
      
      $result = Test-Authentication -Content $code
      
      $result.Passed | Should -Be $true
    }
  }
}

Describe 'Integration: Multiple Controls' -Tag 'Unit', 'NIST', 'Integration' {
  
  Context 'When checking comprehensive compliance' {
    It 'Should evaluate multiple control families' {
      $code = @'
function Invoke-SecureOperation {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    # AC-3: Access Enforcement
    if (-not (Test-UserAuthorization -Credential $Credential)) {
        throw "Access denied"
    }
    
    # AU-2: Event Logging
    Write-EventLog -LogName Application -Source "MyApp" -EventId 1001 -Message "Operation started by $($Credential.UserName)"
    
    # CM-3: Change Control
    if ($PSCmdlet.ShouldProcess("System", "Apply change")) {
        # Perform operation
        Write-Output "Operation completed"
    }
}
'@
      
      $acResult = Test-AccessEnforcement -Content $code
      $auResult = Test-EventLogging -Content $code
      
      $acResult.Passed | Should -Be $true
      $auResult.Passed | Should -Be $true
    }
  }
}
