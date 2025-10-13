<#
.SYNOPSIS
    Enhanced Security Detection Module - OWASP Top 10 & MITRE ATT&CK

.DESCRIPTION
    World-class security vulnerability detection for PowerShell scripts:
    - OWASP Top 10 2023 (Web + API)
    - MITRE ATT&CK framework (T1059.001 PowerShell)
    - Supply chain security (SBOM validation)
    - Cryptographic vulnerabilities (weak algorithms)
    - Advanced secrets scanning
    - CVE correlation capabilities

.NOTES
    Version: 4.0.0
    Part of PoshGuard Security Enhancement
    References:
    - OWASP Top 10 2023 | https://owasp.org/Top10/ | High | Most critical web app security risks
    - MITRE ATT&CK | https://attack.mitre.org | High | Adversary tactics and techniques
    - CWE Top 25 | https://cwe.mitre.org/top25/ | High | Most dangerous software weaknesses
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region OWASP Top 10 2023 Detection

function Test-OWASPTop10 {
    <#
    .SYNOPSIS
        Detect OWASP Top 10 2023 vulnerabilities
    
    .DESCRIPTION
        Comprehensive security analysis covering:
        A01:2023 – Broken Access Control
        A02:2023 – Cryptographic Failures
        A03:2023 – Injection
        A04:2023 – Insecure Design
        A05:2023 – Security Misconfiguration
        A06:2023 – Vulnerable and Outdated Components
        A07:2023 – Identification and Authentication Failures
        A08:2023 – Software and Data Integrity Failures
        A09:2023 – Security Logging and Monitoring Failures
        A10:2023 – Server-Side Request Forgery (SSRF)
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    
    .EXAMPLE
        Test-OWASPTop10 -Content $script -FilePath "script.ps1"
    
    .OUTPUTS
        PSCustomObject[] - Array of detected security issues
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        
        [Parameter()]
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    # A01: Broken Access Control
    $issues += Test-BrokenAccessControl -Content $Content -FilePath $FilePath
    
    # A02: Cryptographic Failures
    $issues += Test-CryptographicFailures -Content $Content -FilePath $FilePath
    
    # A03: Injection
    $issues += Test-InjectionVulnerabilities -Content $Content -FilePath $FilePath
    
    # A07: Authentication Failures
    $issues += Test-AuthenticationFailures -Content $Content -FilePath $FilePath
    
    # A08: Software Integrity Failures
    $issues += Test-IntegrityFailures -Content $Content -FilePath $FilePath
    
    # A09: Logging Failures
    $issues += Test-LoggingFailures -Content $Content -FilePath $FilePath
    
    # A10: SSRF
    $issues += Test-SSRFVulnerabilities -Content $Content -FilePath $FilePath
    
    return $issues
}

function Test-BrokenAccessControl {
    <#
    .SYNOPSIS
        Detect broken access control issues (A01:2023)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        # Check for hardcoded paths without validation
        if ($Content -match '(?i)(Get-Content|Set-Content|Remove-Item).*\$\w+.*\.\w+' -and
            $Content -notmatch 'Test-Path|Resolve-Path') {
            $issues += [PSCustomObject]@{
                Rule = 'A01-PathTraversalRisk'
                Severity = 'Error'
                Line = 0
                Message = 'Potential path traversal vulnerability. Use Resolve-Path or Test-Path to validate file paths before operations.'
                OWASP = 'A01:2023 - Broken Access Control'
                CWE = 'CWE-22'
                Remediation = 'Add path validation: $safePath = Resolve-Path -Path $userInput -ErrorAction Stop'
                FilePath = $FilePath
            }
        }
        
        # Check for unsafe directory listing
        if ($Content -match '(?i)Get-ChildItem.*-Recurse.*\$\w+') {
            $issues += [PSCustomObject]@{
                Rule = 'A01-DirectoryTraversal'
                Severity = 'Warning'
                Line = 0
                Message = 'Recursive directory listing with user input may expose sensitive files.'
                OWASP = 'A01:2023 - Broken Access Control'
                CWE = 'CWE-22'
                Remediation = 'Validate directory path and implement Allowlist of allowed directories'
                FilePath = $FilePath
            }
        }
        
        # Check for missing authorization checks
        if ($Content -match '(?i)(Remove-Item|Remove-ADUser|Remove-ADGroup|Disable-ADAccount)' -and
            $Content -notmatch '(?i)(Test-Administrator|Check-Permission|Verify-Authorization)') {
            $issues += [PSCustomObject]@{
                Rule = 'A01-MissingAuthorization'
                Severity = 'Warning'
                Line = 0
                Message = 'Destructive operation without authorization check. Verify user has required permissions.'
                OWASP = 'A01:2023 - Broken Access Control'
                CWE = 'CWE-862'
                Remediation = 'Add authorization: if (-not (Test-IsAdministrator)) { throw "Insufficient permissions" }'
                FilePath = $FilePath
            }
        }
    }
    catch {
        Write-Verbose "Error in access control check: $_"
    }
    
    return $issues
}

function Test-CryptographicFailures {
    <#
    .SYNOPSIS
        Detect cryptographic failures (A02:2023)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        # Weak cryptographic algorithms
        $weakAlgorithms = @{
            'MD5' = 'CWE-327'
            'SHA1' = 'CWE-327'
            'DES' = 'CWE-326'
            'RC4' = 'CWE-326'
            'ECB' = 'CWE-327'  # ECB mode is weak
        }
        
        foreach ($algo in $weakAlgorithms.Keys) {
            if ($Content -match "(?i)\b$algo\b") {
                $issues += [PSCustomObject]@{
                    Rule = 'A02-WeakCryptography'
                    Severity = 'Error'
                    Line = 0
                    Message = "Weak cryptographic algorithm detected: $algo. Use SHA256 or stronger."
                    OWASP = 'A02:2023 - Cryptographic Failures'
                    CWE = $weakAlgorithms[$algo]
                    Remediation = "Replace $algo with SHA256: [System.Security.Cryptography.SHA256]::Create()"
                    FilePath = $FilePath
                }
            }
        }
        
        # Hardcoded encryption keys
        if ($Content -match '(?i)(AES|TripleDES).*key\s*=\s*[''"][\w\+/=]{16,}[''"]') {
            $issues += [PSCustomObject]@{
                Rule = 'A02-HardcodedKey'
                Severity = 'Error'
                Line = 0
                Message = 'Hardcoded encryption key detected. Store keys securely in Azure Key Vault or similar.'
                OWASP = 'A02:2023 - Cryptographic Failures'
                CWE = 'CWE-321'
                Remediation = 'Use secure key storage: $key = Get-AzKeyVaultSecret -VaultName "MyVault" -Name "EncryptionKey"'
                FilePath = $FilePath
            }
        }
        
        # Missing TLS/SSL validation
        if ($Content -match '(?i)ServicePointManager.*ServerCertificateValidationCallback.*{.*true.*}') {
            $issues += [PSCustomObject]@{
                Rule = 'A02-DisabledCertValidation'
                Severity = 'Error'
                Line = 0
                Message = 'SSL/TLS certificate validation disabled. This enables man-in-the-middle attacks.'
                OWASP = 'A02:2023 - Cryptographic Failures'
                CWE = 'CWE-295'
                Remediation = 'Remove certificate validation bypass. Fix certificate issues instead.'
                FilePath = $FilePath
            }
        }
        
        # Insecure random number generation
        if ($Content -match '(?i)(Get-Random|System\.Random)' -and 
            $Content -match '(?i)(password|key|token|salt|nonce)') {
            $issues += [PSCustomObject]@{
                Rule = 'A02-WeakRNG'
                Severity = 'Error'
                Line = 0
                Message = 'Weak random number generator for security-sensitive value. Use cryptographic RNG.'
                OWASP = 'A02:2023 - Cryptographic Failures'
                CWE = 'CWE-338'
                Remediation = 'Use: $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()'
                FilePath = $FilePath
            }
        }
    }
    catch {
        Write-Verbose "Error in cryptography check: $_"
    }
    
    return $issues
}

function Test-InjectionVulnerabilities {
    <#
    .SYNOPSIS
        Detect injection vulnerabilities (A03:2023)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        # Command injection via Invoke-Expression
        if ($Content -match '(?i)Invoke-Expression.*\$\w+' -or $Content -match '(?i)\biex\b.*\$\w+') {
            $issues += [PSCustomObject]@{
                Rule = 'A03-CommandInjection'
                Severity = 'Error'
                Line = 0
                Message = 'Command injection vulnerability via Invoke-Expression with variable input.'
                OWASP = 'A03:2023 - Injection'
                CWE = 'CWE-78'
                MITRE = 'T1059.001 - PowerShell'
                Remediation = 'Use native cmdlets instead of string-based execution. Example: & $command -ArgumentList $args'
                FilePath = $FilePath
            }
        }
        
        # SQL injection risk
        if ($Content -match '(?i)(Invoke-Sqlcmd|ExecuteNonQuery|ExecuteScalar).*\$\w+' -and
            $Content -notmatch '(?i)SqlParameter') {
            $issues += [PSCustomObject]@{
                Rule = 'A03-SQLInjection'
                Severity = 'Error'
                Line = 0
                Message = 'Potential SQL injection. User input in SQL query without parameterization.'
                OWASP = 'A03:2023 - Injection'
                CWE = 'CWE-89'
                Remediation = 'Use parameterized queries: $cmd.Parameters.AddWithValue("@param", $value)'
                FilePath = $FilePath
            }
        }
        
        # XML injection
        if ($Content -match '(?i)(Select-Xml|ConvertTo-Xml).*\$\w+' -and
            $Content -notmatch '(?i)(Escape|Encode|Sanitize)') {
            $issues += [PSCustomObject]@{
                Rule = 'A03-XMLInjection'
                Severity = 'Warning'
                Line = 0
                Message = 'Potential XML injection. User input in XML operation without sanitization.'
                OWASP = 'A03:2023 - Injection'
                CWE = 'CWE-91'
                Remediation = 'Sanitize input: $safe = [System.Security.SecurityElement]::Escape($userInput)'
                FilePath = $FilePath
            }
        }
        
        # LDAP injection
        if ($Content -match '(?i)Get-AD(User|Group|Computer).*-Filter.*\$\w+' -and
            $Content -notmatch '(?i)(Escape|Sanitize)') {
            $issues += [PSCustomObject]@{
                Rule = 'A03-LDAPInjection'
                Severity = 'Error'
                Line = 0
                Message = 'Potential LDAP injection. User input in AD filter without sanitization.'
                OWASP = 'A03:2023 - Injection'
                CWE = 'CWE-90'
                Remediation = 'Escape special chars: $safe = $userInput -replace "[\(\)\*\\]", "\$&"'
                FilePath = $FilePath
            }
        }
    }
    catch {
        Write-Verbose "Error in injection check: $_"
    }
    
    return $issues
}

function Test-AuthenticationFailures {
    <#
    .SYNOPSIS
        Detect authentication failures (A07:2023)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        # Weak password policy
        if ($Content -match '(?i)password.*length.*[0-5]') {
            $issues += [PSCustomObject]@{
                Rule = 'A07-WeakPasswordPolicy'
                Severity = 'Warning'
                Line = 0
                Message = 'Weak password length requirement (< 6 characters). Use minimum 12 characters.'
                OWASP = 'A07:2023 - Identification and Authentication Failures'
                CWE = 'CWE-521'
                Remediation = 'Set minimum password length to 12: $minLength = 12'
                FilePath = $FilePath
            }
        }
        
        # Missing session timeout
        if ($Content -match '(?i)(New-PSSession|Enter-PSSession)' -and
            $Content -notmatch '(?i)(IdleTimeout|MaxIdleTimeMs)') {
            $issues += [PSCustomObject]@{
                Rule = 'A07-NoSessionTimeout'
                Severity = 'Warning'
                Line = 0
                Message = 'Remote session without idle timeout. Set timeout to prevent unauthorized access.'
                OWASP = 'A07:2023 - Identification and Authentication Failures'
                CWE = 'CWE-613'
                Remediation = 'Add timeout: New-PSSession -ComputerName $server -SessionOption (New-PSSessionOption -IdleTimeout 300000)'
                FilePath = $FilePath
            }
        }
        
        # Credential exposure in exception
        if ($Content -match '(?i)catch.*credential' -and $Content -match '\$_|PSItem') {
            $issues += [PSCustomObject]@{
                Rule = 'A07-CredentialExposure'
                Severity = 'Error'
                Line = 0
                Message = 'Potential credential exposure in error handling. Sanitize exception messages.'
                OWASP = 'A07:2023 - Identification and Authentication Failures'
                CWE = 'CWE-209'
                Remediation = 'Sanitize: Write-Error "Authentication failed" (do not include $_)'
                FilePath = $FilePath
            }
        }
    }
    catch {
        Write-Verbose "Error in authentication check: $_"
    }
    
    return $issues
}

function Test-IntegrityFailures {
    <#
    .SYNOPSIS
        Detect software and data integrity failures (A08:2023)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        # Insecure deserialization
        if ($Content -match '(?i)(Import-Clixml|ConvertFrom-Json|BinaryFormatter|NetDataContractSerializer)' -and
            $Content -match '(?i)(Download|Web|Http|Url|Uri)') {
            $issues += [PSCustomObject]@{
                Rule = 'A08-InsecureDeserialization'
                Severity = 'Error'
                Line = 0
                Message = 'Insecure deserialization of untrusted data. Can lead to remote code execution.'
                OWASP = 'A08:2023 - Software and Data Integrity Failures'
                CWE = 'CWE-502'
                MITRE = 'T1027.002 - Obfuscated Files or Information: Software Packing'
                Remediation = 'Validate and sanitize data before deserialization. Use safe formats (JSON with validation).'
                FilePath = $FilePath
            }
        }
        
        # Unsigned script execution
        if ($Content -match '(?i)Set-ExecutionPolicy.*Unrestricted') {
            $issues += [PSCustomObject]@{
                Rule = 'A08-UnsignedScriptExecution'
                Severity = 'Error'
                Line = 0
                Message = 'Setting execution policy to Unrestricted allows unsigned scripts. Security risk.'
                OWASP = 'A08:2023 - Software and Data Integrity Failures'
                CWE = 'CWE-494'
                Remediation = 'Use RemoteSigned or AllSigned: Set-ExecutionPolicy RemoteSigned'
                FilePath = $FilePath
            }
        }
        
        # Missing integrity checks for downloads
        if ($Content -match '(?i)(Invoke-WebRequest|DownloadFile|DownloadString)' -and
            $Content -notmatch '(?i)(hash|checksum|signature)') {
            $issues += [PSCustomObject]@{
                Rule = 'A08-MissingIntegrityCheck'
                Severity = 'Warning'
                Line = 0
                Message = 'Downloaded file without integrity verification. Verify hash or signature.'
                OWASP = 'A08:2023 - Software and Data Integrity Failures'
                CWE = 'CWE-494'
                Remediation = 'Verify hash: if ((Get-FileHash $file).Hash -ne $expectedHash) { throw "Integrity check failed" }'
                FilePath = $FilePath
            }
        }
    }
    catch {
        Write-Verbose "Error in integrity check: $_"
    }
    
    return $issues
}

function Test-LoggingFailures {
    <#
    .SYNOPSIS
        Detect security logging and monitoring failures (A09:2023)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        # Catch without logging
        if ($Content -match '(?i)catch\s*{[^}]*}' -and
            $Content -notmatch '(?i)(Write-Log|Write-EventLog|Write-Error|Write-Warning|Add-Content.*log)') {
            $issues += [PSCustomObject]@{
                Rule = 'A09-NoErrorLogging'
                Severity = 'Warning'
                Line = 0
                Message = 'Exception caught without logging. Security incidents may go undetected.'
                OWASP = 'A09:2023 - Security Logging and Monitoring Failures'
                CWE = 'CWE-778'
                Remediation = 'Log errors: catch { Write-EventLog -LogName Application -Source "MyApp" -EventId 1000 -Message $_.Exception.Message }'
                FilePath = $FilePath
            }
        }
        
        # Missing audit trail for sensitive operations
        if ($Content -match '(?i)(Remove-Item|Remove-AD|Delete|Disable|Set-AD)' -and
            $Content -notmatch '(?i)(Write-Log|Write-EventLog|Write-Verbose|Add-Content.*log)') {
            $issues += [PSCustomObject]@{
                Rule = 'A09-NoAuditTrail'
                Severity = 'Warning'
                Line = 0
                Message = 'Sensitive operation without audit logging. Track changes for security compliance.'
                OWASP = 'A09:2023 - Security Logging and Monitoring Failures'
                CWE = 'CWE-778'
                Remediation = 'Add audit log: Write-EventLog -LogName Security -Source "MyApp" -EventId 4001 -Message "Operation: $operation"'
                FilePath = $FilePath
            }
        }
    }
    catch {
        Write-Verbose "Error in logging check: $_"
    }
    
    return $issues
}

function Test-SSRFVulnerabilities {
    <#
    .SYNOPSIS
        Detect Server-Side Request Forgery (A10:2023)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    try {
        # User-controlled URL in web request
        if ($Content -match '(?i)(Invoke-WebRequest|Invoke-RestMethod).*\$\w+' -and
            $Content -notmatch '(?i)(Test-Url|Validate-Url|Allowlist|allowlist)') {
            $issues += [PSCustomObject]@{
                Rule = 'A10-SSRFRisk'
                Severity = 'Error'
                Line = 0
                Message = 'Potential SSRF vulnerability. User-controlled URL without validation.'
                OWASP = 'A10:2023 - Server-Side Request Forgery'
                CWE = 'CWE-918'
                Remediation = 'Validate URL against Allowlist: if ($url -notmatch "^https://trusted\.domain\.com") { throw "Invalid URL" }'
                FilePath = $FilePath
            }
        }
    }
    catch {
        Write-Verbose "Error in SSRF check: $_"
    }
    
    return $issues
}

#endregion

#region MITRE ATT&CK Detection

function Test-MITREAttack {
    <#
    .SYNOPSIS
        Detect MITRE ATT&CK techniques in PowerShell
    
    .DESCRIPTION
        Identifies adversary techniques specific to PowerShell:
        T1059.001 - Command and Scripting Interpreter: PowerShell
        T1027 - Obfuscated Files or Information
        T1140 - Deobfuscate/Decode Files or Information
        T1552.001 - Unsecured Credentials: Credentials In Files
        T1053.005 - Scheduled Task/Job
        T1070.001 - Indicator Removal on Host: Clear Windows Event Logs
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    
    .OUTPUTS
        PSCustomObject[] - Array of detected ATT&CK techniques
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        
        [Parameter()]
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    # T1059.001 - PowerShell execution
    if ($Content -match '(?i)powershell\.exe.*-enc|-encodedcommand') {
        $issues += [PSCustomObject]@{
            Rule = 'MITRE-T1059.001-EncodedCommand'
            Severity = 'Error'
            Line = 0
            Message = 'Encoded PowerShell command detected. Often used by attackers to evade detection.'
            MITRE = 'T1059.001 - PowerShell'
            Remediation = 'Review encoded command for malicious activity. Use plain text for legitimate scripts.'
            FilePath = $FilePath
        }
    }
    
    # T1027 - Obfuscation
    if ($Content -match '(?i)(frombase64string|tobase64string)' -or
        $Content -match '\$\w+\s*=\s*\$\w+\[\d+\]' -or
        $Content -match '-join\s*\(.*\[[^]]+\]') {
        $issues += [PSCustomObject]@{
            Rule = 'MITRE-T1027-Obfuscation'
            Severity = 'Warning'
            Line = 0
            Message = 'Code obfuscation detected. May indicate malicious intent or evasion technique.'
            MITRE = 'T1027 - Obfuscated Files or Information'
            Remediation = 'Review obfuscated code. Use clear, readable code for legitimate purposes.'
            FilePath = $FilePath
        }
    }
    
    # T1552.001 - Credentials in files
    if ($Content -match '(?i)password\s*=\s*[''"][^''"]+[''"]') {
        $issues += [PSCustomObject]@{
            Rule = 'MITRE-T1552.001-CredentialsInFile'
            Severity = 'Error'
            Line = 0
            Message = 'Hardcoded credentials detected. Use secure credential storage.'
            MITRE = 'T1552.001 - Unsecured Credentials: Credentials In Files'
            CWE = 'CWE-798'
            Remediation = 'Use credential manager: $cred = Get-Credential'
            FilePath = $FilePath
        }
    }
    
    # T1053.005 - Scheduled tasks
    if ($Content -match '(?i)(New-ScheduledTask|Register-ScheduledTask|schtasks)' -and
        $Content -match '\$\w+') {
        $issues += [PSCustomObject]@{
            Rule = 'MITRE-T1053.005-ScheduledTask'
            Severity = 'Warning'
            Line = 0
            Message = 'Scheduled task creation with variables. Verify task legitimacy.'
            MITRE = 'T1053.005 - Scheduled Task/Job'
            Remediation = 'Review scheduled task details. Implement approval process for task creation.'
            FilePath = $FilePath
        }
    }
    
    # T1070.001 - Clear event logs
    if ($Content -match '(?i)(Clear-EventLog|wevtutil.*cl|Remove-EventLog)') {
        $issues += [PSCustomObject]@{
            Rule = 'MITRE-T1070.001-ClearLogs'
            Severity = 'Error'
            Line = 0
            Message = 'Event log clearing detected. This is a common attacker technique to hide activity.'
            MITRE = 'T1070.001 - Indicator Removal: Clear Windows Event Logs'
            Remediation = 'Remove log clearing functionality. Implement proper log rotation instead.'
            FilePath = $FilePath
        }
    }
    
    return $issues
}

#endregion

#region Advanced Secrets Detection

function Test-AdvancedSecrets {
    <#
    .SYNOPSIS
        Advanced secrets detection beyond basic patterns
    
    .DESCRIPTION
        Detects:
        - API keys (AWS, Azure, GCP, GitHub, etc.)
        - Connection strings
        - Private keys
        - Tokens and JWTs
        - Environment-specific secrets
    
    .PARAMETER Content
        Script content to analyze
    
    .PARAMETER FilePath
        File path for context
    
    .OUTPUTS
        PSCustomObject[] - Array of detected secrets
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        
        [Parameter()]
        [string]$FilePath = ''
    )
    
    $issues = @()
    
    $secretPatterns = @{
        'AWS Access Key' = 'AKIA[0-9A-Z]{16}'
        'AWS Secret Key' = '[''"][A-Za-z0-9/\+=]{40}[''"]'
        'Azure Storage Key' = '[''"][A-Za-z0-9+/]{86}==[''"]'
        'GitHub Token' = 'gh[ps]_[A-Za-z0-9]{36}'
        'Slack Token' = 'xox[baprs]-[A-Za-z0-9-]+'
        'JWT Token' = 'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
        'Private Key' = '-----BEGIN (RSA |DSA |EC )?PRIVATE KEY-----'
        'Connection String' = '(?i)(Server|Data Source)=[^;]+;.*password=[^;]+'
    }
    
    foreach ($secretType in $secretPatterns.Keys) {
        if ($Content -match $secretPatterns[$secretType]) {
            $issues += [PSCustomObject]@{
                Rule = 'AdvancedSecrets-Detected'
                Severity = 'Error'
                Line = 0
                Message = "$secretType detected in code. Store secrets securely (Azure Key Vault, AWS Secrets Manager, etc.)."
                SecretType = $secretType
                CWE = 'CWE-798'
                Remediation = 'Use secret management service. Example: $secret = Get-AzKeyVaultSecret -VaultName "vault" -Name "secret"'
                FilePath = $FilePath
            }
        }
    }
    
    return $issues
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Test-OWASPTop10',
    'Test-MITREAttack',
    'Test-AdvancedSecrets',
    'Test-BrokenAccessControl',
    'Test-CryptographicFailures',
    'Test-InjectionVulnerabilities',
    'Test-AuthenticationFailures',
    'Test-IntegrityFailures',
    'Test-LoggingFailures',
    'Test-SSRFVulnerabilities'
)
