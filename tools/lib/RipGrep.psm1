#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    RipGrep Integration Module for PoshGuard

.DESCRIPTION
    Provides high-performance pre-filtering and secret scanning using RipGrep (rg).
    Dramatically improves performance for large codebases by using RipGrep to identify
    candidate files before expensive AST analysis.

    Features:
    - Pre-filtering for AST analysis (5-10x speedup)
    - Secret scanning with pattern matching
    - Configuration file validation
    - Multi-repository scanning
    - SARIF report enhancement
    - Incremental CI/CD scanning support

.NOTES
    Author: PoshGuard Contributors
    Version: 1.0.0
    Requires: RipGrep 14.0+ (optional - falls back to slower scanning if not installed)
    Part of PoshGuard v4.3.0+
#>

Set-StrictMode -Version Latest

#region Helper Functions

<#
.SYNOPSIS
    Test if RipGrep is available on the system

.DESCRIPTION
    Checks if 'rg' command is available and returns version information

.OUTPUTS
    PSCustomObject with IsAvailable and Version properties
#>
function Test-RipGrepAvailable {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        $version = rg --version 2>$null | Select-Object -First 1
        if ($version -match 'ripgrep (\d+\.\d+\.\d+)') {
            return [PSCustomObject]@{
                IsAvailable = $true
                Version = $Matches[1]
            }
        }
    }
    catch {
        Write-Verbose "RipGrep not available: $_"
    }

    return [PSCustomObject]@{
        IsAvailable = $false
        Version = $null
    }
}

#endregion

#region Pre-Filtering Functions

<#
.SYNOPSIS
    Find PowerShell scripts with suspicious patterns using RipGrep

.DESCRIPTION
    Uses RipGrep to quickly identify PowerShell scripts that contain high-risk
    patterns before running expensive AST analysis. This dramatically improves
    performance for large codebases.

.PARAMETER Path
    Path to directory to scan

.PARAMETER Patterns
    Array of regex patterns to search for (defaults to common security issues)

.PARAMETER IncludeTests
    Include test files in the scan (default: false)

.OUTPUTS
    Array of file paths that match the patterns

.EXAMPLE
    Find-SuspiciousScripts -Path ./src
    Find all suspicious scripts in ./src directory

.EXAMPLE
    Find-SuspiciousScripts -Path ./src -Patterns @('Invoke-Expression', 'DownloadString')
    Find scripts with specific patterns
#>
function Find-SuspiciousScripts {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [string[]]$Patterns = @(
            'ConvertTo-SecureString\s+-AsPlainText',
            'Invoke-Expression',
            'iex\s+',
            'Start-Process.*-Credential',
            'password\s*=\s*[''"][^''"]+[''"]',
            'api[_-]?key\s*=',
            'DownloadString',
            'DownloadFile',
            'System\.Net\.WebClient',
            'Invoke-RestMethod.*-Uri.*\$'
        ),

        [Parameter()]
        [switch]$IncludeTests
    )

    $rgCheck = Test-RipGrepAvailable
    if (-not $rgCheck.IsAvailable) {
        Write-Warning "RipGrep not installed. Falling back to slower Get-ChildItem scan."
        Write-Warning "Install RipGrep for 10-100x faster scanning: https://github.com/BurntSushi/ripgrep"
        return Get-ChildItem -Path $Path -Recurse -Filter *.ps1 | Select-Object -ExpandProperty FullName
    }

    $rgArgs = @(
        '--files-with-matches',
        '--type', 'ps1',
        '--ignore-case'
    )

    # Exclude test files by default
    if (-not $IncludeTests) {
        $rgArgs += @('--glob', '!*test*', '--glob', '!*.Tests.ps1')
    }

    # Build regex pattern
    $pattern = $Patterns -join '|'
    $rgArgs += $pattern
    $rgArgs += $Path

    try {
        # Execute ripgrep
        $candidateFiles = & rg @rgArgs 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            return $candidateFiles
        }
        elseif ($LASTEXITCODE -eq 1) {
            # No matches found (expected case)
            return @()
        }
        else {
            Write-Warning "RipGrep returned exit code $LASTEXITCODE. Falling back to Get-ChildItem."
            return Get-ChildItem -Path $Path -Recurse -Filter *.ps1 | Select-Object -ExpandProperty FullName
        }
    }
    catch {
        Write-Warning "RipGrep execution failed: $_. Falling back to Get-ChildItem."
        return Get-ChildItem -Path $Path -Recurse -Filter *.ps1 | Select-Object -ExpandProperty FullName
    }
}

#endregion

#region Secret Scanning Functions

<#
.SYNOPSIS
    Find hardcoded secrets in PowerShell scripts using RipGrep

.DESCRIPTION
    Fast credential detection across entire repositories using pattern matching.
    Detects AWS keys, GitHub tokens, passwords, API keys, and more.

.PARAMETER Path
    Path to directory to scan

.PARAMETER ExportSarif
    Export findings to SARIF format

.PARAMETER SarifOutputPath
    Path to save SARIF output (default: poshguard-secrets.sarif)

.OUTPUTS
    Array of PSCustomObject with File, Line, SecretType, Match, and Severity properties

.EXAMPLE
    Find-HardcodedSecrets -Path ./scripts
    Scan for hardcoded secrets in scripts directory

.EXAMPLE
    $secrets = Find-HardcodedSecrets -Path ./src -ExportSarif
    if ($secrets.Count -gt 0) { exit 1 }
    Scan and fail if secrets found
#>
function Find-HardcodedSecrets {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [switch]$ExportSarif,

        [Parameter()]
        [string]$SarifOutputPath = './poshguard-secrets.sarif'
    )

    $rgCheck = Test-RipGrepAvailable
    if (-not $rgCheck.IsAvailable) {
        Write-Warning "RipGrep not installed. Secret scanning requires RipGrep for best performance."
        Write-Warning "Install from: https://github.com/BurntSushi/ripgrep"
        return @()
    }

    $secretPatterns = @{
        'AWS Access Key' = 'AKIA[0-9A-Z]{16}'
        'Generic API Key' = 'api[_-]?key\s*[=:]\s*[''"][a-zA-Z0-9]{20,}[''"]'
        'Password' = 'password\s*[=:]\s*[''"][^''"]{8,}[''"]'
        'Private Key' = '-----BEGIN (RSA|DSA|EC) PRIVATE KEY-----'
        'Azure Connection String' = 'DefaultEndpointsProtocol=https;AccountName='
        'GitHub Token' = 'ghp_[a-zA-Z0-9]{36}'
        'Slack Token' = 'xox[baprs]-[a-zA-Z0-9-]+'
        'Generic Secret' = 'secret\s*[=:]\s*[''"][^''"]{8,}[''"]'
        'Database Connection' = '(Server|Data Source)=.*;.*Password='
        'Base64 Encoded' = '(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=){1}'
    }

    $findings = @()

    foreach ($secretType in $secretPatterns.Keys) {
        $pattern = $secretPatterns[$secretType]

        try {
            # Run ripgrep with context
            $results = & rg --type ps1 `
                          --ignore-case `
                          --line-number `
                          --no-heading `
                          --color never `
                          --only-matching `
                          --max-count 1000 `
                          --glob '!*test*' `
                          --glob '!*.Tests.ps1' `
                          $pattern $Path 2>$null

            if ($LASTEXITCODE -eq 0 -and $results) {
                foreach ($match in $results) {
                    if ($match -match '^(.+):(\d+):(.+)$') {
                        # Redact the actual secret for security
                        $redactedMatch = $Matches[3] -replace '([''"])[^''"]{8,}([''"])', '$1***REDACTED***$2'
                        
                        $findings += [PSCustomObject]@{
                            File = $Matches[1]
                            Line = [int]$Matches[2]
                            SecretType = $secretType
                            Match = $redactedMatch
                            Severity = 'CRITICAL'
                        }
                    }
                }
            }
        }
        catch {
            Write-Verbose "Error scanning for $secretType : $_"
        }
    }

    if ($ExportSarif -and $findings.Count -gt 0) {
        Export-SecretFindingsToSarif -Findings $findings -OutputPath $SarifOutputPath
    }

    return $findings
}

<#
.SYNOPSIS
    Export secret findings to SARIF format

.DESCRIPTION
    Converts secret findings to SARIF format for GitHub Code Scanning integration

.PARAMETER Findings
    Array of findings from Find-HardcodedSecrets

.PARAMETER OutputPath
    Path to save SARIF file

.EXAMPLE
    Export-SecretFindingsToSarif -Findings $secrets -OutputPath ./results.sarif
#>
function Export-SecretFindingsToSarif {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$Findings,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $results = @()
    foreach ($finding in $Findings) {
        $results += @{
            ruleId = "PoshGuard-Secret-$($finding.SecretType -replace '\s', '')"
            level = 'error'
            message = @{
                text = "Hardcoded $($finding.SecretType) detected"
            }
            locations = @(
                @{
                    physicalLocation = @{
                        artifactLocation = @{
                            uri = $finding.File
                        }
                        region = @{
                            startLine = $finding.Line
                        }
                    }
                }
            )
        }
    }

    $sarif = @{
        version = '2.1.0'
        '$schema' = 'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json'
        runs = @(
            @{
                tool = @{
                    driver = @{
                        name = 'PoshGuard RipGrep Secret Scanner'
                        version = '1.0.0'
                        informationUri = 'https://github.com/cboyd0319/PoshGuard'
                    }
                }
                results = $results
            }
        )
    }

    $sarif | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Verbose "SARIF report exported to: $OutputPath"
}

#endregion

#region Configuration Validation Functions

<#
.SYNOPSIS
    Test module security configuration across PowerShell scripts

.DESCRIPTION
    Search across multiple .psd1 module manifests and scripts for security
    misconfigurations like execution policy bypasses and unsigned scripts.

.PARAMETER Path
    Path to directory to scan

.OUTPUTS
    Array of PSCustomObject with File, Issue, and Rule properties

.EXAMPLE
    Test-ModuleSecurityConfig -Path ./modules
    Check all modules for security issues
#>
function Test-ModuleSecurityConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $rgCheck = Test-RipGrepAvailable
    if (-not $rgCheck.IsAvailable) {
        Write-Warning "RipGrep not installed. Configuration validation requires RipGrep."
        return @()
    }

    $issues = @()

    try {
        # Check for execution policy bypasses
        $bypassFiles = & rg --type ps1 `
                          --files-with-matches `
                          'Set-ExecutionPolicy.*-Scope.*Process.*-Force' `
                          $Path 2>$null

        if ($LASTEXITCODE -eq 0 -and $bypassFiles) {
            foreach ($file in $bypassFiles) {
                $issues += [PSCustomObject]@{
                    File = $file
                    Issue = 'ExecutionPolicy bypass detected'
                    Rule = 'SEC-001'
                    Severity = 'HIGH'
                }
            }
        }

        # Check for unsigned script execution indicators
        $unsignedFiles = & rg --glob '*.ps1' `
                            --files-without-match `
                            '# SIG # Begin signature block' `
                            $Path 2>$null

        if ($LASTEXITCODE -eq 0 -and $unsignedFiles) {
            foreach ($file in $unsignedFiles) {
                $issues += [PSCustomObject]@{
                    File = $file
                    Issue = 'Unsigned script detected'
                    Rule = 'SEC-002'
                    Severity = 'MEDIUM'
                }
            }
        }

        # Check for dangerous cmdlet usage
        $dangerousCmdlets = & rg --type ps1 `
                              --files-with-matches `
                              'Invoke-Expression|Start-Process.*-Credential|ConvertTo-SecureString.*-AsPlainText' `
                              $Path 2>$null

        if ($LASTEXITCODE -eq 0 -and $dangerousCmdlets) {
            foreach ($file in $dangerousCmdlets) {
                $issues += [PSCustomObject]@{
                    File = $file
                    Issue = 'Dangerous cmdlet usage detected'
                    Rule = 'SEC-003'
                    Severity = 'HIGH'
                }
            }
        }
    }
    catch {
        Write-Warning "Configuration validation error: $_"
    }

    return $issues
}

#endregion

#region Multi-Repository Scanning Functions

<#
.SYNOPSIS
    Perform organization-wide security scanning across multiple repositories

.DESCRIPTION
    Scan entire PowerShell Gallery or enterprise GitHub org for vulnerabilities
    using parallel processing and RipGrep pre-filtering.

.PARAMETER OrgPath
    Path containing cloned repositories

.PARAMETER OutputPath
    Directory to save scan results

.OUTPUTS
    PSCustomObject with scan summary

.EXAMPLE
    Invoke-OrgWideScan -OrgPath ./repos -OutputPath ./scan-results
    Scan all repos in ./repos directory
#>
function Invoke-OrgWideScan {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$OrgPath,

        [Parameter()]
        [string]$OutputPath = './org-scan-results'
    )

    $rgCheck = Test-RipGrepAvailable
    if (-not $rgCheck.IsAvailable) {
        Write-Warning "RipGrep not installed. Organization-wide scanning requires RipGrep."
        return $null
    }

    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    try {
        # Find all PowerShell scripts across all repos
        $allScripts = & rg --files --type ps1 $OrgPath 2>$null
        $scriptCount = if ($allScripts) { ($allScripts | Measure-Object).Count } else { 0 }

        Write-Host "Found $scriptCount PowerShell scripts across organization"

        # Pre-filter for high-risk patterns
        $highRiskScripts = & rg --files-with-matches `
                              --type ps1 `
                              'Invoke-Expression|DownloadString|ConvertTo-SecureString.*-AsPlainText' `
                              $OrgPath 2>$null

        $highRiskCount = if ($highRiskScripts) { ($highRiskScripts | Measure-Object).Count } else { 0 }
        Write-Host "Prioritizing $highRiskCount high-risk scripts for detailed analysis"

        # Scan for secrets
        $secrets = Find-HardcodedSecrets -Path $OrgPath
        $secretsPath = Join-Path $OutputPath 'secrets.json'
        $secrets | ConvertTo-Json -Depth 10 | Set-Content -Path $secretsPath -Encoding UTF8

        # Scan for configuration issues
        $configIssues = Test-ModuleSecurityConfig -Path $OrgPath
        $configPath = Join-Path $OutputPath 'config-issues.json'
        $configIssues | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8

        # Return summary
        return [PSCustomObject]@{
            TotalScripts = $scriptCount
            HighRiskScripts = $highRiskCount
            SecretsFound = $secrets.Count
            ConfigIssues = $configIssues.Count
            OutputPath = $OutputPath
            Timestamp = Get-Date
        }
    }
    catch {
        Write-Error "Organization-wide scan failed: $_"
        return $null
    }
}

#endregion

#region SARIF Report Enhancement Functions

<#
.SYNOPSIS
    Extract critical findings from SARIF reports

.DESCRIPTION
    Use RipGrep to find specific CWE patterns in SARIF files for dashboard reporting.

.PARAMETER SarifPath
    Path to SARIF file

.PARAMETER CWEFilter
    Array of CWE IDs to filter (e.g., 'CWE-798', 'CWE-327')

.OUTPUTS
    Array of PSCustomObject with Line and CWE properties

.EXAMPLE
    Get-CriticalFindings -SarifPath ./results.sarif -CWEFilter @('CWE-798')
    Extract CWE-798 findings from SARIF
#>
function Get-CriticalFindings {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$SarifPath,

        [Parameter()]
        [string[]]$CWEFilter = @('CWE-798', 'CWE-327', 'CWE-502')
    )

    $rgCheck = Test-RipGrepAvailable
    if (-not $rgCheck.IsAvailable) {
        Write-Warning "RipGrep not installed. SARIF querying requires RipGrep."
        return @()
    }

    if (-not (Test-Path $SarifPath)) {
        Write-Warning "SARIF file not found: $SarifPath"
        return @()
    }

    $findings = @()
    $cwePattern = $CWEFilter -join '|'

    try {
        $criticalLines = & rg --json `
                            --max-count 1000 `
                            $cwePattern `
                            $SarifPath 2>$null

        if ($LASTEXITCODE -eq 0 -and $criticalLines) {
            # Parse JSON output and extract findings
            $criticalLines | ForEach-Object {
                try {
                    $jsonLine = $_ | ConvertFrom-Json
                    if ($jsonLine.type -eq 'match') {
                        $cweMatch = $jsonLine.data.lines.text | Select-String -Pattern 'CWE-\d+' -AllMatches
                        if ($cweMatch) {
                            foreach ($match in $cweMatch.Matches) {
                                $findings += [PSCustomObject]@{
                                    Line = $jsonLine.data.line_number
                                    CWE = $match.Value
                                    Context = $jsonLine.data.lines.text
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Error parsing JSON line: $_"
                }
            }
        }
    }
    catch {
        Write-Warning "Error querying SARIF file: $_"
    }

    return $findings
}

#endregion

# Export all functions
Export-ModuleMember -Function @(
    'Test-RipGrepAvailable',
    'Find-SuspiciousScripts',
    'Find-HardcodedSecrets',
    'Export-SecretFindingsToSarif',
    'Test-ModuleSecurityConfig',
    'Invoke-OrgWideScan',
    'Get-CriticalFindings'
)
