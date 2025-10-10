@{
    # Module manifest for Security module
    RootModule = 'Security.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'https://github.com/cboyd0319'
    CompanyName = 'PoshGuard'
    Copyright = '(c) 2025 PoshGuard. All rights reserved.'
    Description = 'Enterprise-grade security module for PoshGuard - Protected Event Logging, Script Block Logging, Credential Management, and more.'
    PowerShellVersion = '5.1'

    # Nested modules to load
    NestedModules = @(
        'ProtectedEventLogging.psm1'
        'ScriptBlockLogging.psm1'
        'SecureCredentialStore.psm1'
    )

    # Functions to export
    FunctionsToExport = @(
        # Protected Event Logging
        'New-ProtectedEventLoggingCertificate'
        'Get-ProtectedEventLoggingCertificate'
        'Test-ProtectedEventLoggingCertificate'
        'Initialize-ProtectedEventLogging'
        'Protect-EventLogData'
        'Unprotect-EventLogData'
        'Write-ProtectedEventLog'
        'Get-ProtectedEventLog'
        'Get-WindowsProtectedEventLog'

        # Script Block Logging
        'Enable-ScriptBlockLogging'
        'Disable-ScriptBlockLogging'
        'Get-ScriptBlockLoggingStatus'
        'Get-ScriptBlockEvent'
        'Test-ScriptBlockThreat'

        # Secure Credential Store
        'New-SecureCredentialStore'
        'Set-SecureCredential'
        'Get-SecureCredential'
        'Remove-SecureCredential'
        'Test-SecureCredentialStore'
        'Export-SecureCredentialStore'
        'Import-SecureCredentialStore'
        'Get-SecureCredentialStoreStatus'
    )

    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('Security', 'Logging', 'Encryption', 'Credentials', 'Audit', 'Compliance', 'PoshGuard')
            LicenseUri = 'https://github.com/cboyd0319/PoshGuard/blob/main/LICENSE'
            ProjectUri = 'https://github.com/cboyd0319/PoshGuard'
            ReleaseNotes = @'
v1.0.0 - Initial Release
- Protected Event Logging with CMS encryption
- Script Block Logging configuration and monitoring
- Secure Credential Store with DPAPI encryption
- Certificate management and lifecycle
- Threat detection and analysis
- Cross-platform support (where applicable)
'@
        }
    }
}
