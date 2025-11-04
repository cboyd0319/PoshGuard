<#
.SYNOPSIS
    PoshGuard Observability Module - Metrics, Traces, and Structured Logging

.DESCRIPTION
    Provides comprehensive observability for PoshGuard operations:
    - Structured logging (JSONL format)
    - Metrics collection (success rate, latency, error counts)
    - Distributed tracing with correlation IDs
    - Performance profiling
    - SLO monitoring

    Aligned with Google SRE principles and OpenTelemetry standards.

.NOTES
    Version: 3.1.0
    Part of PoshGuard UGE Framework Enhancement
    Reference: docs/development/SRE-PRINCIPLES.md
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Module-level trace ID (set at operation start)
$script:CurrentTraceId = $null
$script:OperationStartTime = $null
$script:Metrics = @{
  FilesProcessed = 0
  FilesSucceeded = 0
  FilesFailed = 0
  ViolationsDetected = 0
  ViolationsFixed = 0
  TotalDurationMs = 0
}

function Initialize-Observability {
  <#
    .SYNOPSIS
        Initializes observability context for an operation
    
    .DESCRIPTION
        Sets up trace ID, start time, and resets metrics for new operation.
        Call this at the beginning of each major operation (e.g., Apply-AutoFix run).
    
    .EXAMPLE
        Initialize-Observability
        # Returns: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    
    .OUTPUTS
        System.String - The generated trace ID
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param()
    
  $script:CurrentTraceId = [guid]::NewGuid().ToString()
  $script:OperationStartTime = Get-Date
    
  # Reset metrics for new operation
  $script:Metrics = @{
    FilesProcessed = 0
    FilesSucceeded = 0
    FilesFailed = 0
    ViolationsDetected = 0
    ViolationsFixed = 0
    TotalDurationMs = 0
  }
    
  Write-StructuredLog -Level INFO -Message "Operation started" -Properties @{
    operation = "initialize"
    powershell_version = $PSVersionTable.PSVersion.ToString()
    platform = $PSVersionTable.Platform
  }
    
  return $script:CurrentTraceId
}

function Get-TraceId {
  <#
    .SYNOPSIS
        Gets the current trace ID
    
    .DESCRIPTION
        Returns the active trace ID for correlation across log entries.
        If no trace ID exists, generates a new one.
    
    .OUTPUTS
        System.String - The current trace ID
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param()
    
  if (-not $script:CurrentTraceId) {
    $script:CurrentTraceId = [guid]::NewGuid().ToString()
  }
    
  return $script:CurrentTraceId
}

function Write-StructuredLog {
  <#
    .SYNOPSIS
        Writes structured log entry in JSONL format
    
    .DESCRIPTION
        Emits log entries as JSON Lines for machine parsing and analysis.
        Includes timestamp, level, message, trace ID, and custom properties.
    
    .PARAMETER Level
        Log level: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
    
    .PARAMETER Message
        Human-readable log message
    
    .PARAMETER Properties
        Hashtable of additional structured properties
    
    .PARAMETER FilePath
        Optional log file path (defaults to ./logs/poshguard.jsonl)
    
    .EXAMPLE
        Write-StructuredLog -Level INFO -Message "File processed" -Properties @{
            file = "script.ps1"
            duration_ms = 123
            success = $true
        }
    #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', 
    Justification = 'Write-Host is used as fallback when file logging fails')]
  [CmdletBinding()]
  [OutputType([void])]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')]
    [string]$Level,
        
    [Parameter(Mandatory)]
    [string]$Message,
        
    [Parameter()]
    [hashtable]$Properties = @{},
        
    [Parameter()]
    [string]$FilePath = './logs/poshguard.jsonl'
  )
    
  $logEntry = @{
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    level = $Level
    message = $Message
    trace_id = Get-TraceId
  }
    
  # Merge custom properties
  foreach ($key in $Properties.Keys) {
    $logEntry[$key] = $Properties[$key]
  }
    
  # Ensure log directory exists
  $logDir = Split-Path -Path $FilePath -Parent
  if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
  }
    
  # Write as JSON Lines (one JSON object per line)
  try {
    $jsonLine = $logEntry | ConvertTo-Json -Compress -Depth 10
    Add-Content -Path $FilePath -Value $jsonLine -Encoding UTF8 -ErrorAction Stop
  }
  catch {
    # Fallback: write to console if file logging fails
    Write-Warning "Failed to write structured log: $_"
    Write-Host ($logEntry | ConvertTo-Json -Depth 10)
  }
}

function Write-Metric {
  <#
    .SYNOPSIS
        Records a metric value
    
    .DESCRIPTION
        Captures metrics for monitoring and alerting.
        Metrics are aggregated in-memory and can be exported.
    
    .PARAMETER Name
        Metric name (dot-separated namespace, e.g., "poshguard.processing.duration")
    
    .PARAMETER Value
        Numeric metric value
    
    .PARAMETER Unit
        Optional unit (ms, bytes, count, percent)
    
    .PARAMETER Tags
        Optional hashtable of tags for metric dimensions
    
    .EXAMPLE
        Write-Metric -Name "poshguard.files.processed" -Value 1 -Unit "count"
        Write-Metric -Name "poshguard.processing.duration" -Value 1234 -Unit "ms" -Tags @{ file_size = "large" }
    #>
  [CmdletBinding()]
  [OutputType([void])]
  param(
    [Parameter(Mandatory)]
    [string]$Name,
        
    [Parameter(Mandatory)]
    [double]$Value,
        
    [Parameter()]
    [string]$Unit = 'count',
        
    [Parameter()]
    [hashtable]$Tags = @{}
  )
    
  $metric = @{
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    name = $Name
    value = $Value
    unit = $Unit
    trace_id = Get-TraceId
  }
    
  # Add tags
  foreach ($key in $Tags.Keys) {
    $metric["tag_$key"] = $Tags[$key]
  }
    
  # Log metric as structured log
  Write-StructuredLog -Level TRACE -Message "Metric recorded" -Properties $metric
}

function Measure-Operation {
  <#
    .SYNOPSIS
        Measures operation duration and emits metrics
    
    .DESCRIPTION
        Executes a script block and captures duration metrics.
        Automatically logs start, end, duration, and success/failure.
    
    .PARAMETER Name
        Operation name for metrics and logging
    
    .PARAMETER ScriptBlock
        The operation to measure
    
    .PARAMETER Tags
        Optional tags for metric dimensions
    
    .EXAMPLE
        $result = Measure-Operation -Name "parse_ast" -ScriptBlock {
            [Parser]::ParseFile($path, [ref]$null, [ref]$null)
        }
    
    .OUTPUTS
        Returns the result of the script block execution
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,
        
    [Parameter(Mandatory)]
    [scriptblock]$ScriptBlock,
        
    [Parameter()]
    [hashtable]$Tags = @{}
  )
    
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  $success = $false
  $errorMessage = $null
  $result = $null
    
  Write-StructuredLog -Level DEBUG -Message "Operation starting" -Properties @{
    operation = $Name
  }
    
  try {
    $result = & $ScriptBlock
    $success = $true
  }
  catch {
    $errorMessage = $_.Exception.Message
    Write-StructuredLog -Level ERROR -Message "Operation failed" -Properties @{
      operation = $Name
      error = $errorMessage
    }
    throw
  }
  finally {
    $stopwatch.Stop()
    $durationMs = $stopwatch.ElapsedMilliseconds
        
    # Record metrics
    Write-Metric -Name "poshguard.operation.duration" -Value $durationMs -Unit "ms" -Tags (@{ operation = $Name; success = $success.ToString() } + $Tags)
    Write-Metric -Name "poshguard.operation.count" -Value 1 -Unit "count" -Tags (@{ operation = $Name; success = $success.ToString() } + $Tags)
        
    # Log completion
    Write-StructuredLog -Level INFO -Message "Operation completed" -Properties @{
      operation = $Name
      duration_ms = $durationMs
      success = $success
      error = $errorMessage
    }
  }
    
  return $result
}

function Update-OperationMetric {
  <#
    .SYNOPSIS
        Updates aggregate operation metrics
    
    .DESCRIPTION
        Tracks cumulative metrics for the current operation.
    
    .PARAMETER FilesProcessed
        Number of files processed (increment)
    
    .PARAMETER FilesSucceeded
        Number of files successfully fixed (increment)
    
    .PARAMETER FilesFailed
        Number of files that failed (increment)
    
    .PARAMETER ViolationsDetected
        Number of violations detected (increment)
    
    .PARAMETER ViolationsFixed
        Number of violations fixed (increment)
    
    .EXAMPLE
        Update-OperationMetrics -FilesProcessed 1 -FilesSucceeded 1 -ViolationsFixed 5
    #>
  [CmdletBinding()]
  [OutputType([void])]
  param(
    [Parameter()]
    [int]$FilesProcessed = 0,
        
    [Parameter()]
    [int]$FilesSucceeded = 0,
        
    [Parameter()]
    [int]$FilesFailed = 0,
        
    [Parameter()]
    [int]$ViolationsDetected = 0,
        
    [Parameter()]
    [int]$ViolationsFixed = 0
  )
    
  $script:Metrics.FilesProcessed += $FilesProcessed
  $script:Metrics.FilesSucceeded += $FilesSucceeded
  $script:Metrics.FilesFailed += $FilesFailed
  $script:Metrics.ViolationsDetected += $ViolationsDetected
  $script:Metrics.ViolationsFixed += $ViolationsFixed
    
  # Calculate duration since operation start
  if ($script:OperationStartTime) {
    $script:Metrics.TotalDurationMs = ((Get-Date) - $script:OperationStartTime).TotalMilliseconds
  }
}

function Get-OperationMetric {
  <#
    .SYNOPSIS
        Gets current operation metrics
    
    .DESCRIPTION
        Returns aggregate metrics for the current operation.
    
    .EXAMPLE
        $metrics = Get-OperationMetrics
        Write-Host "Success rate: $($metrics.SuccessRate)%"
    
    .OUTPUTS
        Hashtable with operation metrics and calculated rates
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param()
    
  $successRate = if ($script:Metrics.FilesProcessed -gt 0) {
    [math]::Round(($script:Metrics.FilesSucceeded / $script:Metrics.FilesProcessed) * 100, 2)
  } else { 0 }
    
  $fixRate = if ($script:Metrics.ViolationsDetected -gt 0) {
    [math]::Round(($script:Metrics.ViolationsFixed / $script:Metrics.ViolationsDetected) * 100, 2)
  } else { 0 }
    
  return @{
    FilesProcessed = $script:Metrics.FilesProcessed
    FilesSucceeded = $script:Metrics.FilesSucceeded
    FilesFailed = $script:Metrics.FilesFailed
    ViolationsDetected = $script:Metrics.ViolationsDetected
    ViolationsFixed = $script:Metrics.ViolationsFixed
    TotalDurationMs = $script:Metrics.TotalDurationMs
    SuccessRate = $successRate
    FixRate = $fixRate
    TraceId = Get-TraceId
  }
}

function Export-OperationMetric {
  <#
    .SYNOPSIS
        Exports operation metrics to file
    
    .DESCRIPTION
        Writes final operation metrics to JSON file for analysis.
    
    .PARAMETER FilePath
        Path to metrics file (defaults to ./logs/metrics_<timestamp>.json)
    
    .EXAMPLE
        Export-OperationMetrics
        Export-OperationMetrics -FilePath ./reports/metrics.json
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter()]
    [string]$FilePath = "./logs/metrics_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
  )
    
  $metrics = Get-OperationMetrics
  $metrics['exported_at'] = (Get-Date).ToUniversalTime().ToString("o")
    
  # Ensure directory exists
  $dir = Split-Path -Path $FilePath -Parent
  if (-not (Test-Path -Path $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
  }
    
  $metrics | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8
    
  Write-StructuredLog -Level INFO -Message "Metrics exported" -Properties @{
    metrics_file = $FilePath
  }
    
  return $FilePath
}

function Test-SLO {
  <#
    .SYNOPSIS
        Tests if operation meets Service Level Objectives
    
    .DESCRIPTION
        Evaluates current metrics against defined SLOs.
        See docs/development/SRE-PRINCIPLES.md for SLO definitions.
    
    .EXAMPLE
        $sloStatus = Test-SLO
        if (-not $sloStatus.AllSLOsMet) {
            Write-Warning "SLO breach detected"
        }
    
    .OUTPUTS
        Hashtable with SLO compliance status
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param()
    
  $metrics = Get-OperationMetrics
    
  # Define SLO targets (from docs/development/SRE-PRINCIPLES.md)
  $sloTargets = @{
    AvailabilityTarget = 99.5  # 99.5% success rate
    LatencyP95Target = 5000    # 5s per file (p95)
    QualityTarget = 70.0       # 70% fix rate
    CorrectnessTarget = 100.0  # 100% valid syntax after fix
  }
    
  # Calculate SLO compliance
  $availabilityMet = $metrics.SuccessRate -ge $sloTargets.AvailabilityTarget
  $qualityMet = $metrics.FixRate -ge $sloTargets.QualityTarget
    
  # Latency: Approximate p95 as average (would need percentile calculation for exact)
  $avgLatency = if ($metrics.FilesProcessed -gt 0) {
    $metrics.TotalDurationMs / $metrics.FilesProcessed
  } else { 0 }
  $latencyMet = $avgLatency -le $sloTargets.LatencyP95Target
    
  $allMet = $availabilityMet -and $qualityMet -and $latencyMet
    
  $sloStatus = @{
    AllSLOsMet = $allMet
    Availability = @{
      Target = $sloTargets.AvailabilityTarget
      Actual = $metrics.SuccessRate
      Met = $availabilityMet
    }
    Quality = @{
      Target = $sloTargets.QualityTarget
      Actual = $metrics.FixRate
      Met = $qualityMet
    }
    Latency = @{
      Target = $sloTargets.LatencyP95Target
      Actual = [math]::Round($avgLatency, 2)
      Met = $latencyMet
    }
  }
    
  Write-StructuredLog -Level INFO -Message "SLO evaluation completed" -Properties @{
    slo_status = $sloStatus
  }
    
  return $sloStatus
}

# Export all observability functions
Export-ModuleMember -Function @(
  'Initialize-Observability',
  'Get-TraceId',
  'Write-StructuredLog',
  'Write-Metric',
  'Measure-Operation',
  'Update-OperationMetrics',
  'Get-OperationMetrics',
  'Export-OperationMetrics',
  'Test-SLO'
)
