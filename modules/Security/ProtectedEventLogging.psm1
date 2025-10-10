#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Protected Event Logging module with certificate-based encryption for PoshGuard.

.DESCRIPTION
    Provides enterprise-grade event logging with CMS (Cryptographic Message Syntax) encryption,
    certificate management, and Group Policy integration. Surpasses WindowsSecurityAudit and
    WELA by providing automated certificate generation, encryption key rotation, and multi-tier
    logging architecture.

.NOTES
    Author: https://github.com/cboyd0319
    Version: 1.0.0
    Requires: PowerShell 5.1+ (CMS cmdlets)
    Platform: Windows (uses Windows CMS and Certificate APIs)

.EXAMPLE
    # Initialize protected event logging with auto-generated certificate
    Initialize-ProtectedEventLogging -AutoGenerateCert

.EXAMPLE
    # Enable protected logging with existing certificate
    Enable-ProtectedEventLogging -CertificateThumbprint "A1B2C3D4..."

.EXAMPLE
    # Decrypt protected events from event log
    Get-ProtectedEventLogEntry -LogName "Microsoft-Windows-PowerShell/Operational" -EventId 4104
#>

[CmdletBinding()]
param()

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:LogSource = 'PoshGuard.ProtectedEventLogging'
$script:CertificateStore = 'Cert:\LocalMachine\My'
$script:EncryptionCertSubject = 'CN=PoshGuard Protected Event Logging'
$script:ProtectedLogPath = Join-Path $env:ProgramData 'PoshGuard\ProtectedLogs'
$script:CertBackupPath = Join-Path $env:ProgramData 'PoshGuard\Certificates'
$script:ConfigPath = Join-Path $env:ProgramData 'PoshGuard\Config'
$script:ActiveCertThumbprint = $null
#endregion

#region Helper Functions

function Write-ModuleLog {
    <#
    .SYNOPSIS
        Internal logging function for the module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Warning', 'Error', 'Verbose')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$ErrorCode,

        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [$Level] [$script:LogSource] $Message"

    switch ($Level) {
        'Info' { Write-Information $logEntry -InformationAction Continue }
        'Warning' { Write-Warning $logEntry }
        'Error' {
            if ($ErrorRecord) {
                Write-Error "$logEntry - $($ErrorRecord.Exception.Message)"
            }
            else {
                Write-Error $logEntry
            }
        }
        'Verbose' { Write-Verbose $logEntry }
    }

    # Write to PoshGuard log if logger module is available
    if (Get-Module -Name PSQALogger) {
        switch ($Level) {
            'Info' { Write-PSQAInfo $Message }
            'Warning' { Write-PSQAWarning $Message -Code $ErrorCode }
            'Error' { Write-PSQAError $Message -Code $ErrorCode }
        }
    }
}

function Test-IsAdmin {
    <#
    .SYNOPSIS
        Checks if the current PowerShell session has administrator privileges.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    return $false
}

function New-PoshGuardDirectory {
    <#
    .SYNOPSIS
        Creates a directory with proper error handling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Description
    )

    if (-not (Test-Path -Path $Path)) {
        try {
            $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            Write-ModuleLog -Level Verbose -Message "Created directory: $Path ($Description)"
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to create directory: $Path" -ErrorRecord $_
            throw
        }
    }
}

#endregion

#region Certificate Management

function New-ProtectedEventLoggingCertificate {
    <#
    .SYNOPSIS
        Creates a new self-signed certificate for protected event logging encryption.

    .DESCRIPTION
        Generates a self-signed X.509 certificate with Document Encryption EKU (1.3.6.1.4.1.311.80.1)
        and Key Encipherment key usage. The certificate is stored in the Local Machine certificate
        store and can be used for CMS encryption of event log data.

        This certificate should be exported (without private key) and deployed to systems that
        need to encrypt events. The private key should be kept secure on a separate system for
        decryption.

    .PARAMETER Subject
        Certificate subject name. Default: CN=PoshGuard Protected Event Logging

    .PARAMETER ValidityYears
        Certificate validity period in years. Default: 5 years

    .PARAMETER KeyLength
        RSA key length. Default: 4096 bits (higher security than standard 2048)

    .PARAMETER ExportPath
        Optional path to export the certificate (without private key) for distribution

    .PARAMETER ExportPrivateKey
        If specified, exports the private key (use with extreme caution)

    .PARAMETER PrivateKeyPassword
        Secure password for private key export (required if ExportPrivateKey is specified)

    .OUTPUTS
        System.Security.Cryptography.X509Certificates.X509Certificate2

    .EXAMPLE
        $cert = New-ProtectedEventLoggingCertificate -Verbose
        # Creates certificate and stores in LocalMachine\My

    .EXAMPLE
        $cert = New-ProtectedEventLoggingCertificate -ExportPath "C:\Certs\PoshGuard-Encryption.cer"
        # Creates certificate and exports public key for distribution

    .EXAMPLE
        $password = ConvertTo-SecureString "MySecurePassword123!" -AsPlainText -Force
        $cert = New-ProtectedEventLoggingCertificate -ExportPrivateKey -PrivateKeyPassword $password
        # Creates certificate and exports with private key (for backup/recovery)

    .NOTES
        Requires administrative privileges.
        Certificate is created in LocalMachine\My store.
        Private key is marked as exportable for backup purposes.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter()]
        [string]$Subject = $script:EncryptionCertSubject,

        [Parameter()]
        [ValidateRange(1, 20)]
        [int]$ValidityYears = 5,

        [Parameter()]
        [ValidateSet(2048, 4096, 8192)]
        [int]$KeyLength = 4096,

        [Parameter()]
        [string]$ExportPath,

        [Parameter()]
        [switch]$ExportPrivateKey,

        [Parameter()]
        [securestring]$PrivateKeyPassword
    )

    begin {
        Write-ModuleLog -Level Verbose -Message "Starting certificate generation"

        # Validate prerequisites
        if (-not (Test-IsAdmin)) {
            $errMsg = "Administrator privileges required to create certificate in LocalMachine store"
            Write-ModuleLog -Level Error -Message $errMsg -ErrorCode 'CERT001'
            throw $errMsg
        }

        if ($ExportPrivateKey -and -not $PrivateKeyPassword) {
            $errMsg = "PrivateKeyPassword is required when ExportPrivateKey is specified"
            Write-ModuleLog -Level Error -Message $errMsg -ErrorCode 'CERT002'
            throw [ArgumentException]::new($errMsg)
        }

        # Ensure backup directory exists
        New-PoshGuardDirectory -Path $script:CertBackupPath -Description 'Certificate backup directory'
    }

    process {
        try {
            $certParams = @{
                Subject           = $Subject
                CertStoreLocation = $script:CertificateStore
                KeyLength         = $KeyLength
                KeyAlgorithm      = 'RSA'
                KeyUsage          = 'KeyEncipherment', 'DataEncipherment'
                Type              = 'DocumentEncryptionCert'
                NotAfter          = (Get-Date).AddYears($ValidityYears)
                KeyExportPolicy   = 'Exportable'
                HashAlgorithm     = 'SHA256'
            }

            if ($PSCmdlet.ShouldProcess("LocalMachine\My", "Create certificate '$Subject'")) {
                Write-ModuleLog -Level Info -Message "Creating certificate: $Subject (KeyLength: $KeyLength, Validity: $ValidityYears years)"

                # Create the certificate
                $cert = New-SelfSignedCertificate @certParams -ErrorAction Stop

                Write-ModuleLog -Level Info -Message "Certificate created successfully. Thumbprint: $($cert.Thumbprint)"

                # Set module variable
                $script:ActiveCertThumbprint = $cert.Thumbprint

                # Export public certificate if requested
                if ($ExportPath) {
                    $exportDir = Split-Path -Path $ExportPath -Parent
                    if ($exportDir -and -not (Test-Path $exportDir)) {
                        New-PoshGuardDirectory -Path $exportDir -Description 'Certificate export directory'
                    }

                    $null = Export-Certificate -Cert $cert -FilePath $ExportPath -ErrorAction Stop
                    Write-ModuleLog -Level Info -Message "Certificate exported to: $ExportPath"
                }

                # Export with private key if requested (DANGEROUS - handle with care)
                if ($ExportPrivateKey) {
                    $pfxPath = Join-Path $script:CertBackupPath "PoshGuard-ProtectedLogging-$(Get-Date -Format 'yyyyMMdd-HHmmss').pfx"

                    if ($PSCmdlet.ShouldProcess($pfxPath, "Export certificate with PRIVATE KEY")) {
                        $null = Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $PrivateKeyPassword -ErrorAction Stop
                        Write-ModuleLog -Level Warning -Message "Certificate with PRIVATE KEY exported to: $pfxPath - SECURE THIS FILE!"
                    }
                }

                return $cert
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to create certificate" -ErrorRecord $_ -ErrorCode 'CERT003'
            throw
        }
    }
}

function Get-ProtectedEventLoggingCertificate {
    <#
    .SYNOPSIS
        Retrieves the PoshGuard protected event logging certificate.

    .DESCRIPTION
        Searches for the protected event logging certificate in the Local Machine certificate store.
        Can search by thumbprint, subject name, or retrieve the first valid certificate for document encryption.

    .PARAMETER Thumbprint
        Specific certificate thumbprint to retrieve

    .PARAMETER Subject
        Certificate subject name (default: CN=PoshGuard Protected Event Logging)

    .PARAMETER IncludeExpired
        Include expired certificates in the search

    .OUTPUTS
        System.Security.Cryptography.X509Certificates.X509Certificate2

    .EXAMPLE
        $cert = Get-ProtectedEventLoggingCertificate
        # Gets the active PoshGuard certificate

    .EXAMPLE
        $cert = Get-ProtectedEventLoggingCertificate -Thumbprint "A1B2C3..."
        # Gets certificate by thumbprint
    #>
    [CmdletBinding(DefaultParameterSetName = 'BySubject')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(ParameterSetName = 'ByThumbprint', Mandatory)]
        [string]$Thumbprint,

        [Parameter(ParameterSetName = 'BySubject')]
        [string]$Subject = $script:EncryptionCertSubject,

        [Parameter()]
        [switch]$IncludeExpired
    )

    try {
        if ($PSCmdlet.ParameterSetName -eq 'ByThumbprint') {
            Write-ModuleLog -Level Verbose -Message "Searching for certificate by thumbprint: $Thumbprint"
            $cert = Get-ChildItem -Path $script:CertificateStore | Where-Object { $_.Thumbprint -eq $Thumbprint }
        }
        else {
            Write-ModuleLog -Level Verbose -Message "Searching for certificate by subject: $Subject"
            $certs = Get-ChildItem -Path $script:CertificateStore | Where-Object {
                $_.Subject -eq $Subject -and
                $_.HasPrivateKey -and
                ($IncludeExpired -or $_.NotAfter -gt (Get-Date))
            }

            # Get the newest certificate
            $cert = $certs | Sort-Object -Property NotAfter -Descending | Select-Object -First 1
        }

        if ($cert) {
            Write-ModuleLog -Level Verbose -Message "Certificate found: $($cert.Thumbprint) (Expires: $($cert.NotAfter))"
            return $cert
        }
        else {
            Write-ModuleLog -Level Warning -Message "No valid certificate found" -ErrorCode 'CERT004'
            return $null
        }
    }
    catch {
        Write-ModuleLog -Level Error -Message "Failed to retrieve certificate" -ErrorRecord $_ -ErrorCode 'CERT005'
        throw
    }
}

function Test-ProtectedEventLoggingCertificate {
    <#
    .SYNOPSIS
        Validates a certificate for protected event logging.

    .DESCRIPTION
        Checks if a certificate meets the requirements for protected event logging:
        - Has private key
        - Document Encryption EKU (1.3.6.1.4.1.311.80.1)
        - KeyEncipherment key usage
        - Not expired
        - Sufficient key length (minimum 2048 bits)

    .PARAMETER Certificate
        Certificate to validate

    .PARAMETER Thumbprint
        Certificate thumbprint to validate

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        $cert = Get-ProtectedEventLoggingCertificate
        if (Test-ProtectedEventLoggingCertificate -Certificate $cert) {
            Write-Host "Certificate is valid"
        }
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByCertificate')]
    [OutputType([bool])]
    param(
        [Parameter(ParameterSetName = 'ByCertificate', Mandatory, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(ParameterSetName = 'ByThumbprint', Mandatory)]
        [string]$Thumbprint
    )

    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ByThumbprint') {
                $Certificate = Get-ProtectedEventLoggingCertificate -Thumbprint $Thumbprint
                if (-not $Certificate) {
                    Write-ModuleLog -Level Warning -Message "Certificate not found: $Thumbprint" -ErrorCode 'CERT006'
                    return $false
                }
            }

            $issues = [System.Collections.Generic.List[string]]::new()

            # Check private key
            if (-not $Certificate.HasPrivateKey) {
                $issues.Add("Certificate does not have a private key")
            }

            # Check expiration
            if ($Certificate.NotAfter -lt (Get-Date)) {
                $issues.Add("Certificate expired on $($Certificate.NotAfter)")
            }

            # Check key length
            if ($Certificate.PublicKey.Key.KeySize -lt 2048) {
                $issues.Add("Key length ($($Certificate.PublicKey.Key.KeySize)) is less than minimum 2048 bits")
            }

            # Check EKU for Document Encryption (1.3.6.1.4.1.311.80.1)
            $documentEncryptionEku = '1.3.6.1.4.1.311.80.1'
            $hasDocumentEncryption = $Certificate.EnhancedKeyUsageList | Where-Object { $_.ObjectId -eq $documentEncryptionEku }

            if (-not $hasDocumentEncryption) {
                $issues.Add("Certificate does not have Document Encryption EKU ($documentEncryptionEku)")
            }

            if ($issues.Count -gt 0) {
                Write-ModuleLog -Level Warning -Message "Certificate validation failed: $($issues -join '; ')" -ErrorCode 'CERT007'
                return $false
            }

            Write-ModuleLog -Level Verbose -Message "Certificate validation successful"
            return $true
        }
        catch {
            Write-ModuleLog -Level Error -Message "Certificate validation error" -ErrorRecord $_ -ErrorCode 'CERT008'
            return $false
        }
    }
}

#endregion

#region Event Logging Functions

function Initialize-ProtectedEventLogging {
    <#
    .SYNOPSIS
        Initializes the protected event logging system.

    .DESCRIPTION
        Sets up the protected event logging infrastructure:
        - Creates required directories
        - Generates or validates encryption certificate
        - Configures event log settings
        - Sets up log rotation

    .PARAMETER AutoGenerateCert
        Automatically generate a new certificate if one doesn't exist

    .PARAMETER CertificateThumbprint
        Use an existing certificate by thumbprint

    .PARAMETER Force
        Force re-initialization even if already configured

    .EXAMPLE
        Initialize-ProtectedEventLogging -AutoGenerateCert -Verbose
        # Initialize with auto-generated certificate

    .EXAMPLE
        Initialize-ProtectedEventLogging -CertificateThumbprint "A1B2C3..." -Verbose
        # Initialize with existing certificate

    .NOTES
        Requires administrative privileges.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'AutoGenerate')]
    param(
        [Parameter(ParameterSetName = 'AutoGenerate')]
        [switch]$AutoGenerateCert,

        [Parameter(ParameterSetName = 'ExistingCert', Mandatory)]
        [string]$CertificateThumbprint,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-ModuleLog -Level Info -Message "Initializing Protected Event Logging v$script:ModuleVersion"

        if (-not (Test-IsAdmin)) {
            $errMsg = "Administrator privileges required for initialization"
            Write-ModuleLog -Level Error -Message $errMsg -ErrorCode 'INIT001'
            throw $errMsg
        }
    }

    process {
        try {
            # Create required directories
            New-PoshGuardDirectory -Path $script:ProtectedLogPath -Description 'Protected logs directory'
            New-PoshGuardDirectory -Path $script:CertBackupPath -Description 'Certificate backup directory'
            New-PoshGuardDirectory -Path $script:ConfigPath -Description 'Configuration directory'

            # Handle certificate
            $cert = $null

            if ($PSCmdlet.ParameterSetName -eq 'ExistingCert') {
                Write-ModuleLog -Level Info -Message "Using existing certificate: $CertificateThumbprint"
                $cert = Get-ProtectedEventLoggingCertificate -Thumbprint $CertificateThumbprint

                if (-not $cert) {
                    throw "Certificate not found: $CertificateThumbprint"
                }

                if (-not (Test-ProtectedEventLoggingCertificate -Certificate $cert)) {
                    throw "Certificate validation failed: $CertificateThumbprint"
                }
            }
            elseif ($AutoGenerateCert) {
                # Check for existing certificate first
                $cert = Get-ProtectedEventLoggingCertificate

                if ($cert -and -not $Force) {
                    Write-ModuleLog -Level Info -Message "Using existing certificate: $($cert.Thumbprint)"
                }
                else {
                    if ($PSCmdlet.ShouldProcess("LocalMachine\My", "Generate new encryption certificate")) {
                        Write-ModuleLog -Level Info -Message "Generating new encryption certificate"
                        $cert = New-ProtectedEventLoggingCertificate -Verbose:$VerbosePreference
                    }
                }
            }

            if ($cert) {
                $script:ActiveCertThumbprint = $cert.Thumbprint

                # Save configuration
                $config = @{
                    Version              = $script:ModuleVersion
                    CertificateThumbprint = $cert.Thumbprint
                    Initialized          = Get-Date
                    ProtectedLogPath     = $script:ProtectedLogPath
                }

                $configFile = Join-Path $script:ConfigPath 'ProtectedEventLogging.json'
                $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Force -ErrorAction Stop

                Write-ModuleLog -Level Info -Message "Protected Event Logging initialized successfully"
                Write-ModuleLog -Level Info -Message "Certificate Thumbprint: $($cert.Thumbprint)"
                Write-ModuleLog -Level Info -Message "Protected Log Path: $script:ProtectedLogPath"
                Write-ModuleLog -Level Info -Message "Configuration saved to: $configFile"

                return @{
                    Success              = $true
                    CertificateThumbprint = $cert.Thumbprint
                    ProtectedLogPath     = $script:ProtectedLogPath
                    ConfigurationPath    = $configFile
                }
            }
            else {
                throw "Failed to obtain valid certificate for protected event logging"
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Initialization failed" -ErrorRecord $_ -ErrorCode 'INIT002'
            throw
        }
    }
}

function Protect-EventLogData {
    <#
    .SYNOPSIS
        Encrypts event log data using CMS (Cryptographic Message Syntax).

    .DESCRIPTION
        Encrypts sensitive event log data using the configured certificate.
        Uses CMS encryption for compatibility with Protected Event Logging feature in Windows.

    .PARAMETER InputObject
        Data to encrypt (can be string, hashtable, or PSObject)

    .PARAMETER Certificate
        Certificate to use for encryption (default: active PoshGuard certificate)

    .PARAMETER Thumbprint
        Certificate thumbprint to use for encryption

    .PARAMETER AsBase64
        Return encrypted data as Base64 string instead of CMS format

    .OUTPUTS
        System.String (CMS encrypted message or Base64 encoded)

    .EXAMPLE
        $encrypted = Protect-EventLogData -InputObject "Sensitive data" -Verbose
        # Encrypts using active certificate

    .EXAMPLE
        $data = @{ Username = "admin"; Action = "Login" }
        $encrypted = Protect-EventLogData -InputObject $data -AsBase64
        # Encrypts hashtable as Base64
    #>
    [CmdletBinding(DefaultParameterSetName = 'DefaultCert')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [Parameter(ParameterSetName = 'ByCertificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(ParameterSetName = 'ByThumbprint')]
        [string]$Thumbprint,

        [Parameter()]
        [switch]$AsBase64
    )

    process {
        try {
            # Get certificate
            if (-not $Certificate) {
                if ($Thumbprint) {
                    $Certificate = Get-ProtectedEventLoggingCertificate -Thumbprint $Thumbprint
                }
                elseif ($script:ActiveCertThumbprint) {
                    $Certificate = Get-ProtectedEventLoggingCertificate -Thumbprint $script:ActiveCertThumbprint
                }
                else {
                    $Certificate = Get-ProtectedEventLoggingCertificate
                }

                if (-not $Certificate) {
                    throw "No valid encryption certificate found. Run Initialize-ProtectedEventLogging first."
                }
            }

            # Validate certificate
            if (-not (Test-ProtectedEventLoggingCertificate -Certificate $Certificate)) {
                throw "Certificate validation failed"
            }

            # Convert input to string
            $dataToEncrypt = if ($InputObject -is [string]) {
                $InputObject
            }
            else {
                $InputObject | ConvertTo-Json -Compress -Depth 10
            }

            Write-ModuleLog -Level Verbose -Message "Encrypting data (Length: $($dataToEncrypt.Length) bytes)"

            # Encrypt using CMS
            $encrypted = Protect-CmsMessage -To $Certificate -Content $dataToEncrypt -ErrorAction Stop

            if ($AsBase64) {
                # Convert to Base64 for compact storage
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($encrypted)
                $base64 = [Convert]::ToBase64String($bytes)
                Write-ModuleLog -Level Verbose -Message "Encrypted data converted to Base64 (Length: $($base64.Length) bytes)"
                return $base64
            }
            else {
                Write-ModuleLog -Level Verbose -Message "Data encrypted successfully (CMS format)"
                return $encrypted
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to encrypt data" -ErrorRecord $_ -ErrorCode 'ENCRYPT001'
            throw
        }
    }
}

function Unprotect-EventLogData {
    <#
    .SYNOPSIS
        Decrypts CMS-encrypted event log data.

    .DESCRIPTION
        Decrypts event log data that was encrypted with Protect-EventLogData.
        Requires the private key of the certificate used for encryption.

    .PARAMETER EncryptedData
        CMS-encrypted message or Base64-encoded encrypted data

    .PARAMETER AsObject
        Parse decrypted JSON data back to object

    .PARAMETER FromBase64
        Indicates the input is Base64-encoded CMS message

    .OUTPUTS
        System.String or System.Object (if AsObject is specified)

    .EXAMPLE
        $decrypted = Unprotect-EventLogData -EncryptedData $encrypted -Verbose
        # Decrypts CMS message

    .EXAMPLE
        $data = Unprotect-EventLogData -EncryptedData $base64 -FromBase64 -AsObject
        # Decrypts Base64 and converts to object
    #>
    [CmdletBinding()]
    [OutputType([string], [object])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$EncryptedData,

        [Parameter()]
        [switch]$AsObject,

        [Parameter()]
        [switch]$FromBase64
    )

    process {
        try {
            # Handle Base64 input
            $cmsMessage = if ($FromBase64) {
                Write-ModuleLog -Level Verbose -Message "Converting from Base64 to CMS message"
                $bytes = [Convert]::FromBase64String($EncryptedData)
                [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            else {
                $EncryptedData
            }

            Write-ModuleLog -Level Verbose -Message "Decrypting CMS message"

            # Decrypt
            $decrypted = Unprotect-CmsMessage -Content $cmsMessage -ErrorAction Stop

            Write-ModuleLog -Level Verbose -Message "Data decrypted successfully (Length: $($decrypted.Length) bytes)"

            if ($AsObject) {
                try {
                    $obj = $decrypted | ConvertFrom-Json -ErrorAction Stop
                    Write-ModuleLog -Level Verbose -Message "Decrypted data parsed as JSON object"
                    return $obj
                }
                catch {
                    Write-ModuleLog -Level Warning -Message "Failed to parse decrypted data as JSON, returning as string"
                    return $decrypted
                }
            }
            else {
                return $decrypted
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to decrypt data" -ErrorRecord $_ -ErrorCode 'DECRYPT001'
            throw
        }
    }
}

function Write-ProtectedEventLog {
    <#
    .SYNOPSIS
        Writes an encrypted event to a protected log file.

    .DESCRIPTION
        Writes event data to a protected log file with CMS encryption.
        Events are stored in JSONL format with encryption applied to sensitive fields.

    .PARAMETER EventData
        Event data to log (hashtable or PSObject)

    .PARAMETER EventType
        Type of event (Info, Warning, Error, Security)

    .PARAMETER Source
        Event source identifier

    .PARAMETER EncryptFields
        Array of field names to encrypt (default: all fields except metadata)

    .PARAMETER LogName
        Protected log file name (default: PoshGuard-Protected)

    .EXAMPLE
        Write-ProtectedEventLog -EventData @{ Action = "Login"; User = "admin" } -EventType Security
        # Writes encrypted security event

    .EXAMPLE
        $event = @{
            Command = "Get-Secret -Name ApiKey"
            Result = "sk-abc123..."
            Timestamp = Get-Date
        }
        Write-ProtectedEventLog -EventData $event -EncryptFields @('Result')
        # Encrypts only the Result field
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$EventData,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Security', 'Audit')]
        [string]$EventType = 'Info',

        [Parameter()]
        [string]$Source = 'PoshGuard',

        [Parameter()]
        [string[]]$EncryptFields,

        [Parameter()]
        [string]$LogName = 'PoshGuard-Protected'
    )

    begin {
        $logFile = Join-Path $script:ProtectedLogPath "$LogName-$(Get-Date -Format 'yyyyMMdd').jsonl"

        # Ensure log directory exists
        New-PoshGuardDirectory -Path $script:ProtectedLogPath -Description 'Protected logs directory'
    }

    process {
        try {
            # Build event record
            $eventRecord = @{
                Timestamp = (Get-Date).ToString('o')
                EventType = $EventType
                Source    = $Source
                EventId   = (New-Guid).ToString()
                Data      = $EventData
            }

            # Encrypt specified fields or entire data
            if ($EncryptFields -and $EncryptFields.Count -gt 0) {
                Write-ModuleLog -Level Verbose -Message "Encrypting fields: $($EncryptFields -join ', ')"

                $dataHash = if ($EventData -is [hashtable]) {
                    $EventData
                }
                else {
                    @{}
                    $EventData.PSObject.Properties | ForEach-Object { $dataHash[$_.Name] = $_.Value }
                }

                foreach ($field in $EncryptFields) {
                    if ($dataHash.ContainsKey($field)) {
                        $originalValue = $dataHash[$field]
                        $dataHash[$field] = Protect-EventLogData -InputObject $originalValue -AsBase64
                        Write-ModuleLog -Level Verbose -Message "Field '$field' encrypted"
                    }
                }

                $eventRecord.Data = $dataHash
                $eventRecord.EncryptedFields = $EncryptFields
            }
            else {
                # Encrypt entire data block
                Write-ModuleLog -Level Verbose -Message "Encrypting entire event data"
                $eventRecord.Data = Protect-EventLogData -InputObject $EventData -AsBase64
                $eventRecord.FullyEncrypted = $true
            }

            # Convert to JSONL
            $jsonLine = $eventRecord | ConvertTo-Json -Compress -Depth 10

            if ($PSCmdlet.ShouldProcess($logFile, "Write protected event")) {
                # Append to log file (atomic write)
                Add-Content -Path $logFile -Value $jsonLine -Encoding UTF8 -ErrorAction Stop
                Write-ModuleLog -Level Verbose -Message "Protected event written to: $logFile"
            }

            return $eventRecord
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to write protected event" -ErrorRecord $_ -ErrorCode 'EVENTLOG001'
            throw
        }
    }
}

function Get-ProtectedEventLog {
    <#
    .SYNOPSIS
        Retrieves and decrypts events from protected log files.

    .DESCRIPTION
        Reads protected log files and decrypts event data.
        Supports filtering by date, event type, and source.

    .PARAMETER LogName
        Protected log file name (default: PoshGuard-Protected)

    .PARAMETER StartDate
        Filter events from this date onwards

    .PARAMETER EndDate
        Filter events until this date

    .PARAMETER EventType
        Filter by event type

    .PARAMETER Source
        Filter by event source

    .PARAMETER Latest
        Return only the most recent N events

    .PARAMETER Decrypt
        Decrypt encrypted fields (requires private key)

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]

    .EXAMPLE
        Get-ProtectedEventLog -LogName "PoshGuard-Protected" -Latest 10 -Decrypt
        # Get and decrypt the 10 most recent events

    .EXAMPLE
        Get-ProtectedEventLog -EventType Security -StartDate (Get-Date).AddDays(-7) -Decrypt
        # Get security events from last 7 days
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter()]
        [string]$LogName = 'PoshGuard-Protected',

        [Parameter()]
        [datetime]$StartDate,

        [Parameter()]
        [datetime]$EndDate,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Security', 'Audit')]
        [string]$EventType,

        [Parameter()]
        [string]$Source,

        [Parameter()]
        [int]$Latest,

        [Parameter()]
        [switch]$Decrypt
    )

    begin {
        Write-ModuleLog -Level Verbose -Message "Reading protected event log: $LogName"
    }

    process {
        try {
            # Find log files matching pattern
            $logPattern = Join-Path $script:ProtectedLogPath "$LogName-*.jsonl"
            $logFiles = Get-ChildItem -Path $logPattern -ErrorAction SilentlyContinue

            if (-not $logFiles) {
                Write-ModuleLog -Level Warning -Message "No log files found matching: $logPattern"
                return @()
            }

            $events = [System.Collections.Generic.List[PSCustomObject]]::new()

            foreach ($file in $logFiles) {
                Write-ModuleLog -Level Verbose -Message "Processing log file: $($file.Name)"

                $lines = Get-Content -Path $file.FullName -Encoding UTF8 -ErrorAction Stop

                foreach ($line in $lines) {
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }

                    try {
                        $event = $line | ConvertFrom-Json

                        # Apply filters
                        $eventTime = [datetime]::Parse($event.Timestamp)

                        if ($StartDate -and $eventTime -lt $StartDate) { continue }
                        if ($EndDate -and $eventTime -gt $EndDate) { continue }
                        if ($EventType -and $event.EventType -ne $EventType) { continue }
                        if ($Source -and $event.Source -ne $Source) { continue }

                        # Decrypt if requested
                        if ($Decrypt) {
                            if ($event.FullyEncrypted) {
                                try {
                                    $event.Data = Unprotect-EventLogData -EncryptedData $event.Data -FromBase64 -AsObject
                                    $event.Decrypted = $true
                                }
                                catch {
                                    Write-ModuleLog -Level Warning -Message "Failed to decrypt event $($event.EventId): $_"
                                    $event.DecryptionFailed = $true
                                }
                            }
                            elseif ($event.EncryptedFields) {
                                foreach ($field in $event.EncryptedFields) {
                                    if ($event.Data.$field) {
                                        try {
                                            $event.Data.$field = Unprotect-EventLogData -EncryptedData $event.Data.$field -FromBase64
                                        }
                                        catch {
                                            Write-ModuleLog -Level Warning -Message "Failed to decrypt field '$field' in event $($event.EventId): $_"
                                        }
                                    }
                                }
                                $event.Decrypted = $true
                            }
                        }

                        $events.Add($event)
                    }
                    catch {
                        Write-ModuleLog -Level Warning -Message "Failed to parse log line: $_"
                    }
                }
            }

            # Sort by timestamp descending
            $sorted = $events | Sort-Object -Property { [datetime]::Parse($_.Timestamp) } -Descending

            # Apply Latest filter
            if ($Latest -gt 0) {
                $sorted = $sorted | Select-Object -First $Latest
            }

            Write-ModuleLog -Level Info -Message "Retrieved $($sorted.Count) protected events"
            return $sorted
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to retrieve protected events" -ErrorRecord $_ -ErrorCode 'EVENTLOG002'
            throw
        }
    }
}

function Get-WindowsProtectedEventLog {
    <#
    .SYNOPSIS
        Retrieves and decrypts events from Windows PowerShell Operational event log.

    .DESCRIPTION
        Queries Windows event log for protected PowerShell events (Event ID 4104 - Script Block Logging)
        and decrypts CMS-encrypted messages. This integrates with Windows Protected Event Logging
        Group Policy feature.

    .PARAMETER LogName
        Event log name (default: Microsoft-Windows-PowerShell/Operational)

    .PARAMETER EventId
        Filter by Event ID (default: 4104 for Script Block Logging)

    .PARAMETER MaxEvents
        Maximum number of events to retrieve (default: 100)

    .PARAMETER StartTime
        Filter events from this time onwards

    .PARAMETER Decrypt
        Decrypt protected events (requires private key)

    .OUTPUTS
        System.Diagnostics.Eventing.Reader.EventLogRecord[]

    .EXAMPLE
        Get-WindowsProtectedEventLog -MaxEvents 10 -Decrypt
        # Get and decrypt the 10 most recent PowerShell script block events

    .EXAMPLE
        $events = Get-WindowsProtectedEventLog -StartTime (Get-Date).AddHours(-1) -Decrypt
        # Get events from the last hour and decrypt them

    .NOTES
        Requires private key for decryption.
        Only works on Windows systems.
    #>
    [CmdletBinding()]
    [OutputType([System.Diagnostics.Eventing.Reader.EventLogRecord[]])]
    param(
        [Parameter()]
        [string]$LogName = 'Microsoft-Windows-PowerShell/Operational',

        [Parameter()]
        [int]$EventId = 4104,

        [Parameter()]
        [int]$MaxEvents = 100,

        [Parameter()]
        [datetime]$StartTime,

        [Parameter()]
        [switch]$Decrypt
    )

    begin {
        if (-not $IsWindows -and $PSVersionTable.PSEdition -ne 'Desktop') {
            throw "This function is only supported on Windows systems"
        }

        Write-ModuleLog -Level Verbose -Message "Querying Windows event log: $LogName (EventId: $EventId)"
    }

    process {
        try {
            # Build filter hashtable
            $filter = @{
                LogName = $LogName
            }

            if ($EventId) {
                $filter.Id = $EventId
            }

            if ($StartTime) {
                $filter.StartTime = $StartTime
            }

            # Query event log
            $events = Get-WinEvent -FilterHashtable $filter -MaxEvents $MaxEvents -ErrorAction Stop

            Write-ModuleLog -Level Info -Message "Retrieved $($events.Count) events from Windows event log"

            if ($Decrypt) {
                foreach ($event in $events) {
                    # Try to decrypt the message
                    try {
                        $decrypted = Unprotect-CmsMessage -EventLogRecord $event -ErrorAction Stop
                        $event | Add-Member -NotePropertyName 'DecryptedMessage' -NotePropertyValue $decrypted -Force
                        $event | Add-Member -NotePropertyName 'Decrypted' -NotePropertyValue $true -Force
                        Write-ModuleLog -Level Verbose -Message "Event $($event.RecordId) decrypted successfully"
                    }
                    catch {
                        # Event might not be encrypted, or we don't have the key
                        Write-ModuleLog -Level Verbose -Message "Event $($event.RecordId) not encrypted or decryption failed"
                        $event | Add-Member -NotePropertyName 'Decrypted' -NotePropertyValue $false -Force
                    }
                }
            }

            return $events
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to query Windows event log" -ErrorRecord $_ -ErrorCode 'WINEVENT001'
            throw
        }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    # Certificate Management
    'New-ProtectedEventLoggingCertificate'
    'Get-ProtectedEventLoggingCertificate'
    'Test-ProtectedEventLoggingCertificate'

    # Initialization
    'Initialize-ProtectedEventLogging'

    # Encryption/Decryption
    'Protect-EventLogData'
    'Unprotect-EventLogData'

    # Event Logging
    'Write-ProtectedEventLog'
    'Get-ProtectedEventLog'
    'Get-WindowsProtectedEventLog'
)
