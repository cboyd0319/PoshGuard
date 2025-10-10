#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    PoshGuard Security Module - Enterprise-grade security for PowerShell.

.DESCRIPTION
    Comprehensive security module providing:
    - Protected Event Logging with CMS encryption
    - Script Block Logging configuration and monitoring
    - Secure Credential Storage with DPAPI
    - Threat detection and analysis
    - Certificate lifecycle management
    - Audit and compliance support

    This module surpasses WindowsSecurityAudit and WELA by providing
    automated certificate management, intelligent threat detection,
    and enterprise-ready credential storage.

.NOTES
    Author: https://github.com/cboyd0319
    Version: 1.0.0
    Requires: PowerShell 5.1+
    Platform: Cross-platform (some features Windows-only)

.EXAMPLE
    Import-Module ./modules/Security/Security.psd1

.EXAMPLE
    # Quick setup for protected logging
    Initialize-PoshGuardSecurity -EnableProtectedLogging -EnableScriptBlockLogging

.EXAMPLE
    # Get comprehensive security status
    Get-PoshGuardSecurityStatus | Format-List
#>

[CmdletBinding()]
param()

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'PoshGuard.Security'
$script:ConfigPath = Join-Path $env:ProgramData 'PoshGuard\Config'
$script:InitializedModules = @{}
#endregion

#region Helper Functions

function Write-SecurityLog {
    <#
    .SYNOPSIS
        Internal logging function for the Security module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Warning', 'Error', 'Verbose')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Component = 'Security'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [$Level] [$script:ModuleName.$Component] $Message"

    switch ($Level) {
        'Info' { Write-Information $logEntry -InformationAction Continue }
        'Warning' { Write-Warning $logEntry }
        'Error' { Write-Error $logEntry }
        'Verbose' { Write-Verbose $logEntry }
    }

    # Write to PoshGuard logger if available
    if (Get-Module -Name PSQALogger) {
        switch ($Level) {
            'Info' { Write-PSQAInfo $Message }
            'Warning' { Write-PSQAWarning $Message }
            'Error' { Write-PSQAError $Message }
        }
    }
}

#endregion

#region Initialization Functions

function Initialize-PoshGuardSecurity {
    <#
    .SYNOPSIS
        Initializes the PoshGuard Security module with recommended settings.

    .DESCRIPTION
        One-command initialization of the entire security module:
        - Protected Event Logging with auto-generated certificates
        - Script Block Logging configuration
        - Secure Credential Store
        - Security baseline configuration

    .PARAMETER EnableProtectedLogging
        Enable Protected Event Logging with auto-generated certificate

    .PARAMETER EnableScriptBlockLogging
        Enable Script Block Logging (requires admin on Windows)

    .PARAMETER EnableInvocationLogging
        Also enable invocation logging (high volume)

    .PARAMETER CreateCredentialStore
        Create a secure credential store

    .PARAMETER Force
        Force re-initialization even if already configured

    .OUTPUTS
        PSCustomObject with initialization results

    .EXAMPLE
        Initialize-PoshGuardSecurity -EnableProtectedLogging -EnableScriptBlockLogging
        # Full security setup

    .EXAMPLE
        Initialize-PoshGuardSecurity -EnableProtectedLogging -CreateCredentialStore
        # Logging and credential storage only

    .NOTES
        Requires administrator privileges for Script Block Logging configuration.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$EnableProtectedLogging,

        [Parameter()]
        [switch]$EnableScriptBlockLogging,

        [Parameter()]
        [switch]$EnableInvocationLogging,

        [Parameter()]
        [switch]$CreateCredentialStore,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-SecurityLog -Level Info -Message "Initializing PoshGuard Security Module v$script:ModuleVersion"
    }

    process {
        $results = @{
            Success = $true
            Timestamp = Get-Date
            Modules = @{}
            Errors = @()
        }

        try {
            # Initialize Protected Event Logging
            if ($EnableProtectedLogging) {
                Write-SecurityLog -Level Info -Message "Initializing Protected Event Logging" -Component 'ProtectedEventLogging'

                try {
                    if ($PSCmdlet.ShouldProcess('ProtectedEventLogging', 'Initialize')) {
                        $pelResult = Initialize-ProtectedEventLogging -AutoGenerateCert -ErrorAction Stop
                        $results.Modules['ProtectedEventLogging'] = @{
                            Success = $true
                            CertificateThumbprint = $pelResult.CertificateThumbprint
                            ConfigPath = $pelResult.ConfigurationPath
                        }
                        $script:InitializedModules['ProtectedEventLogging'] = $true
                        Write-SecurityLog -Level Info -Message "Protected Event Logging initialized successfully" -Component 'ProtectedEventLogging'
                    }
                }
                catch {
                    $results.Modules['ProtectedEventLogging'] = @{
                        Success = $false
                        Error = $_.Exception.Message
                    }
                    $results.Errors += "ProtectedEventLogging: $($_.Exception.Message)"
                    Write-SecurityLog -Level Error -Message "Failed to initialize Protected Event Logging: $_" -Component 'ProtectedEventLogging'
                }
            }

            # Initialize Script Block Logging
            if ($EnableScriptBlockLogging) {
                Write-SecurityLog -Level Info -Message "Initializing Script Block Logging" -Component 'ScriptBlockLogging'

                try {
                    if ($PSCmdlet.ShouldProcess('ScriptBlockLogging', 'Enable')) {
                        $sblParams = @{ ErrorAction = 'Stop' }
                        if ($EnableInvocationLogging) {
                            $sblParams['EnableInvocationLogging'] = $true
                        }

                        $sblResult = Enable-ScriptBlockLogging @sblParams
                        $results.Modules['ScriptBlockLogging'] = @{
                            Success = $true
                            Enabled = $sblResult.ScriptBlockLoggingEnabled
                            InvocationLogging = $sblResult.InvocationLoggingEnabled
                        }
                        $script:InitializedModules['ScriptBlockLogging'] = $true
                        Write-SecurityLog -Level Info -Message "Script Block Logging enabled successfully" -Component 'ScriptBlockLogging'
                    }
                }
                catch {
                    $results.Modules['ScriptBlockLogging'] = @{
                        Success = $false
                        Error = $_.Exception.Message
                    }
                    $results.Errors += "ScriptBlockLogging: $($_.Exception.Message)"
                    Write-SecurityLog -Level Warning -Message "Failed to enable Script Block Logging (may require admin): $_" -Component 'ScriptBlockLogging'
                }
            }

            # Initialize Credential Store
            if ($CreateCredentialStore) {
                Write-SecurityLog -Level Info -Message "Initializing Secure Credential Store" -Component 'CredentialStore'

                try {
                    if ($PSCmdlet.ShouldProcess('SecureCredentialStore', 'Create')) {
                        $defaultStorePath = Join-Path $env:USERPROFILE '.poshguard\credentials.dat'
                        $credResult = New-SecureCredentialStore -StorePath $defaultStorePath -Force:$Force -ErrorAction Stop
                        $results.Modules['CredentialStore'] = @{
                            Success = $true
                            StorePath = $credResult.StorePath
                        }
                        $script:InitializedModules['CredentialStore'] = $true
                        Write-SecurityLog -Level Info -Message "Secure Credential Store created successfully" -Component 'CredentialStore'
                    }
                }
                catch {
                    $results.Modules['CredentialStore'] = @{
                        Success = $false
                        Error = $_.Exception.Message
                    }
                    $results.Errors += "CredentialStore: $($_.Exception.Message)"
                    Write-SecurityLog -Level Error -Message "Failed to create Credential Store: $_" -Component 'CredentialStore'
                }
            }

            # Save initialization state
            $configFile = Join-Path $script:ConfigPath 'SecurityModuleInit.json'
            if (-not (Test-Path -Path $script:ConfigPath)) {
                $null = New-Item -Path $script:ConfigPath -ItemType Directory -Force
            }

            $results | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Force

            if ($results.Errors.Count -gt 0) {
                $results.Success = $false
                Write-SecurityLog -Level Warning -Message "Initialization completed with errors: $($results.Errors.Count) error(s)"
            }
            else {
                Write-SecurityLog -Level Info -Message "PoshGuard Security Module initialized successfully"
            }

            return [PSCustomObject]$results
        }
        catch {
            Write-SecurityLog -Level Error -Message "Initialization failed: $_"
            throw
        }
    }
}

function Get-PoshGuardSecurityStatus {
    <#
    .SYNOPSIS
        Gets comprehensive status of all PoshGuard Security modules.

    .DESCRIPTION
        Retrieves current configuration status for:
        - Protected Event Logging
        - Script Block Logging
        - Secure Credential Store
        - Overall security posture

    .OUTPUTS
        PSCustomObject with comprehensive security status

    .EXAMPLE
        Get-PoshGuardSecurityStatus | Format-List
        # Shows full security configuration

    .EXAMPLE
        $status = Get-PoshGuardSecurityStatus
        if (-not $status.ProtectedEventLogging.Initialized) {
            Initialize-ProtectedEventLogging -AutoGenerateCert
        }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    begin {
        Write-SecurityLog -Level Verbose -Message "Retrieving PoshGuard Security status"
    }

    process {
        $status = [PSCustomObject]@{
            ModuleVersion = $script:ModuleVersion
            Timestamp = Get-Date
            ProtectedEventLogging = $null
            ScriptBlockLogging = $null
            CredentialStore = $null
            OverallStatus = 'Unknown'
            Recommendations = @()
        }

        # Get Protected Event Logging status
        try {
            $configFile = Join-Path $env:ProgramData 'PoshGuard\Config\ProtectedEventLogging.json'
            if (Test-Path -Path $configFile) {
                $pelConfig = Get-Content -Path $configFile -Raw | ConvertFrom-Json
                $cert = Get-ProtectedEventLoggingCertificate -ErrorAction SilentlyContinue

                $status.ProtectedEventLogging = @{
                    Initialized = $true
                    CertificateThumbprint = $pelConfig.CertificateThumbprint
                    CertificateValid = ($cert -and (Test-ProtectedEventLoggingCertificate -Certificate $cert))
                    CertificateExpiry = $cert.NotAfter
                    InitializedDate = $pelConfig.Initialized
                }
            }
            else {
                $status.ProtectedEventLogging = @{
                    Initialized = $false
                }
                $status.Recommendations += "Initialize Protected Event Logging: Initialize-ProtectedEventLogging -AutoGenerateCert"
            }
        }
        catch {
            $status.ProtectedEventLogging = @{ Initialized = $false; Error = $_.Exception.Message }
        }

        # Get Script Block Logging status
        try {
            $sblStatus = Get-ScriptBlockLoggingStatus -ErrorAction SilentlyContinue
            $status.ScriptBlockLogging = $sblStatus

            if (-not $sblStatus.ScriptBlockLoggingEnabled) {
                $status.Recommendations += "Enable Script Block Logging: Enable-ScriptBlockLogging"
            }
        }
        catch {
            $status.ScriptBlockLogging = @{ Error = $_.Exception.Message }
        }

        # Get Credential Store status
        try {
            $defaultStorePath = Join-Path $env:USERPROFILE '.poshguard\credentials.dat'
            if (Test-Path -Path $defaultStorePath) {
                $storeStatus = Get-SecureCredentialStoreStatus -StorePath $defaultStorePath -ErrorAction SilentlyContinue
                $status.CredentialStore = $storeStatus
            }
            else {
                $status.CredentialStore = @{
                    Exists = $false
                }
                $status.Recommendations += "Create Credential Store: New-SecureCredentialStore"
            }
        }
        catch {
            $status.CredentialStore = @{ Error = $_.Exception.Message }
        }

        # Determine overall status
        $initializedCount = 0
        if ($status.ProtectedEventLogging.Initialized) { $initializedCount++ }
        if ($status.ScriptBlockLogging.ScriptBlockLoggingEnabled) { $initializedCount++ }
        if ($status.CredentialStore.Exists) { $initializedCount++ }

        $status.OverallStatus = switch ($initializedCount) {
            3 { 'Excellent - All modules configured' }
            2 { 'Good - Most modules configured' }
            1 { 'Fair - Some modules configured' }
            0 { 'Poor - No modules configured' }
        }

        return $status
    }
}

#endregion

#region Module Loading

Write-SecurityLog -Level Info -Message "PoshGuard Security Module v$script:ModuleVersion loaded"
Write-SecurityLog -Level Verbose -Message "Nested modules loaded: ProtectedEventLogging, ScriptBlockLogging, SecureCredentialStore"

#endregion

# Export additional orchestration functions
Export-ModuleMember -Function @(
    'Initialize-PoshGuardSecurity'
    'Get-PoshGuardSecurityStatus'
)
