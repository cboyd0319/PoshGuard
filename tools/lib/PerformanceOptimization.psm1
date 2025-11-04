<#
.SYNOPSIS
    Performance Optimization Module for PoshGuard

.DESCRIPTION
    Advanced performance features for processing large codebases:
    - Parallel file processing using runspaces
    - Incremental analysis (only changed files)
    - AST caching for faster re-analysis
    - Memory-efficient streaming
    - Progress tracking with ETA
    - Resource throttling
    
.NOTES
    Version: 4.1.0
    Part of PoshGuard UGE Framework
    References:
    - PowerShell Runspaces Best Practices
    - Memory Management Guidelines
    
    Performance Targets:
    - 10x faster for >100 files
    - <500MB memory for 1000 files
    - Incremental analysis <1s
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Configuration

$script:PerfConfig = @{
  MaxParallelJobs = [Environment]::ProcessorCount
  CachePath = "./cache/ast"
  EnableCache = $true
  EnableIncremental = $true
  MaxMemoryMB = 1024
  ChunkSize = 50
}

$script:ASTCache = @{}
$script:FileHashes = @{}

#endregion

#region Parallel Processing

function Invoke-ParallelAnalysis {
  <#
    .SYNOPSIS
        Analyze multiple files in parallel using runspaces
    
    .DESCRIPTION
        Processes files concurrently to maximize CPU utilization.
        Uses PowerShell runspaces for true parallelism.
    
    .PARAMETER Files
        Array of file paths to analyze
    
    .PARAMETER MaxParallel
        Maximum number of parallel jobs (default: CPU count)
    
    .PARAMETER ScriptBlock
        Analysis script block to execute for each file
    
    .EXAMPLE
        $files = Get-ChildItem -Path ./src -Include *.ps1 -Recurse
        $results = Invoke-ParallelAnalysis -Files $files -ScriptBlock {
            param($file)
            Invoke-PoshGuard -Path $file.FullName
        }
    
    .OUTPUTS
        Array of analysis results
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [array]$Files,
        
    [Parameter()]
    [int]$MaxParallel = $script:PerfConfig.MaxParallelJobs,
        
    [Parameter(Mandatory)]
    [scriptblock]$ScriptBlock
  )
    
  Write-Verbose "Starting parallel analysis with $MaxParallel workers"
    
  # Create runspace pool
  $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxParallel)
  $runspacePool.Open()
    
  $jobs = @()
  $results = @()
  $completed = 0
  $total = $Files.Count
    
  try {
    # Create jobs
    foreach ($file in $Files) {
      $powershell = [powershell]::Create().AddScript($ScriptBlock).AddArgument($file)
      $powershell.RunspacePool = $runspacePool
            
      $jobs += [PSCustomObject]@{
        PowerShell = $powershell
        Handle = $powershell.BeginInvoke()
        File = $file
      }
    }
        
    # Wait for completion and collect results
    $startTime = Get-Date
    while ($jobs.Count -gt 0) {
      $finished = $jobs | Where-Object { $_.Handle.IsCompleted }
            
      foreach ($job in $finished) {
        try {
          $result = $job.PowerShell.EndInvoke($job.Handle)
          $results += $result
          $completed++
                    
          # Progress
          $elapsed = (Get-Date) - $startTime
          $rate = $completed / $elapsed.TotalSeconds
          $remaining = ($total - $completed) / $rate
          $eta = [TimeSpan]::FromSeconds($remaining)
                    
          Write-Progress `
            -Activity "Parallel Analysis" `
            -Status "Processed $completed of $total files" `
            -PercentComplete (($completed / $total) * 100) `
            -SecondsRemaining $remaining
        }
        catch {
          Write-Warning "Failed to process $($job.File.Name): $_"
        }
        finally {
          $job.PowerShell.Dispose()
        }
      }
            
      # Remove completed jobs
      $jobs = $jobs | Where-Object { -not $_.Handle.IsCompleted }
            
      Start-Sleep -Milliseconds 100
    }
        
    Write-Progress -Activity "Parallel Analysis" -Completed
  }
  finally {
    $runspacePool.Close()
    $runspacePool.Dispose()
  }
    
  $totalTime = ((Get-Date) - $startTime).TotalSeconds
  Write-Verbose "Parallel analysis completed in $($totalTime.ToString('F2'))s"
  Write-Verbose "Average: $($($total / $totalTime).ToString('F2')) files/second"
    
  return $results
}

#endregion

#region Incremental Analysis

function Get-ChangedFile {
  <#
    .SYNOPSIS
        Identify files that have changed since last analysis
    
    .DESCRIPTION
        Uses file hashes to detect changes for incremental analysis.
        Only analyzes files that have been modified.
    
    .PARAMETER Path
        Root path to scan for files
    
    .PARAMETER Extensions
        File extensions to include
    
    .PARAMETER Force
        Force analysis of all files
    
    .EXAMPLE
        $changed = Get-ChangedFiles -Path ./src -Extensions @('.ps1', '.psm1')
    
    .OUTPUTS
        Array of changed file paths
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [string]$Path,
        
    [Parameter()]
    [array]$Extensions = @('.ps1', '.psm1', '.psd1'),
        
    [Parameter()]
    [switch]$Force
  )
    
  if ($Force -or -not $script:PerfConfig.EnableIncremental) {
    # Return all files - convert extensions to wildcards for -Include
    $includePatterns = $Extensions | ForEach-Object { "*$_" }
    return Get-ChildItem -Path $Path -Include $includePatterns -Recurse -File
  }
    
  # Load previous hashes
  $hashFile = Join-Path $script:PerfConfig.CachePath "file-hashes.json"
  if (Test-Path $hashFile) {
    $savedHashes = Get-Content $hashFile -Raw | ConvertFrom-Json -AsHashtable
  }
  else {
    $savedHashes = @{}
  }
    
  $changedFiles = @()
  $currentHashes = @{}
    
  # Convert extensions to wildcards for -Include
  $includePatterns = $Extensions | ForEach-Object { "*$_" }
  $files = Get-ChildItem -Path $Path -Include $includePatterns -Recurse -File
    
  foreach ($file in $files) {
    $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
    $currentHashes[$file.FullName] = $hash.Hash
        
    $previousHash = $savedHashes[$file.FullName]
    if (-not $previousHash -or $previousHash -ne $hash.Hash) {
      $changedFiles += $file
    }
  }
    
  # Save current hashes
  if (-not (Test-Path $script:PerfConfig.CachePath)) {
    New-Item -Path $script:PerfConfig.CachePath -ItemType Directory -Force | Out-Null
  }
  $currentHashes | ConvertTo-Json | Set-Content $hashFile
    
  Write-Verbose "Found $($changedFiles.Count) changed files out of $($files.Count) total"
    
  return $changedFiles
}

function Clear-AnalysisCache {
  <#
    .SYNOPSIS
        Clear all cached analysis data
    
    .EXAMPLE
        Clear-AnalysisCache
    #>
  [CmdletBinding()]
  param()
    
  $script:ASTCache.Clear()
  $script:FileHashes.Clear()
    
  if (Test-Path $script:PerfConfig.CachePath) {
    Remove-Item $script:PerfConfig.CachePath -Recurse -Force
    Write-Host "✓ Analysis cache cleared" -ForegroundColor Green
  }
}

#endregion

#region AST Caching

function Get-CachedAST {
  <#
    .SYNOPSIS
        Get cached AST or parse and cache
    
    .PARAMETER FilePath
        Path to PowerShell file
    
    .PARAMETER Content
        File content (optional, will be read if not provided)
    
    .EXAMPLE
        $ast = Get-CachedAST -FilePath ./script.ps1
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$FilePath,
        
    [Parameter()]
    [string]$Content
  )
    
  if (-not $script:PerfConfig.EnableCache) {
    # Caching disabled, parse directly
    if (-not $Content) {
      $Content = Get-Content -Path $FilePath -Raw
    }
    return [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
  }
    
  # Check cache
  $hash = if ($Content) {
    [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Content)) | 
      ForEach-Object { $_.ToString("x2") } | Join-String
  }
  else {
    (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
  }
    
  if ($script:ASTCache.ContainsKey($hash)) {
    Write-Verbose "Using cached AST for $FilePath"
    return $script:ASTCache[$hash]
  }
    
  # Parse and cache
  if (-not $Content) {
    $Content = Get-Content -Path $FilePath -Raw
  }
    
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
    
  # Cache if under memory limit
  if ($script:ASTCache.Count -lt 1000) {
    $script:ASTCache[$hash] = $ast
  }
    
  return $ast
}

#endregion

#region Memory Management

function Optimize-Memory {
  <#
    .SYNOPSIS
        Optimize memory usage during analysis
    
    .DESCRIPTION
        Forces garbage collection and trims caches if memory usage is high
    
    .EXAMPLE
        Optimize-Memory
    #>
  [CmdletBinding()]
  param()
    
  $currentMemoryMB = [System.GC]::GetTotalMemory($false) / 1MB
    
  if ($currentMemoryMB -gt $script:PerfConfig.MaxMemoryMB) {
    Write-Verbose "Memory usage high ($($currentMemoryMB.ToString('F0'))MB), optimizing..."
        
    # Clear old cache entries
    if ($script:ASTCache.Count -gt 500) {
      $toRemove = $script:ASTCache.Count - 500
      $keys = $script:ASTCache.Keys | Select-Object -First $toRemove
      foreach ($key in $keys) {
        $script:ASTCache.Remove($key)
      }
    }
        
    # Force GC
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
        
    $newMemoryMB = [System.GC]::GetTotalMemory($false) / 1MB
    $saved = $currentMemoryMB - $newMemoryMB
        
    Write-Verbose "Memory optimized: $($newMemoryMB.ToString('F0'))MB (saved $($saved.ToString('F0'))MB)"
  }
}

#endregion

#region Batch Processing

function Invoke-BatchAnalysis {
  <#
    .SYNOPSIS
        Process files in batches to manage memory
    
    .PARAMETER Files
        Array of files to process
    
    .PARAMETER ChunkSize
        Number of files per batch
    
    .PARAMETER ScriptBlock
        Processing script block
    
    .EXAMPLE
        $files = Get-ChildItem -Path ./src -Include *.ps1 -Recurse
        $results = Invoke-BatchAnalysis -Files $files -ChunkSize 50 -ScriptBlock {
            param($file)
            Invoke-PoshGuard -Path $file.FullName
        }
    #>
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [array]$Files,
        
    [Parameter()]
    [int]$ChunkSize = $script:PerfConfig.ChunkSize,
        
    [Parameter(Mandatory)]
    [scriptblock]$ScriptBlock
  )
    
  $results = @()
  $total = $Files.Count
  $processed = 0
    
  for ($i = 0; $i -lt $total; $i += $ChunkSize) {
    $chunk = $Files[$i..[Math]::Min($i + $ChunkSize - 1, $total - 1)]
        
    Write-Progress `
      -Activity "Batch Analysis" `
      -Status "Processing batch $([Math]::Floor($i / $ChunkSize) + 1) of $([Math]::Ceiling($total / $ChunkSize))" `
      -PercentComplete (($processed / $total) * 100)
        
    # Process chunk in parallel
    $chunkResults = Invoke-ParallelAnalysis -Files $chunk -ScriptBlock $ScriptBlock
    $results += $chunkResults
        
    $processed += $chunk.Count
        
    # Optimize memory between batches
    Optimize-Memory
  }
    
  Write-Progress -Activity "Batch Analysis" -Completed
    
  return $results
}

#endregion

#region Performance Monitoring

function Get-PerformanceMetric {
  <#
    .SYNOPSIS
        Get current performance metrics
    
    .EXAMPLE
        $metrics = Get-PerformanceMetrics
    #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param()
    
  $memoryMB = [System.GC]::GetTotalMemory($false) / 1MB
    
  return [PSCustomObject]@{
    CachedASTs = $script:ASTCache.Count
    CachedHashes = $script:FileHashes.Count
    MemoryUsageMB = [Math]::Round($memoryMB, 2)
    MaxParallelJobs = $script:PerfConfig.MaxParallelJobs
    CacheEnabled = $script:PerfConfig.EnableCache
    IncrementalEnabled = $script:PerfConfig.EnableIncremental
  }
}

function Show-PerformanceReport {
  <#
    .SYNOPSIS
        Display performance analysis report
    
    .PARAMETER StartTime
        Analysis start time
    
    .PARAMETER FileCount
        Number of files processed
    
    .EXAMPLE
        Show-PerformanceReport -StartTime $start -FileCount 100
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [datetime]$StartTime,
        
    [Parameter(Mandatory)]
    [int]$FileCount
  )
    
  $elapsed = (Get-Date) - $StartTime
  $rate = $FileCount / $elapsed.TotalSeconds
  $metrics = Get-PerformanceMetrics
    
  Write-Host ""
  Write-Host "⚡ Performance Report" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Files Processed: $FileCount" -ForegroundColor White
  Write-Host "  Total Time: $($elapsed.ToString('mm\:ss\.ff'))" -ForegroundColor White
  Write-Host "  Processing Rate: $($rate.ToString('F2')) files/second" -ForegroundColor White
  Write-Host "  Average Time: $($($elapsed.TotalMilliseconds / $FileCount).ToString('F0'))ms per file" -ForegroundColor White
  Write-Host ""
  Write-Host "  Memory Usage: $($metrics.MemoryUsageMB)MB" -ForegroundColor White
  Write-Host "  Cached ASTs: $($metrics.CachedASTs)" -ForegroundColor White
  Write-Host "  Parallel Workers: $($metrics.MaxParallelJobs)" -ForegroundColor White
  Write-Host ""
}

#endregion

#region Export

Export-ModuleMember -Function @(
  'Invoke-ParallelAnalysis',
  'Get-ChangedFiles',
  'Clear-AnalysisCache',
  'Get-CachedAST',
  'Optimize-Memory',
  'Invoke-BatchAnalysis',
  'Get-PerformanceMetrics',
  'Show-PerformanceReport'
)

#endregion
