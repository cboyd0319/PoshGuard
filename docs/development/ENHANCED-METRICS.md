# Enhanced Metrics & Observability

**Version**: 3.3.0  
**Module**: EnhancedMetrics.psm1  
**Standards**: Google SRE Principles, SLO Framework  

## Overview

PoshGuard's Enhanced Metrics module provides **granular observability** into fix quality, performance, and success rates. Track every fix attempt with confidence scoring, detailed diagnostics, and actionable insights.

### Why Enhanced Metrics?

Traditional tools report "success" or "failure" without context. Enhanced Metrics answers:

- **How confident should we be in this fix?** (0.0-1.0 confidence score)
- **Which rules perform best?** (success rates by rule)
- **What's slowing us down?** (performance profiling)
- **Why did this fail?** (detailed error diagnostics)
- **Are we improving?** (trend analysis)

This enables **continuous improvement** and **data-driven decisions** about code quality tooling.

---

## Features

### 1. Fix Confidence Scoring

**Purpose**: Quantify the quality of each fix with a 0.0-1.0 score

**Algorithm**:
```
Confidence Score = (0.5 × Syntax Valid) +
                   (0.2 × AST Preserved) +
                   (0.2 × Minimal Changes) +
                   (0.1 × No Side Effects)
```

**Components**:

#### Syntax Validation (50% weight)
- **1.0**: Zero parse errors
- **0.0**: Parse errors present

The fixed code must be syntactically valid. This is non-negotiable.

#### AST Structure Preservation (20% weight)
- **1.0**: Same number of functions before/after
- **0.5**: Off by 1 function
- **0.0**: Significantly different structure

Good fixes preserve the code's structure - they don't add/remove functions unless necessary.

#### Minimal Changes (20% weight)
- **1.0**: ≤ 10% lines changed
- **0.75**: ≤ 40% lines changed
- **0.5**: ≤ 60% lines changed  
- **0.25**: ≤ 80% lines changed
- **0.0**: > 80% lines changed

Surgical fixes that change only what's necessary are more trustworthy.

#### No Side Effects (10% weight)
- **1.0**: No dangerous patterns introduced
- **0.0**: Introduced `Invoke-Expression`, `Start-Process`, `Remove-Item -Recurse`, etc.

Fixes shouldn't introduce new risks.

**Example**:
```powershell
$original = @'
function Test {
    Write-Host "test"
}
'@

$fixed = @'
function Test {
    Write-Output "test"
}
'@

$score = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
# Result: 0.95 (high confidence - minimal valid change)
```

**Interpretation**:
- **0.9-1.0**: Excellent - Deploy with confidence
- **0.7-0.89**: Good - Review recommended
- **0.5-0.69**: Moderate - Manual review required
- **< 0.5**: Low - Likely problematic, investigate

---

### 2. Per-Rule Metrics

**Purpose**: Track success/failure rates and performance for each rule

**Metrics Collected**:
```powershell
@{
    Attempts = 0           # Total fix attempts
    Successes = 0          # Successful fixes
    Failures = 0           # Failed fixes
    TotalDurationMs = 0    # Cumulative time
    AvgDurationMs = 0      # Average time per fix
    MinDurationMs = 0      # Fastest fix
    MaxDurationMs = 0      # Slowest fix
    ConfidenceScores = @() # Array of scores
    AvgConfidence = 0.0    # Average confidence
    Errors = @()           # Error details
}
```

**Usage**:
```powershell
# Track a successful fix
Add-RuleMetric -RuleName 'PSAvoidUsingCmdletAliases' `
               -Success $true `
               -DurationMs 45 `
               -ConfidenceScore 0.95 `
               -FilePath 'script.ps1'

# Track a failure
Add-RuleMetric -RuleName 'PSAvoidEmptyCatchBlock' `
               -Success $false `
               -DurationMs 120 `
               -FilePath 'script.ps1' `
               -ErrorMessage 'Complex catch structure not supported'
```

**Analysis**:
```powershell
$summary = Get-MetricsSummary

# Find problem rules (success rate < 50%)
$problemRules = $summary.ProblemRules
foreach ($rule in $problemRules) {
    Write-Warning "$($rule.RuleName): $($rule.SuccessRate)% success"
    
    # Get error details
    $ruleMetrics = $script:MetricsStore.RuleMetrics[$rule.RuleName]
    foreach ($error in $ruleMetrics.Errors) {
        Write-Host "  File: $($error.FilePath)"
        Write-Host "  Error: $($error.Message)"
    }
}
```

---

### 3. Session Tracking

**Purpose**: Monitor overall performance across a fixing session

**Session Metrics**:
- Session duration
- Total files processed
- Total fix attempts/successes/failures
- Overall success rate
- Rules executed

**Usage**:
```powershell
Initialize-MetricsTracking  # Start of session

# ... process files and track metrics ...

$summary = Get-MetricsSummary
Write-Host "Session Duration: $($summary.SessionDuration.Formatted)"
Write-Host "Success Rate: $($summary.OverallStats.SuccessRate)%"
Write-Host "Files Processed: $($summary.OverallStats.TotalFiles)"
```

---

### 4. File-Level Metrics

**Purpose**: Track fix performance per file

**File Metrics**:
```powershell
@{
    FilePath = ''
    ViolationCount = 0   # Violations detected
    FixedCount = 0       # Violations fixed
    FixRate = 0.0        # Percentage fixed
    DurationMs = 0       # Processing time
    AvgConfidence = 0.0  # Average fix confidence
    Timestamp = ''
}
```

**Usage**:
```powershell
Add-FileMetric -FilePath 'MyScript.ps1' `
               -ViolationCount 10 `
               -FixedCount 8 `
               -DurationMs 1500 `
               -AvgConfidence 0.87
```

**Analysis**:
```powershell
$summary = Get-MetricsSummary

# Find files with low fix rates
$problematicFiles = $summary.FileMetrics | 
    Where-Object { $_.FixRate -lt 70 } |
    Sort-Object FixRate

foreach ($file in $problematicFiles) {
    Write-Warning "Low fix rate in $($file.FilePath): $($file.FixRate)%"
}

# Find slow files
$slowFiles = $summary.FileMetrics |
    Sort-Object DurationMs -Descending |
    Select-Object -First 5

Write-Host "Slowest Files:"
$slowFiles | Format-Table FilePath, DurationMs, ViolationCount
```

---

## Complete Workflow Example

### Basic Integration

```powershell
Import-Module ./tools/lib/EnhancedMetrics.psm1

# Initialize tracking
Initialize-MetricsTracking

# Process files
$files = Get-ChildItem -Path ./src -Filter *.ps1

foreach ($file in $files) {
    $original = Get-Content $file.FullName -Raw
    $violations = Invoke-ScriptAnalyzer -Path $file.FullName
    
    $fixedCount = 0
    $totalConfidence = 0
    
    $startTime = Get-Date
    
    foreach ($violation in $violations) {
        $fixStart = Get-Date
        
        try {
            $fixed = Invoke-Fix -Content $original -Violation $violation
            
            $confidence = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
            $duration = ((Get-Date) - $fixStart).TotalMilliseconds
            
            Add-RuleMetric -RuleName $violation.RuleName `
                          -Success $true `
                          -DurationMs $duration `
                          -ConfidenceScore $confidence `
                          -FilePath $file.Name
            
            $fixedCount++
            $totalConfidence += $confidence
            $original = $fixed
            
        } catch {
            $duration = ((Get-Date) - $fixStart).TotalMilliseconds
            
            Add-RuleMetric -RuleName $violation.RuleName `
                          -Success $false `
                          -DurationMs $duration `
                          -FilePath $file.Name `
                          -ErrorMessage $_.Exception.Message
        }
    }
    
    $fileTime = ((Get-Date) - $startTime).TotalMilliseconds
    $avgConfidence = if ($fixedCount -gt 0) { $totalConfidence / $fixedCount } else { 0 }
    
    Add-FileMetric -FilePath $file.Name `
                   -ViolationCount $violations.Count `
                   -FixedCount $fixedCount `
                   -DurationMs $fileTime `
                   -AvgConfidence $avgConfidence
}

# Display summary
Show-MetricsSummary

# Export for analysis
Export-MetricsReport -OutputPath "./metrics/session_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
```

### Output

```
╔═══════════════════════════════════════════════════════════╗
║            Enhanced Metrics Summary                       ║
╚═══════════════════════════════════════════════════════════╝

Session Duration: 0h 2m 34s

Overall Statistics:
  Files Processed:  15
  Fix Attempts:     127
  Successes:        112
  Failures:         15
  Success Rate:     88.19%

Top Performing Rules:
  PSAvoidUsingCmdletAliases: 100% (25/25, conf: 0.95, 42ms)
  PSUseCorrectCasing: 100% (18/18, conf: 0.93, 38ms)
  PSAvoidTrailingWhitespace: 100% (15/15, conf: 0.98, 12ms)
  PSAvoidSemicolons: 95.45% (21/22, conf: 0.91, 35ms)
  PSUseOutputType: 92.31% (12/13, conf: 0.87, 65ms)

Rules Needing Attention:
  PSAvoidEmptyCatchBlock: 40% (2/5)
  PSUseShouldProcess: 33.33% (1/3)

Slowest Rules (Performance Optimization Candidates):
  PSAvoidLongLines: 850ms (8 attempts)
  PSProvideCommentHelp: 720ms (6 attempts)
  PSUseShouldProcess: 580ms (3 attempts)
```

---

## Advanced Features

### Trend Analysis

```powershell
# Collect metrics over multiple sessions
$sessions = @()

foreach ($day in 1..7) {
    Initialize-MetricsTracking
    
    # ... process files ...
    
    $summary = Get-MetricsSummary
    $sessions += [PSCustomObject]@{
        Date = (Get-Date).AddDays(-$day)
        SuccessRate = $summary.OverallStats.SuccessRate
        AvgDuration = ($summary.FileMetrics | Measure-Object -Property DurationMs -Average).Average
    }
}

# Analyze trends
$sessions | Sort-Object Date | 
    Format-Table Date, SuccessRate, AvgDuration
```

### Alerting

```powershell
$summary = Get-MetricsSummary

# Alert on low success rate
if ($summary.OverallStats.SuccessRate -lt 80) {
    Send-Alert -Message "Fix success rate below threshold: $($summary.OverallStats.SuccessRate)%"
}

# Alert on slow performance
$slowRules = $summary.SlowestRules | Where-Object { $_.AvgDurationMs -gt 500 }
if ($slowRules) {
    $message = "Slow rules detected: $($slowRules.RuleName -join ', ')"
    Send-Alert -Message $message
}

# Alert on problematic rules
if ($summary.ProblemRules.Count -gt 0) {
    $message = "Rules with <50% success: $($summary.ProblemRules.RuleName -join ', ')"
    Send-Alert -Message $message
}
```

### Integration with CI/CD

```yaml
# .github/workflows/code-quality.yml
- name: Run PoshGuard with Metrics
  run: |
    Import-Module ./tools/lib/EnhancedMetrics.psm1
    Initialize-MetricsTracking
    
    # ... run fixes ...
    
    $summary = Get-MetricsSummary
    Export-MetricsReport -OutputPath "./metrics.json"
    
    # Fail if success rate below threshold
    if ($summary.OverallStats.SuccessRate -lt 85) {
        Write-Error "Success rate $($summary.OverallStats.SuccessRate)% below 85% threshold"
        exit 1
    }

- name: Upload Metrics
  uses: actions/upload-artifact@v3
  with:
    name: poshguard-metrics
    path: metrics.json

- name: Comment on PR
  run: |
    $summary = Get-Content metrics.json | ConvertFrom-Json
    $comment = @"
## PoshGuard Metrics
- Success Rate: $($summary.OverallStats.SuccessRate)%
- Files Processed: $($summary.OverallStats.TotalFiles)
- Fixes Applied: $($summary.OverallStats.TotalSuccesses)
"@
    # Post comment to PR
```

---

## Metrics Export Format

JSON structure:

```json
{
  "SessionDuration": {
    "TotalSeconds": 154.32,
    "Formatted": "0h 2m 34s"
  },
  "OverallStats": {
    "TotalFiles": 15,
    "TotalAttempts": 127,
    "TotalSuccesses": 112,
    "TotalFailures": 15,
    "SuccessRate": 88.19
  },
  "RulesExecuted": 23,
  "TopPerformers": [
    {
      "RuleName": "PSAvoidUsingCmdletAliases",
      "Attempts": 25,
      "Successes": 25,
      "Failures": 0,
      "SuccessRate": 100,
      "AvgDurationMs": 42,
      "AvgConfidence": 0.95
    }
  ],
  "ProblemRules": [
    {
      "RuleName": "PSAvoidEmptyCatchBlock",
      "SuccessRate": 40
    }
  ],
  "AllRules": [ /* ... */ ],
  "FileMetrics": [ /* ... */ ],
  "Timestamp": "2025-10-12T12:34:56.789Z"
}
```

---

## Performance

Enhanced Metrics adds minimal overhead:

| Operation | Time | Notes |
|-----------|------|-------|
| Initialize tracking | <1ms | One-time |
| Add rule metric | <1ms | Per fix attempt |
| Calculate confidence | 5-15ms | Per fix |
| Add file metric | <1ms | Per file |
| Get summary | 5-10ms | Aggregation |
| Export JSON | 10-30ms | Depends on size |

**Total overhead**: <1% of fix time for typical workloads

---

## API Reference

### Core Functions

#### Initialize-MetricsTracking
```powershell
Initialize-MetricsTracking
```
Resets metrics store and starts new session. Call once at start of session.

#### Add-RuleMetric
```powershell
Add-RuleMetric -RuleName 'PSAvoidUsingCmdletAliases' `
               -Success $true `
               -DurationMs 45 `
               -ConfidenceScore 0.95 `
               -FilePath 'script.ps1' `
               -ErrorMessage 'Optional error message'
```
Records metrics for a single rule execution.

#### Get-FixConfidenceScore
```powershell
$score = Get-FixConfidenceScore -OriginalContent $before -FixedContent $after
```
Calculates confidence score (0.0-1.0) for a fix.

#### Add-FileMetric
```powershell
Add-FileMetric -FilePath 'script.ps1' `
               -ViolationCount 10 `
               -FixedCount 8 `
               -DurationMs 1500 `
               -AvgConfidence 0.87
```
Records metrics for a file processing.

#### Get-MetricsSummary
```powershell
$summary = Get-MetricsSummary
```
Returns comprehensive metrics summary object.

#### Show-MetricsSummary
```powershell
Show-MetricsSummary
```
Pretty-prints metrics to console with color coding.

#### Export-MetricsReport
```powershell
Export-MetricsReport -OutputPath './metrics/report.json'
```
Exports metrics to JSON file.

---

## Best Practices

### 1. Always Initialize
```powershell
# Start of session
Initialize-MetricsTracking
```

### 2. Track Every Fix Attempt
```powershell
# Even failures - they provide insight
try {
    $fixed = Invoke-Fix $content
    Add-RuleMetric ... -Success $true
} catch {
    Add-RuleMetric ... -Success $false -ErrorMessage $_.Exception.Message
}
```

### 3. Calculate Confidence for All Fixes
```powershell
$confidence = Get-FixConfidenceScore -OriginalContent $original -FixedContent $fixed
# Use confidence to decide whether to apply fix
if ($confidence -ge 0.7) {
    Set-Content -Path $file -Value $fixed
}
```

### 4. Export Metrics for Analysis
```powershell
# End of session
Export-MetricsReport -OutputPath "./metrics/$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
```

### 5. Review Problem Rules
```powershell
$summary = Get-MetricsSummary
foreach ($rule in $summary.ProblemRules) {
    Write-Warning "Review $($rule.RuleName): $($rule.SuccessRate)% success"
}
```

---

## Troubleshooting

### Issue: Confidence scores always low

**Cause**: Fixes changing too many lines

**Solution**: Improve fix precision - target only the violation

### Issue: All rules marked as "slow"

**Cause**: Large files or complex AST operations

**Solution**: 
- Optimize AST traversals
- Cache parsed ASTs when possible
- Consider parallel processing

### Issue: Metrics not persisting

**Cause**: Not calling `Export-MetricsReport`

**Solution**: Always export at end of session

---

## References

1. **Google SRE Book** | https://sre.google/books/ | High | SLO/SLI framework
2. **Four Golden Signals** | https://sre.google/sre-book/monitoring-distributed-systems/ | High | Latency, traffic, errors, saturation
3. **Observability Engineering** | https://www.oreilly.com/library/view/observability-engineering/9781492076438/ | Medium | Modern observability practices

---

**Version History**:
- v3.3.0 (2025-10-12): Initial release with confidence scoring and per-rule metrics
