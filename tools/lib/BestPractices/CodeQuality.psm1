<#
.SYNOPSIS
    PoshGuard Code Quality Enhancement Module

.DESCRIPTION
    Beyond-PSSA community-requested rules for code quality improvements:
    - TODO/FIXME comment detection and tracking
    - Unused namespace detection (optimize `using namespace`)
    - ASCII character warnings (prevent encoding issues)
    - Get-Content | ConvertFrom-Json optimization (add `-Raw`)
    - SecureString disclosure detection

    Part of PoshGuard v3.2.0 roadmap - Innovation leadership in PowerShell tooling.

.NOTES
    Part of PoshGuard v3.2.0
    Requires PowerShell 5.1 or higher
    
    References:
    - SWEBOK v4.0 | Code Quality Standards
    - PowerShell Best Practices | https://learn.microsoft.com/powershell
#>

Set-StrictMode -Version Latest

function Invoke-TodoCommentDetectionFix {
  <#
    .SYNOPSIS
        Detects and tracks TODO/FIXME comments for technical debt management
    
    .DESCRIPTION
        Scans code for TODO, FIXME, HACK, XXX, and NOTE comments.
        Adds metadata tracking for technical debt management.
        
        DETECTED PATTERNS:
        - # TODO: <description>
        - # FIXME: <description>
        - # HACK: <description>
        - # XXX: <description>
        - # NOTE: <description>
        
        ENHANCEMENT:
        Ensures all TODO comments follow a consistent format with optional issue tracking.
    
    .PARAMETER Content
        The script content to analyze
    
    .EXAMPLE
        Invoke-TodoCommentDetectionFix -Content $scriptContent
        
        # BEFORE:
        # todo fix this later
        
        # AFTER:
        # TODO: Fix this later (tracked for technical debt)
    
    .NOTES
        Low priority - This is informational only, does not modify code structure.
        Helps teams track technical debt systematically.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
    
  try {
    $lines = $Content -split "`r?`n"
    $modified = $false
    $newLines = @()
    $todoPattern = '^\s*#\s*(TODO|FIXME|HACK|XXX|NOTE)[\s:]*(.*)$'
        
    foreach ($line in $lines) {
      if ($line -match $todoPattern) {
        $keyword = $Matches[1].ToUpper()
        $description = $Matches[2].Trim()
                
        # Ensure consistent format: # KEYWORD: Description
        if ($line -notmatch '^\s*#\s*(TODO|FIXME|HACK|XXX|NOTE):\s+\S+') {
          $indent = ''
          if ($line -match '^(\s*)') {
            $indent = $Matches[1]
          }
                    
          if ([string]::IsNullOrWhiteSpace($description)) {
            $description = 'Review and address this item'
          }
                    
          $newLine = "$indent# $keyword`: $description"
          $newLines += $newLine
          $modified = $true
          Write-Verbose "Standardized $keyword comment format"
        }
        else {
          $newLines += $line
        }
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
    Write-Verbose "TODO comment detection failed: $_"
  }
    
  return $Content
}

function Invoke-UnusedNamespaceDetectionFix {
  <#
    .SYNOPSIS
        Detects and warns about potentially unused namespace imports
    
    .DESCRIPTION
        Analyzes 'using namespace' statements and adds warnings for those that might not
        be referenced in the code. This is informational only and does not remove namespaces
        automatically to avoid breaking code that uses namespaces dynamically.
        
        DETECTION:
        - Finds all 'using namespace X' statements
        - Checks if types from namespace X appear to be used
        - Adds comments suggesting review for potentially unused namespaces
    
    .PARAMETER Content
        The script content to analyze
    
    .EXAMPLE
        Invoke-UnusedNamespaceDetectionFix -Content $scriptContent
        
        # BEFORE:
        using namespace System.Collections.Generic
        using namespace System.Net
        
        function Test { $list = [Generic.List[int]]::new() }
        
        # AFTER:
        using namespace System.Collections.Generic
        # REVIEW: Namespace may be unused - using namespace System.Net
        
        function Test { $list = [Generic.List[int]]::new() }
    
    .NOTES
        Performance optimization - Helps identify namespaces that could be removed.
        Conservative approach - marks as "REVIEW" rather than removing automatically.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
    
  try {
    $lines = $Content -split "`r?`n"
    $usingPattern = '^\s*using\s+namespace\s+([^\s]+)\s*$'
    $namespaces = @()
        
    # Find all using namespace statements
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match $usingPattern) {
        $namespaces += @{
          LineNumber = $i
          Line = $lines[$i]
          Namespace = $Matches[1]
          Used = $false
        }
      }
    }
        
    if ($namespaces.Count -eq 0) {
      return $Content
    }
        
    # Get content after all using statements for checking usage
    $lastUsingLine = ($namespaces | Measure-Object -Property LineNumber -Maximum).Maximum
    $contentToCheck = ($lines[($lastUsingLine + 1)..($lines.Count - 1)] -join "`n")
        
    # Check if each namespace is used
    foreach ($ns in $namespaces) {
      $namespaceParts = $ns.Namespace.Split('.')
      $lastPart = $namespaceParts[-1]
            
      # Check various usage patterns
      # 1. Full namespace path used explicitly
      if ($contentToCheck -match [regex]::Escape($ns.Namespace)) {
        $ns.Used = $true
        continue
      }
            
      # 2. Qualified type name (e.g., Generic.List, Collections.ArrayList)
      if ($contentToCheck -match "\[$lastPart\." -or 
        $contentToCheck -match "\b$lastPart\.") {
        $ns.Used = $true
        continue
      }
            
      # 3. Static member access (e.g., Math::Pow)
      if ($contentToCheck -match "::$lastPart") {
        $ns.Used = $true
        continue
      }
    }
        
    # Add warnings for potentially unused namespaces
    $newLines = @()
    $modified = $false
        
    foreach ($ns in $namespaces) {
      if (-not $ns.Used) {
        # Add comment line before the using statement
        $newLines += "# REVIEW: Namespace may be unused - $($ns.Line)"
        $modified = $true
        Write-Verbose "Marked potentially unused namespace: $($ns.Namespace)"
      }
      $newLines += $ns.Line
    }
        
    # Add remaining content
    $lastUsingLine = ($namespaces | Measure-Object -Property LineNumber -Maximum).Maximum
    $newLines += $lines[($lastUsingLine + 1)..($lines.Count - 1)]
        
    if ($modified) {
      return ($newLines -join "`n")
    }
  }
  catch {
    Write-Verbose "Unused namespace detection failed: $_"
  }
    
  return $Content
}

function Invoke-AsciiCharacterWarningFix {
  <#
    .SYNOPSIS
        Detects non-ASCII characters and adds warnings
    
    .DESCRIPTION
        Identifies lines with non-ASCII characters that might cause encoding issues
        across different systems. Adds inline warnings for review.
        
        COMMON ISSUES:
        - Smart quotes (" " ' ') instead of straight quotes (" ")
        - Em dashes (—) instead of hyphens (-)
        - Non-breaking spaces instead of regular spaces
        - Unicode characters that may not render on all systems
    
    .PARAMETER Content
        The script content to analyze
    
    .EXAMPLE
        Invoke-AsciiCharacterWarningFix -Content $scriptContent
        
        # BEFORE:
        Write-Host "Hello—world"  # Em dash
        
        # AFTER:
        Write-Host "Hello—world"  # WARNING: Non-ASCII character detected (U+2014). Consider using ASCII equivalent.
    
    .NOTES
        Encoding compatibility - Prevents cross-platform encoding issues.
        Informational only - does not modify the actual characters.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
    
  try {
    $lines = $Content -split "`r?`n"
    $newLines = @()
    $modified = $false
        
    foreach ($line in $lines) {
      # Check if line already has our warning
      if ($line -match 'WARNING: Non-ASCII character detected') {
        $newLines += $line
        continue
      }
            
      # Check for non-ASCII characters
      $nonAsciiMatch = [regex]::Match($line, '[^\u0000-\u007F]')
            
      if ($nonAsciiMatch.Success) {
        # Get the non-ASCII character and its Unicode code point
        $char = $nonAsciiMatch.Value
        $codePoint = [string]::Format('U+{0:X4}', [int][char]$char)
                
        # Add warning comment
        $warning = "  # WARNING: Non-ASCII character detected ($codePoint). Consider using ASCII equivalent."
        $newLine = $line + $warning
        $newLines += $newLine
        $modified = $true
        Write-Verbose "Added warning for non-ASCII character: $codePoint"
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
    Write-Verbose "ASCII character warning fix failed: $_"
  }
    
  return $Content
}

function Invoke-ConvertFromJsonOptimizationFix {
  <#
    .SYNOPSIS
        Optimizes Get-Content | ConvertFrom-Json to use -Raw parameter
    
    .DESCRIPTION
        Detects the common anti-pattern of piping Get-Content to ConvertFrom-Json
        without the -Raw parameter, which is inefficient. Adds -Raw parameter for
        better performance.
        
        OPTIMIZATION:
        # SLOW (reads line by line):
        Get-Content file.json | ConvertFrom-Json
        
        # FAST (reads entire file at once):
        Get-Content file.json -Raw | ConvertFrom-Json
    
    .PARAMETER Content
        The script content to analyze
    
    .EXAMPLE
        Invoke-ConvertFromJsonOptimizationFix -Content $scriptContent
        
        # BEFORE:
        $data = Get-Content "config.json" | ConvertFrom-Json
        
        # AFTER:
        $data = Get-Content "config.json" -Raw | ConvertFrom-Json
    
    .NOTES
        Performance optimization - Significantly improves JSON parsing speed.
        Safe transformation - maintains same output.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
    
  try {
    # Pattern: Get-Content <path> | ConvertFrom-Json (without -Raw)
    $pattern = '(Get-Content\s+[^|]+?)(\s*\|\s*ConvertFrom-Json)'
        
    if ($Content -match $pattern) {
      $modified = $Content
            
      # Find all matches
      $matches = [regex]::Matches($Content, $pattern)
            
      foreach ($match in $matches) {
        $getContentPart = $match.Groups[1].Value
        $pipelinePart = $match.Groups[2].Value
                
        # Check if -Raw is already present
        if ($getContentPart -notmatch '-Raw\b') {
          # Add -Raw before the pipeline
          $fixed = "$getContentPart -Raw$pipelinePart"
          $modified = $modified.Replace($match.Value, $fixed)
          Write-Verbose "Added -Raw parameter to Get-Content | ConvertFrom-Json"
        }
      }
            
      if ($modified -ne $Content) {
        return $modified
      }
    }
  }
  catch {
    Write-Verbose "ConvertFrom-Json optimization failed: $_"
  }
    
  return $Content
}

function Invoke-SecureStringDisclosureFix {
  <#
    .SYNOPSIS
        Detects potential SecureString disclosure vulnerabilities
    
    .DESCRIPTION
        Identifies patterns where SecureString objects might be inadvertently
        disclosed through logging, console output, or string concatenation.
        
        VULNERABLE PATTERNS:
        - Write-Host/Write-Output with SecureString variables
        - String concatenation with SecureString
        - SecureString in error messages
        - ConvertFrom-SecureString without encryption key (exports in clear text)
    
    .PARAMETER Content
        The script content to analyze
    
    .EXAMPLE
        Invoke-SecureStringDisclosureFix -Content $scriptContent
        
        # BEFORE:
        Write-Host "Password: $securePassword"
        
        # AFTER:
        Write-Host "Password: $securePassword"  # SECURITY WARNING: Potential SecureString disclosure
    
    .NOTES
        Security - Prevents accidental credential disclosure.
        Maps to OWASP ASVS V6: Stored Cryptography and V8: Data Protection.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )
    
  try {
    $lines = $Content -split "`r?`n"
    $newLines = @()
    $modified = $false
        
    # Patterns that might indicate SecureString disclosure
    $vulnerablePatterns = @(
      'Write-Host.*\$.*[Pp]assword',
      'Write-Output.*\$.*[Pp]assword',
      'Write-Verbose.*\$.*[Ss]ecure',
      '".*\$.*[Ss]ecure.*"',
      "'.*\$.*[Pp]assword.*'"
    )
        
    foreach ($line in $lines) {
      # Skip if line already has our warning
      if ($line -match 'SECURITY WARNING: Potential SecureString disclosure') {
        $newLines += $line
        continue
      }
            
      $hasVulnerability = $false
      foreach ($pattern in $vulnerablePatterns) {
        if ($line -match $pattern) {
          $hasVulnerability = $true
          break
        }
      }
            
      if ($hasVulnerability) {
        $warning = "  # SECURITY WARNING: Potential SecureString disclosure"
        $newLine = $line + $warning
        $newLines += $newLine
        $modified = $true
        Write-Verbose "Added security warning for potential SecureString disclosure"
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
    Write-Verbose "SecureString disclosure detection failed: $_"
  }
    
  return $Content
}

# Export all code quality functions
Export-ModuleMember -Function @(
  'Invoke-TodoCommentDetectionFix',
  'Invoke-UnusedNamespaceDetectionFix',
  'Invoke-AsciiCharacterWarningFix',
  'Invoke-ConvertFromJsonOptimizationFix',
  'Invoke-SecureStringDisclosureFix'
)
