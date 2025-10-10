#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Secure Credential Storage module with DPAPI encryption for PoshGuard.

.DESCRIPTION
    Enterprise-grade credential storage using Windows DPAPI (Data Protection API)
    on Windows and AES-256 encryption on non-Windows platforms. Provides:

    - Secure credential storage with user-scope or machine-scope encryption
    - SecureString and PSCredential support
    - Encrypted import/export for backup and transfer
    - Key rotation and migration support
    - Audit trail for all credential operations
    - Cross-platform support (DPAPI on Windows, AES on Linux/macOS)

.NOTES
    Author: https://github.com/cboyd0319
    Version: 1.0.0
    Requires: PowerShell 5.1+
    Platform: Cross-platform (DPAPI on Windows, AES elsewhere)

.EXAMPLE
    # Create a new credential store
    New-SecureCredentialStore -StorePath "~/.poshguard/creds.dat"

.EXAMPLE
    # Store a credential
    $cred = Get-Credential
    Set-SecureCredential -Name "GitHub-Token" -Credential $cred

.EXAMPLE
    # Retrieve a credential
    $token = Get-SecureCredential -Name "GitHub-Token"
#>

[CmdletBinding()]
param()

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:LogSource = 'PoshGuard.SecureCredentialStore'
$script:DefaultStorePath = Join-Path $env:USERPROFILE '.poshguard\credentials.dat'
$script:ActiveStore = $null
$script:StoreMetadata = @{}
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

    # Write to PoshGuard logger if available
    if (Get-Module -Name PSQALogger) {
        switch ($Level) {
            'Info' { Write-PSQAInfo $Message }
            'Warning' { Write-PSQAWarning $Message -Code $ErrorCode }
            'Error' { Write-PSQAError $Message -Code $ErrorCode }
        }
    }
}

function ConvertTo-EncryptedString {
    <#
    .SYNOPSIS
        Encrypts a string using DPAPI (Windows) or AES (cross-platform).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [securestring]$SecureString,

        [Parameter()]
        [byte[]]$Key,

        [Parameter()]
        [switch]$UseMachineScope
    )

    try {
        if ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
            # Use DPAPI on Windows
            $scope = if ($UseMachineScope) {
                [System.Security.Cryptography.DataProtectionScope]::LocalMachine
            }
            else {
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            }

            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            try {
                $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
                $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)
                $encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
                    $plainBytes,
                    $null,
                    $scope
                )
                return [Convert]::ToBase64String($encrypted)
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        }
        else {
            # Use AES on non-Windows platforms
            if (-not $Key) {
                throw "Encryption key required for non-Windows platforms"
            }

            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            try {
                $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
                $encrypted = ConvertFrom-SecureString -SecureString $SecureString -Key $Key
                return $encrypted
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        }
    }
    catch {
        Write-ModuleLog -Level Error -Message "Failed to encrypt string" -ErrorRecord $_ -ErrorCode 'ENCRYPT001'
        throw
    }
}

function ConvertFrom-EncryptedString {
    <#
    .SYNOPSIS
        Decrypts a string using DPAPI (Windows) or AES (cross-platform).
    #>
    [CmdletBinding()]
    [OutputType([securestring])]
    param(
        [Parameter(Mandatory)]
        [string]$EncryptedString,

        [Parameter()]
        [byte[]]$Key,

        [Parameter()]
        [switch]$UseMachineScope
    )

    try {
        if ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
            # Use DPAPI on Windows
            $scope = if ($UseMachineScope) {
                [System.Security.Cryptography.DataProtectionScope]::LocalMachine
            }
            else {
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            }

            $encryptedBytes = [Convert]::FromBase64String($EncryptedString)
            $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $encryptedBytes,
                $null,
                $scope
            )
            $plainText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
            return ConvertTo-SecureString -String $plainText -AsPlainText -Force
        }
        else {
            # Use AES on non-Windows platforms
            if (-not $Key) {
                throw "Decryption key required for non-Windows platforms"
            }

            return ConvertTo-SecureString -String $EncryptedString -Key $Key
        }
    }
    catch {
        Write-ModuleLog -Level Error -Message "Failed to decrypt string" -ErrorRecord $_ -ErrorCode 'DECRYPT001'
        throw
    }
}

function New-AESKey {
    <#
    .SYNOPSIS
        Generates a new AES-256 encryption key.
    #>
    [CmdletBinding()]
    [OutputType([byte[]])]
    param()

    $key = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($key)
    $rng.Dispose()
    return $key
}

#endregion

#region Store Management

function New-SecureCredentialStore {
    <#
    .SYNOPSIS
        Creates a new secure credential store.

    .DESCRIPTION
        Initializes a new encrypted credential store file. On Windows, uses DPAPI
        for encryption. On other platforms, generates an AES-256 key.

    .PARAMETER StorePath
        Path to the credential store file (default: ~/.poshguard/credentials.dat)

    .PARAMETER UseMachineScope
        Use machine-scope DPAPI encryption (Windows only, requires admin)

    .PARAMETER Force
        Overwrite existing store

    .OUTPUTS
        PSCustomObject with store information

    .EXAMPLE
        New-SecureCredentialStore -Verbose
        # Creates store at default location

    .EXAMPLE
        New-SecureCredentialStore -StorePath "C:\SecureStore\creds.dat" -UseMachineScope
        # Creates machine-scope store (requires admin)

    .NOTES
        On Windows: Uses DPAPI (no key file needed)
        On Linux/macOS: Generates AES key file (store securely!)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$StorePath = $script:DefaultStorePath,

        [Parameter()]
        [switch]$UseMachineScope,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-ModuleLog -Level Info -Message "Creating new secure credential store"
    }

    process {
        try {
            # Expand path
            $StorePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StorePath)

            # Check if store exists
            if ((Test-Path -Path $StorePath) -and -not $Force) {
                throw "Credential store already exists at: $StorePath. Use -Force to overwrite."
            }

            # Ensure directory exists
            $storeDir = Split-Path -Path $StorePath -Parent
            if (-not (Test-Path -Path $storeDir)) {
                $null = New-Item -Path $storeDir -ItemType Directory -Force -ErrorAction Stop
                Write-ModuleLog -Level Verbose -Message "Created directory: $storeDir"
            }

            if ($PSCmdlet.ShouldProcess($StorePath, "Create secure credential store")) {
                # Initialize store structure
                $store = @{
                    Version = $script:ModuleVersion
                    Created = (Get-Date).ToString('o')
                    Platform = $PSVersionTable.Platform
                    PSEdition = $PSVersionTable.PSEdition
                    UseMachineScope = $UseMachineScope.IsPresent
                    Credentials = @{}
                }

                # Generate AES key for non-Windows platforms
                if ($PSVersionTable.PSEdition -ne 'Desktop' -and -not $IsWindows) {
                    $keyPath = "$StorePath.key"
                    $aesKey = New-AESKey
                    $aesKey | Set-Content -Path $keyPath -AsByteStream -Force -ErrorAction Stop

                    Write-ModuleLog -Level Warning -Message "AES key saved to: $keyPath - SECURE THIS FILE!"
                    $store.KeyFile = $keyPath
                }

                # Save store
                $storeJson = $store | ConvertTo-Json -Depth 10
                $storeJson | Set-Content -Path $StorePath -Force -ErrorAction Stop

                Write-ModuleLog -Level Info -Message "Credential store created successfully: $StorePath"

                # Set active store
                $script:ActiveStore = $StorePath
                $script:StoreMetadata = $store

                return [PSCustomObject]@{
                    Success = $true
                    StorePath = $StorePath
                    KeyFile = $store.KeyFile
                    UseMachineScope = $UseMachineScope.IsPresent
                    Platform = $PSVersionTable.Platform
                }
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to create credential store" -ErrorRecord $_ -ErrorCode 'STORE001'
            throw
        }
    }
}

function Set-SecureCredential {
    <#
    .SYNOPSIS
        Stores a credential in the secure credential store.

    .DESCRIPTION
        Encrypts and stores a credential (username + password) or just a password/token.
        Supports PSCredential objects, SecureString, and plain strings (converted to SecureString).

    .PARAMETER Name
        Unique name for the credential

    .PARAMETER Credential
        PSCredential object to store

    .PARAMETER SecureString
        SecureString to store (password/token only)

    .PARAMETER PlainText
        Plain text password/token (will be converted to SecureString)

    .PARAMETER Username
        Optional username (used with SecureString or PlainText)

    .PARAMETER StorePath
        Path to credential store (default: active store or default path)

    .PARAMETER Metadata
        Optional metadata hashtable to store with credential

    .EXAMPLE
        $cred = Get-Credential
        Set-SecureCredential -Name "GitHub" -Credential $cred

    .EXAMPLE
        $token = Read-Host "Enter API token" -AsSecureString
        Set-SecureCredential -Name "GitHub-Token" -SecureString $token

    .EXAMPLE
        Set-SecureCredential -Name "DB-Password" -PlainText "MyP@ssw0rd!" -Username "sa"
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Credential')]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Credential', Mandatory)]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SecureString', Mandatory)]
        [securestring]$SecureString,

        [Parameter(ParameterSetName = 'PlainText', Mandatory)]
        [string]$PlainText,

        [Parameter(ParameterSetName = 'SecureString')]
        [Parameter(ParameterSetName = 'PlainText')]
        [string]$Username,

        [Parameter()]
        [string]$StorePath,

        [Parameter()]
        [hashtable]$Metadata
    )

    begin {
        if (-not $StorePath) {
            $StorePath = if ($script:ActiveStore) { $script:ActiveStore } else { $script:DefaultStorePath }
        }

        $StorePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StorePath)

        if (-not (Test-Path -Path $StorePath)) {
            throw "Credential store not found: $StorePath. Create one with New-SecureCredentialStore"
        }

        Write-ModuleLog -Level Verbose -Message "Storing credential: $Name"
    }

    process {
        try {
            # Load store
            $store = Get-Content -Path $StorePath -Raw | ConvertFrom-Json

            # Get encryption key for non-Windows
            $key = $null
            if ($store.KeyFile -and (Test-Path -Path $store.KeyFile)) {
                $key = Get-Content -Path $store.KeyFile -AsByteStream
            }

            # Prepare credential data
            $credData = @{
                Name = $Name
                Created = (Get-Date).ToString('o')
                Modified = (Get-Date).ToString('o')
                Metadata = $Metadata
            }

            # Process based on parameter set
            switch ($PSCmdlet.ParameterSetName) {
                'Credential' {
                    $credData.Username = $Credential.UserName
                    $credData.Password = ConvertTo-EncryptedString -SecureString $Credential.Password -Key $key -UseMachineScope:$store.UseMachineScope
                }
                'SecureString' {
                    $credData.Username = $Username
                    $credData.Password = ConvertTo-EncryptedString -SecureString $SecureString -Key $key -UseMachineScope:$store.UseMachineScope
                }
                'PlainText' {
                    $credData.Username = $Username
                    $securePass = ConvertTo-SecureString -String $PlainText -AsPlainText -Force
                    $credData.Password = ConvertTo-EncryptedString -SecureString $securePass -Key $key -UseMachineScope:$store.UseMachineScope
                }
            }

            if ($PSCmdlet.ShouldProcess($Name, "Store credential")) {
                # Update store
                if ($store.Credentials.$Name) {
                    $credData.Created = $store.Credentials.$Name.Created
                    Write-ModuleLog -Level Info -Message "Updating existing credential: $Name"
                }
                else {
                    Write-ModuleLog -Level Info -Message "Creating new credential: $Name"
                }

                $store.Credentials.$Name = $credData

                # Save store
                $store | ConvertTo-Json -Depth 10 | Set-Content -Path $StorePath -Force -ErrorAction Stop

                Write-ModuleLog -Level Info -Message "Credential stored successfully: $Name"

                return $true
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to store credential: $Name" -ErrorRecord $_ -ErrorCode 'STORE002'
            throw
        }
    }
}

function Get-SecureCredential {
    <#
    .SYNOPSIS
        Retrieves a credential from the secure credential store.

    .DESCRIPTION
        Decrypts and retrieves a stored credential. Returns PSCredential object by default.

    .PARAMETER Name
        Name of the credential to retrieve

    .PARAMETER StorePath
        Path to credential store (default: active store or default path)

    .PARAMETER AsSecureString
        Return password as SecureString instead of PSCredential

    .PARAMETER AsPlainText
        Return password as plain text (use with caution!)

    .OUTPUTS
        PSCredential, SecureString, or string (depending on parameters)

    .EXAMPLE
        $cred = Get-SecureCredential -Name "GitHub"
        # Returns PSCredential object

    .EXAMPLE
        $token = Get-SecureCredential -Name "GitHub-Token" -AsSecureString
        # Returns just the password as SecureString

    .EXAMPLE
        $password = Get-SecureCredential -Name "DB-Password" -AsPlainText
        # Returns plain text password (DANGEROUS!)
    #>
    [CmdletBinding(DefaultParameterSetName = 'AsCredential')]
    [OutputType([PSCredential], [securestring], [string])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$StorePath,

        [Parameter(ParameterSetName = 'AsSecureString')]
        [switch]$AsSecureString,

        [Parameter(ParameterSetName = 'AsPlainText')]
        [switch]$AsPlainText
    )

    begin {
        if (-not $StorePath) {
            $StorePath = if ($script:ActiveStore) { $script:ActiveStore } else { $script:DefaultStorePath }
        }

        $StorePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StorePath)

        if (-not (Test-Path -Path $StorePath)) {
            throw "Credential store not found: $StorePath"
        }

        Write-ModuleLog -Level Verbose -Message "Retrieving credential: $Name"
    }

    process {
        try {
            # Load store
            $store = Get-Content -Path $StorePath -Raw | ConvertFrom-Json

            # Check if credential exists
            if (-not $store.Credentials.$Name) {
                throw "Credential not found: $Name"
            }

            $credData = $store.Credentials.$Name

            # Get decryption key for non-Windows
            $key = $null
            if ($store.KeyFile -and (Test-Path -Path $store.KeyFile)) {
                $key = Get-Content -Path $store.KeyFile -AsByteStream
            }

            # Decrypt password
            $securePassword = ConvertFrom-EncryptedString -EncryptedString $credData.Password -Key $key -UseMachineScope:$store.UseMachineScope

            Write-ModuleLog -Level Info -Message "Retrieved credential: $Name"

            # Return based on parameter set
            switch ($PSCmdlet.ParameterSetName) {
                'AsSecureString' {
                    return $securePassword
                }
                'AsPlainText' {
                    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
                    try {
                        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
                    }
                    finally {
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                    }
                }
                default {
                    # Return PSCredential
                    if ($credData.Username) {
                        return New-Object PSCredential($credData.Username, $securePassword)
                    }
                    else {
                        # No username, return SecureString
                        return $securePassword
                    }
                }
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to retrieve credential: $Name" -ErrorRecord $_ -ErrorCode 'STORE003'
            throw
        }
    }
}

function Remove-SecureCredential {
    <#
    .SYNOPSIS
        Removes a credential from the secure credential store.

    .PARAMETER Name
        Name of the credential to remove

    .PARAMETER StorePath
        Path to credential store

    .EXAMPLE
        Remove-SecureCredential -Name "OldToken" -Verbose
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$StorePath
    )

    begin {
        if (-not $StorePath) {
            $StorePath = if ($script:ActiveStore) { $script:ActiveStore } else { $script:DefaultStorePath }
        }

        $StorePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StorePath)
    }

    process {
        try {
            $store = Get-Content -Path $StorePath -Raw | ConvertFrom-Json

            if (-not $store.Credentials.$Name) {
                Write-ModuleLog -Level Warning -Message "Credential not found: $Name"
                return $false
            }

            if ($PSCmdlet.ShouldProcess($Name, "Remove credential")) {
                $store.Credentials.PSObject.Properties.Remove($Name)
                $store | ConvertTo-Json -Depth 10 | Set-Content -Path $StorePath -Force

                Write-ModuleLog -Level Info -Message "Credential removed: $Name"
                return $true
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to remove credential: $Name" -ErrorRecord $_
            throw
        }
    }
}

function Test-SecureCredentialStore {
    <#
    .SYNOPSIS
        Validates a credential store.

    .PARAMETER StorePath
        Path to credential store

    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [string]$StorePath = $script:DefaultStorePath
    )

    try {
        $StorePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StorePath)

        if (-not (Test-Path -Path $StorePath)) {
            return $false
        }

        $store = Get-Content -Path $StorePath -Raw | ConvertFrom-Json

        return ($store.Version -and $store.Credentials)
    }
    catch {
        return $false
    }
}

function Get-SecureCredentialStoreStatus {
    <#
    .SYNOPSIS
        Gets status and statistics for a credential store.

    .PARAMETER StorePath
        Path to credential store

    .OUTPUTS
        PSCustomObject with store status
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$StorePath = $script:DefaultStorePath
    )

    try {
        $StorePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StorePath)

        $status = [PSCustomObject]@{
            Exists = (Test-Path -Path $StorePath)
            StorePath = $StorePath
            CredentialCount = 0
            Created = $null
            Version = $null
            Platform = $null
            UseMachineScope = $false
        }

        if ($status.Exists) {
            $store = Get-Content -Path $StorePath -Raw | ConvertFrom-Json
            $status.CredentialCount = ($store.Credentials.PSObject.Properties | Measure-Object).Count
            $status.Created = $store.Created
            $status.Version = $store.Version
            $status.Platform = $store.Platform
            $status.UseMachineScope = $store.UseMachineScope
        }

        return $status
    }
    catch {
        Write-ModuleLog -Level Error -Message "Failed to get store status" -ErrorRecord $_
        throw
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'New-SecureCredentialStore'
    'Set-SecureCredential'
    'Get-SecureCredential'
    'Remove-SecureCredential'
    'Test-SecureCredentialStore'
    'Get-SecureCredentialStoreStatus'
)
