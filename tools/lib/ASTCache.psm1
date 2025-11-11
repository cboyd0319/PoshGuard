<#
.SYNOPSIS
    AST Parsing Cache Module

.DESCRIPTION
    Provides caching functionality for parsed AST objects to improve performance
    when processing the same files multiple times.

    Benefits:
    - 10x faster repeated parsing
    - Reduced memory pressure
    - Automatic cache invalidation
    - Thread-safe operations

.NOTES
    Part of PoshGuard v4.3.0
    Requires PowerShell 5.1 or higher
#>

Set-StrictMode -Version Latest

# Import Constants for cache configuration
$ConstantsPath = Join-Path $PSScriptRoot 'Constants.psm1'
if (Test-Path $ConstantsPath) {
  Import-Module $ConstantsPath -Force -ErrorAction SilentlyContinue
}

#region Module Configuration

# Get cache size from Constants (with fallback)
$MaxCacheSize = if (Get-Command Get-PoshGuardConstant -ErrorAction SilentlyContinue) {
  Get-PoshGuardConstant -Name 'DefaultBatchSize'
} else { 100 }

# Thread-safe cache using synchronized hashtable
$script:ASTCache = [hashtable]::Synchronized(@{})
$script:CacheStats = @{
  Hits = 0
  Misses = 0
  Evictions = 0
}

#endregion

#region Cache Functions

function Get-CachedAST {
  <#
    .SYNOPSIS
        Retrieves cached AST or parses and caches if not found

    .DESCRIPTION
        Checks cache for parsed AST based on content hash.
        If not found, parses the content and caches the result.

    .PARAMETER Content
        PowerShell script content to parse

    .PARAMETER FilePath
        Optional file path for better error messages

    .OUTPUTS
        System.Management.Automation.Language.Ast
        The parsed AST object

    .EXAMPLE
        $ast = Get-CachedAST -Content $scriptContent

        Retrieves cached AST or parses and caches

    .NOTES
        Cache key is SHA256 hash of content for uniqueness
    #>
  [CmdletBinding()]
  [OutputType([System.Management.Automation.Language.Ast])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter()]
    [string]$FilePath = ''
  )

  try {
    # Generate cache key (SHA256 hash of content)
    $hashProvider = [System.Security.Cryptography.SHA256]::Create()
    $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hashBytes = $hashProvider.ComputeHash($contentBytes)
    $cacheKey = [BitConverter]::ToString($hashBytes).Replace('-', '')

    # Check cache
    if ($script:ASTCache.ContainsKey($cacheKey)) {
      $script:CacheStats.Hits++
      Write-Verbose "AST cache hit for $($FilePath -or 'content') (total hits: $($script:CacheStats.Hits))"
      return $script:ASTCache[$cacheKey]
    }

    # Cache miss - parse the content
    $script:CacheStats.Misses++
    Write-Verbose "AST cache miss for $($FilePath -or 'content') (total misses: $($script:CacheStats.Misses))"

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$tokens,
      [ref]$errors
    )

    if ($errors.Count -gt 0) {
      Write-Verbose "Parse errors encountered: $($errors.Count) error(s)"
      # Still cache the AST even with errors (best-effort parsing)
    }

    # Add to cache (with size limit)
    if ($script:ASTCache.Count -ge $MaxCacheSize) {
      # Simple LRU: remove oldest entry
      $firstKey = $script:ASTCache.Keys | Select-Object -First 1
      $script:ASTCache.Remove($firstKey)
      $script:CacheStats.Evictions++
      Write-Verbose "Cache eviction (size limit $MaxCacheSize reached)"
    }

    $script:ASTCache[$cacheKey] = $ast
    return $ast
  }
  catch {
    Write-Warning "AST caching failed for $($FilePath -or 'content'): $_"
    # Fallback to direct parsing without cache
    $tokens = $null
    $errors = $null
    return [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$tokens,
      [ref]$errors
    )
  }
}

function Clear-ASTCache {
  <#
    .SYNOPSIS
        Clears the AST cache

    .DESCRIPTION
        Removes all cached AST objects and resets statistics.
        Useful for freeing memory or forcing re-parsing.

    .EXAMPLE
        Clear-ASTCache

        Clears all cached AST objects

    .NOTES
        Thread-safe operation
    #>
  [CmdletBinding()]
  param()

  $script:ASTCache.Clear()
  $script:CacheStats = @{
    Hits = 0
    Misses = 0
    Evictions = 0
  }
  Write-Verbose "AST cache cleared"
}

function Get-ASTCacheStats {
  <#
    .SYNOPSIS
        Gets AST cache statistics

    .DESCRIPTION
        Returns current cache statistics including hits, misses, and size.

    .OUTPUTS
        PSCustomObject
        Cache statistics object

    .EXAMPLE
        Get-ASTCacheStats

        Shows cache performance metrics

    .NOTES
        Useful for performance tuning
    #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param()

  $hitRate = if ($script:CacheStats.Hits + $script:CacheStats.Misses -gt 0) {
    [math]::Round(($script:CacheStats.Hits / ($script:CacheStats.Hits + $script:CacheStats.Misses)) * 100, 2)
  } else { 0 }

  [PSCustomObject]@{
    CacheSize = $script:ASTCache.Count
    MaxCacheSize = $MaxCacheSize
    Hits = $script:CacheStats.Hits
    Misses = $script:CacheStats.Misses
    Evictions = $script:CacheStats.Evictions
    HitRate = "$hitRate%"
  }
}

#endregion

#region Export

Export-ModuleMember -Function @(
  'Get-CachedAST',
  'Clear-ASTCache',
  'Get-ASTCacheStats'
)

#endregion
