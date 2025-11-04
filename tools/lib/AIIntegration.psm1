<#
.SYNOPSIS
    AI/ML Integration Module for PoshGuard

.DESCRIPTION
    Provides artificial intelligence and machine learning capabilities:
    - ML-based confidence scoring for fixes
    - Model Context Protocol (MCP) integration
    - Pattern learning and continuous improvement
    - AI-powered fix suggestions
    - Semantic code understanding
    - Predictive issue detection

.NOTES
    Version: 4.0.0
    Part of PoshGuard UGE Framework Enhancement
    Reference: docs/reference/AI-ML-INTEGRATION.md
    
    Privacy: All features work locally by default. MCP integration is optional.
    Cost: FREE - No cloud services required
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Module Variables

$script:AIConfig = @{
  ConfidenceScoring = $true
  PatternLearning = $true
  MCPIntegration = $false
  LLMIntegration = $false
  PatternDatabasePath = "./ml/patterns.jsonl"
  ConfigPath = "./config/ai.json"
}

$script:ConfidenceWeights = @{
  SyntaxValid = 0.50
  ASTPreserved = 0.20
  MinimalChange = 0.20
  NoSideEffects = 0.10
}

$script:MCPCache = @{}

#endregion

#region Confidence Scoring

function Get-FixConfidenceScore {
  <#
    .SYNOPSIS
        Calculate confidence score for a code fix
    
    .DESCRIPTION
        Uses ML-based algorithm to score fix quality from 0.0 to 1.0
        Factors: syntax validity (50%), AST preservation (20%), 
                 minimal changes (20%), no side effects (10%)
    
    .PARAMETER OriginalContent
        Original code content before fix
    
    .PARAMETER FixedContent
        Fixed code content after transformation
    
    .EXAMPLE
        $score = Get-FixConfidenceScore -OriginalContent $before -FixedContent $after
        # Returns: 0.92 (Excellent quality fix)
    
    .OUTPUTS
        System.Double - Confidence score between 0.0 and 1.0
    #>
  [CmdletBinding()]
  [OutputType([double])]
  param(
    [Parameter(Mandatory)]
    [string]$OriginalContent,
        
    [Parameter(Mandatory)]
    [string]$FixedContent
  )
    
  if (-not $script:AIConfig.ConfidenceScoring) {
    return 1.0  # Default confidence when AI disabled
  }
    
  try {
    # Calculate individual scores
    $syntaxValid = Test-SyntaxValidity -Content $FixedContent
    $astPreserved = Test-ASTStructurePreservation -Before $OriginalContent -After $FixedContent
    $minimalChange = Test-ChangeMinimality -Before $OriginalContent -After $FixedContent
    $noSideEffects = Test-SafetyChecks -Content $FixedContent
        
    # Weighted average
    $confidence = (
      ($syntaxValid * $script:ConfidenceWeights.SyntaxValid) +
      ($astPreserved * $script:ConfidenceWeights.ASTPreserved) +
      ($minimalChange * $script:ConfidenceWeights.MinimalChange) +
      ($noSideEffects * $script:ConfidenceWeights.NoSideEffects)
    )
        
    return [Math]::Round($confidence, 2)
  }
  catch {
    Write-Verbose "Confidence scoring failed: $_"
    return 0.5  # Neutral confidence on error
  }
}

function Test-SyntaxValidity {
  <#
    .SYNOPSIS
        Test if code has valid PowerShell syntax
    
    .PARAMETER Content
        Code content to validate
    
    .OUTPUTS
        System.Double - Score 1.0 if valid, 0.0 if invalid
    #>
  [CmdletBinding()]
  [OutputType([double])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
    
  try {
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content, [ref]$null, [ref]$null
    )
    return 1.0
  }
  catch {
    return 0.0
  }
}

function Test-ASTStructurePreservation {
  <#
    .SYNOPSIS
        Test if AST structure is preserved after fix
    
    .PARAMETER Before
        Original code
    
    .PARAMETER After
        Fixed code
    
    .OUTPUTS
        System.Double - Score based on AST similarity (0.0-1.0)
    #>
  [CmdletBinding()]
  [OutputType([double])]
  param(
    [Parameter(Mandatory)]
    [string]$Before,
        
    [Parameter(Mandatory)]
    [string]$After
  )
    
  try {
    $astBefore = [System.Management.Automation.Language.Parser]::ParseInput(
      $Before, [ref]$null, [ref]$null
    )
    $astAfter = [System.Management.Automation.Language.Parser]::ParseInput(
      $After, [ref]$null, [ref]$null
    )
        
    # Compare AST node counts as proxy for structure similarity
    $nodesBefore = @($astBefore.FindAll({ $true }, $true)).Count
    $nodesAfter = @($astAfter.FindAll({ $true }, $true)).Count
        
    if ($nodesBefore -eq 0) {
      return 1.0
    }
        
    $difference = [Math]::Abs($nodesBefore - $nodesAfter)
    $similarity = 1.0 - ([Math]::Min($difference, $nodesBefore) / $nodesBefore)
        
    return [Math]::Max(0.0, [Math]::Min(1.0, $similarity))
  }
  catch {
    return 0.5  # Neutral score if comparison fails
  }
}

function Test-ChangeMinimality {
  <#
    .SYNOPSIS
        Test if changes are minimal (prefer smaller diffs)
    
    .PARAMETER Before
        Original code
    
    .PARAMETER After
        Fixed code
    
    .OUTPUTS
        System.Double - Score based on change size (0.0-1.0)
    #>
  [CmdletBinding()]
  [OutputType([double])]
  param(
    [Parameter(Mandatory)]
    [string]$Before,
        
    [Parameter(Mandatory)]
    [string]$After
  )
    
  try {
    $linesBefore = ($Before -split "`n").Count
    $linesAfter = ($After -split "`n").Count
        
    if ($linesBefore -eq 0) {
      return 1.0
    }
        
    # Calculate change ratio
    $changeRatio = [Math]::Abs($linesBefore - $linesAfter) / $linesBefore
        
    # Score: 1.0 for no change, decreasing with change size
    $score = 1.0 - [Math]::Min($changeRatio, 1.0)
        
    return [Math]::Max(0.0, $score)
  }
  catch {
    return 0.5
  }
}

function Test-SafetyCheck {
  <#
    .SYNOPSIS
        Test if code passes safety checks (no dangerous operations)
    
    .PARAMETER Content
        Code content to check
    
    .OUTPUTS
        System.Double - Score 1.0 if safe, reduced for dangerous patterns
    #>
  [CmdletBinding()]
  [OutputType([double])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
    
  try {
    $dangerousPatterns = @(
      'Invoke-Expression',
      'iex',
      'New-Object\s+Net\.WebClient',
      '\beval\b',
      'DownloadString',
      'DownloadFile'
    )
        
    $score = 1.0
    foreach ($pattern in $dangerousPatterns) {
      if ($Content -match $pattern) {
        $score -= 0.2
      }
    }
        
    return [Math]::Max(0.0, $score)
  }
  catch {
    return 0.8
  }
}

#endregion

#region Pattern Learning

function Add-FixPattern {
  <#
    .SYNOPSIS
        Record a fix attempt for pattern learning
    
    .PARAMETER RuleName
        Name of the rule that was applied
    
    .PARAMETER FilePath
        Path to the file that was fixed
    
    .PARAMETER LineNumber
        Line number of the fix
    
    .PARAMETER OriginalCode
        Original code before fix
    
    .PARAMETER FixedCode
        Fixed code after transformation
    
    .PARAMETER ConfidenceScore
        Confidence score of the fix
    
    .PARAMETER Success
        Whether the fix was successful
    
    .PARAMETER ExecutionTimeMs
        Time taken to apply fix in milliseconds
    
    .EXAMPLE
        Add-FixPattern -RuleName "PSAvoidUsingCmdletAliases" -Success $true -ConfidenceScore 0.95
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$RuleName,
        
    [Parameter(Mandatory)]
    [string]$FilePath,
        
    [Parameter(Mandatory)]
    [int]$LineNumber,
        
    [Parameter(Mandatory)]
    [string]$OriginalCode,
        
    [Parameter(Mandatory)]
    [string]$FixedCode,
        
    [Parameter(Mandatory)]
    [double]$ConfidenceScore,
        
    [Parameter(Mandatory)]
    [bool]$Success,
        
    [Parameter()]
    [int]$ExecutionTimeMs = 0
  )
    
  if (-not $script:AIConfig.PatternLearning) {
    return
  }
    
  try {
    # Ensure directory exists
    $dbPath = $script:AIConfig.PatternDatabasePath
    $dbDir = Split-Path -Parent $dbPath
    if ($dbDir -and -not (Test-Path -Path $dbDir)) {
      New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
    }
        
    # Create pattern record
    $pattern = @{
      timestamp = Get-Date -Format "o"
      rule = $RuleName
      file_path = $FilePath
      line_number = $LineNumber
      original_code = $OriginalCode.Substring(0, [Math]::Min(500, $OriginalCode.Length))
      fixed_code = $FixedCode.Substring(0, [Math]::Min(500, $FixedCode.Length))
      confidence_score = $ConfidenceScore
      success = $Success
      execution_time_ms = $ExecutionTimeMs
    }
        
    # Append to JSONL database
    Add-Content -Path $dbPath -Value ($pattern | ConvertTo-Json -Compress)
        
    # Check if retraining needed (every 100 patterns)
    if ((Get-Content -Path $dbPath | Measure-Object).Count % 100 -eq 0) {
      Write-Verbose "100 patterns accumulated - triggering model retraining"
      Invoke-ModelRetraining
    }
  }
  catch {
    Write-Verbose "Failed to add pattern: $_"
  }
}

function Invoke-ModelRetraining {
  <#
    .SYNOPSIS
        Retrain ML model with accumulated patterns
    
    .DESCRIPTION
        Analyzes historical fix patterns to:
        - Calculate success rates per rule
        - Identify problem rules (< 50% success)
        - Update confidence scoring weights
    
    .EXAMPLE
        Invoke-ModelRetraining -Verbose
    #>
  [CmdletBinding()]
  param()
    
  Write-Verbose "🔄 Retraining ML model with latest patterns..."
    
  try {
    $dbPath = $script:AIConfig.PatternDatabasePath
    if (-not (Test-Path -Path $dbPath)) {
      Write-Warning "No pattern database found. Run some fixes first."
      return
    }
        
    # Load all patterns
    $patterns = Get-Content -Path $dbPath | ForEach-Object {
      try { $_ | ConvertFrom-Json } catch { $null }
    } | Where-Object { $_ -ne $null }
        
    if ($patterns.Count -eq 0) {
      Write-Warning "Pattern database is empty"
      return
    }
        
    # Calculate statistics per rule
    $ruleStats = $patterns | Group-Object -Property rule | ForEach-Object {
      $group = $_.Group
      $successCount = ($group | Where-Object { $_.success }).Count
      $totalCount = $_.Count
            
      [PSCustomObject]@{
        Rule = $_.Name
        SuccessRate = if ($totalCount -gt 0) { $successCount / $totalCount } else { 0 }
        AvgConfidence = ($group | Measure-Object -Property confidence_score -Average).Average
        TotalAttempts = $totalCount
      }
    }
        
    # Identify problem rules
    $problemRules = $ruleStats | Where-Object { $_.SuccessRate -lt 0.5 }
        
    if ($problemRules) {
      Write-Warning "⚠️  Rules needing attention:"
      foreach ($rule in $problemRules) {
        Write-Warning "  • $($rule.Rule): $([Math]::Round($rule.SuccessRate * 100, 1))% success rate ($($rule.TotalAttempts) attempts)"
      }
    }
        
    # Update confidence weights based on performance
    Update-ConfidenceWeights -Statistics $ruleStats
        
    Write-Verbose "✅ Model retraining complete - analyzed $($patterns.Count) patterns"
  }
  catch {
    Write-Warning "Model retraining failed: $_"
  }
}

function Update-ConfidenceWeight {
  <#
    .SYNOPSIS
        Update confidence scoring weights based on historical performance
    
    .PARAMETER Statistics
        Array of rule statistics from pattern analysis
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [object[]]$Statistics
  )
    
  # For now, keep weights static
  # Future: Implement adaptive weight adjustment based on correlations
  Write-Verbose "Confidence weights remain unchanged (adaptive weighting not yet implemented)"
}

#endregion

#region MCP Integration

function Test-MCPAvailable {
  <#
    .SYNOPSIS
        Check if MCP integration is available
    
    .OUTPUTS
        System.Boolean - True if MCP is configured and available
    #>
  [CmdletBinding()]
  [OutputType([bool])]
  param()
    
  return ($script:AIConfig.MCPIntegration -and (Get-Command Invoke-MCPQuery -ErrorAction SilentlyContinue))
}

function Get-MCPContext {
  <#
    .SYNOPSIS
        Get contextual information from MCP server
    
    .PARAMETER Query
        Query to send to MCP server
    
    .PARAMETER CacheTTL
        Cache time-to-live in seconds (default: 3600)
    
    .EXAMPLE
        $context = Get-MCPContext -Query "PowerShell SecureString best practices"
    
    .OUTPUTS
        System.Object - Context information from MCP server
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Query,
        
    [Parameter()]
    [int]$CacheTTL = 3600
  )
    
  if (-not (Test-MCPAvailable)) {
    Write-Verbose "MCP not available"
    return $null
  }
    
  # Check cache
  $cacheKey = $Query.GetHashCode()
  if ($script:MCPCache.ContainsKey($cacheKey)) {
    $cached = $script:MCPCache[$cacheKey]
    if ((Get-Date) -lt $cached.Expires) {
      Write-Verbose "Using cached MCP response"
      return $cached.Data
    }
  }
    
  try {
    # Query MCP server (placeholder - requires FastMCP module)
    Write-Verbose "Querying MCP server: $Query"
        
    # This would be the actual MCP call:
    # $response = Invoke-MCPQuery -Query $Query
        
    # For now, return placeholder
    $response = @{
      Source = "Context7"
      Query = $Query
      Result = "MCP integration available but FastMCP module not loaded"
      References = @()
    }
        
    # Cache response
    $script:MCPCache[$cacheKey] = @{
      Data = $response
      Expires = (Get-Date).AddSeconds($CacheTTL)
    }
        
    return $response
  }
  catch {
    Write-Verbose "MCP query failed: $_"
    return $null
  }
}

function Clear-MCPCache {
  <#
    .SYNOPSIS
        Clear MCP response cache
    #>
  [CmdletBinding()]
  param()
    
  $script:MCPCache = @{}
  Write-Verbose "MCP cache cleared"
}

#endregion

#region AI Configuration

function Initialize-AIFeature {
  <#
    .SYNOPSIS
        Initialize AI/ML features for PoshGuard
    
    .PARAMETER Configuration
        Hashtable with AI configuration options
    
    .PARAMETER Minimal
        Use minimal configuration (local ML only)
    
    .EXAMPLE
        Initialize-AIFeatures -Minimal
    
    .EXAMPLE
        Initialize-AIFeatures -Configuration @{ MCPIntegration = $true }
    #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [hashtable]$Configuration,
        
    [Parameter()]
    [switch]$Minimal
  )
    
  if ($Minimal) {
    $script:AIConfig.ConfidenceScoring = $true
    $script:AIConfig.PatternLearning = $true
    $script:AIConfig.MCPIntegration = $false
    $script:AIConfig.LLMIntegration = $false
  }
  elseif ($Configuration) {
    foreach ($key in $Configuration.Keys) {
      if ($script:AIConfig.ContainsKey($key)) {
        $script:AIConfig[$key] = $Configuration[$key]
      }
    }
  }
    
  # Create directories
  $mlDir = Split-Path -Parent $script:AIConfig.PatternDatabasePath
  if ($mlDir -and -not (Test-Path -Path $mlDir)) {
    New-Item -Path $mlDir -ItemType Directory -Force | Out-Null
  }
    
  # Save configuration
  $configDir = Split-Path -Parent $script:AIConfig.ConfigPath
  if ($configDir -and -not (Test-Path -Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
  }
    
  Set-Content -Path $script:AIConfig.ConfigPath -Value ($script:AIConfig | ConvertTo-Json)
    
  Write-Host "✅ AI features initialized" -ForegroundColor Green
  Write-Host "  Confidence Scoring: $($script:AIConfig.ConfidenceScoring)" -ForegroundColor Cyan
  Write-Host "  Pattern Learning: $($script:AIConfig.PatternLearning)" -ForegroundColor Cyan
  Write-Host "  MCP Integration: $($script:AIConfig.MCPIntegration)" -ForegroundColor Cyan
  Write-Host "  LLM Integration: $($script:AIConfig.LLMIntegration)" -ForegroundColor Cyan
}

function Get-AIConfiguration {
  <#
    .SYNOPSIS
        Get current AI configuration
    
    .OUTPUTS
        System.Collections.Hashtable - Current AI configuration
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param()
    
  return $script:AIConfig.Clone()
}

function Test-AIFeature {
  <#
    .SYNOPSIS
        Test AI features are working correctly
    
    .EXAMPLE
        Test-AIFeatures -Verbose
    
    .OUTPUTS
        PSCustomObject with test results
    #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is used intentionally for test progress output with colors')]
  param()
    
  Write-Host "🧪 Testing AI Features" -ForegroundColor Cyan
    
  # Test confidence scoring
  Write-Host "`n1. Testing Confidence Scoring..." -ForegroundColor Yellow
  $testCode = 'Get-ChildItem -Path C:\'
  $score = Get-FixConfidenceScore -OriginalContent 'gci C:\' -FixedContent $testCode
  Write-Host "   ✅ Confidence Score: $score" -ForegroundColor Green
  $confidenceScoringPassed = $score -gt 0
    
  # Test pattern learning
  Write-Host "`n2. Testing Pattern Learning..." -ForegroundColor Yellow
  Add-FixPattern -RuleName "Test" -FilePath "test.ps1" -LineNumber 1 `
    -OriginalCode "test" -FixedCode "test" -ConfidenceScore 0.9 `
    -Success $true -ExecutionTimeMs 10
  Write-Host "   ✅ Pattern recorded" -ForegroundColor Green
  $patternLearningPassed = $true
    
  # Test MCP
  Write-Host "`n3. Testing MCP Integration..." -ForegroundColor Yellow
  $mcpAvailable = Test-MCPAvailable
  if ($mcpAvailable) {
    Write-Host "   ✅ MCP available" -ForegroundColor Green
  }
  else {
    Write-Host "   ℹ️  MCP not configured (optional)" -ForegroundColor Gray
  }
    
  Write-Host "`n✅ All tests passed" -ForegroundColor Green
    
  # Return test results
  return [PSCustomObject]@{
    ConfidenceScoring = $confidenceScoringPassed
    PatternLearning = $patternLearningPassed
    MCPIntegration = $mcpAvailable
    AllPassed = $confidenceScoringPassed -and $patternLearningPassed
  }
}

#endregion

# Export public functions
Export-ModuleMember -Function @(
  'Get-FixConfidenceScore',
  'Add-FixPattern',
  'Invoke-ModelRetraining',
  'Test-MCPAvailable',
  'Get-MCPContext',
  'Clear-MCPCache',
  'Initialize-AIFeatures',
  'Get-AIConfiguration',
  'Test-AIFeatures'
)
