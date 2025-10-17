<#
.SYNOPSIS
    Standard Pester configurations for PoshGuard test suite

.DESCRIPTION
    Pre-configured PesterConfiguration objects following best practices:
    - Fast unit tests (no coverage)
    - Coverage-enabled runs (CI mode)
    - Debug mode (detailed output)
    - Single file runs
    
    Ensures consistent test execution across development and CI.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Version: 1.0.0
#>

Set-StrictMode -Version Latest

function New-FastTestConfiguration {
  <#
  .SYNOPSIS
      Creates Pester configuration for fast unit test runs (no coverage)
  
  .PARAMETER Path
      Path to test files or directory (default: ./tests/Unit)
  
  .PARAMETER PassThru
      Return test results object
  
  .EXAMPLE
      $config = New-FastTestConfiguration
      Invoke-Pester -Configuration $config
  #>
  [CmdletBinding()]
  [OutputType([object])]
  param(
    [string]$Path = './tests/Unit',
    
    [switch]$PassThru
  )
  
  # Ensure Pester is loaded
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -MinimumVersion 5.5.0 -ErrorAction Stop
  }
  
  $config = New-PesterConfiguration
  
  # Run settings
  $config.Run.Path = $Path
  $config.Run.PassThru = $PassThru.IsPresent
  $config.Run.Exit = $false
  
  # Output settings
  $config.Output.Verbosity = 'Normal'
  
  # Disable coverage for speed
  $config.CodeCoverage.Enabled = $false
  
  # Disable test results file
  $config.TestResult.Enabled = $false
  
  return $config
}

function New-CoverageTestConfiguration {
  <#
  .SYNOPSIS
      Creates Pester configuration with code coverage (CI mode)
  
  .PARAMETER Path
      Path to test files or directory
  
  .PARAMETER CoveragePath
      Path(s) to modules for coverage analysis
  
  .PARAMETER OutputPath
      Path for coverage report (default: ./coverage.xml)
  
  .PARAMETER TestResultPath
      Path for test results (default: ./test-results.xml)
  
  .EXAMPLE
      $config = New-CoverageTestConfiguration -Path './tests/Unit' -CoveragePath './tools/lib/*.psm1'
      Invoke-Pester -Configuration $config
  #>
  [CmdletBinding()]
  [OutputType([object])]
  param(
    [string]$Path = './tests/Unit',
    
    [string[]]$CoveragePath = @('./tools/lib/*.psm1'),
    
    [string]$OutputPath = './coverage.xml',
    
    [string]$TestResultPath = './test-results.xml'
  )
  
  # Ensure Pester is loaded
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -MinimumVersion 5.5.0 -ErrorAction Stop
  }
  
  $config = New-PesterConfiguration
  
  # Run settings
  $config.Run.Path = $Path
  $config.Run.PassThru = $true
  $config.Run.Exit = $false
  
  # Output settings
  $config.Output.Verbosity = 'Normal'
  
  # Code coverage settings
  $config.CodeCoverage.Enabled = $true
  $config.CodeCoverage.Path = $CoveragePath
  $config.CodeCoverage.OutputFormat = 'JaCoCo'
  $config.CodeCoverage.OutputPath = $OutputPath
  
  # Test result settings
  $config.TestResult.Enabled = $true
  $config.TestResult.OutputFormat = 'NUnitXml'
  $config.TestResult.OutputPath = $TestResultPath
  
  return $config
}

function New-DebugTestConfiguration {
  <#
  .SYNOPSIS
      Creates Pester configuration for debugging (detailed output)
  
  .PARAMETER Path
      Path to test file or directory
  
  .PARAMETER StopOnFailure
      Stop test run on first failure
  
  .EXAMPLE
      $config = New-DebugTestConfiguration -Path './tests/Unit/Core.Tests.ps1'
      Invoke-Pester -Configuration $config
  #>
  [CmdletBinding()]
  [OutputType([object])]
  param(
    [string]$Path = './tests/Unit',
    
    [switch]$StopOnFailure
  )
  
  # Ensure Pester is loaded
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -MinimumVersion 5.5.0 -ErrorAction Stop
  }
  
  $config = New-PesterConfiguration
  
  # Run settings
  $config.Run.Path = $Path
  $config.Run.PassThru = $true
  $config.Run.Exit = $false
  
  if ($StopOnFailure) {
    $config.Run.SkipRemainingOnFailure = 'Container'
  }
  
  # Output settings (detailed for debugging)
  $config.Output.Verbosity = 'Detailed'
  
  # Disable coverage for speed
  $config.CodeCoverage.Enabled = $false
  
  # Disable test results file
  $config.TestResult.Enabled = $false
  
  return $config
}

function New-SingleFileTestConfiguration {
  <#
  .SYNOPSIS
      Creates Pester configuration optimized for single file testing
  
  .PARAMETER FilePath
      Path to single test file
  
  .PARAMETER ShowProgress
      Show detailed progress for each test
  
  .EXAMPLE
      $config = New-SingleFileTestConfiguration -FilePath './tests/Unit/Core.Tests.ps1'
      Invoke-Pester -Configuration $config
  #>
  [CmdletBinding()]
  [OutputType([object])]
  param(
    [Parameter(Mandatory)]
    [string]$FilePath,
    
    [switch]$ShowProgress
  )
  
  if (-not (Test-Path $FilePath)) {
    throw "Test file not found: $FilePath"
  }
  
  # Ensure Pester is loaded
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -MinimumVersion 5.5.0 -ErrorAction Stop
  }
  
  $config = New-PesterConfiguration
  
  # Run settings
  $config.Run.Path = $FilePath
  $config.Run.PassThru = $true
  $config.Run.Exit = $false
  
  # Output settings
  $config.Output.Verbosity = if ($ShowProgress) { 'Detailed' } else { 'Normal' }
  
  # Disable coverage for speed
  $config.CodeCoverage.Enabled = $false
  
  # Disable test results file
  $config.TestResult.Enabled = $false
  
  return $config
}

function New-TaggedTestConfiguration {
  <#
  .SYNOPSIS
      Creates Pester configuration for running tagged tests
  
  .PARAMETER Path
      Path to test files or directory
  
  .PARAMETER Tag
      Tags to include (e.g., 'Unit', 'Security', 'Fast')
  
  .PARAMETER ExcludeTag
      Tags to exclude (e.g., 'Slow', 'Integration')
  
  .EXAMPLE
      $config = New-TaggedTestConfiguration -Tag 'Unit','Security' -ExcludeTag 'Slow'
      Invoke-Pester -Configuration $config
  #>
  [CmdletBinding()]
  [OutputType([object])]
  param(
    [string]$Path = './tests/Unit',
    
    [string[]]$Tag,
    
    [string[]]$ExcludeTag
  )
  
  # Ensure Pester is loaded
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -MinimumVersion 5.5.0 -ErrorAction Stop
  }
  
  $config = New-PesterConfiguration
  
  # Run settings
  $config.Run.Path = $Path
  $config.Run.PassThru = $true
  $config.Run.Exit = $false
  
  # Filter settings
  if ($Tag) {
    $config.Filter.Tag = $Tag
  }
  
  if ($ExcludeTag) {
    $config.Filter.ExcludeTag = $ExcludeTag
  }
  
  # Output settings
  $config.Output.Verbosity = 'Normal'
  
  # Disable coverage for speed
  $config.CodeCoverage.Enabled = $false
  
  # Disable test results file
  $config.TestResult.Enabled = $false
  
  return $config
}

function New-CITestConfiguration {
  <#
  .SYNOPSIS
      Creates Pester configuration matching CI/CD pipeline settings
  
  .PARAMETER Path
      Path to test files or directory
  
  .PARAMETER CoveragePath
      Path(s) to modules for coverage analysis
  
  .PARAMETER EnableCoverage
      Enable code coverage (default on Linux only)
  
  .EXAMPLE
      # Simulate CI locally
      $config = New-CITestConfiguration -EnableCoverage:$IsLinux
      Invoke-Pester -Configuration $config
  #>
  [CmdletBinding()]
  [OutputType([object])]
  param(
    [string]$Path = './tests/Unit',
    
    [string[]]$CoveragePath = @('./tools/lib/*.psm1'),
    
    [bool]$EnableCoverage = $false
  )
  
  # Ensure Pester is loaded
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -MinimumVersion 5.5.0 -ErrorAction Stop
  }
  
  $config = New-PesterConfiguration
  
  # Run settings
  $config.Run.Path = $Path
  $config.Run.PassThru = $true
  $config.Run.Exit = $false
  
  # Output settings (detailed for CI logs)
  $config.Output.Verbosity = 'Detailed'
  
  # Test result settings (always enabled in CI)
  $config.TestResult.Enabled = $true
  $config.TestResult.OutputFormat = 'NUnitXml'
  $config.TestResult.OutputPath = './test-results.xml'
  
  # Code coverage settings (conditional)
  if ($EnableCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $CoveragePath
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = './coverage.xml'
  } else {
    $config.CodeCoverage.Enabled = $false
  }
  
  return $config
}

function Invoke-TestWithRetry {
  <#
  .SYNOPSIS
      Runs Pester tests with automatic retry on failure
  
  .PARAMETER Configuration
      PesterConfiguration object
  
  .PARAMETER MaxRetries
      Maximum number of retry attempts (default: 3)
  
  .PARAMETER RetryDelaySeconds
      Delay between retries in seconds (default: 2)
  
  .EXAMPLE
      $config = New-FastTestConfiguration
      $result = Invoke-TestWithRetry -Configuration $config -MaxRetries 2
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [object]$Configuration,
    
    [int]$MaxRetries = 3,
    
    [int]$RetryDelaySeconds = 2
  )
  
  # Ensure Pester is loaded
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -MinimumVersion 5.5.0 -ErrorAction Stop
  }
  
  $attempt = 0
  $result = $null
  
  do {
    $attempt++
    
    if ($attempt -gt 1) {
      Write-Host "Retry attempt $attempt of $MaxRetries..." -ForegroundColor Yellow
      Start-Sleep -Seconds $RetryDelaySeconds
    }
    
    $result = Invoke-Pester -Configuration $Configuration
    
    if ($result.FailedCount -eq 0) {
      Write-Host "Tests passed on attempt $attempt" -ForegroundColor Green
      break
    }
    
    if ($attempt -lt $MaxRetries) {
      Write-Host "$($result.FailedCount) test(s) failed, retrying..." -ForegroundColor Yellow
    }
    
  } while ($attempt -lt $MaxRetries)
  
  if ($result.FailedCount -gt 0) {
    Write-Host "Tests failed after $attempt attempts" -ForegroundColor Red
  }
  
  return $result
}

function Get-TestSummary {
  <#
  .SYNOPSIS
      Formats and displays a test run summary
  
  .PARAMETER Result
      Pester test result object
  
  .PARAMETER ShowCoverage
      Include coverage information if available
  
  .EXAMPLE
      $result = Invoke-Pester -Configuration $config
      Get-TestSummary -Result $result -ShowCoverage
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [object]$Result,
    
    [switch]$ShowCoverage
  )
  
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host "Test Summary" -ForegroundColor Cyan
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host "Total:        $($Result.TotalCount)" -ForegroundColor White
  Write-Host "Passed:       $($Result.PassedCount)" -ForegroundColor Green
  Write-Host "Failed:       $($Result.FailedCount)" -ForegroundColor $(if ($Result.FailedCount -gt 0) { 'Red' } else { 'Green' })
  Write-Host "Skipped:      $($Result.SkippedCount)" -ForegroundColor Yellow
  Write-Host "Duration:     $($Result.Duration.ToString('mm\:ss\.fff'))" -ForegroundColor White
  
  if ($ShowCoverage -and $Result.CodeCoverage) {
    $cc = $Result.CodeCoverage
    $coveragePercent = 0
    if ($cc.CommandsAnalyzedCount -gt 0) {
      $coveragePercent = ($cc.CommandsExecutedCount / $cc.CommandsAnalyzedCount) * 100
    }
    
    $coverageColor = if ($coveragePercent -ge 90) {
      'Green'
    } elseif ($coveragePercent -ge 80) {
      'Yellow'
    } else {
      'Red'
    }
    
    Write-Host "Coverage:     $($coveragePercent.ToString('F2'))% ($($cc.CommandsExecutedCount)/$($cc.CommandsAnalyzedCount))" -ForegroundColor $coverageColor
  }
  
  Write-Host "========================================" -ForegroundColor Cyan
  
  if ($Result.FailedCount -gt 0) {
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($failed in $Result.Failed) {
      Write-Host "  - $($failed.Name)" -ForegroundColor Red
      if ($failed.ErrorRecord) {
        Write-Host "    $($failed.ErrorRecord.Exception.Message)" -ForegroundColor DarkRed
      }
    }
  }
}

# Export all functions
Export-ModuleMember -Function @(
  'New-FastTestConfiguration',
  'New-CoverageTestConfiguration',
  'New-DebugTestConfiguration',
  'New-SingleFileTestConfiguration',
  'New-TaggedTestConfiguration',
  'New-CITestConfiguration',
  'Invoke-TestWithRetry',
  'Get-TestSummary'
)
