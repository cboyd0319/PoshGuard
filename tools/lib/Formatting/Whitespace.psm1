<#
.SYNOPSIS
    PoshGuard Whitespace Formatting Module

.DESCRIPTION
    PowerShell whitespace and formatting fixes including:
    - PSScriptAnalyzer Invoke-Formatter integration
    - Trailing whitespace removal
    - Misleading backtick detection

    Ensures consistent whitespace formatting across codebases.

.NOTES
    Part of PoshGuard v2.4.0
    Requires PowerShell 5.1 or higher
#>

Set-StrictMode -Version Latest

function Invoke-FormatterFix {
  <#
    .SYNOPSIS
        Applies PSScriptAnalyzer code formatter

    .DESCRIPTION
        Uses Invoke-Formatter from PSScriptAnalyzer to apply consistent formatting.
        Skips PSQAAutoFixer.psm1 to prevent self-corruption.

    .PARAMETER Content
        The script content to format

    .PARAMETER FilePath
        Optional file path for context-aware skipping

    .EXAMPLE
        Invoke-FormatterFix -Content $scriptContent
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
    [Parameter()]
    [string]$FilePath = ''
  )

  if ($FilePath -match 'PSQAAutoFixer\.psm1$') {
    Write-Verbose "Skipping Invoke-Formatter on PSQAAutoFixer to prevent self-corruption"
    return $Content
  }

  if (-not (Get-Command -Name Invoke-Formatter -ErrorAction SilentlyContinue)) {
    Write-Verbose "Invoke-Formatter not available (PSScriptAnalyzer not installed)"
    return $Content
  }

  try {
    return Invoke-Formatter -ScriptDefinition $Content
  }
  catch {
    Write-Verbose "Invoke-Formatter failed: $_"
  }

  return $Content
}

function Invoke-WhitespaceFix {
  <#
    .SYNOPSIS
        Removes trailing whitespace from lines

    .DESCRIPTION
        Trims trailing whitespace from all lines and ensures file ends with newline.
        Improves git diff readability and follows best practices.

    .EXAMPLE
        Invoke-WhitespaceFix -Content $scriptContent
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  $lines = $Content -split "`r?`n"
  $fixed = $lines | ForEach-Object { $_.TrimEnd() }
  $result = $fixed -join "`n"

  if (-not $result.EndsWith("`n")) {
    $result += "`n"
  }

  return $result
}

function Invoke-MisleadingBacktickFix {
  <#
    .SYNOPSIS
        Fixes backticks followed by whitespace

    .DESCRIPTION
        Detects backticks used for line continuation that are followed by whitespace.
        This is often a typo and the backtick should be at the end of the line.

        FIXES:
        - Backtick followed by spaces before newline
        - Removes trailing whitespace after backtick

    .EXAMPLE
        # BEFORE:
        Get-ChildItem `
            -Path C:\

        # AFTER:
        Get-ChildItem `
            -Path C:\
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  try {
    # Pattern: backtick followed by whitespace before newline
    $pattern = '`\s+$'

    $lines = $Content -split "`n"
    $modified = $false
    $newLines = @()

    foreach ($line in $lines) {
      if ($line -match $pattern) {
        # Remove whitespace after backtick
        $fixed = $line -replace '`\s+$', '`'
        $newLines += $fixed
        $modified = $true
        Write-Verbose "Fixed misleading backtick with trailing whitespace"
      }
      else {
        $newLines += $line
      }
    }

    if ($modified) {
      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "Misleading backtick fix failed: $_"
  }

  return $Content
}

# Export all whitespace fix functions
Export-ModuleMember -Function @(
  'Invoke-FormatterFix',
  'Invoke-WhitespaceFix',
  'Invoke-MisleadingBacktickFix'
)
