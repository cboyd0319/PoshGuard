#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Analyzes a single PowerShell file.

.DESCRIPTION
    Runs a series of analyses on a file, including PSScriptAnalyzer and a custom security scan.
    It collects all findings into a PSQAResult object.

.PARAMETER File
    The [System.IO.FileInfo] object of the file to analyze.

.PARAMETER TraceId
    The correlation ID for this analysis run.

.EXAMPLE
    $result = Invoke-FileAnalysis -File $fileInfo -TraceId $traceId

.NOTES
    Returns a PSQAResult object containing all analysis findings.
#>
function Invoke-FileAnalysis {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory)]
        [string]$TraceId
    )

    if ($pscmdlet.ShouldProcess($File.FullName, "Analyze file")) {
        Write-Verbose "Analyzing file: $($File.FullName)"

        $result = [PSQAResult]::new($File.FullName, $TraceId)

        $config = Get-PSQAConfig
        try {
            # Run PSScriptAnalyzer
            $pssaResults = Invoke-ScriptAnalyzer -Path $File.FullName -Settings $config.PSScriptAnalyzerSettings

            foreach ($pssaResult in $pssaResults) {
                $analysisResult = [PSQAAnalysisResult]::new(
                    $pssaResult.RuleName,
                    $pssaResult.Severity.ToString(),
                    $pssaResult.Message,
                    $pssaResult.Line,
                    $pssaResult.Column,
                    'PSScriptAnalyzer'
                )
                $result.AnalysisResults += $analysisResult
            }

            # Run security analysis if enabled
            if ($config.Analysis.Security.Enabled) {
                $securityResults = Invoke-SecurityAnalysis -File $File
                $result.AnalysisResults += $securityResults
            }

            # Calculate metrics
            $result.Metrics = Get-FileMetric -File $File

            Write-Verbose "Analysis completed for: $($File.Name)"

        } catch {
            $errorMessage = "Failed to analyze file $($File.FullName): $_"
            Write-Error $errorMessage
            $result.Errors += $errorMessage
        }

        return $result
    }
}

<#
.SYNOPSIS
    Performs a security analysis on a file's content.

.DESCRIPTION
    Scans the file content for patterns defined in the SecurityRules.psd1 configuration.
    This is used to find potential security vulnerabilities like hardcoded secrets.

.PARAMETER File
    The [System.IO.FileInfo] object of the file to analyze.

.EXAMPLE
    $securityIssues = Invoke-SecurityAnalysis -File $fileInfo

.NOTES
    Returns an array of PSQAAnalysisResult objects for any security issues found.
#>
function Invoke-SecurityAnalysis {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File
    )

    if ($pscmdlet.ShouldProcess($File.FullName, "Perform security analysis")) {
        $config = Get-PSQAConfig
        $results = @()
        $content = Get-Content -Path $File.FullName -Raw

        if ($config.SecurityRules -and $config.SecurityRules.Categories) {
            foreach ($category in $config.SecurityRules.Categories.Keys) {
                $categoryRules = $config.SecurityRules.Categories[$category].Rules

                foreach ($rule in $categoryRules) {
                    foreach ($pattern in $rule.Patterns) {
                        $regexMatches = [regex]::Matches($content, $pattern, 'IgnoreCase,Multiline')

                        foreach ($match in $regexMatches) {
                            # Calculate line number
                            $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count

                            $result = [PSQAAnalysisResult]::new(
                                $rule.Name,
                                $rule.Severity,
                                $rule.Description,
                                $lineNumber,
                                $match.Index,
                                'SecurityAnalyzer'
                            )
                            $results += $result
                        }
                    }
                }
            }
        }

        return $results
    }
}

<#
.SYNOPSIS
    Calculates various metrics for a given file.

.DESCRIPTION
    Gathers metrics such as line count, file size, comment lines, and AST-based metrics
    like function and variable counts.

.PARAMETER File
    The [System.IO.FileInfo] object of the file to measure.

.EXAMPLE
    $metrics = Get-FileMetric -File $fileInfo

.NOTES
    Returns a hashtable of metrics. Handles parsing errors gracefully.
#>
function Get-FileMetric {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File
    )

    if ($pscmdlet.ShouldProcess($File.FullName, "Calculate metrics")) {
        $metrics = @{}

        try {
            $content = Get-Content -Path $File.FullName -Raw
            $lines = $content -split "`r?`n"

            $metrics.FileSize = $File.Length
            $metrics.LineCount = $lines.Count
            $metrics.CharacterCount = $content.Length
            $metrics.EmptyLines = ($lines | Where-Object { $_.Trim() -eq '' }).Count
            $metrics.CommentLines = ($lines | Where-Object { $_.Trim().StartsWith('#') }).Count

            # Try to parse AST for more detailed metrics
            try {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$null)
                $metrics.FunctionCount = ($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)).Count
                $metrics.VariableCount = ($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)).Count
            } catch {
                Write-Verbose "Could not parse AST for $($File.Name) to gather metrics: $_"
            }

        } catch {
            Write-Warning "Could not calculate metrics for $($File.Name): $_"
        }

        return $metrics
    }
}

Export-ModuleMember -Function Invoke-FileAnalysis, Invoke-SecurityAnalysis, Get-FileMetric

