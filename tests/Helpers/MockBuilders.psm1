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

function New-MockSBOM {
  <#
  .SYNOPSIS
      Creates a mock SBOM (Software Bill of Materials)
  
  .PARAMETER Format
      SBOM format (CycloneDX, SPDX)
  
  .PARAMETER ComponentCount
      Number of mock components to include
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [ValidateSet('CycloneDX', 'SPDX')]
    [string]$Format = 'CycloneDX',
    
    [int]$ComponentCount = 2
  )
  
  $components = @()
  for ($i = 1; $i -le $ComponentCount; $i++) {
    $components += [PSCustomObject]@{
      Name = "TestComponent$i"
      Version = "1.$i.0"
      Type = 'library'
      Licenses = @('MIT')
    }
  }
  
  return [PSCustomObject]@{
    BOMFormat = $Format
    SpecVersion = if ($Format -eq 'CycloneDX') { '1.5' } else { '2.3' }
    Components = $components
    Dependencies = @()
    Metadata = @{
      Timestamp = [DateTime]::Parse('2025-01-01T00:00:00Z')
    }
  }
}

function New-MockVulnerability {
  <#
  .SYNOPSIS
      Creates a mock vulnerability finding
  
  .PARAMETER Severity
      Severity level
  
  .PARAMETER CVE
      CVE identifier
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [ValidateSet('Critical', 'High', 'Medium', 'Low')]
    [string]$Severity = 'High',
    
    [string]$CVE = 'CVE-2024-0001'
  )
  
  return [PSCustomObject]@{
    ID = $CVE
    Severity = $Severity
    Description = 'Test vulnerability description'
    Remediation = 'Update to latest version'
    AffectedVersions = @('< 2.0.0')
    FixedVersion = '2.0.0'
    CVSS = 7.5
    References = @('https://nvd.nist.gov/vuln/detail/' + $CVE)
  }
}

function New-MockNISTControl {
  <#
  .SYNOPSIS
      Creates a mock NIST SP 800-53 control result
  
  .PARAMETER ControlID
      Control identifier (e.g., 'AC-2')
  
  .PARAMETER Compliant
      Whether control is compliant
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [string]$ControlID = 'AC-2',
    
    [bool]$Compliant = $true
  )
  
  return [PSCustomObject]@{
    ControlID = $ControlID
    Title = "Test Control: $ControlID"
    Compliant = $Compliant
    Findings = if (-not $Compliant) { @('Non-compliance found') } else { @() }
    Severity = if (-not $Compliant) { 'High' } else { 'None' }
    Remediation = if (-not $Compliant) { 'Address findings' } else { $null }
  }
}

function New-MockMCPResponse {
  <#
  .SYNOPSIS
      Creates a mock Model Context Protocol response
  
  .PARAMETER Success
      Whether the operation succeeded
  
  .PARAMETER Result
      Result data
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [bool]$Success = $true,
    
    [object]$Result = @{ data = 'test' }
  )
  
  return [PSCustomObject]@{
    Success = $Success
    Result = $Result
    Error = if (-not $Success) { 'Mock error' } else { $null }
    Timestamp = [DateTime]::Parse('2025-01-01T00:00:00Z')
  }
}

function New-MockRLState {
  <#
  .SYNOPSIS
      Creates a mock Reinforcement Learning state
  
  .PARAMETER StateVector
      State representation vector
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [double[]]$StateVector = @(0.1, 0.2, 0.3)
  )
  
  return [PSCustomObject]@{
    Vector = $StateVector
    Hash = ($StateVector -join ',').GetHashCode()
    Timestamp = [DateTime]::Parse('2025-01-01T00:00:00Z')
  }
}

function New-MockMetric {
  <#
  .SYNOPSIS
      Creates a mock metric data point
  
  .PARAMETER Name
      Metric name
  
  .PARAMETER Value
      Metric value
  
  .PARAMETER Tags
      Metric tags/labels
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [string]$Name = 'test.metric',
    
    [double]$Value = 42.0,
    
    [hashtable]$Tags = @{ environment = 'test' }
  )
  
  return [PSCustomObject]@{
    Name = $Name
    Value = $Value
    Tags = $Tags
    Timestamp = [DateTime]::Parse('2025-01-01T00:00:00Z')
    Unit = 'count'
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
  'Get-MockTimeProvider',
  'New-MockSBOM',
  'New-MockVulnerability',
  'New-MockNISTControl',
  'New-MockMCPResponse',
  'New-MockRLState',
  'New-MockMetric'
)
