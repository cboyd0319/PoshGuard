<#
.SYNOPSIS
    Test helper functions for PoshGuard Pester tests

.DESCRIPTION
    Common utilities for creating test fixtures, mock data, and assertions
    Used across all PoshGuard test suites for consistent, deterministic testing

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ best practices with hermetic test execution
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-TestPowerShellFile {
  <#
  .SYNOPSIS
      Create a temporary PowerShell file in TestDrive for testing
  
  .PARAMETER Content
      The PowerShell code content
  
  .PARAMETER FileName
      Optional filename (default: test.ps1)
  
  .PARAMETER Extension
      File extension (default: .ps1)
  
  .EXAMPLE
      $file = New-TestPowerShellFile -Content 'Get-Process' -FileName 'mytest'
  #>
  [CmdletBinding()]
  [OutputType([System.IO.FileInfo])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
    
    [Parameter()]
    [string]$FileName = 'test',
    
    [Parameter()]
    [ValidateSet('.ps1', '.psm1', '.psd1')]
    [string]$Extension = '.ps1'
  )
  
  $fullName = $FileName + $Extension
  $testPath = Join-Path -Path 'TestDrive:' -ChildPath $fullName
  
  Set-Content -Path $testPath -Value $Content -Encoding UTF8 -ErrorAction Stop
  
  return Get-Item -Path $testPath -ErrorAction Stop
}

function Get-MockedAst {
  <#
  .SYNOPSIS
      Parse PowerShell code and return its AST
  
  .PARAMETER Content
      The PowerShell code to parse
  
  .EXAMPLE
      $ast = Get-MockedAst -Content 'function Test { "hello" }'
  #>
  [CmdletBinding()]
  [OutputType([System.Management.Automation.Language.Ast])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
  
  $tokens = $null
  $errors = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $Content,
    [ref]$tokens,
    [ref]$errors
  )
  
  if ($errors -and $errors.Count -gt 0) {
    Write-Warning "AST parsing encountered $($errors.Count) error(s)"
    foreach ($error in $errors) {
      Write-Warning "  - $($error.Message)"
    }
  }
  
  return $ast
}

function Assert-CodeTransformation {
  <#
  .SYNOPSIS
      Compare original and transformed code, assert they differ as expected
  
  .PARAMETER Original
      Original PowerShell code
  
  .PARAMETER Transformed
      Expected transformed code
  
  .PARAMETER ActualTransformed
      Actual result from transformation function
  
  .EXAMPLE
      Assert-CodeTransformation -Original $before -Transformed $expected -ActualTransformed $result
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Original,
    
    [Parameter(Mandatory)]
    [string]$Expected,
    
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$ActualTransformed
  )
  
  # Normalize whitespace for comparison
  $normalizedExpected = ($Expected -replace '\r\n', "`n").Trim()
  $normalizedActual = ($ActualTransformed -replace '\r\n', "`n").Trim()
  
  if ($normalizedExpected -ne $normalizedActual) {
    Write-Host "Expected:`n$normalizedExpected" -ForegroundColor Yellow
    Write-Host "`nActual:`n$normalizedActual" -ForegroundColor Cyan
    throw "Code transformation did not match expected result"
  }
}

function New-MockPSScriptAnalyzerResult {
  <#
  .SYNOPSIS
      Create a mock PSScriptAnalyzer result object for testing
  
  .PARAMETER RuleName
      Name of the PSScriptAnalyzer rule
  
  .PARAMETER Message
      Diagnostic message
  
  .PARAMETER Severity
      Severity level (Error, Warning, Information)
  
  .PARAMETER ScriptPath
      Path to script file
  
  .PARAMETER Line
      Line number where issue occurs
  
  .PARAMETER Column
      Column number where issue occurs
  
  .PARAMETER Extent
      Optional extent object for the issue location
  
  .EXAMPLE
      $result = New-MockPSScriptAnalyzerResult -RuleName 'PSAvoidUsingWriteHost' -Message 'Avoid Write-Host'
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [string]$RuleName,
    
    [Parameter(Mandatory)]
    [string]$Message,
    
    [Parameter()]
    [ValidateSet('Error', 'Warning', 'Information')]
    [string]$Severity = 'Warning',
    
    [Parameter()]
    [string]$ScriptPath = 'TestDrive:\test.ps1',
    
    [Parameter()]
    [int]$Line = 1,
    
    [Parameter()]
    [int]$Column = 1,
    
    [Parameter()]
    [object]$Extent = $null
  )
  
  # Create mock extent if not provided
  if (-not $Extent) {
    $Extent = [PSCustomObject]@{
      StartLineNumber   = $Line
      StartColumnNumber = $Column
      EndLineNumber     = $Line
      EndColumnNumber   = $Column + 10
      Text              = 'mock-extent'
      File              = $ScriptPath
    }
  }
  
  return [PSCustomObject]@{
    PSTypeName       = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord'
    RuleName         = $RuleName
    Message          = $Message
    Severity         = $Severity
    ScriptPath       = $ScriptPath
    Line             = $Line
    Column           = $Column
    Extent           = $Extent
    RuleSuppressions = @()
  }
}

function New-TestBackupDirectory {
  <#
  .SYNOPSIS
      Create a test backup directory structure in TestDrive
  
  .PARAMETER OldDays
      Number of days old for test files (default: 5)
  
  .EXAMPLE
      $backupDir = New-TestBackupDirectory -OldDays 10
  #>
  [CmdletBinding()]
  [OutputType([System.IO.DirectoryInfo])]
  param(
    [Parameter()]
    [int]$OldDays = 5
  )
  
  $backupDir = Join-Path -Path 'TestDrive:' -ChildPath '.psqa-backup'
  New-Item -Path $backupDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
  
  # Create some old files
  $oldFile = Join-Path -Path $backupDir -ChildPath 'old-backup.ps1.bak'
  Set-Content -Path $oldFile -Value '# old backup' -ErrorAction Stop
  
  # Set the file timestamp to be old
  $oldDate = (Get-Date).AddDays(-$OldDays)
  (Get-Item -Path $oldFile).LastWriteTime = $oldDate
  
  return Get-Item -Path $backupDir -ErrorAction Stop
}

function Assert-FileContent {
  <#
  .SYNOPSIS
      Assert that a file contains expected content
  
  .PARAMETER Path
      Path to file
  
  .PARAMETER ExpectedContent
      Expected content string
  
  .PARAMETER NormalizeWhitespace
      Normalize whitespace before comparison
  
  .EXAMPLE
      Assert-FileContent -Path $testFile -ExpectedContent 'expected text'
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path,
    
    [Parameter(Mandatory)]
    [string]$ExpectedContent,
    
    [Parameter()]
    [switch]$NormalizeWhitespace
  )
  
  if (-not (Test-Path -Path $Path)) {
    throw "File not found: $Path"
  }
  
  $actualContent = Get-Content -Path $Path -Raw -ErrorAction Stop
  
  if ($NormalizeWhitespace) {
    $expectedNormalized = ($ExpectedContent -replace '\r\n', "`n" -replace '\s+', ' ').Trim()
    $actualNormalized = ($actualContent -replace '\r\n', "`n" -replace '\s+', ' ').Trim()
    
    if ($expectedNormalized -ne $actualNormalized) {
      throw "File content mismatch (normalized). Expected: '$expectedNormalized' but got: '$actualNormalized'"
    }
  }
  else {
    if ($ExpectedContent -ne $actualContent) {
      throw "File content mismatch. Expected: '$ExpectedContent' but got: '$actualContent'"
    }
  }
}

function Invoke-WithMockedDate {
  <#
  .SYNOPSIS
      Execute a script block with a mocked Get-Date
  
  .PARAMETER Date
      The date to mock (default: 2025-01-01T12:00:00Z)
  
  .PARAMETER ScriptBlock
      The script block to execute
  
  .EXAMPLE
      Invoke-WithMockedDate -Date ([DateTime]'2025-06-01') -ScriptBlock { Get-Date }
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [DateTime]$Date = [DateTime]'2025-01-01T12:00:00Z',
    
    [Parameter(Mandatory)]
    [ScriptBlock]$ScriptBlock
  )
  
  Mock Get-Date { $Date }
  
  try {
    & $ScriptBlock
  }
  finally {
    # Mock cleanup happens automatically in Pester
  }
}

function Get-TestCaseMatrix {
  <#
  .SYNOPSIS
      Generate test case matrices for table-driven tests
  
  .PARAMETER Type
      Type of test cases to generate (LogLevels, Extensions, EdgeCases)
  
  .EXAMPLE
      $testCases = Get-TestCaseMatrix -Type LogLevels
  #>
  [CmdletBinding()]
  [OutputType([hashtable[]])]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('LogLevels', 'Extensions', 'EdgeCases', 'SecurityPatterns')]
    [string]$Type
  )
  
  switch ($Type) {
    'LogLevels' {
      return @(
        @{ Level = 'Info'; Expected = 'INFO' }
        @{ Level = 'Warn'; Expected = 'WARN' }
        @{ Level = 'Error'; Expected = 'ERROR' }
        @{ Level = 'Success'; Expected = 'SUCCESS' }
        @{ Level = 'Critical'; Expected = 'CRITICAL' }
        @{ Level = 'Debug'; Expected = 'DEBUG' }
      )
    }
    'Extensions' {
      return @(
        @{ Extension = '.ps1'; Description = 'PowerShell script' }
        @{ Extension = '.psm1'; Description = 'PowerShell module' }
        @{ Extension = '.psd1'; Description = 'PowerShell data file' }
      )
    }
    'EdgeCases' {
      return @(
        @{ Input = ''; Description = 'empty string'; ShouldThrow = $true }
        @{ Input = $null; Description = 'null value'; ShouldThrow = $true }
        @{ Input = '   '; Description = 'whitespace only'; ShouldThrow = $false }
        @{ Input = [string]::Empty; Description = 'string.Empty'; ShouldThrow = $true }
      )
    }
    'SecurityPatterns' {
      return @(
        @{ Pattern = 'Password'; RuleName = 'PSAvoidUsingPlainTextForPassword' }
        @{ Pattern = 'ConvertTo-SecureString'; RuleName = 'PSAvoidUsingConvertToSecureStringWithPlainText' }
        @{ Pattern = 'Invoke-Expression'; RuleName = 'PSAvoidUsingInvokeExpression' }
      )
    }
  }
}

# Export all helper functions
Export-ModuleMember -Function @(
  'New-TestPowerShellFile',
  'Get-MockedAst',
  'Assert-CodeTransformation',
  'New-MockPSScriptAnalyzerResult',
  'New-TestBackupDirectory',
  'Assert-FileContent',
  'Invoke-WithMockedDate',
  'Get-TestCaseMatrix'
)
