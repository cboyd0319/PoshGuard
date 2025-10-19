<#
.SYNOPSIS
    Common test helpers for PoshGuard Pester tests

.DESCRIPTION
    Shared utility functions, mock builders, and test data generators
    for consistent test patterns across the PoshGuard test suite.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ best practices with AAA pattern
#>

Set-StrictMode -Version Latest

function New-TestScriptContent {
  <#
  .SYNOPSIS
      Creates test PowerShell script content with configurable issues
  
  .PARAMETER HasSecurityIssue
      Include security violations (plain text passwords, etc.)
  
  .PARAMETER HasFormattingIssue
      Include formatting issues (whitespace, casing, etc.)
  
  .PARAMETER HasBestPracticeIssue
      Include best practice violations
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [switch]$HasSecurityIssue,
    [switch]$HasFormattingIssue,
    [switch]$HasBestPracticeIssue
  )

  $content = @'
function Test-Function {
'@

  if ($HasSecurityIssue) {
    $content += @'

    param(
        [string]$Password
    )
'@
  } else {
    $content += @'

    param(
        [string]$Name
    )
'@
  }

  if ($HasFormattingIssue) {
    $content += @'

    write-host "Testing"
'@
  } else {
    $content += @'

    Write-Output "Testing"
'@
  }

  if ($HasBestPracticeIssue) {
    $content += @'

    $global:Result = $Name
'@
  } else {
    $content += @'

    $Result = $Name
'@
  }

  $content += @'

}
'@

  return $content
}

function New-TestFile {
  <#
  .SYNOPSIS
      Creates a test file in TestDrive with specified content
  
  .PARAMETER FileName
      Name of the file to create
  
  .PARAMETER Content
      Content to write to the file
  
  .OUTPUTS
      Full path to the created file
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$FileName,

    [Parameter(Mandatory)]
    [string]$Content
  )

  $filePath = Join-Path -Path $TestDrive -ChildPath $FileName
  Set-Content -Path $filePath -Value $Content -Encoding UTF8 -Force
  return $filePath
}

function Assert-ContentContains {
  <#
  .SYNOPSIS
      Asserts that content contains expected text
  
  .PARAMETER Content
      The content to check
  
  .PARAMETER ExpectedText
      The text that should be present
  
  .PARAMETER CaseSensitive
      Whether comparison should be case-sensitive
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Content,

    [Parameter(Mandatory)]
    [string]$ExpectedText,

    [switch]$CaseSensitive
  )

  if ($CaseSensitive) {
    $Content | Should -Match ([regex]::Escape($ExpectedText))
  } else {
    $Content | Should -Match "(?i)$([regex]::Escape($ExpectedText))"
  }
}

function New-MockAST {
  <#
  .SYNOPSIS
      Creates a mock AST from PowerShell script content
  
  .PARAMETER Content
      PowerShell script content to parse
  
  .OUTPUTS
      Parsed AST object
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  $errors = $null
  $tokens = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $Content,
    [ref]$tokens,
    [ref]$errors
  )

  return @{
    AST    = $ast
    Tokens = $tokens
    Errors = $errors
  }
}

function Test-FunctionExists {
  <#
  .SYNOPSIS
      Tests if a function exists in the current session
  
  .PARAMETER Name
      Name of the function to check
  #>
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  return (Get-Command -Name $Name -ErrorAction SilentlyContinue) -ne $null
}

function New-TestHashtable {
  <#
  .SYNOPSIS
      Creates a test hashtable with common properties
  
  .PARAMETER IncludeNested
      Include nested hashtables
  #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [switch]$IncludeNested
  )

  $hash = @{
    StringProperty = 'TestValue'
    IntProperty    = 42
    BoolProperty   = $true
    ArrayProperty  = @(1, 2, 3)
  }

  if ($IncludeNested) {
    $hash['NestedHash'] = @{
      NestedKey = 'NestedValue'
    }
  }

  return $hash
}

function Invoke-WithMockedDate {
  <#
  .SYNOPSIS
      Executes a script block with a mocked date
  
  .PARAMETER ScriptBlock
      The script to execute with mocked date
  
  .PARAMETER MockDate
      The date to return from Get-Date
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory)]
    [datetime]$MockDate
  )

  Mock Get-Date { return $MockDate }
  
  try {
    & $ScriptBlock
  } finally {
    # Mock cleanup happens automatically in Pester
  }
}

function New-TestModuleManifest {
  <#
  .SYNOPSIS
      Creates a test module manifest content
  
  .PARAMETER ModuleName
      Name of the module
  
  .PARAMETER HasIssues
      Include common manifest issues
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$ModuleName,

    [switch]$HasIssues
  )

  $content = @"
@{
    RootModule = '$ModuleName.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-4789-a012-3456789abcde'
    Author = 'Test Author'
    CompanyName = 'Test Company'
    Copyright = '(c) 2025 Test. All rights reserved.'
    Description = 'Test module'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Test-Function')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
"@

  if ($HasIssues) {
    $content += @"

    # Deprecated field
    CLRVersion = '4.0'
"@
  }

  $content += @"

}
"@

  return $content
}

function Assert-NoVerboseOutput {
  <#
  .SYNOPSIS
      Asserts that a command produces no verbose output
  
  .PARAMETER ScriptBlock
      The command to test
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [scriptblock]$ScriptBlock
  )

  $VerbosePreference = 'Continue'
  $verboseOutput = & $ScriptBlock 4>&1
  $verboseOutput | Should -BeNullOrEmpty
}

function ConvertTo-UnixLineEndings {
  <#
  .SYNOPSIS
      Converts Windows line endings to Unix
  
  .PARAMETER Content
      Content to convert
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  return $Content -replace "`r`n", "`n"
}

function Initialize-PerformanceMocks {
  <#
  .SYNOPSIS
      Sets up performance-optimized mocks for console output functions
  
  .DESCRIPTION
      Mocks Write-Host and Write-Progress globally in the specified module
      to prevent slow console I/O during tests. This can reduce test execution
      time by 70-80% for modules that generate significant console output.
  
  .PARAMETER ModuleName
      Name of the module to mock console output functions for
  
  .EXAMPLE
      Initialize-PerformanceMocks -ModuleName 'Core'
      
  .NOTES
      Part of Pester Architect test optimization strategy
      Should be called in BeforeAll block for maximum performance
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ModuleName
  )
  
  # Mock Write-Host to prevent slow console I/O
  Mock -ModuleName $ModuleName Write-Host { }
  
  # Mock Write-Progress to prevent progress bar overhead
  Mock -ModuleName $ModuleName Write-Progress { }
  
  Write-Verbose "Performance mocks initialized for module: $ModuleName"
}

# Export all functions
Export-ModuleMember -Function *
