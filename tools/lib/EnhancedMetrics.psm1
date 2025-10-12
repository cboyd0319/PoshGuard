<#
.SYNOPSIS
    Enhanced Metrics and Observability Module

.DESCRIPTION
    Provides granular metrics, confidence scoring, and detailed diagnostics:
    - Per-rule success/failure tracking
    - Fix confidence scores
    - Performance profiling per rule
    - Detailed failure diagnostics
    - Fix quality metrics

.NOTES
    Module: EnhancedMetrics
    Version: 3.3.0
    SRE Principles: Golden Signals (latency, errors, saturation)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Global metrics store
$script:MetricsStore = @{
    RuleMetrics = @{}
    SessionStart = Get-Date
    TotalFiles = 0
    TotalFixes = 0
    TotalFailures = 0
}

function Initialize-MetricsTracking {
    <#
    .SYNOPSIS
        Initializes metrics tracking for a session
    
    .DESCRIPTION
        Resets metrics store and prepares for tracking
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    
    $script:MetricsStore = @{
        RuleMetrics = @{}
        SessionStart = Get-Date
        TotalFiles = 0
        TotalFixes = 0
        TotalFailures = 0
        FileMetrics = @()
    }
    
    Write-Verbose "Metrics tracking initialized at $($script:MetricsStore.SessionStart)"
}

function Add-RuleMetric {
    <#
    .SYNOPSIS
        Records metrics for a rule execution
    
    .DESCRIPTION
        Tracks success/failure, duration, and confidence for each rule fix
    
    .PARAMETER RuleName
        Name of the PSSA or custom rule
    
    .PARAMETER Success
        Whether the fix succeeded
    
    .PARAMETER DurationMs
        Time taken in milliseconds
    
    .PARAMETER ConfidenceScore
        Confidence in fix quality (0.0-1.0)
    
    .PARAMETER FilePath
        File being processed
    
    .PARAMETER ErrorMessage
        Error message if failed
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$RuleName,
        
        [Parameter(Mandatory)]
        [bool]$Success,
        
        [Parameter(Mandatory)]
        [int]$DurationMs,
        
        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$ConfidenceScore = 1.0,
        
        [Parameter()]
        [string]$FilePath = '',
        
        [Parameter()]
        [string]$ErrorMessage = ''
    )
    
    if (-not $script:MetricsStore.RuleMetrics.ContainsKey($RuleName)) {
        $script:MetricsStore.RuleMetrics[$RuleName] = @{
            Attempts = 0
            Successes = 0
            Failures = 0
            TotalDurationMs = 0
            AvgDurationMs = 0
            MinDurationMs = [int]::MaxValue
            MaxDurationMs = 0
            ConfidenceScores = @()
            AvgConfidence = 0.0
            Errors = @()
        }
    }
    
    $metric = $script:MetricsStore.RuleMetrics[$RuleName]
    $metric.Attempts++
    
    if ($Success) {
        $metric.Successes++
        $script:MetricsStore.TotalFixes++
    } else {
        $metric.Failures++
        $script:MetricsStore.TotalFailures++
        if ($ErrorMessage) {
            $metric.Errors += [PSCustomObject]@{
                FilePath = $FilePath
                Message = $ErrorMessage
                Timestamp = Get-Date
            }
        }
    }
    
    $metric.TotalDurationMs += $DurationMs
    $metric.AvgDurationMs = [int]($metric.TotalDurationMs / $metric.Attempts)
    
    if ($DurationMs -lt $metric.MinDurationMs) {
        $metric.MinDurationMs = $DurationMs
    }
    if ($DurationMs -gt $metric.MaxDurationMs) {
        $metric.MaxDurationMs = $DurationMs
    }
    
    if ($Success) {
        $metric.ConfidenceScores += $ConfidenceScore
        $metric.AvgConfidence = ($metric.ConfidenceScores | Measure-Object -Average).Average
    }
}

function Get-FixConfidenceScore {
    <#
    .SYNOPSIS
        Calculates confidence score for a fix
    
    .DESCRIPTION
        Evaluates fix quality based on:
        - Syntax validation (0.5 weight)
        - AST structure preservation (0.2 weight)
        - Minimal changes (0.2 weight)
        - No side effects detected (0.1 weight)
    
    .PARAMETER OriginalContent
        Original script content
    
    .PARAMETER FixedContent
        Fixed script content
    
    .EXAMPLE
        Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [string]$OriginalContent,
        
        [Parameter(Mandatory)]
        [string]$FixedContent
    )
    
    $score = 0.0
    
    # 1. Syntax validation (50% weight)
    $errors = $null
    $tokens = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput(
        $FixedContent,
        [ref]$tokens,
        [ref]$errors
    )
    
    if ($null -eq $errors -or $errors.Count -eq 0) {
        $score += 0.5
    } else {
        # Any syntax errors get no credit
        # ParseError objects don't have Severity property, they ARE errors
        $score += 0.0
    }
    
    # 2. AST structure preservation (20% weight)
    try {
        $origAst = [System.Management.Automation.Language.Parser]::ParseInput(
            $OriginalContent,
            [ref]$null,
            [ref]$null
        )
        $fixedAst = [System.Management.Automation.Language.Parser]::ParseInput(
            $FixedContent,
            [ref]$null,
            [ref]$null
        )
        
        $origFunctions = $origAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true).Count
        $fixedFunctions = $fixedAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true).Count
        
        if ($origFunctions -eq $fixedFunctions) {
            $score += 0.2
        } elseif ([Math]::Abs($origFunctions - $fixedFunctions) -eq 1) {
            $score += 0.1
        }
    } catch {
        Write-Verbose "Error comparing AST structure: $_"
    }
    
    # 3. Minimal changes (20% weight)
    $origLines = $OriginalContent -split "`n"
    $fixedLines = $FixedContent -split "`n"
    
    $maxLines = [Math]::Max($origLines.Count, $fixedLines.Count)
    if ($maxLines -eq 0) { $maxLines = 1 }
    
    $changedLines = 0
    for ($i = 0; $i -lt $maxLines; $i++) {
        $origLine = if ($i -lt $origLines.Count) { $origLines[$i] } else { '' }
        $fixedLine = if ($i -lt $fixedLines.Count) { $fixedLines[$i] } else { '' }
        
        if ($origLine -ne $fixedLine) {
            $changedLines++
        }
    }
    
    $changeRatio = $changedLines / $maxLines
    if ($changeRatio -le 0.1) {
        $score += 0.2
    } elseif ($changeRatio -le 0.4) {
        $score += 0.15
    } elseif ($changeRatio -le 0.6) {
        $score += 0.1
    } elseif ($changeRatio -le 0.8) {
        $score += 0.05
    }
    
    # 4. No side effects (10% weight)
    # Check for dangerous patterns that might have been introduced
    $dangerousPatterns = @(
        'Invoke-Expression',
        'iex ',
        'Start-Process',
        'Remove-Item.*-Recurse',
        'rm -rf'
    )
    
    $hasDangerousPattern = $false
    foreach ($pattern in $dangerousPatterns) {
        if ($FixedContent -match $pattern -and $OriginalContent -notmatch $pattern) {
            $hasDangerousPattern = $true
            break
        }
    }
    
    if (-not $hasDangerousPattern) {
        $score += 0.1
    }
    
    return [Math]::Round($score, 2)
}

function Add-FileMetric {
    <#
    .SYNOPSIS
        Records metrics for a file processing
    
    .PARAMETER FilePath
        File being processed
    
    .PARAMETER ViolationCount
        Number of violations detected
    
    .PARAMETER FixedCount
        Number of violations fixed
    
    .PARAMETER DurationMs
        Processing time in milliseconds
    
    .PARAMETER AvgConfidence
        Average confidence of fixes
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [int]$ViolationCount,
        
        [Parameter(Mandatory)]
        [int]$FixedCount,
        
        [Parameter(Mandatory)]
        [int]$DurationMs,
        
        [Parameter()]
        [double]$AvgConfidence = 0.0
    )
    
    $script:MetricsStore.TotalFiles++
    
    $script:MetricsStore.FileMetrics += [PSCustomObject]@{
        FilePath = $FilePath
        ViolationCount = $ViolationCount
        FixedCount = $FixedCount
        FixRate = if ($ViolationCount -gt 0) { [Math]::Round(($FixedCount / $ViolationCount) * 100, 2) } else { 0 }
        DurationMs = $DurationMs
        AvgConfidence = $AvgConfidence
        Timestamp = Get-Date
    }
}

function Get-MetricsSummary {
    <#
    .SYNOPSIS
        Returns comprehensive metrics summary
    
    .DESCRIPTION
        Provides detailed metrics for the session including:
        - Overall statistics
        - Per-rule performance
        - Top performers and problem rules
        - Quality metrics
    
    .EXAMPLE
        Get-MetricsSummary | ConvertTo-Json -Depth 5
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $sessionDuration = (Get-Date) - $script:MetricsStore.SessionStart
    
    # Calculate overall statistics
    $totalAttempts = 0
    $totalSuccesses = 0
    $totalFailures = 0
    
    foreach ($rule in $script:MetricsStore.RuleMetrics.Values) {
        $totalAttempts += $rule.Attempts
        $totalSuccesses += $rule.Successes
        $totalFailures += $rule.Failures
    }
    
    $overallSuccessRate = if ($totalAttempts -gt 0) { 
        [Math]::Round(($totalSuccesses / $totalAttempts) * 100, 2) 
    } else { 0 }
    
    # Find top and bottom performers
    $rulePerformance = @()
    foreach ($ruleName in $script:MetricsStore.RuleMetrics.Keys) {
        $rule = $script:MetricsStore.RuleMetrics[$ruleName]
        $successRate = if ($rule.Attempts -gt 0) { 
            [Math]::Round(($rule.Successes / $rule.Attempts) * 100, 2) 
        } else { 0 }
        
        $rulePerformance += [PSCustomObject]@{
            RuleName = $ruleName
            Attempts = $rule.Attempts
            Successes = $rule.Successes
            Failures = $rule.Failures
            SuccessRate = $successRate
            AvgDurationMs = $rule.AvgDurationMs
            AvgConfidence = [Math]::Round($rule.AvgConfidence, 2)
        }
    }
    
    $topPerformers = $rulePerformance | Sort-Object SuccessRate -Descending | Select-Object -First 5
    $problemRules = $rulePerformance | Where-Object { $_.SuccessRate -lt 50 } | Sort-Object SuccessRate
    $slowestRules = $rulePerformance | Sort-Object AvgDurationMs -Descending | Select-Object -First 5
    
    $summary = [PSCustomObject]@{
        SessionDuration = [PSCustomObject]@{
            TotalSeconds = [Math]::Round($sessionDuration.TotalSeconds, 2)
            Formatted = "$($sessionDuration.Hours)h $($sessionDuration.Minutes)m $($sessionDuration.Seconds)s"
        }
        OverallStats = [PSCustomObject]@{
            TotalFiles = $script:MetricsStore.TotalFiles
            TotalAttempts = $totalAttempts
            TotalSuccesses = $totalSuccesses
            TotalFailures = $totalFailures
            SuccessRate = $overallSuccessRate
        }
        RulesExecuted = $script:MetricsStore.RuleMetrics.Count
        TopPerformers = $topPerformers
        ProblemRules = $problemRules
        SlowestRules = $slowestRules
        AllRules = $rulePerformance | Sort-Object RuleName
        FileMetrics = $script:MetricsStore.FileMetrics
        Timestamp = Get-Date -Format 'o'
    }
    
    return $summary
}

function Export-MetricsReport {
    <#
    .SYNOPSIS
        Exports metrics to JSON file
    
    .PARAMETER OutputPath
        Path to save metrics report
    
    .EXAMPLE
        Export-MetricsReport -OutputPath "./metrics/session_20251012.json"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    $summary = Get-MetricsSummary
    
    $directory = Split-Path -Path $OutputPath -Parent
    if ($directory -and -not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    
    $summary | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Verbose "Metrics exported to: $OutputPath"
    return $OutputPath
}

function Show-MetricsSummary {
    <#
    .SYNOPSIS
        Displays metrics summary in formatted output
    
    .DESCRIPTION
        Pretty-prints metrics to console with color coding
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    
    $summary = Get-MetricsSummary
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            Enhanced Metrics Summary                       ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Session Duration: " -NoNewline -ForegroundColor Yellow
    Write-Host $summary.SessionDuration.Formatted -ForegroundColor White
    Write-Host ""
    
    Write-Host "Overall Statistics:" -ForegroundColor Yellow
    Write-Host "  Files Processed:  " -NoNewline -ForegroundColor Gray
    Write-Host $summary.OverallStats.TotalFiles -ForegroundColor White
    Write-Host "  Fix Attempts:     " -NoNewline -ForegroundColor Gray
    Write-Host $summary.OverallStats.TotalAttempts -ForegroundColor White
    Write-Host "  Successes:        " -NoNewline -ForegroundColor Gray
    Write-Host $summary.OverallStats.TotalSuccesses -ForegroundColor Green
    Write-Host "  Failures:         " -NoNewline -ForegroundColor Gray
    Write-Host $summary.OverallStats.TotalFailures -ForegroundColor Red
    Write-Host "  Success Rate:     " -NoNewline -ForegroundColor Gray
    
    $rateColor = if ($summary.OverallStats.SuccessRate -ge 90) { 'Green' }
                 elseif ($summary.OverallStats.SuccessRate -ge 70) { 'Yellow' }
                 else { 'Red' }
    Write-Host "$($summary.OverallStats.SuccessRate)%" -ForegroundColor $rateColor
    Write-Host ""
    
    $topPerformers = @($summary.TopPerformers)
    if ($topPerformers.Count -gt 0) {
        Write-Host "Top Performing Rules:" -ForegroundColor Yellow
        foreach ($rule in $topPerformers) {
            Write-Host "  $($rule.RuleName): " -NoNewline -ForegroundColor Gray
            Write-Host "$($rule.SuccessRate)% " -NoNewline -ForegroundColor Green
            Write-Host "($($rule.Successes)/$($rule.Attempts), " -NoNewline -ForegroundColor Gray
            Write-Host "conf: $($rule.AvgConfidence), " -NoNewline -ForegroundColor Gray
            Write-Host "$($rule.AvgDurationMs)ms)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    $problemRules = @($summary.ProblemRules)
    if ($problemRules.Count -gt 0) {
        Write-Host "Rules Needing Attention:" -ForegroundColor Yellow
        foreach ($rule in $problemRules) {
            Write-Host "  $($rule.RuleName): " -NoNewline -ForegroundColor Gray
            Write-Host "$($rule.SuccessRate)% " -NoNewline -ForegroundColor Red
            Write-Host "($($rule.Successes)/$($rule.Attempts))" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    $slowestRules = @($summary.SlowestRules)
    if ($slowestRules.Count -gt 0) {
        Write-Host "Slowest Rules (Performance Optimization Candidates):" -ForegroundColor Yellow
        foreach ($rule in $slowestRules) {
            Write-Host "  $($rule.RuleName): " -NoNewline -ForegroundColor Gray
            Write-Host "$($rule.AvgDurationMs)ms " -NoNewline -ForegroundColor Red
            Write-Host "($($rule.Attempts) attempts)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-MetricsTracking',
    'Add-RuleMetric',
    'Get-FixConfidenceScore',
    'Add-FileMetric',
    'Get-MetricsSummary',
    'Export-MetricsReport',
    'Show-MetricsSummary'
)
