#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    PowerShell Script Block Logging configuration and monitoring module for PoshGuard.

.DESCRIPTION
    Provides comprehensive Script Block Logging management with registry configuration,
    Group Policy integration, and advanced event monitoring. Goes beyond basic Windows
    logging by providing intelligent filtering, automatic detection, and threat analysis.

.NOTES
    Author: https://github.com/cboyd0319
    Version: 1.0.0
    Requires: PowerShell 5.1+, Administrator privileges for configuration
    Platform: Windows (Script Block Logging is Windows-only)

.EXAMPLE
    # Enable Script Block Logging with invocation logging
    Enable-ScriptBlockLogging -EnableInvocationLogging

.EXAMPLE
    # Monitor script block events in real-time
    Start-ScriptBlockMonitoring -RealtimeAnalysis -ThreatDetection

.EXAMPLE
    # Get suspicious script block events
    Get-ScriptBlockEvent -SuspiciousOnly -Last24Hours
#>

[CmdletBinding()]
param()

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:LogSource = 'PoshGuard.ScriptBlockLogging'
$script:PSLoggingRegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
$script:PSModuleLoggingRegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging'
$script:EventLogName = 'Microsoft-Windows-PowerShell/Operational'
$script:ScriptBlockEventId = 4104
$script:ModuleLoggingEventId = 4103

# Suspicious patterns for threat detection
$script:SuspiciousPatterns = @(
    @{Pattern = 'Invoke-Expression'; Severity = 'Medium'; Description = 'Dynamic code execution' }
    @{Pattern = 'IEX\s+'; Severity = 'Medium'; Description = 'Invoke-Expression alias' }
    @{Pattern = 'Invoke-WebRequest.*-OutFile'; Severity = 'High'; Description = 'File download' }
    @{Pattern = 'Download(String|File)'; Severity = 'High'; Description = 'Web client download' }
    @{Pattern = 'Start-Process.*-WindowStyle\s+Hidden'; Severity = 'High'; Description = 'Hidden process execution' }
    @{Pattern = 'FromBase64String'; Severity = 'Medium'; Description = 'Base64 decoding (potential obfuscation)' }
    @{Pattern = 'System\.Reflection\.Assembly'; Severity = 'High'; Description = 'Reflection-based loading' }
    @{Pattern = '-EncodedCommand|-enc\s+'; Severity = 'High'; Description = 'Encoded command execution' }
    @{Pattern = 'Add-Type.*-TypeDefinition'; Severity = 'Medium'; Description = 'Dynamic type compilation' }
    @{Pattern = 'Get-WmiObject.*Win32_Process'; Severity = 'Low'; Description = 'Process enumeration' }
    @{Pattern = 'Get-NetTCPConnection'; Severity = 'Low'; Description = 'Network connection enumeration' }
    @{Pattern = 'ConvertTo-SecureString.*-AsPlainText'; Severity = 'High'; Description = 'Plaintext password handling' }
    @{Pattern = '\$.*=.*Get-Credential'; Severity = 'Low'; Description = 'Credential capture' }
    @{Pattern = 'Bypass|Unrestricted'; Severity = 'Medium'; Description = 'Execution policy bypass' }
    @{Pattern = 'mimikatz|invoke-mimikatz'; Severity = 'Critical'; Description = 'Credential dumping tool' }
    @{Pattern = 'powersploit|empire'; Severity = 'Critical'; Description = 'Attack framework' }
)
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

function Test-RegistryPath {
    <#
    .SYNOPSIS
        Tests if a registry path exists, creates it if not.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        try {
            $null = New-Item -Path $Path -Force -ErrorAction Stop
            Write-ModuleLog -Level Verbose -Message "Created registry path: $Path"
            return $true
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to create registry path: $Path" -ErrorRecord $_
            return $false
        }
    }
    return $true
}

#endregion

#region Configuration Functions

function Enable-ScriptBlockLogging {
    <#
    .SYNOPSIS
        Enables PowerShell Script Block Logging via registry configuration.

    .DESCRIPTION
        Configures Windows registry to enable Script Block Logging for all PowerShell
        script blocks. Optionally enables invocation logging for detailed execution traces.

        Script Block Logging records:
        - All script blocks processed by PowerShell
        - Functions, commands, and expressions
        - Deobfuscated code (automatically decodes Base64, etc.)
        - Events written to Microsoft-Windows-PowerShell/Operational log (Event ID 4104)

    .PARAMETER EnableInvocationLogging
        Also enable invocation logging (logs start/stop of each script block)
        WARNING: Generates high volume of events

    .PARAMETER Force
        Force enable even if already enabled

    .EXAMPLE
        Enable-ScriptBlockLogging -Verbose
        # Enables script block logging

    .EXAMPLE
        Enable-ScriptBlockLogging -EnableInvocationLogging -Verbose
        # Enables with detailed invocation logging (high volume!)

    .NOTES
        Requires administrator privileges.
        Changes take effect for new PowerShell sessions.
        Event ID 4104 in Microsoft-Windows-PowerShell/Operational log.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$EnableInvocationLogging,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-ModuleLog -Level Info -Message "Enabling Script Block Logging"

        # Check platform
        if (-not $IsWindows -and $PSVersionTable.PSEdition -ne 'Desktop') {
            throw "Script Block Logging is only supported on Windows"
        }

        # Check admin
        if (-not (Test-IsAdmin)) {
            throw "Administrator privileges required to enable Script Block Logging"
        }
    }

    process {
        try {
            # Check current status
            $currentStatus = Get-ScriptBlockLoggingStatus

            if ($currentStatus.ScriptBlockLoggingEnabled -and -not $Force) {
                Write-ModuleLog -Level Warning -Message "Script Block Logging is already enabled. Use -Force to reconfigure."
                return $currentStatus
            }

            # Ensure registry path exists
            if (-not (Test-RegistryPath -Path $script:PSLoggingRegPath)) {
                throw "Failed to create registry path: $script:PSLoggingRegPath"
            }

            if ($PSCmdlet.ShouldProcess($script:PSLoggingRegPath, "Enable Script Block Logging")) {
                # Enable Script Block Logging
                Set-ItemProperty -Path $script:PSLoggingRegPath `
                    -Name 'EnableScriptBlockLogging' `
                    -Value 1 `
                    -Type DWord `
                    -ErrorAction Stop

                Write-ModuleLog -Level Info -Message "Script Block Logging enabled successfully"

                # Enable invocation logging if requested
                if ($EnableInvocationLogging) {
                    Set-ItemProperty -Path $script:PSLoggingRegPath `
                        -Name 'EnableScriptBlockInvocationLogging' `
                        -Value 1 `
                        -Type DWord `
                        -ErrorAction Stop

                    Write-ModuleLog -Level Warning -Message "Invocation Logging enabled (high volume of events expected)"
                }
                else {
                    # Explicitly disable invocation logging
                    Set-ItemProperty -Path $script:PSLoggingRegPath `
                        -Name 'EnableScriptBlockInvocationLogging' `
                        -Value 0 `
                        -Type DWord `
                        -ErrorAction Stop
                }

                # Return updated status
                $newStatus = Get-ScriptBlockLoggingStatus
                Write-ModuleLog -Level Info -Message "Configuration complete. Restart PowerShell for changes to take full effect."

                return $newStatus
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to enable Script Block Logging" -ErrorRecord $_ -ErrorCode 'SBL001'
            throw
        }
    }
}

function Disable-ScriptBlockLogging {
    <#
    .SYNOPSIS
        Disables PowerShell Script Block Logging.

    .DESCRIPTION
        Configures Windows registry to disable Script Block Logging.
        Also disables invocation logging if enabled.

    .PARAMETER RemoveConfiguration
        Remove registry keys entirely instead of setting to 0

    .EXAMPLE
        Disable-ScriptBlockLogging -Verbose
        # Disables script block logging

    .EXAMPLE
        Disable-ScriptBlockLogging -RemoveConfiguration -Verbose
        # Removes configuration entirely

    .NOTES
        Requires administrator privileges.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$RemoveConfiguration
    )

    begin {
        Write-ModuleLog -Level Info -Message "Disabling Script Block Logging"

        if (-not (Test-IsAdmin)) {
            throw "Administrator privileges required to disable Script Block Logging"
        }
    }

    process {
        try {
            if (-not (Test-Path -Path $script:PSLoggingRegPath)) {
                Write-ModuleLog -Level Warning -Message "Script Block Logging is not configured"
                return
            }

            if ($PSCmdlet.ShouldProcess($script:PSLoggingRegPath, "Disable Script Block Logging")) {
                if ($RemoveConfiguration) {
                    Remove-Item -Path $script:PSLoggingRegPath -Recurse -Force -ErrorAction Stop
                    Write-ModuleLog -Level Info -Message "Script Block Logging configuration removed"
                }
                else {
                    Set-ItemProperty -Path $script:PSLoggingRegPath `
                        -Name 'EnableScriptBlockLogging' `
                        -Value 0 `
                        -Type DWord `
                        -ErrorAction Stop

                    Set-ItemProperty -Path $script:PSLoggingRegPath `
                        -Name 'EnableScriptBlockInvocationLogging' `
                        -Value 0 `
                        -Type DWord `
                        -ErrorAction SilentlyContinue

                    Write-ModuleLog -Level Info -Message "Script Block Logging disabled successfully"
                }

                return Get-ScriptBlockLoggingStatus
            }
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to disable Script Block Logging" -ErrorRecord $_ -ErrorCode 'SBL002'
            throw
        }
    }
}

function Get-ScriptBlockLoggingStatus {
    <#
    .SYNOPSIS
        Gets the current Script Block Logging configuration status.

    .DESCRIPTION
        Retrieves the current state of Script Block Logging and Module Logging
        from Windows registry and system configuration.

    .OUTPUTS
        PSCustomObject with configuration details

    .EXAMPLE
        Get-ScriptBlockLoggingStatus | Format-List
        # Shows current logging configuration

    .NOTES
        Does not require administrator privileges to read status.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    begin {
        Write-ModuleLog -Level Verbose -Message "Checking Script Block Logging status"
    }

    process {
        try {
            $status = [PSCustomObject]@{
                ScriptBlockLoggingEnabled        = $false
                InvocationLoggingEnabled         = $false
                ModuleLoggingEnabled             = $false
                RegistryConfigured               = (Test-Path -Path $script:PSLoggingRegPath)
                ModuleLoggingRegistryConfigured  = (Test-Path -Path $script:PSModuleLoggingRegPath)
                EventLogExists                   = $false
                EventLogEnabled                  = $false
                EventLogMaxSizeMB                = 0
                RecommendedAction                = ''
            }

            # Check Script Block Logging
            if ($status.RegistryConfigured) {
                $sblValue = Get-ItemProperty -Path $script:PSLoggingRegPath -Name 'EnableScriptBlockLogging' -ErrorAction SilentlyContinue
                $status.ScriptBlockLoggingEnabled = ($sblValue.EnableScriptBlockLogging -eq 1)

                $invValue = Get-ItemProperty -Path $script:PSLoggingRegPath -Name 'EnableScriptBlockInvocationLogging' -ErrorAction SilentlyContinue
                $status.InvocationLoggingEnabled = ($invValue.EnableScriptBlockInvocationLogging -eq 1)
            }

            # Check Module Logging
            if ($status.ModuleLoggingRegistryConfigured) {
                $modValue = Get-ItemProperty -Path $script:PSModuleLoggingRegPath -Name 'EnableModuleLogging' -ErrorAction SilentlyContinue
                $status.ModuleLoggingEnabled = ($modValue.EnableModuleLogging -eq 1)
            }

            # Check Event Log
            try {
                $eventLog = Get-WinEvent -ListLog $script:EventLogName -ErrorAction Stop
                $status.EventLogExists = $true
                $status.EventLogEnabled = $eventLog.IsEnabled
                $status.EventLogMaxSizeMB = [math]::Round($eventLog.MaximumSizeInBytes / 1MB, 2)
            }
            catch {
                Write-ModuleLog -Level Warning -Message "Unable to query event log status: $_"
            }

            # Recommendations
            if (-not $status.ScriptBlockLoggingEnabled) {
                $status.RecommendedAction = "Enable Script Block Logging with: Enable-ScriptBlockLogging"
            }
            elseif ($status.InvocationLoggingEnabled) {
                $status.RecommendedAction = "Invocation logging is enabled (high volume). Consider disabling if not needed."
            }
            elseif ($status.EventLogMaxSizeMB -lt 100) {
                $status.RecommendedAction = "Consider increasing event log size to at least 100MB"
            }
            else {
                $status.RecommendedAction = "Configuration looks good"
            }

            return $status
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to retrieve Script Block Logging status" -ErrorRecord $_ -ErrorCode 'SBL003'
            throw
        }
    }
}

#endregion

#region Monitoring Functions

function Get-ScriptBlockEvent {
    <#
    .SYNOPSIS
        Retrieves Script Block Logging events from the Windows Event Log.

    .DESCRIPTION
        Queries the PowerShell Operational event log for script block events (ID 4104)
        with advanced filtering and threat detection capabilities.

    .PARAMETER MaxEvents
        Maximum number of events to retrieve (default: 100)

    .PARAMETER StartTime
        Filter events from this time onwards

    .PARAMETER EndTime
        Filter events until this time

    .PARAMETER Last24Hours
        Convenience filter for events in the last 24 hours

    .PARAMETER SuspiciousOnly
        Return only events flagged as suspicious by threat detection

    .PARAMETER MinimumSeverity
        Minimum severity level for threat detection (Low, Medium, High, Critical)

    .PARAMETER IncludeThreatAnalysis
        Add threat analysis to each event

    .OUTPUTS
        System.Diagnostics.Eventing.Reader.EventLogRecord[]

    .EXAMPLE
        Get-ScriptBlockEvent -MaxEvents 50 -Verbose
        # Get 50 most recent script block events

    .EXAMPLE
        Get-ScriptBlockEvent -Last24Hours -SuspiciousOnly
        # Get suspicious events from last 24 hours

    .EXAMPLE
        Get-ScriptBlockEvent -IncludeThreatAnalysis | Format-Table TimeCreated, ThreatScore, ScriptBlockText
        # Get events with threat analysis
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.Diagnostics.Eventing.Reader.EventLogRecord[]])]
    param(
        [Parameter()]
        [int]$MaxEvents = 100,

        [Parameter(ParameterSetName = 'TimeRange')]
        [datetime]$StartTime,

        [Parameter(ParameterSetName = 'TimeRange')]
        [datetime]$EndTime,

        [Parameter(ParameterSetName = 'Last24Hours')]
        [switch]$Last24Hours,

        [Parameter()]
        [switch]$SuspiciousOnly,

        [Parameter()]
        [ValidateSet('Low', 'Medium', 'High', 'Critical')]
        [string]$MinimumSeverity,

        [Parameter()]
        [switch]$IncludeThreatAnalysis
    )

    begin {
        Write-ModuleLog -Level Verbose -Message "Retrieving Script Block events"

        if ($Last24Hours) {
            $StartTime = (Get-Date).AddDays(-1)
        }
    }

    process {
        try {
            # Build filter hashtable
            $filter = @{
                LogName = $script:EventLogName
                Id      = $script:ScriptBlockEventId
            }

            if ($StartTime) {
                $filter.StartTime = $StartTime
            }

            if ($EndTime) {
                $filter.EndTime = $EndTime
            }

            # Query events
            Write-ModuleLog -Level Verbose -Message "Querying event log with filter: $($filter | ConvertTo-Json -Compress)"
            $events = Get-WinEvent -FilterHashtable $filter -MaxEvents $MaxEvents -ErrorAction Stop

            Write-ModuleLog -Level Info -Message "Retrieved $($events.Count) script block events"

            # Process events
            $processedEvents = foreach ($event in $events) {
                # Extract script block text
                $scriptBlockText = $event.Properties[2].Value

                if ($IncludeThreatAnalysis -or $SuspiciousOnly) {
                    # Perform threat analysis
                    $analysis = Test-ScriptBlockThreat -ScriptBlockText $scriptBlockText

                    # Add analysis to event
                    $event | Add-Member -NotePropertyName 'ThreatAnalysis' -NotePropertyValue $analysis -Force
                    $event | Add-Member -NotePropertyName 'ThreatScore' -NotePropertyValue $analysis.ThreatScore -Force
                    $event | Add-Member -NotePropertyName 'IsSuspicious' -NotePropertyValue $analysis.IsSuspicious -Force
                    $event | Add-Member -NotePropertyName 'DetectedPatterns' -NotePropertyValue $analysis.DetectedPatterns -Force
                }

                # Add script block text for easy access
                $event | Add-Member -NotePropertyName 'ScriptBlockText' -NotePropertyValue $scriptBlockText -Force

                $event
            }

            # Filter by suspicious only
            if ($SuspiciousOnly) {
                $processedEvents = $processedEvents | Where-Object { $_.IsSuspicious }
                Write-ModuleLog -Level Info -Message "Filtered to $($processedEvents.Count) suspicious events"
            }

            # Filter by minimum severity
            if ($MinimumSeverity) {
                $severityOrder = @{ 'Low' = 1; 'Medium' = 2; 'High' = 3; 'Critical' = 4 }
                $minLevel = $severityOrder[$MinimumSeverity]

                $processedEvents = $processedEvents | Where-Object {
                    $maxDetectedSeverity = ($_.DetectedPatterns | ForEach-Object { $severityOrder[$_.Severity] } | Measure-Object -Maximum).Maximum
                    $maxDetectedSeverity -ge $minLevel
                }
            }

            return $processedEvents
        }
        catch {
            Write-ModuleLog -Level Error -Message "Failed to retrieve script block events" -ErrorRecord $_ -ErrorCode 'SBL004'
            throw
        }
    }
}

function Test-ScriptBlockThreat {
    <#
    .SYNOPSIS
        Analyzes a script block for suspicious patterns and potential threats.

    .DESCRIPTION
        Performs pattern-based threat detection on PowerShell script blocks.
        Returns threat score and detected patterns.

    .PARAMETER ScriptBlockText
        The script block text to analyze

    .OUTPUTS
        PSCustomObject with threat analysis results

    .EXAMPLE
        $analysis = Test-ScriptBlockThreat -ScriptBlockText 'Invoke-Expression (Get-Content malware.ps1)'
        # Analyzes script for threats
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ScriptBlockText
    )

    process {
        $detectedPatterns = [System.Collections.Generic.List[PSCustomObject]]::new()
        $threatScore = 0

        foreach ($pattern in $script:SuspiciousPatterns) {
            if ($ScriptBlockText -match $pattern.Pattern) {
                $match = [PSCustomObject]@{
                    Pattern     = $pattern.Pattern
                    Severity    = $pattern.Severity
                    Description = $pattern.Description
                }
                $detectedPatterns.Add($match)

                # Calculate threat score
                $score = switch ($pattern.Severity) {
                    'Critical' { 10 }
                    'High' { 5 }
                    'Medium' { 2 }
                    'Low' { 1 }
                    default { 0 }
                }
                $threatScore += $score
            }
        }

        return [PSCustomObject]@{
            ThreatScore      = $threatScore
            IsSuspicious     = ($threatScore -ge 2)
            DetectedPatterns = $detectedPatterns
            AnalyzedAt       = Get-Date
        }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    # Configuration
    'Enable-ScriptBlockLogging'
    'Disable-ScriptBlockLogging'
    'Get-ScriptBlockLoggingStatus'

    # Monitoring
    'Get-ScriptBlockEvent'
    'Test-ScriptBlockThreat'
)
