#requires -Version 5.1

<#
.SYNOPSIS
    Structured logging module for PowerShell QA Engine with JSONL support.

.DESCRIPTION
    Production-grade logging with correlation IDs, structured output, secret redaction,
    and multiple sinks (console, file, JSONL). Implements trace propagation for
    distributed debugging and comprehensive audit trails.

    .NOTES
    Part of PoshGuard
    Author: https://github.com/cboyd0319
    Module: PSQALogger.psm1
#>

[CmdletBinding()]
param()


Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Classes

class PSQALogEntry {
    [datetime]$Timestamp
    [string]$Level
    [string]$Message
    [string]$TraceId
    [string]$Category
    [hashtable]$Properties
    [string]$Code
    [string]$Hint
    [string]$Action

    PSQALogEntry([string]$level, [string]$message, [string]$traceId) {
        $this.Timestamp = Get-Date
        $this.Level = $level
        $this.Message = $message
        $this.TraceId = $traceId
        $this.Category = 'General'
        $this.Properties = @{}
        $this.code = ''
        $this.Hint = ''
        $this.Action = ''
    }
}

#endregion

#region Module Variables

$script:LogConfig = @{
    Level            = 'Info'
    EnableConsole    = $true
    EnableFile       = $true
    EnableStructured = $true
    FilePath         = './logs/qa-engine.log'
    StructuredPath   = './logs/qa-engine.jsonl'
    MaxFileSizeBytes = 52428800  # 50MB
    ColorOutput      = $true
    RedactSecrets    = $true
}

$script:SecretPatterns = @(
    'password',
    'pwd',
    'secret',
    'token',
    'api[_-]?key',
    'apikey',
    'credential'
)

#endregion

#region Public Functions

<#
.SYNOPSIS
    Initializes the logger with custom configuration.

.DESCRIPTION
    Sets up logging configuration including file paths, levels, and output options.
    Creates necessary log directories if they don't exist.

.PARAMETER Config
    Hashtable containing logger configuration options.

.EXAMPLE
    Initialize-PSQALogger -Config @{ Level = 'Debug'; FilePath = './custom-log.log' }

.NOTES
    Called automatically on module import with defaults.
#>
function Initialize-PSQALogger {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter()]
        [hashtable]$Config = @{},

        [Parameter()]
        [switch]$NoAnsi
    )

    if ($pscmdlet.ShouldProcess('Logger', 'Initialize')) {
        # Merge custom config with defaults
        foreach ($key in $Config.Keys) {
            if ($script:LogConfig.ContainsKey($key)) {
                $script:LogConfig[$key] = $Config[$key]
            }
        }

        if ($NoAnsi) {
            $script:LogConfig.ColorOutput = $false
        }

        # Ensure log directories exist
        $logDir = Split-Path -Path $script:LogConfig.FilePath -Parent
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $structuredLogDir = Split-Path -Path $script:LogConfig.StructuredPath -Parent
        if (-not (Test-Path -Path $structuredLogDir)) {
            New-Item -Path $structuredLogDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        Write-Verbose "PSQALogger initialized: Level=$($script:LogConfig.Level)"
    }
}

<#
.SYNOPSIS
    Writes a log entry at the specified level.

.DESCRIPTION
    Core logging function that handles formatting, redaction, and routing to
    configured sinks (console, file, structured JSONL).

.PARAMETER Level
    Log level: Trace, Debug, Info, Warn, Error, Fatal

.PARAMETER Message
    Log message text

.PARAMETER TraceId
    Correlation trace ID for request tracing

.PARAMETER Category
    Log category for filtering

.PARAMETER Code
    Error/event code

.PARAMETER Hint
    Contextual hint for troubleshooting

.PARAMETER Action
    Suggested remediation action

.PARAMETER Properties
    Additional structured properties

.EXAMPLE
    Write-PSQALog -Level Error -Message "File not found" -TraceId $traceId -Code "E001" -Hint "Check file path" -Action "Verify path exists"

.NOTES
    Automatically redacts secrets based on configured patterns.
#>
function Write-PSQALog {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Trace', 'Debug', 'Info', 'Warn', 'Error', 'Fatal')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString(),

        [Parameter()]
        [string]$Category = 'General',

        [Parameter()]
        [string]$Code = '',

        [Parameter()]
        [string]$Hint = '',

        [Parameter()]
        [string]$Action = '',

        [Parameter()]
        [hashtable]$Properties = @{}
    )

    if ($pscmdlet.ShouldProcess($Message, "Write Log")) {
        # Check if level should be logged
        $levels = @('Trace', 'Debug', 'Info', 'Warn', 'Error', 'Fatal')
        $configuredLevel = $levels.IndexOf($script:LogConfig.Level)
        $messageLevel = $levels.IndexOf($Level)

        if ($messageLevel -lt $configuredLevel) {
            return  # Skip logging
        }

        # Create log entry
        $entry = [PSQALogEntry]::new($Level, $Message, $TraceId)
        $entry.Category = $Category
        $entry.code = $Code
        $entry.Hint = $Hint
        $entry.Action = $Action
        $entry.Properties = $Properties

        # Redact secrets if enabled
        if ($script:LogConfig.RedactSecrets) {
            $entry.Message = Hide-SecretInText -Text $entry.Message
            foreach ($key in @($entry.Properties.Keys)) {
                if ($entry.Properties[$key] -is [string]) {
                    $entry.Properties[$key] = Hide-SecretInText -Text $entry.Properties[$key]
                }
            }
        }

        # Write to console
        if ($script:LogConfig.EnableConsole) {
            Write-ConsoleLog -Entry $entry
        }

        # Write to file
        if ($script:LogConfig.EnableFile) {
            Write-FileLog -Entry $entry
        }

        # Write to structured log (JSONL)
        if ($script:LogConfig.EnableStructured) {
            Write-StructuredLog -Entry $entry
        }
    }
}

<#
.SYNOPSIS
    Convenience function for info-level logging.

.DESCRIPTION
    Writes an informational log message.

.PARAMETER Message
    Log message

.PARAMETER TraceId
    Correlation trace ID

.EXAMPLE
    Write-PSQAInfo "Processing completed successfully" -TraceId $traceId
#>
function Write-PSQAInfo {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString()
    )

    Write-PSQALog -Level Info -Message $Message -TraceId $TraceId
}

<#
.SYNOPSIS
    Convenience function for warning-level logging.

.DESCRIPTION
    Writes a warning log message with optional hint and action.

.PARAMETER Message
    Log message

.PARAMETER TraceId
    Correlation trace ID

.PARAMETER Hint
    Contextual hint

.PARAMETER Action
    Suggested action

.EXAMPLE
    Write-PSQAWarning "Deprecated function used" -Hint "Use new function" -Action "Update code"
#>
function Write-PSQAWarning {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString(),

        [Parameter()]
        [string]$Hint = '',

        [Parameter()]
        [string]$Action = ''
    )

    Write-PSQALog -Level Warn -Message $Message -TraceId $TraceId -Hint $Hint -Action $Action
}

<#
.SYNOPSIS
    Convenience function for error-level logging.

.DESCRIPTION
    Writes an error log message with code, hint, and action.

.PARAMETER Message
    Log message

.PARAMETER TraceId
    Correlation trace ID

.PARAMETER Code
    Error code

.PARAMETER Hint
    Contextual hint

.PARAMETER Action
    Suggested action

.EXAMPLE
    Write-PSQAError "Analysis failed" -Code "E001" -Hint "File corrupted" -Action "Re-download file"
#>
function Write-PSQAError {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$TraceId = (New-Guid).ToString(),

        [Parameter()]
        [string]$Code = '',

        [Parameter()]
        [string]$Hint = '',

        [Parameter()]
        [string]$Action = ''
    )

    Write-PSQALog -Level Error -Message $Message -TraceId $TraceId -Code $Code -Hint $Hint -Action $Action
}

#endregion

#region Private Functions

<#
.SYNOPSIS
    Redacts secrets from text based on configured patterns.

.DESCRIPTION
    Scans text for secret patterns and replaces with [REDACTED].

.PARAMETER Text
    Text to scan

.EXAMPLE
    Hide-SecretInText -Text "password=abc123"
#>
function Hide-SecretInText {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $redacted = $Text

    foreach ($pattern in $script:SecretPatterns) {
        # Pattern: key=value or key:value or key="value"
        $redacted = $redacted -replace "($pattern)(\s*[=:]\s*)[^\s;,]+", '$1$2[REDACTED]'
    }

    return $redacted
}

<#
.SYNOPSIS
    Writes log entry to console with color formatting.

.DESCRIPTION
    Formats and displays log entries on the console with appropriate colors.

.PARAMETER Entry
    Log entry to write
#>
function Write-ConsoleLog {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSQALogEntry]$Entry
    )

    $timestamp = $Entry.Timestamp.ToString('yyyy-MM-dd HH:mm:ss.fff')
    $color = Get-LogColor -Level $Entry.Level

    $msg = "[$timestamp] [$($Entry.Level.ToUpper())] [$($Entry.TraceId.Substring(0, 8))] $($Entry.Message)"

    if ($Entry.code) {
        $msg += " [Code: $($Entry.Code)]"
    }
    if ($Entry.Hint) {
        $msg += " [Hint: $($Entry.Hint)]"
    }
    if ($Entry.Action) {
        $msg += " [Action: $($Entry.Action)]"
    }

    if ($script:LogConfig.ColorOutput) {
        Write-Host $msg -ForegroundColor $color
    }
    else {
        Write-Output $msg
    }
}

<#
.SYNOPSIS
    Writes log entry to file.

.DESCRIPTION
    Appends log entry to the configured log file with rotation support.

.PARAMETER Entry
    Log entry to write
#>
function Write-FileLog {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSQALogEntry]$Entry
    )

    $timestamp = $Entry.Timestamp.ToString('yyyy-MM-dd HH:mm:ss.fff')
    $logLine = "[$timestamp] [$($Entry.Level.ToUpper())] [$($Entry.TraceId)] [$($Entry.Category)] $($Entry.Message)"

    if ($Entry.code) { $logLine += " [Code: $($Entry.Code)]" }
    if ($Entry.Hint) { $logLine += " [Hint: $($Entry.Hint)]" }
    if ($Entry.Action) { $logLine += " [Action: $($Entry.Action)]" }

    # Check file size and rotate if needed
    if (Test-Path -Path $script:LogConfig.FilePath) {
        $fileSize = (Get-Item $script:LogConfig.FilePath).Length
        if ($fileSize -gt $script:LogConfig.MaxFileSizeBytes) {
            $rotatedPath = "$($script:LogConfig.FilePath).$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -Path $script:LogConfig.FilePath -Destination $rotatedPath -Force -ErrorAction Stop
        }
    }

    Add-Content -Path $script:LogConfig.FilePath -Value $logLine -Encoding UTF8 -ErrorAction Stop
}

<#
.SYNOPSIS
    Writes log entry as structured JSONL.

.DESCRIPTION
    Serializes log entry to JSON and appends to JSONL file.

.PARAMETER Entry
    Log entry to write
#>
function Write-StructuredLog {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSQALogEntry]$Entry
    )

    $jsonEntry = @{
        timestamp  = $Entry.Timestamp.ToString('o')
        level      = $Entry.Level
        trace_id   = $Entry.TraceId
        category   = $Entry.Category
        message    = $Entry.Message
        code       = $Entry.code
        hint       = $Entry.Hint
        action     = $Entry.Action
        properties = $Entry.Properties
    }

    $jsonLine = $jsonEntry | ConvertTo-Json -Compress

    # Check file size and rotate if needed
    if (Test-Path -Path $script:LogConfig.StructuredPath) {
        $fileSize = (Get-Item $script:LogConfig.StructuredPath).Length
        if ($fileSize -gt $script:LogConfig.MaxFileSizeBytes) {
            $rotatedPath = "$($script:LogConfig.StructuredPath).$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -Path $script:LogConfig.StructuredPath -Destination $rotatedPath -Force -ErrorAction Stop
        }
    }

    Add-Content -Path $script:LogConfig.StructuredPath -Value $jsonLine -Encoding UTF8 -ErrorAction Stop
}

<#
.SYNOPSIS
    Returns console color based on log level.

.DESCRIPTION
    Maps log levels to console colors.

.PARAMETER Level
    Log level

.EXAMPLE
    Get-LogColor -Level Error
#>
function Get-LogColor {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Level
    )

    switch ($Level) {
        'Trace' { 'DarkGray' }
        'Debug' { 'Gray' }
        'Info' { 'White' }
        'Warn' { 'Yellow' }
        'Error' { 'Red' }
        'Fatal' { 'Magenta' }
        default { 'White' }
    }
}

#endregion

#region Module Initialization

# Initialize with defaults on module import
Initialize-PSQALogger

#endregion

#region Exports

Export-ModuleMember -Function @(
    'Initialize-PSQALogger',
    'Write-PSQALog',
    'Write-PSQAInfo',
    'Write-PSQAWarning',
    'Write-PSQAError'
)

#endregion
