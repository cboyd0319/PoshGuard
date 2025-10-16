<#
.SYNOPSIS
    Test data generators for PoshGuard Pester tests

.DESCRIPTION
    Provides sample PowerShell scripts with known issues for testing
    fix functions. All samples are deterministic and hermetic.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Provides consistent test data across all test files
#>

Set-StrictMode -Version Latest

function Get-SampleScriptWithSecurityIssue {
  <#
  .SYNOPSIS
      Returns PowerShell script with security issues
  
  .PARAMETER IssueType
      Type of security issue to include
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [ValidateSet('PlainTextPassword', 'HardcodedCredential', 'ConvertToSecureString', 'InvokeExpression')]
    [string]$IssueType = 'PlainTextPassword'
  )
  
  switch ($IssueType) {
    'PlainTextPassword' {
      return @'
function Set-UserPassword {
  param(
    [string]$Password
  )
  Write-Host "Setting password: $Password"
}
'@
    }
    'HardcodedCredential' {
      return @'
$username = "admin"
$password = "P@ssw0rd123"
$credential = New-Object System.Management.Automation.PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force))
'@
    }
    'ConvertToSecureString' {
      return @'
$securePass = ConvertTo-SecureString "MyPassword" -AsPlainText -Force
'@
    }
    'InvokeExpression' {
      return @'
$command = "Get-Process"
Invoke-Expression $command
'@
    }
  }
}

function Get-SampleScriptWithFormattingIssue {
  <#
  .SYNOPSIS
      Returns PowerShell script with formatting issues
  
  .PARAMETER IssueType
      Type of formatting issue to include
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [ValidateSet('WriteHost', 'Alias', 'Whitespace', 'Casing', 'MisleadingBacktick')]
    [string]$IssueType = 'WriteHost'
  )
  
  switch ($IssueType) {
    'WriteHost' {
      return @'
function Show-Message {
  write-host "Hello World"
}
'@
    }
    'Alias' {
      return @'
function Get-Data {
  gci C:\temp | ? { $_.Length -gt 1000 }
}
'@
    }
    'Whitespace' {
      return @'
function Test-Function{
    $result=1+2
    return $result
}
'@
    }
    'Casing' {
      return @'
function test-function {
  $RESULT = get-process
  return $RESULT
}
'@
    }
    'MisleadingBacktick' {
      return @'
Get-Process `
  -Name powershell
'@
    }
  }
}

function Get-SampleScriptWithBestPracticeIssue {
  <#
  .SYNOPSIS
      Returns PowerShell script with best practice violations
  
  .PARAMETER IssueType
      Type of best practice issue to include
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [ValidateSet('GlobalVariable', 'PluralNoun', 'UnapprovedVerb', 'PositionalParameter', 'NullComparison')]
    [string]$IssueType = 'GlobalVariable'
  )
  
  switch ($IssueType) {
    'GlobalVariable' {
      return @'
function Set-Config {
  $global:ConfigData = @{ Key = "Value" }
}
'@
    }
    'PluralNoun' {
      return @'
function Get-Items {
  param([string]$Path)
  Get-ChildItem -Path $Path
}
'@
    }
    'UnapprovedVerb' {
      return @'
function Destroy-TempFile {
  param([string]$Path)
  Remove-Item -Path $Path
}
'@
    }
    'PositionalParameter' {
      return @'
function Get-User {
  Get-ADUser "jdoe"
}
'@
    }
    'NullComparison' {
      return @'
function Test-Value {
  param($Value)
  if ($null -eq $Value) {
    return $false
  }
  return $true
}
'@
    }
  }
}

function Get-SampleScriptWithAdvancedIssue {
  <#
  .SYNOPSIS
      Returns PowerShell script with advanced issues
  
  .PARAMETER IssueType
      Type of advanced issue to include
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [ValidateSet('MissingCmdletBinding', 'MissingShouldProcess', 'UnusedParameter', 'MissingCommentHelp')]
    [string]$IssueType = 'MissingCmdletBinding'
  )
  
  switch ($IssueType) {
    'MissingCmdletBinding' {
      return @'
function Get-Data {
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )
  return $Name
}
'@
    }
    'MissingShouldProcess' {
      return @'
function Remove-TempFile {
  param([string]$Path)
  Remove-Item -Path $Path
}
'@
    }
    'UnusedParameter' {
      return @'
function Get-Value {
  [CmdletBinding()]
  param(
    [string]$Name,
    [string]$UnusedParam
  )
  return $Name
}
'@
    }
    'MissingCommentHelp' {
      return @'
function Get-Data {
  [CmdletBinding()]
  param([string]$Name)
  return $Name
}
'@
    }
  }
}

function Get-ValidScript {
  <#
  .SYNOPSIS
      Returns a well-formed PowerShell script with no issues
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param()
  
  return @'
<#
.SYNOPSIS
    Gets user data by name

.PARAMETER Name
    User name to retrieve

.EXAMPLE
    Get-UserData -Name "jdoe"
#>
function Get-UserData {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )
  
  $result = Get-ADUser -Identity $Name
  return $result
}
'@
}

function Get-EmptyScript {
  <#
  .SYNOPSIS
      Returns an empty or minimal script
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param()
  
  return ''
}

function Get-CommentOnlyScript {
  <#
  .SYNOPSIS
      Returns a script with only comments
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param()
  
  return @'
# This is a comment
# Another comment

<#
  Block comment
#>
'@
}

function Get-LargeScript {
  <#
  .SYNOPSIS
      Returns a large script for performance testing
  
  .PARAMETER LineCount
      Number of lines to generate
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [int]$LineCount = 100
  )
  
  $lines = @('function Test-LargeScript {')
  for ($i = 1; $i -le $LineCount; $i++) {
    $lines += "  `$var$i = $i"
  }
  $lines += '}'
  
  return $lines -join "`n"
}

function Get-ScriptWithEntropy {
  <#
  .SYNOPSIS
      Returns script with high-entropy strings (potential secrets)
  
  .PARAMETER EntropyLevel
      High, Medium, or Low entropy
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [ValidateSet('High', 'Medium', 'Low')]
    [string]$EntropyLevel = 'High'
  )
  
  switch ($EntropyLevel) {
    'High' {
      # High entropy random-looking string (potential secret)
      return @'
$apiKey = "xKj9mP2vL8nQ4rY7sT1wU6zH3bN5cM0aF"
'@
    }
    'Medium' {
      # Medium entropy
      return @'
$token = "Bearer_abc123def456"
'@
    }
    'Low' {
      # Low entropy (normal text)
      return @'
$message = "Hello World"
'@
    }
  }
}

# Export all functions
Export-ModuleMember -Function @(
  'Get-SampleScriptWithSecurityIssue',
  'Get-SampleScriptWithFormattingIssue',
  'Get-SampleScriptWithBestPracticeIssue',
  'Get-SampleScriptWithAdvancedIssue',
  'Get-ValidScript',
  'Get-EmptyScript',
  'Get-CommentOnlyScript',
  'Get-LargeScript',
  'Get-ScriptWithEntropy'
)
