#!/usr/bin/env pwsh
#requires -Version 5.1

# Core Types for the PowerShell QA Engine

[CmdletBinding()]
param()


class PSQAResult {
    [string]$FilePath
    [string]$TraceId
    [datetime]$Timestamp
    [System.Collections.ArrayList]$AnalysisResults
    [PSQAFixResult[]]$FixResults
    [hashtable]$Metrics
    [string[]]$Errors

    PSQAResult([string]$filePath, [string]$traceId) {
        $this.FilePath = $filePath
        $this.TraceId = $traceId
        $this.Timestamp = Get-Date
        $this.AnalysisResults = [System.Collections.ArrayList]::new()
        $this.FixResults = @()
        $this.Metrics = @{}
        $this.Errors = @()
    }
}

class PSQAAnalysisResult {
    [string]$RuleName
    [string]$Severity
    [string]$Message
    [int]$Line
    [int]$Column
    [string]$Source

    PSQAAnalysisResult([string]$rule, [string]$severity, [string]$message, [int]$line, [int]$column, [string]$source) {
        $this.RuleName = $rule
        $this.Severity = $severity
        $this.Message = $message
        $this.Line = $line
        $this.Column = $column
        $this.Source = $source
    }
}

class PSQAFixResult {
    [string]$FixType
    [string]$Description
    [bool]$Applied
    [string]$OriginalContent
    [string]$FixedContent

    PSQAFixResult([string]$fixType, [string]$description) {
        $this.FixType = $fixType
        $this.Description = $description
        $this.Applied = $false
    }
}

Export-ModuleMember -Variable '*'
