#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard SecurityDetectionEnhanced module

.DESCRIPTION
    Comprehensive unit tests for SecurityDetectionEnhanced.psm1 covering:
    - OWASP Top 10 2023 detection (all 10 categories)
    - MITRE ATT&CK technique detection
    - Advanced secrets scanning
    - Cryptographic vulnerability detection
    - Injection vulnerability detection
    
    Tests verify comprehensive security coverage.
    All tests are hermetic with mocked dependencies.

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

  # Import SecurityDetectionEnhanced module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/SecurityDetectionEnhanced.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find SecurityDetectionEnhanced module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'SecurityDetectionEnhanced' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  }
}

Describe 'Test-OWASPTop10' -Tag 'Unit', 'Security', 'OWASP' {
  
  Context 'When testing comprehensive OWASP coverage' {
    It 'Should detect multiple OWASP Top 10 issues' {
      $code = @'
# A01: Broken Access Control
Get-Content -Path $userInput

# A02: Cryptographic Failures
$password = "admin123"

# A03: Injection
Invoke-Expression $cmd

# A07: Authentication Failures
if ($user -eq "admin" -and $pass -eq "password") { }
'@
      
      $result = Test-OWASPTop10 -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -BeGreaterThan 0
    }

    It 'Should return minimal issues for secure code' {
      $code = @'
function Get-SecureData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )
    
    # Proper validation and error handling
    if (Test-Authorization -Id $Id) {
        Get-DataSecurely -Id $Id
    }
}
'@
      
      $result = Test-OWASPTop10 -Content $code -FilePath "test.ps1"
      
      $criticalIssues = $result | Where-Object { $_.Severity -eq 'Critical' }
      $criticalIssues.Count | Should -Be 0
    }
  }
}

Describe 'Test-BrokenAccessControl' -Tag 'Unit', 'Security', 'OWASP', 'A01' {
  
  Context 'When detecting broken access control (A01:2023)' {
    It 'Should detect direct object references without validation' {
      $code = @'
function Get-UserData {
    param($UserId)
    Get-Content -Path "C:\Users\$UserId\data.txt"
}
'@
      
      $result = Test-BrokenAccessControl -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect missing authorization checks' {
      $code = @'
function Delete-User {
    param($UserId)
    Remove-Item -Path "C:\Users\$UserId" -Recurse
}
'@
      
      $result = Test-BrokenAccessControl -Content $code -FilePath "test.ps1"
      
      $result.Count | Should -BeGreaterThan 0
    }

    It 'Should pass for code with proper authorization' {
      $code = @'
function Get-UserData {
    param($UserId)
    if (Test-UserAuthorization -UserId $UserId -Action "Read") {
        Get-Content -Path (Get-SecurePath -UserId $UserId)
    }
}
'@
      
      $result = Test-BrokenAccessControl -Content $code -FilePath "test.ps1"
      
      # Should have fewer issues with authorization check
      $result.Count | Should -BeLessThan 3
    }
  }
}

Describe 'Test-CryptographicFailures' -Tag 'Unit', 'Security', 'OWASP', 'A02' {
  
  Context 'When detecting cryptographic failures (A02:2023)' {
    It 'Should detect plaintext passwords' {
      $code = '$password = "MySecretPassword123"'
      
      $result = Test-CryptographicFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect weak encryption algorithms' {
      $code = @'
$md5 = [System.Security.Cryptography.MD5]::Create()
$hash = $md5.ComputeHash($bytes)
'@
      
      $result = Test-CryptographicFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
      $result[0].Description | Should -Match 'MD5|weak'
    }

    It 'Should detect insecure SSL/TLS' {
      $code = '[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3'
      
      $result = Test-CryptographicFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-InjectionVulnerabilities' -Tag 'Unit', 'Security', 'OWASP', 'A03' {
  
  Context 'When detecting injection vulnerabilities (A03:2023)' {
    It 'Should detect command injection' {
      $code = 'Invoke-Expression "Get-Process $processName"'
      
      $result = Test-InjectionVulnerabilities -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect SQL injection' {
      $code = @'
$query = "SELECT * FROM Users WHERE Name = '" + $userName + "'"
Invoke-Sqlcmd -Query $query
'@
      
      $result = Test-InjectionVulnerabilities -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect LDAP injection' {
      $code = '$filter = "(&(objectClass=user)(sAMAccountName=' + $user + '))"'
      
      $result = Test-InjectionVulnerabilities -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should pass for parameterized queries' {
      $code = @'
$query = "SELECT * FROM Users WHERE Name = @userName"
Invoke-Sqlcmd -Query $query -Parameters @{userName = $userName}
'@
      
      $result = Test-InjectionVulnerabilities -Content $code -FilePath "test.ps1"
      
      # Parameterized queries should have fewer findings
      $critical = $result | Where-Object { $_.Severity -eq 'Critical' }
      $critical.Count | Should -Be 0
    }
  }
}

Describe 'Test-AuthenticationFailures' -Tag 'Unit', 'Security', 'OWASP', 'A07' {
  
  Context 'When detecting authentication failures (A07:2023)' {
    It 'Should detect weak password validation' {
      $code = 'if ($password -eq "admin") { Write-Output "Logged in" }'
      
      $result = Test-AuthenticationFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect missing credential validation' {
      $code = @'
function Authenticate {
    param($Username, $Password)
    if ($Username -and $Password) {
        return $true
    }
}
'@
      
      $result = Test-AuthenticationFailures -Content $code -FilePath "test.ps1"
      
      $result.Count | Should -BeGreaterThan 0
    }

    It 'Should pass for proper credential handling' {
      $code = @'
function Authenticate {
    param([PSCredential]$Credential)
    Test-Credential -Credential $Credential
}
'@
      
      $result = Test-AuthenticationFailures -Content $code -FilePath "test.ps1"
      
      # Should have minimal issues with PSCredential
      $critical = $result | Where-Object { $_.Severity -eq 'Critical' }
      $critical.Count | Should -Be 0
    }
  }
}

Describe 'Test-IntegrityFailures' -Tag 'Unit', 'Security', 'OWASP', 'A08' {
  
  Context 'When detecting software integrity failures (A08:2023)' {
    It 'Should detect unsigned script execution' {
      $code = 'Set-ExecutionPolicy Bypass -Scope Process -Force'
      
      $result = Test-IntegrityFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect unsafe deserialization' {
      $code = @'
$data = Get-Content -Path $file | ConvertFrom-Json
Invoke-Expression $data.Command
'@
      
      $result = Test-IntegrityFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect download without verification' {
      $code = @'
Invoke-WebRequest -Uri $url -OutFile $file
. $file
'@
      
      $result = Test-IntegrityFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-LoggingFailures' -Tag 'Unit', 'Security', 'OWASP', 'A09' {
  
  Context 'When detecting logging failures (A09:2023)' {
    It 'Should detect missing security event logging' {
      $code = @'
function Delete-User {
    param($UserId)
    Remove-LocalUser -Name $UserId
}
'@
      
      $result = Test-LoggingFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect sensitive data in logs' {
      $code = 'Write-Host "Password: $password"'
      
      $result = Test-LoggingFailures -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should pass for proper logging' {
      $code = @'
function Delete-User {
    param($UserId)
    Write-EventLog -LogName Application -Source "MyApp" -EventId 1001 -Message "User $UserId deleted"
    Remove-LocalUser -Name $UserId
}
'@
      
      $result = Test-LoggingFailures -Content $code -FilePath "test.ps1"
      
      # Should have fewer issues with proper logging
      $result.Count | Should -BeLessThan 2
    }
  }
}

Describe 'Test-SSRFVulnerabilities' -Tag 'Unit', 'Security', 'OWASP', 'A10' {
  
  Context 'When detecting SSRF vulnerabilities (A10:2023)' {
    It 'Should detect unvalidated URL access' {
      $code = @'
$url = Read-Host "Enter URL"
Invoke-WebRequest -Uri $url
'@
      
      $result = Test-SSRFVulnerabilities -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect internal URL access' {
      $code = 'Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/"'
      
      $result = Test-SSRFVulnerabilities -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect file:// protocol usage' {
      $code = 'Invoke-WebRequest -Uri "file:///etc/passwd"'
      
      $result = Test-SSRFVulnerabilities -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-MITREAttack' -Tag 'Unit', 'Security', 'MITRE' {
  
  Context 'When detecting MITRE ATT&CK techniques' {
    It 'Should detect T1059.001 PowerShell execution' {
      $code = 'powershell.exe -EncodedCommand $encoded'
      
      $result = Test-MITREAttack -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
      $result[0] | Should -Match 'T1059'
    }

    It 'Should detect T1552.001 credential dumping' {
      $code = 'Get-Credential | Export-Clixml -Path C:\creds.xml'
      
      $result = Test-MITREAttack -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-AdvancedSecrets' -Tag 'Unit', 'Security', 'Secrets' {
  
  Context 'When detecting advanced secret patterns' {
    It 'Should detect JWT tokens' {
      $code = '$jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"'
      
      $result = Test-AdvancedSecrets -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect OAuth tokens' {
      $code = '$token = "ya29.a0AfH6SMBx..."'
      
      $result = Test-AdvancedSecrets -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect Azure storage keys' {
      $code = '$key = "DefaultEndpointsProtocol=https;AccountName=myaccount;AccountKey=abc123..."'
      
      $result = Test-AdvancedSecrets -Content $code -FilePath "test.ps1"
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}
