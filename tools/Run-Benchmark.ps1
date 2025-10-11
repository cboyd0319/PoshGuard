#Requires -Version 7.0
<#
.SYNOPSIS
    Automated benchmark runner for PoshGuard with before/after metrics.

.DESCRIPTION
    Runs PSScriptAnalyzer before and after PoshGuard fixes, emits delta metrics
    in CSV/JSONL formats, and optionally generates charts for README.

.PARAMETER Path
    Path to script(s) to benchmark (default: ./samples/)

.PARAMETER OutputFormat
    Output format: csv, jsonl, or both (default: both)

.PARAMETER OutputPath
    Directory for output files (default: ./benchmarks/)

.PARAMETER GenerateChart
    Generate SVG chart for README embedding

.EXAMPLE
    ./tools/Run-Benchmark.ps1 -Path ./samples/

.EXAMPLE
    ./tools/Run-Benchmark.ps1 -Path ./samples/ -GenerateChart

.EXAMPLE
    ./tools/Run-Benchmark.ps1 -Path ./MyProject/ -OutputFormat jsonl
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = './samples/',

    [Parameter()]
    [ValidateSet('csv', 'jsonl', 'both')]
    [string]$OutputFormat = 'both',

    [Parameter()]
    [string]$OutputPath = './benchmarks/',

    [Parameter()]
    [switch]$GenerateChart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Timestamp for this run
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runId = "benchmark_$timestamp"

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         PoshGuard Benchmark Suite - v3.0.0              ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check dependencies
Write-Host "→ Checking dependencies..." -ForegroundColor Yellow
try {
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    $pssaVersion = (Get-Module PSScriptAnalyzer).Version.ToString()
    Write-Host "  ✓ PSScriptAnalyzer $pssaVersion" -ForegroundColor Green
}
catch {
    Write-Error "PSScriptAnalyzer not found. Install with: Install-Module PSScriptAnalyzer -Force"
    exit 2
}

Write-Host "  ✓ PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green
Write-Host ""

# Get test files
Write-Host "→ Discovering test files..." -ForegroundColor Yellow
$testFiles = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse | 
    Where-Object { $_.Name -notlike "after-*" -and $_.Name -notlike "*-expected.ps1" }

if ($testFiles.Count -eq 0) {
    Write-Error "No test files found in $Path"
    exit 2
}

Write-Host "  ✓ Found $($testFiles.Count) test files" -ForegroundColor Green
Write-Host ""

# Initialize results collection
$results = @()
$totalViolationsBefore = 0
$totalViolationsAfter = 0
$totalFixed = 0
$totalFailed = 0

# Process each file
foreach ($file in $testFiles) {
    Write-Host "→ Processing: $($file.Name)" -ForegroundColor Cyan
    
    # Create secure temporary copy for benchmarking
    $tempFileObj = New-TemporaryFile
    $tempFile = "$($tempFileObj.FullName).ps1"
    Remove-Item $tempFileObj.FullName -Force  # Remove the temp file, keep the unique name
    Copy-Item $file.FullName -Destination $tempFile -Force
    
    try {
        # BEFORE: Run PSScriptAnalyzer
        Write-Host "  • Running PSScriptAnalyzer (before)..." -ForegroundColor Gray
        $violationsBefore = Invoke-ScriptAnalyzer -Path $tempFile -ErrorAction SilentlyContinue
        $countBefore = ($violationsBefore | Measure-Object).Count
        $totalViolationsBefore += $countBefore
        
        Write-Host "    Found: $countBefore violations" -ForegroundColor Gray
        
        # Get detailed rule counts before
        $ruleCountsBefore = $violationsBefore | Group-Object RuleName | 
            Select-Object @{N='Rule';E={$_.Name}}, Count
        
        # Record start time
        $startTime = Get-Date
        
        # Apply PoshGuard fixes
        Write-Host "  • Applying PoshGuard fixes..." -ForegroundColor Gray
        
        # Import Core module if needed
        if (-not (Get-Module Core)) {
            try {
                Import-Module ./tools/lib/Core.psm1 -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to import required module 'Core' from ./tools/lib/Core.psm1. Error: $($_.Exception.Message)"
                exit 1
            }
        }
        
        # Run fix script
        try {
            & ./tools/Apply-AutoFix.ps1 -Path $tempFile -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "Apply-AutoFix.ps1 failed for $($file.Name): $($_.Exception.Message)"
            # Continue with benchmark even if fixes fail
        }
        
        # Record end time
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        # AFTER: Run PSScriptAnalyzer again
        Write-Host "  • Running PSScriptAnalyzer (after)..." -ForegroundColor Gray
        $violationsAfter = Invoke-ScriptAnalyzer -Path $tempFile -ErrorAction SilentlyContinue
        $countAfter = ($violationsAfter | Measure-Object).Count
        $totalViolationsAfter += $countAfter
        
        $fixed = $countBefore - $countAfter
        $totalFixed += $fixed
        
        # Get detailed rule counts after
        $ruleCountsAfter = $violationsAfter | Group-Object RuleName | 
            Select-Object @{N='Rule';E={$_.Name}}, Count
        
        # Calculate success rate
        $successRate = if ($countBefore -gt 0) { 
            [math]::Round(($fixed / $countBefore) * 100, 2) 
        } else { 
            100 
        }
        
        Write-Host "    Fixed: $fixed/$countBefore violations ($successRate%)" -ForegroundColor $(if ($successRate -eq 100) { 'Green' } else { 'Yellow' })
        Write-Host "    Time: $([math]::Round($duration, 0))ms" -ForegroundColor Gray
        
        # Store result
        $result = [PSCustomObject]@{
            RunId = $runId
            Timestamp = $timestamp
            File = $file.Name
            FilePath = $file.FullName
            ViolationsBefore = $countBefore
            ViolationsAfter = $countAfter
            Fixed = $fixed
            SuccessRate = $successRate
            DurationMs = [math]::Round($duration, 2)
            PSScriptAnalyzerVersion = $pssaVersion
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            Platform = $PSVersionTable.Platform
        }
        $results += $result
        
        Write-Host ""
        
    }
    catch {
        Write-Host "  ✗ Error processing file: $_" -ForegroundColor Red
        $totalFailed++
    }
    finally {
        # Clean up temp file
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

# Calculate aggregate statistics
$overallSuccessRate = if ($totalViolationsBefore -gt 0) {
    [math]::Round(($totalFixed / $totalViolationsBefore) * 100, 2)
} else {
    100
}

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  Benchmark Results                       ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Files Processed:        $($testFiles.Count)" -ForegroundColor White
Write-Host "Total Violations:       $totalViolationsBefore" -ForegroundColor White
Write-Host "Violations Fixed:       $totalFixed" -ForegroundColor Green
Write-Host "Violations Remaining:   $totalViolationsAfter" -ForegroundColor $(if ($totalViolationsAfter -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Success Rate:           $overallSuccessRate%" -ForegroundColor $(if ($overallSuccessRate -eq 100) { 'Green' } else { 'Yellow' })
Write-Host "Failed Fixes:           $totalFailed" -ForegroundColor $(if ($totalFailed -eq 0) { 'Green' } else { 'Red' })
Write-Host ""

# Output to CSV
if ($OutputFormat -in @('csv', 'both')) {
    $csvPath = Join-Path $OutputPath "$runId.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "→ CSV report saved: $csvPath" -ForegroundColor Cyan
}

# Output to JSONL
if ($OutputFormat -in @('jsonl', 'both')) {
    $jsonlPath = Join-Path $OutputPath "$runId.jsonl"
    $results | ForEach-Object { 
        $_ | ConvertTo-Json -Compress 
    } | Set-Content -Path $jsonlPath
    Write-Host "→ JSONL report saved: $jsonlPath" -ForegroundColor Cyan
}

# Create summary JSON
$summary = [PSCustomObject]@{
    RunId = $runId
    Timestamp = $timestamp
    FilesProcessed = $testFiles.Count
    TotalViolationsBefore = $totalViolationsBefore
    TotalViolationsAfter = $totalViolationsAfter
    TotalFixed = $totalFixed
    TotalFailed = $totalFailed
    SuccessRate = $overallSuccessRate
    PSScriptAnalyzerVersion = $pssaVersion
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Platform = $PSVersionTable.Platform
    PoshGuardVersion = "3.0.0"
}

$summaryPath = Join-Path $OutputPath "$runId.summary.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath
Write-Host "→ Summary saved: $summaryPath" -ForegroundColor Cyan
Write-Host ""

# Generate SVG chart if requested
if ($GenerateChart) {
    Write-Host "→ Generating chart..." -ForegroundColor Yellow
    
    $svgPath = Join-Path $OutputPath "$runId.svg"
    
    # Simple SVG bar chart
    $svgWidth = 600
    $svgHeight = 200
    $barHeight = 40
    $barSpacing = 20
    
    # Handle zero violations case
    $maxViolations = [Math]::Max($totalViolationsBefore, $totalViolationsAfter)
    
    if ($maxViolations -eq 0) {
        # Special case: No violations detected
        $svg = @"
<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">
  <rect width="$svgWidth" height="$svgHeight" fill="#f8f9fa"/>
  
  <!-- Title -->
  <text x="10" y="25" font-family="Arial" font-size="16" font-weight="bold" fill="#333">
    PoshGuard Benchmark: No Violations Detected
  </text>
  
  <!-- Success message -->
  <text x="10" y="80" font-family="Arial" font-size="14" fill="#28a745">
    ✓ All samples passed PSScriptAnalyzer validation
  </text>
  
  <text x="10" y="110" font-family="Arial" font-size="12" fill="#666">
    Total files analyzed: $($testFiles.Count)
  </text>
  
  <text x="10" y="135" font-family="Arial" font-size="12" fill="#666">
    No fixes required - code is already compliant!
  </text>
</svg>
"@
    } else {
        # Normal case: Calculate bar widths proportionally
        $beforeBar = ($totalViolationsBefore / $maxViolations) * ($svgWidth - 150)
        $afterBar = ($totalViolationsAfter / $maxViolations) * ($svgWidth - 150)
        
        $svg = @"
<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">
  <rect width="$svgWidth" height="$svgHeight" fill="#f8f9fa"/>
  
  <!-- Title -->
  <text x="10" y="25" font-family="Arial" font-size="16" font-weight="bold" fill="#333">
    PoshGuard Benchmark: $overallSuccessRate% Success Rate
  </text>
  
  <!-- Before bar -->
  <text x="10" y="70" font-family="Arial" font-size="14" fill="#666">Before:</text>
  <rect x="100" y="55" width="$beforeBar" height="$barHeight" fill="#dc3545"/>
  <text x="$(100 + $beforeBar + 10)" y="80" font-family="Arial" font-size="14" fill="#333">
    $totalViolationsBefore violations
  </text>
  
  <!-- After bar -->
  <text x="10" y="130" font-family="Arial" font-size="14" fill="#666">After:</text>
  <rect x="100" y="115" width="$afterBar" height="$barHeight" fill="#28a745"/>
  <text x="$(100 + $afterBar + 10)" y="140" font-family="Arial" font-size="14" fill="#333">
    $totalViolationsAfter violations
  </text>
  
  <!-- Fixed label -->
  <text x="10" y="185" font-family="Arial" font-size="12" fill="#28a745">
    ✓ Fixed: $totalFixed ($overallSuccessRate%)
  </text>
</svg>
"@
    }
    
    $svg | Set-Content -Path $svgPath
    Write-Host "  ✓ Chart saved: $svgPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Add to README with:" -ForegroundColor Gray
    Write-Host "  ![Benchmark Results]($svgPath)" -ForegroundColor White
    Write-Host ""
}

# Create latest.json symlink/copy for easy reference
$latestPath = Join-Path $OutputPath "latest.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $latestPath
Write-Host "→ Latest results: $latestPath" -ForegroundColor Cyan

Write-Host ""
Write-Host "✓ Benchmark complete!" -ForegroundColor Green
Write-Host ""

# Exit code based on success rate
if ($overallSuccessRate -eq 100) {
    exit 0
}
elseif ($overallSuccessRate -ge 90) {
    exit 0  # Still acceptable
}
else {
    exit 1  # Below threshold
}
