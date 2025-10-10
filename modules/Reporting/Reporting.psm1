#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Generates a QA report in various formats.

.DESCRIPTION
    Takes the collected results and generates a report in the specified format(s).
    Supported formats are Console, JSON, and HTML.

.PARAMETER Results
    An array of PSQAResult objects to include in the report.

.PARAMETER OutputFormat
    The format of the report. Can be Console, JSON, HTML, or All.

.EXAMPLE
    New-QAReport -Results $allResults -OutputFormat 'All'

.NOTES
    Report files are saved in the current working directory.
#>
[CmdletBinding()]
param()


function New-QAReport {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [PSQAResult[]]$Results,

        [Parameter(Mandatory)]
        [string]$OutputFormat,

        [Parameter(Mandatory)]
        [datetime]$StartTime,

        [Parameter(Mandatory)]
        [string]$TraceId,

        [Parameter(Mandatory)]
        [string]$EngineVersion
    )

    if ($pscmdlet.ShouldProcess($OutputFormat, "Generate QA report")) {
        $summary = @{
            TotalFiles    = $Results.Count
            TotalIssues   = ($Results | ForEach-Object { $_.AnalysisResults.Count } | Measure-Object -Sum).Sum
            ErrorCount    = ($Results | ForEach-Object { ($_.AnalysisResults | Where-Object { $_.Severity -eq 'Error' }).Count } | Measure-Object -Sum).Sum
            WarningCount  = ($Results | ForEach-Object { ($_.AnalysisResults | Where-Object { $_.Severity -eq 'Warning' }).Count } | Measure-Object -Sum).Sum
            InfoCount     = ($Results | ForEach-Object { ($_.AnalysisResults | Where-Object { $_.Severity -eq 'Information' }).Count } | Measure-Object -Sum).Sum
            FixesApplied  = ($Results | ForEach-Object { ($_.FixResults | Where-Object { $_.Applied }).Count } | Measure-Object -Sum).Sum
            ExecutionTime = (Get-Date) - $StartTime
        }

        switch ($OutputFormat) {
            'Console' {
                Write-ConsoleReport -Results $Results -Summary $summary
            }
            'JSON' {
                Write-JsonReport -Results $Results -Summary $summary -TraceId $TraceId -EngineVersion $EngineVersion
            }
            'HTML' {
                Write-HtmlReport -Results $Results -Summary $summary
            }
            'All' {
                Write-ConsoleReport -Results $Results -Summary $summary
                Write-JsonReport -Results $Results -Summary $summary -TraceId $TraceId -EngineVersion $EngineVersion
                Write-HtmlReport -Results $Results -Summary $summary
            }
        }
    }
}

<#
.SYNOPSIS
    Writes the QA report to the console.

.DESCRIPTION
    Formats and outputs the analysis results and summary to the console with color coding.

.PARAMETER Results
    The array of PSQAResult objects.

.PARAMETER Summary
    The summary hashtable of the QA run.

.EXAMPLE
    Write-ConsoleReport -Results $results -Summary $summary
#>
function Write-ConsoleReport {
    [CmdletBinding()]
    [OutputType([void])]
    param($Results, $Summary)

    Write-Output "`n=== PowerShell QA Engine Report ===" -ForegroundColor Cyan
    Write-Output "Execution Time: $($Summary.ExecutionTime.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray
    Write-Output "Files Analyzed: $($Summary.TotalFiles)" -ForegroundColor Gray
    Write-Output "Total Issues: $($Summary.TotalIssues)" -ForegroundColor Gray

    if ($Summary.ErrorCount -gt 0) {
        Write-Output "Errors: $($Summary.ErrorCount)" -ForegroundColor Red
    }
    if ($Summary.WarningCount -gt 0) {
        Write-Output "Warnings: $($Summary.WarningCount)" -ForegroundColor Yellow
    }
    if ($Summary.InfoCount -gt 0) {
        Write-Output "Information: $($Summary.InfoCount)" -ForegroundColor Blue
    }
    if ($Summary.FixesApplied -gt 0) {
        Write-Output "Fixes Applied: $($Summary.FixesApplied)" -ForegroundColor Green
    }

    Write-Output "`n=== Detailed Results ===" -ForegroundColor Cyan

    foreach ($result in $Results) {
        if ($result.AnalysisResults.Count -gt 0) {
            Write-Output "`nFile: $($result.FilePath)" -ForegroundColor White

            foreach ($issue in $result.AnalysisResults) {
                $color = switch ($issue.Severity) {
                    'Error' { 'Red' }
                    'Warning' { 'Yellow' }
                    'Information' { 'Blue' }
                    default { 'Gray' }
                }
                Write-Output "  [$($issue.Severity)] Line $($issue.Line): $($issue.Message) ($($issue.RuleName))" -ForegroundColor $color
            }
        }
    }

    Write-Output "`n=== Summary ===" -ForegroundColor Cyan
    if ($Summary.TotalIssues -eq 0) {
        Write-Output "✓ No issues found! Code quality is excellent." -ForegroundColor Green
    }
    else {
        Write-Output "⚠ Found $($Summary.TotalIssues) issues that need attention." -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Writes the QA report to a JSON file.

.DESCRIPTION
    Serializes the results and summary to a JSON file with a timestamped name.

.PARAMETER Results
    The array of PSQAResult objects.

.PARAMETER Summary
    The summary hashtable of the QA run.

.EXAMPLE
    Write-JsonReport -Results $results -Summary $summary
#>
function Write-JsonReport {
    [CmdletBinding()]
    [OutputType([void])]
    param($Results, $Summary, $TraceId, $EngineVersion)

    $reportPath = Join-Path -Path $PWD -ChildPath "qa-report-$(Get-Date -Format 'yyyyMMddHHmmss').json"

    $report = @{
        Metadata = @{
            Timestamp = (Get-Date).ToString('o')
            TraceId   = $TraceId
            Engine    = "PowerShell QA Engine v$($EngineVersion)"
        }
        Summary  = $Summary
        Results  = $Results
    }

    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8 -ErrorAction Stop
    Write-Verbose "JSON report saved to: $reportPath"
}

<#
.SYNOPSIS
    Writes the QA report to an HTML file.

.DESCRIPTION
    Generates a styled HTML report from the analysis results and summary.

.PARAMETER Results
    The array of PSQAResult objects.

.PARAMETER Summary
    The summary hashtable of the QA run.

.EXAMPLE
    Write-HtmlReport -Results $results -Summary $summary
#>
function Write-HtmlReport {
    [CmdletBinding()]
    [OutputType([void])]
    param($Results, $Summary)

    $reportPath = Join-Path -Path $PWD -ChildPath "qa-report-$(Get-Date -Format 'yyyyMMddHHmmss').html"

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerShell QA Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .error { color: #d32f2f; }
        .warning { color: #f57c00; }
        .info { color: #1976d2; }
        .success { color: #388e3c; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>PowerShell QA Engine Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Execution Time:</strong> $($Summary.ExecutionTime.TotalSeconds.ToString('F2')) seconds</p>
        <p><strong>Files Analyzed:</strong> $($Summary.TotalFiles)</p>
        <p><strong>Total Issues:</strong> $($Summary.TotalIssues)</p>
        <p><strong>Errors:</strong> <span class="error">$($Summary.ErrorCount)</span></p>
        <p><strong>Warnings:</strong> <span class="warning">$($Summary.WarningCount)</span></p>
        <p><strong>Information:</strong> <span class="info">$($Summary.InfoCount)</span></p>
        <p><strong>Fixes Applied:</strong> <span class="success">$($Summary.FixesApplied)</span></p>
    </div>

    <h2>Detailed Results</h2>
    <table>
        <tr>
            <th>File</th>
            <th>Rule</th>
            <th>Severity</th>
            <th>Line</th>
            <th>Message</th>
        </tr>
"@

    foreach ($result in $Results) {
        foreach ($issue in $result.AnalysisResults) {
            $cssClass = $issue.Severity.ToLower()
            $html += @"
        <tr>
            <td>$($result.FilePath)</td>
            <td>$($issue.RuleName)</td>
            <td><span class="$cssClass">$($issue.Severity)</span></td>
            <td>$($issue.Line)</td>
            <td>$($issue.Message)</td>
        </tr>
"@
        }
    }

    $html += @"
    </table>
</body>
</html>
"@

    $html | Set-Content -Path $reportPath -Encoding UTF8 -ErrorAction Stop
    Write-Verbose "HTML report saved to: $reportPath"
}

Export-ModuleMember -Function New-QAReport, Write-ConsoleReport, Write-JsonReport, Write-HtmlReport
