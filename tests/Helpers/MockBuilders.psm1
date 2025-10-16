<#
.SYNOPSIS
    Mock object builders for PoshGuard Pester tests

.DESCRIPTION
    Factory functions for creating mock objects used across test suites:
    - PSScriptAnalyzer diagnostic records
    - AST objects
    - Security findings
    - OpenTelemetry spans
    - AI/ML model responses

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ best practices with deterministic mock data
#>

Set-StrictMode -Version Latest

function New-MockDiagnosticRecord {
  <#
  .SYNOPSIS
      Creates a mock PSScriptAnalyzer diagnostic record
  
  .PARAMETER RuleName
      Name of the PSScriptAnalyzer rule
  
  .PARAMETER Message
      Diagnostic message
  
  .PARAMETER Severity
      Severity level (Error, Warning, Information)
  
  .PARAMETER Line
      Line number where issue was found
  
  .PARAMETER Column
      Column number where issue was found
  
  .PARAMETER ScriptPath
      Path to the script file
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [string]$RuleName,
    
    [Parameter(Mandatory)]
    [string]$Message,
    
    [ValidateSet('Error', 'Warning', 'Information')]
    [string]$Severity = 'Warning',
    
    [int]$Line = 1,
    
    [int]$Column = 1,
    
    [string]$ScriptPath = 'TestScript.ps1'
  )
  
  return [PSCustomObject]@{
    RuleName        = $RuleName
    Message         = $Message
    Severity        = $Severity
    Line            = $Line
    Column          = $Column
    ScriptPath      = $ScriptPath
    RuleSuppressionID = $null
    SuggestedCorrections = @()
  }
}

function New-MockAST {
  <#
  .SYNOPSIS
      Creates a simplified mock AST object
  
  .PARAMETER Type
      Type of AST element (ScriptBlock, FunctionDefinition, etc.)
  
  .PARAMETER Extent
      Mock extent with line/column info
  
  .PARAMETER Content
      Script content
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [string]$Type = 'ScriptBlockAst',
    
    [hashtable]$Extent = @{
      StartLineNumber = 1
      EndLineNumber = 1
      StartColumnNumber = 1
      EndColumnNumber = 10
      Text = ''
    },
    
    [string]$Content = ''
  )
  
  $mockExtent = [PSCustomObject]$Extent
  $mockExtent.PSTypeNames.Insert(0, 'System.Management.Automation.Language.IScriptExtent')
  
  $ast = [PSCustomObject]@{
    Extent = $mockExtent
    PSTypeNames = @("System.Management.Automation.Language.$Type")
  }
  
  if ($Content) {
    $ast | Add-Member -NotePropertyName 'Content' -NotePropertyValue $Content
  }
  
  return $ast
}

function New-MockSecurityFinding {
  <#
  .SYNOPSIS
      Creates a mock security finding object
  
  .PARAMETER FindingType
      Type of security finding
  
  .PARAMETER Severity
      Severity level (Critical, High, Medium, Low)
  
  .PARAMETER Description
      Finding description
  
  .PARAMETER Line
      Line number
  
  .PARAMETER Remediation
      Suggested remediation
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [string]$FindingType,
    
    [ValidateSet('Critical', 'High', 'Medium', 'Low')]
    [string]$Severity = 'Medium',
    
    [string]$Description = 'Security finding',
    
    [int]$Line = 1,
    
    [string]$Remediation = 'Fix the issue'
  )
  
  return [PSCustomObject]@{
    FindingType = $FindingType
    Severity = $Severity
    Description = $Description
    Line = $Line
    Remediation = $Remediation
    Confidence = 0.95
    CVSS = $null
  }
}

function New-MockOTelSpan {
  <#
  .SYNOPSIS
      Creates a mock OpenTelemetry span
  
  .PARAMETER Name
      Span name
  
  .PARAMETER TraceId
      Trace ID (deterministic for tests)
  
  .PARAMETER SpanId
      Span ID (deterministic for tests)
  
  .PARAMETER Status
      Span status (OK, Error)
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [string]$Name = 'test-span',
    
    [string]$TraceId = '00000000000000000000000000000001',
    
    [string]$SpanId = '0000000000000001',
    
    [ValidateSet('OK', 'Error')]
    [string]$Status = 'OK'
  )
  
  return [PSCustomObject]@{
    Name = $Name
    TraceId = $TraceId
    SpanId = $SpanId
    Status = $Status
    Attributes = @{}
    StartTime = [DateTime]::Parse('2025-01-01T00:00:00Z')
    EndTime = [DateTime]::Parse('2025-01-01T00:00:01Z')
  }
}

function New-MockAIResponse {
  <#
  .SYNOPSIS
      Creates a mock AI/ML model response
  
  .PARAMETER Confidence
      Confidence score (0.0 - 1.0)
  
  .PARAMETER Prediction
      Predicted value/class
  
  .PARAMETER ModelVersion
      Model version identifier
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [ValidateRange(0.0, 1.0)]
    [double]$Confidence = 0.95,
    
    [string]$Prediction = 'safe',
    
    [string]$ModelVersion = '1.0.0'
  )
  
  return [PSCustomObject]@{
    Confidence = $Confidence
    Prediction = $Prediction
    ModelVersion = $ModelVersion
    Timestamp = [DateTime]::Parse('2025-01-01T00:00:00Z')
    Features = @{}
  }
}

function New-MockPSScriptAnalyzerResult {
  <#
  .SYNOPSIS
      Creates a complete mock PSScriptAnalyzer result with multiple diagnostics
  
  .PARAMETER DiagnosticRecords
      Array of diagnostic records to include
  #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter()]
    [array]$DiagnosticRecords = @()
  )
  
  return $DiagnosticRecords
}

function New-TestScriptAST {
  <#
  .SYNOPSIS
      Parses PowerShell script content into real AST for testing
  
  .PARAMETER Content
      PowerShell script content to parse
  
  .PARAMETER ThrowOnError
      Throw if parsing fails (default: true)
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
    
    [bool]$ThrowOnError = $true
  )
  
  $errors = $null
  $tokens = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $Content,
    [ref]$tokens,
    [ref]$errors
  )
  
  if ($errors -and $ThrowOnError) {
    throw "Failed to parse script: $($errors[0].Message)"
  }
  
  return [PSCustomObject]@{
    AST = $ast
    Tokens = $tokens
    Errors = $errors
  }
}

function Get-MockTimeProvider {
  <#
  .SYNOPSIS
      Returns a mock time provider for deterministic time-based tests
  
  .PARAMETER FixedTime
      Fixed time to return (default: 2025-01-01 00:00:00 UTC)
  #>
  [CmdletBinding()]
  param(
    [DateTime]$FixedTime = [DateTime]::Parse('2025-01-01T00:00:00Z')
  )
  
  return @{
    GetCurrentTime = { $FixedTime }
    FixedTime = $FixedTime
  }
}

# Export all functions
Export-ModuleMember -Function @(
  'New-MockDiagnosticRecord',
  'New-MockAST',
  'New-MockSecurityFinding',
  'New-MockOTelSpan',
  'New-MockAIResponse',
  'New-MockPSScriptAnalyzerResult',
  'New-TestScriptAST',
  'Get-MockTimeProvider'
)
