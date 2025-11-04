<#
.SYNOPSIS
    Enhanced Security Detection with CWE and MITRE ATT&CK Mappings

.DESCRIPTION
    Advanced security detection capabilities beyond basic PSScriptAnalyzer rules:
    - CWE (Common Weakness Enumeration) mappings
    - MITRE ATT&CK technique detection
    - OWASP Top 10 2023 coverage
    - Advanced secrets detection (API keys, tokens, certificates)
    - Supply chain security checks
    - Code injection vulnerability detection
    - Cryptographic weakness detection
    
.NOTES
    Version: 4.1.0
    Part of PoshGuard UGE Framework
    References:
    - CWE: https://cwe.mitre.org/
    - MITRE ATT&CK: https://attack.mitre.org/
    - OWASP Top 10 2023: https://owasp.org/Top10/
    
    Security Standards: OWASP ASVS 5.0, NIST 800-53, CIS Benchmarks
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region CWE Mappings

$script:CWEMappings = @{
  # CWE-78: OS Command Injection
  'CommandInjection' = @{
    CWE = 'CWE-78'
    MITREATTCK = 'T1059.001'
    OWASP = 'A03:2023-Injection'
    Severity = 'Critical'
    Description = 'Improper neutralization of special elements used in an OS command'
  }
    
  # CWE-79: Cross-Site Scripting
  'XSSVulnerability' = @{
    CWE = 'CWE-79'
    MITREATTCK = 'T1059'
    OWASP = 'A03:2023-Injection'
    Severity = 'High'
    Description = 'Improper neutralization of input during web page generation'
  }
    
  # CWE-89: SQL Injection
  'SQLInjection' = @{
    CWE = 'CWE-89'
    MITREATTCK = 'T1190'
    OWASP = 'A03:2023-Injection'
    Severity = 'Critical'
    Description = 'Improper neutralization of special elements used in SQL commands'
  }
    
  # CWE-327: Use of a Broken or Risky Cryptographic Algorithm
  'WeakCryptography' = @{
    CWE = 'CWE-327'
    MITREATTCK = 'T1573'
    OWASP = 'A02:2023-Cryptographic Failures'
    Severity = 'High'
    Description = 'Use of a broken or risky cryptographic algorithm'
  }
    
  # CWE-259: Use of Hard-coded Password
  'HardcodedCredentials' = @{
    CWE = 'CWE-259'
    MITREATTCK = 'T1552.001'
    OWASP = 'A07:2023-Identification and Authentication Failures'
    Severity = 'Critical'
    Description = 'Use of hard-coded password'
  }
    
  # CWE-798: Use of Hard-coded Credentials
  'HardcodedSecrets' = @{
    CWE = 'CWE-798'
    MITREATTCK = 'T1552.001'
    OWASP = 'A02:2023-Cryptographic Failures'
    Severity = 'Critical'
    Description = 'Use of hard-coded credentials'
  }
    
  # CWE-22: Path Traversal
  'PathTraversal' = @{
    CWE = 'CWE-22'
    MITREATTCK = 'T1083'
    OWASP = 'A01:2023-Broken Access Control'
    Severity = 'High'
    Description = 'Improper limitation of a pathname to a restricted directory'
  }
    
  # CWE-502: Deserialization of Untrusted Data
  'UnsafeDeserialization' = @{
    CWE = 'CWE-502'
    MITREATTCK = 'T1027'
    OWASP = 'A08:2023-Software and Data Integrity Failures'
    Severity = 'Critical'
    Description = 'Deserialization of untrusted data'
  }
    
  # CWE-94: Improper Control of Generation of Code
  'CodeInjection' = @{
    CWE = 'CWE-94'
    MITREATTCK = 'T1059.001'
    OWASP = 'A03:2023-Injection'
    Severity = 'Critical'
    Description = 'Improper control of generation of code (code injection)'
  }
    
  # CWE-611: Improper Restriction of XML External Entity Reference
  'XXEVulnerability' = @{
    CWE = 'CWE-611'
    MITREATTCK = 'T1203'
    OWASP = 'A05:2023-Security Misconfiguration'
    Severity = 'High'
    Description = 'Improper restriction of XML external entity reference'
  }
    
  # CWE-918: Server-Side Request Forgery (SSRF)
  'SSRFVulnerability' = @{
    CWE = 'CWE-918'
    MITREATTCK = 'T1071'
    OWASP = 'A10:2023-Server-Side Request Forgery'
    Severity = 'High'
    Description = 'Server-side request forgery'
  }
    
  # CWE-532: Insertion of Sensitive Information into Log File
  'SensitiveDataInLogs' = @{
    CWE = 'CWE-532'
    MITREATTCK = 'T1552.004'
    OWASP = 'A09:2023-Security Logging and Monitoring Failures'
    Severity = 'Medium'
    Description = 'Insertion of sensitive information into log file'
  }
}

#endregion

#region Advanced Secrets Detection

$script:SecretsPatterns = @{
  # AWS Keys
  'AWSAccessKey' = @{
    Pattern = '(?i)(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'
    Description = 'AWS Access Key ID'
    CWE = 'CWE-798'
    Severity = 'Critical'
  }
    
  'AWSSecretKey' = @{
    Pattern = '(?i)aws(.{0,20})?[''"][0-9a-zA-Z/+]{40}[''"]'
    Description = 'AWS Secret Access Key'
    CWE = 'CWE-798'
    Severity = 'Critical'
  }
    
  # Azure Keys
  'AzureStorageKey' = @{
    Pattern = '(?i)DefaultEndpointsProtocol=https;AccountName=[a-z0-9]+;AccountKey=[A-Za-z0-9+/=]{88};'
    Description = 'Azure Storage Account Key'
    CWE = 'CWE-798'
    Severity = 'Critical'
  }
    
  # GitHub Tokens
  'GitHubToken' = @{
    Pattern = '(?i)(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,255}'
    Description = 'GitHub Personal Access Token'
    CWE = 'CWE-798'
    Severity = 'Critical'
  }
    
  # Slack Tokens
  'SlackToken' = @{
    Pattern = 'xox[baprs]-([0-9a-zA-Z]{10,48})'
    Description = 'Slack Token'
    CWE = 'CWE-798'
    Severity = 'High'
  }
    
  # JWT Tokens
  'JWT' = @{
    Pattern = 'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*'
    Description = 'JSON Web Token (JWT)'
    CWE = 'CWE-798'
    Severity = 'High'
  }
    
  # SSH Private Keys
  'SSHPrivateKey' = @{
    Pattern = '-----BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY-----'
    Description = 'SSH Private Key'
    CWE = 'CWE-798'
    Severity = 'Critical'
  }
    
  # Database Connection Strings
  'DatabaseConnectionString' = @{
    Pattern = '(?i)(server|data source|host)=.*(password|pwd)=[^;''"\s]+'
    Description = 'Database Connection String with Password'
    CWE = 'CWE-798'
    Severity = 'Critical'
  }
    
  # API Keys (Generic)
  'GenericAPIKey' = @{
    Pattern = '(?i)(api[_-]?key|apikey|api[_-]?secret)[''"\s:=]+[a-zA-Z0-9_\-]{20,}'
    Description = 'Generic API Key'
    CWE = 'CWE-798'
    Severity = 'High'
  }
    
  # Password in Code (Generic)
  'PasswordInCode' = @{
    Pattern = '(?i)(password|passwd|pwd)\s*=\s*[''"][^''"]{8,}[''"]'
    Description = 'Hard-coded Password'
    CWE = 'CWE-259'
    Severity = 'High'
  }
}

#endregion

#region MITRE ATT&CK Detection

$script:MITREPatterns = @{
  # T1059.001 - PowerShell
  'PowerShellObfuscation' = @{
    Pattern = '(?i)-[eE]nc(odedcommand)?\s+[A-Za-z0-9+/=]{20,}'
    Technique = 'T1059.001'
    Tactic = 'Execution'
    Description = 'PowerShell encoded command (potential obfuscation)'
    Severity = 'High'
  }
    
  # T1027 - Obfuscation
  'Base64Obfuscation' = @{
    Pattern = '\[System\.Convert\]::FromBase64String\('
    Technique = 'T1027'
    Tactic = 'Defense Evasion'
    Description = 'Base64 encoding/decoding (potential obfuscation)'
    Severity = 'Medium'
  }
    
  # T1552.001 - Credentials in Files
  'CredentialsInFiles' = @{
    Pattern = '(?i)(ConvertTo-SecureString.*-AsPlainText|Get-Credential.*-Password)'
    Technique = 'T1552.001'
    Tactic = 'Credential Access'
    Description = 'Credentials in files or scripts'
    Severity = 'High'
  }
    
  # T1053.005 - Scheduled Task/Job
  'ScheduledTaskCreation' = @{
    Pattern = '(?i)(New-ScheduledTask|Register-ScheduledTask|schtasks\s+/create)'
    Technique = 'T1053.005'
    Tactic = 'Persistence'
    Description = 'Scheduled task creation'
    Severity = 'Medium'
  }
    
  # T1070.001 - Clear Windows Event Logs
  'EventLogClearing' = @{
    Pattern = '(?i)(Clear-EventLog|wevtutil\s+cl|Remove-EventLog)'
    Technique = 'T1070.001'
    Tactic = 'Defense Evasion'
    Description = 'Event log clearing'
    Severity = 'High'
  }
    
  # T1071 - Application Layer Protocol
  'WebRequestsUnsafe' = @{
    Pattern = '(?i)(Invoke-WebRequest|Invoke-RestMethod|New-Object.*Net\.WebClient).*\$\w+'
    Technique = 'T1071'
    Tactic = 'Command and Control'
    Description = 'Web request with user-controlled URL'
    Severity = 'Medium'
  }
    
  # T1140 - Deobfuscate/Decode Files or Information
  'DeobfuscationAttempt' = @{
    Pattern = '(?i)(IEX|Invoke-Expression).*\(.*\[.*Convert.*\]'
    Technique = 'T1140'
    Tactic = 'Defense Evasion'
    Description = 'Dynamic code execution with encoded content'
    Severity = 'High'
  }
    
  # T1218 - System Binary Proxy Execution
  'SystemBinaryProxy' = @{
    Pattern = '(?i)(rundll32|regsvr32|mshta)\.exe'
    Technique = 'T1218'
    Tactic = 'Defense Evasion'
    Description = 'System binary proxy execution'
    Severity = 'Medium'
  }
}

#endregion

#region Detection Functions

function Test-EnhancedSecurityIssue {
  <#
    .SYNOPSIS
        Comprehensive security analysis with CWE and MITRE ATT&CK mappings
    
    .DESCRIPTION
        Performs advanced security detection beyond PSScriptAnalyzer:
        - Secrets and credentials detection
        - MITRE ATT&CK technique detection
        - CWE vulnerability identification
        - OWASP Top 10 2023 coverage
    
    .PARAMETER Content
        PowerShell script content to analyze
    
    .PARAMETER FilePath
        Path to the file being analyzed
    
    .EXAMPLE
        $issues = Test-EnhancedSecurityIssues -Content $scriptContent -FilePath "script.ps1"
    
    .OUTPUTS
        Array of security issue objects with CWE/ATT&CK mappings
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath = ''
  )
    
  $issues = @()
    
  # Detect secrets
  $issues += Find-SecretsInCode -Content $Content -FilePath $FilePath
    
  # Detect MITRE ATT&CK techniques
  $issues += Find-MITREATTCKPatterns -Content $Content -FilePath $FilePath
    
  # Detect code injection vulnerabilities
  $issues += Find-CodeInjectionVulnerabilities -Content $Content -FilePath $FilePath
    
  # Detect cryptographic weaknesses
  $issues += Find-CryptographicWeaknesses -Content $Content -FilePath $FilePath
    
  # Detect path traversal vulnerabilities
  $issues += Find-PathTraversalVulnerabilities -Content $Content -FilePath $FilePath
    
  return $issues
}

function Find-SecretsInCode {
  <#
    .SYNOPSIS
        Detect hard-coded secrets in code
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath
  )
    
  $findings = @()
    
  foreach ($secretType in $script:SecretsPatterns.Keys) {
    $pattern = $script:SecretsPatterns[$secretType]
        
    if ($Content -match $pattern.Pattern) {
      $findings += [PSCustomObject]@{
        Type = 'Secret'
        Name = $secretType
        Description = $pattern.Description
        CWE = $pattern.CWE
        Severity = $pattern.Severity
        FilePath = $FilePath
        Recommendation = "Remove hard-coded secret and use secure secret management (Azure Key Vault, AWS Secrets Manager, etc.)"
        OWASP = 'A02:2023-Cryptographic Failures'
        Line = Get-LineNumber -Content $Content -Pattern $pattern.Pattern
      }
    }
  }
    
  return $findings
}

function Find-MITREATTCKPattern {
  <#
    .SYNOPSIS
        Detect MITRE ATT&CK techniques
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath
  )
    
  $findings = @()
    
  foreach ($attackType in $script:MITREPatterns.Keys) {
    $pattern = $script:MITREPatterns[$attackType]
        
    if ($Content -match $pattern.Pattern) {
      $findings += [PSCustomObject]@{
        Type = 'MITRE_ATTCK'
        Name = $attackType
        Description = $pattern.Description
        Technique = $pattern.Technique
        Tactic = $pattern.Tactic
        Severity = $pattern.Severity
        FilePath = $FilePath
        Recommendation = Get-MITREMitigation -Technique $pattern.Technique
        Line = Get-LineNumber -Content $Content -Pattern $pattern.Pattern
      }
    }
  }
    
  return $findings
}

function Find-CodeInjectionVulnerability {
  <#
    .SYNOPSIS
        Detect code injection vulnerabilities (CWE-94)
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath
  )
    
  $findings = @()
  $injectionPatterns = @(
    'Invoke-Expression\s+\$',
    'iex\s+\$',
    '\|\s*iex',
    '\|\s*Invoke-Expression',
    'Invoke-Command.*-ScriptBlock.*\$'
  )
    
  foreach ($pattern in $injectionPatterns) {
    if ($Content -match $pattern) {
      $findings += [PSCustomObject]@{
        Type = 'Vulnerability'
        Name = 'CodeInjection'
        Description = 'Potential code injection via dynamic execution'
        CWE = 'CWE-94'
        MITREATTCK = 'T1059.001'
        OWASP = 'A03:2023-Injection'
        Severity = 'Critical'
        FilePath = $FilePath
        Recommendation = "Avoid Invoke-Expression with user input. Use parameterized commands or script blocks with bound parameters."
        Line = Get-LineNumber -Content $Content -Pattern $pattern
      }
    }
  }
    
  return $findings
}

function Find-CryptographicWeakness {
  <#
    .SYNOPSIS
        Detect weak cryptographic algorithms (CWE-327)
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath
  )
    
  $findings = @()
  $weakAlgos = @{
    'MD5' = 'MD5 is cryptographically broken and unsuitable for security'
    'SHA1' = 'SHA1 is deprecated and vulnerable to collision attacks'
    'DES' = 'DES has inadequate key length and is deprecated'
    'RC4' = 'RC4 has known vulnerabilities and is deprecated'
    'TripleDES' = 'TripleDES is deprecated; use AES instead'
  }
    
  foreach ($algo in $weakAlgos.Keys) {
    $pattern = "(?i)(New-Object.*$algo|System\.Security\.Cryptography\.$algo)"
    if ($Content -match $pattern) {
      $findings += [PSCustomObject]@{
        Type = 'Vulnerability'
        Name = 'WeakCryptography'
        Description = $weakAlgos[$algo]
        CWE = 'CWE-327'
        OWASP = 'A02:2023-Cryptographic Failures'
        Severity = 'High'
        FilePath = $FilePath
        Recommendation = "Use strong cryptographic algorithms: AES-256, SHA-256 or SHA-512"
        Line = Get-LineNumber -Content $Content -Pattern $pattern
      }
    }
  }
    
  return $findings
}

function Find-PathTraversalVulnerability {
  <#
    .SYNOPSIS
        Detect path traversal vulnerabilities (CWE-22)
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [string]$FilePath
  )
    
  $findings = @()
    
  # Pattern: User input directly used in file paths without validation
  $pattern = '(Get-Content|Set-Content|Remove-Item|Copy-Item|Move-Item).*\$\w+.*\.\.'
    
  if ($Content -match $pattern) {
    $findings += [PSCustomObject]@{
      Type = 'Vulnerability'
      Name = 'PathTraversal'
      Description = 'Potential path traversal with user-controlled path'
      CWE = 'CWE-22'
      MITREATTCK = 'T1083'
      OWASP = 'A01:2023-Broken Access Control'
      Severity = 'High'
      FilePath = $FilePath
      Recommendation = "Validate and sanitize file paths. Use Join-Path and Resolve-Path with -Relative parameter."
      Line = Get-LineNumber -Content $Content -Pattern $pattern
    }
  }
    
  return $findings
}

function Get-LineNumber {
  <#
    .SYNOPSIS
        Get line number for a pattern match
    #>
  [CmdletBinding()]
  param(
    [string]$Content,
    [string]$Pattern
  )
    
  $lines = $Content -split "`n"
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $Pattern) {
      return $i + 1
    }
  }
  return 0
}

function Get-MITREMitigation {
  <#
    .SYNOPSIS
        Get mitigation recommendation for MITRE ATT&CK technique
    #>
  [CmdletBinding()]
  param(
    [string]$Technique
  )
    
  $mitigations = @{
    'T1059.001' = 'Use application allowlisting, code signing, and PowerShell Constrained Language Mode'
    'T1027' = 'Use code signing and verify signatures before execution'
    'T1552.001' = 'Use secure credential management systems like Azure Key Vault or AWS Secrets Manager'
    'T1053.005' = 'Restrict scheduled task creation to administrators only'
    'T1070.001' = 'Implement log forwarding to SIEM and restrict access to event log management'
    'T1071' = 'Implement network egress filtering and monitor outbound connections'
    'T1140' = 'Disable dynamic code execution or use Constrained Language Mode'
    'T1218' = 'Implement application allowlisting and monitor system binary usage'
  }
    
  return $mitigations[$Technique] ?? 'Review MITRE ATT&CK guidance for mitigation strategies'
}

#endregion

#region Reporting

function Get-SecurityReport {
  <#
    .SYNOPSIS
        Generate comprehensive security report
    
    .PARAMETER Issues
        Array of security issues
    
    .EXAMPLE
        $report = Get-SecurityReport -Issues $securityIssues
    #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [array]$Issues
  )
    
  $summary = @{
    TotalIssues = $Issues.Count
    Critical = ($Issues | Where-Object { $_.Severity -eq 'Critical' }).Count
    High = ($Issues | Where-Object { $_.Severity -eq 'High' }).Count
    Medium = ($Issues | Where-Object { $_.Severity -eq 'Medium' }).Count
    Low = ($Issues | Where-Object { $_.Severity -eq 'Low' }).Count
        
    ByType = @{}
    ByCWE = @{}
    ByMITRE = @{}
    ByOWASP = @{}
  }
    
  # Group by type
  $Issues | Group-Object -Property Type | ForEach-Object {
    $summary.ByType[$_.Name] = $_.Count
  }
    
  # Group by CWE
  $Issues | Where-Object { $_.CWE } | Group-Object -Property CWE | ForEach-Object {
    $summary.ByCWE[$_.Name] = $_.Count
  }
    
  # Group by MITRE ATT&CK
  $Issues | Where-Object { $_.MITREATTCK -or $_.Technique } | ForEach-Object {
    $technique = $_.MITREATTCK ?? $_.Technique
    if (-not $summary.ByMITRE.ContainsKey($technique)) {
      $summary.ByMITRE[$technique] = 0
    }
    $summary.ByMITRE[$technique]++
  }
    
  # Group by OWASP
  $Issues | Where-Object { $_.OWASP } | Group-Object -Property OWASP | ForEach-Object {
    $summary.ByOWASP[$_.Name] = $_.Count
  }
    
  return [PSCustomObject]@{
    Summary = $summary
    Issues = $Issues
    Timestamp = Get-Date
    ComplianceStatus = Get-ComplianceStatus -Issues $Issues
  }
}

function Get-ComplianceStatus {
  <#
    .SYNOPSIS
        Calculate compliance status based on issues
    #>
  [CmdletBinding()]
  param(
    [array]$Issues
  )
    
  $criticalCount = ($Issues | Where-Object { $_.Severity -eq 'Critical' }).Count
  $highCount = ($Issues | Where-Object { $_.Severity -eq 'High' }).Count
    
  if ($criticalCount -eq 0 -and $highCount -eq 0) {
    return 'Compliant'
  }
  elseif ($criticalCount -eq 0 -and $highCount -le 2) {
    return 'Mostly Compliant'
  }
  elseif ($criticalCount -le 2) {
    return 'Partially Compliant'
  }
  else {
    return 'Non-Compliant'
  }
}

#endregion

#region Export

Export-ModuleMember -Function @(
  'Test-EnhancedSecurityIssues',
  'Find-SecretsInCode',
  'Find-MITREATTCKPatterns',
  'Find-CodeInjectionVulnerabilities',
  'Find-CryptographicWeaknesses',
  'Find-PathTraversalVulnerabilities',
  'Get-SecurityReport'
)

#endregion
