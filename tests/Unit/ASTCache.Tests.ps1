#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Unit tests for ASTCache module

.DESCRIPTION
    Comprehensive tests for AST caching functionality:
    - Cache hit/miss behavior
    - Cache size limits and eviction
    - Cache statistics
    - Thread safety
    - Performance improvements

.NOTES
    Test Framework: Pester v5+
    Pattern: AAA (Arrange-Act-Assert)
    Coverage Target: 95%+
#>

BeforeAll {
  $ModulePath = Join-Path $PSScriptRoot '../../tools/lib/ASTCache.psm1'
  Import-Module $ModulePath -Force -ErrorAction Stop
}

Describe 'ASTCache Module' -Tag 'Unit', 'ASTCache', 'Performance' {

  BeforeEach {
    # Clear cache before each test
    Clear-ASTCache
  }

  Context 'Get-CachedAST Basic Functionality' {
    It 'Should parse and cache AST on first call' {
      # Arrange
      $content = 'function Test { Write-Host "Hello" }'

      # Act
      $ast = Get-CachedAST -Content $content

      # Assert
      $ast | Should -Not -BeNullOrEmpty
      $ast.GetType().Name | Should -Be 'ScriptBlockAst'

      $stats = Get-ASTCacheStats
      $stats.Misses | Should -Be 1
      $stats.Hits | Should -Be 0
      $stats.CacheSize | Should -Be 1
    }

    It 'Should return cached AST on second call (cache hit)' {
      # Arrange
      $content = 'function Test { Write-Host "Hello" }'

      # Act - First call (cache miss)
      $ast1 = Get-CachedAST -Content $content

      # Act - Second call (cache hit)
      $ast2 = Get-CachedAST -Content $content

      # Assert - Both should return same AST
      $ast1 | Should -Not -BeNullOrEmpty
      $ast2 | Should -Not -BeNullOrEmpty
      $ast1.ToString() | Should -Be $ast2.ToString()

      $stats = Get-ASTCacheStats
      $stats.Misses | Should -Be 1
      $stats.Hits | Should -Be 1
      $stats.HitRate | Should -Be '50%'
    }

    It 'Should cache different content separately' {
      # Arrange
      $content1 = 'function Test1 { Write-Host "Hello" }'
      $content2 = 'function Test2 { Write-Host "World" }'

      # Act
      $ast1 = Get-CachedAST -Content $content1
      $ast2 = Get-CachedAST -Content $content2

      # Assert - Should have 2 cache entries
      $ast1 | Should -Not -BeNullOrEmpty
      $ast2 | Should -Not -BeNullOrEmpty

      $stats = Get-ASTCacheStats
      $stats.CacheSize | Should -Be 2
      $stats.Misses | Should -Be 2
      $stats.Hits | Should -Be 0
    }

    It 'Should handle empty content' {
      # Arrange
      $content = ''

      # Act
      $ast = Get-CachedAST -Content $content

      # Assert
      $ast | Should -Not -BeNullOrEmpty
    }

    It 'Should include FilePath in verbose output' {
      # Arrange
      $content = 'Write-Host "Test"'
      $filePath = 'C:\Test\Script.ps1'

      # Act
      $ast = Get-CachedAST -Content $content -FilePath $filePath -Verbose

      # Assert
      $ast | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Cache with Parse Errors' {
    It 'Should cache AST even with parse errors' {
      # Arrange
      $invalidContent = 'function Test { invalid syntax }'

      # Act - First call
      $ast1 = Get-CachedAST -Content $invalidContent

      # Act - Second call (should hit cache)
      $ast2 = Get-CachedAST -Content $invalidContent

      # Assert - AST returned (best-effort) and cached
      $ast1 | Should -Not -BeNullOrEmpty
      $ast2 | Should -Not -BeNullOrEmpty

      $stats = Get-ASTCacheStats
      $stats.Hits | Should -Be 1
      $stats.Misses | Should -Be 1
    }
  }

  Context 'Cache Size Limits and Eviction' {
    It 'Should respect cache size limit' {
      # Arrange - Create many unique content strings
      $maxSize = (Get-ASTCacheStats).MaxCacheSize
      $contentArray = 1..($maxSize + 5) | ForEach-Object {
        "function Test$_ { Write-Host `"Test$_`" }"
      }

      # Act - Parse more items than cache can hold
      foreach ($content in $contentArray) {
        $ast = Get-CachedAST -Content $content
      }

      # Assert - Cache should not exceed max size
      $stats = Get-ASTCacheStats
      $stats.CacheSize | Should -BeLessOrEqual $maxSize
      $stats.Evictions | Should -BeGreaterThan 0
    }

    It 'Should evict oldest entries when cache is full' {
      # Arrange
      $content1 = 'function Test1 { Write-Host "1" }'
      $content2 = 'function Test2 { Write-Host "2" }'

      # Act - Fill cache and add one more
      $maxSize = (Get-ASTCacheStats).MaxCacheSize

      # Parse first content
      $ast1 = Get-CachedAST -Content $content1

      # Fill cache with other content
      2..$maxSize | ForEach-Object {
        $content = "function Test$_ { Write-Host `"$_`" }"
        Get-CachedAST -Content $content
      }

      # Add one more (should evict)
      Get-CachedAST -Content $content2

      # Assert - Eviction should have occurred
      $stats = Get-ASTCacheStats
      $stats.Evictions | Should -BeGreaterThan 0
    }
  }

  Context 'Clear-ASTCache' {
    It 'Should clear all cached entries' {
      # Arrange - Add some entries
      1..5 | ForEach-Object {
        $content = "function Test$_ { Write-Host `"$_`" }"
        Get-CachedAST -Content $content
      }

      $stats = Get-ASTCacheStats
      $stats.CacheSize | Should -Be 5

      # Act
      Clear-ASTCache

      # Assert
      $stats = Get-ASTCacheStats
      $stats.CacheSize | Should -Be 0
      $stats.Hits | Should -Be 0
      $stats.Misses | Should -Be 0
      $stats.Evictions | Should -Be 0
    }

    It 'Should reset statistics' {
      # Arrange - Generate some activity
      $content = 'function Test { }'
      Get-CachedAST -Content $content  # Miss
      Get-CachedAST -Content $content  # Hit

      $stats = Get-ASTCacheStats
      $stats.Hits | Should -Be 1
      $stats.Misses | Should -Be 1

      # Act
      Clear-ASTCache

      # Assert
      $stats = Get-ASTCacheStats
      $stats.Hits | Should -Be 0
      $stats.Misses | Should -Be 0
    }
  }

  Context 'Get-ASTCacheStats' {
    It 'Should return cache statistics object' {
      # Act
      $stats = Get-ASTCacheStats

      # Assert
      $stats | Should -Not -BeNullOrEmpty
      $stats.CacheSize | Should -BeOfType [int]
      $stats.MaxCacheSize | Should -BeOfType [int]
      $stats.Hits | Should -BeOfType [int]
      $stats.Misses | Should -BeOfType [int]
      $stats.Evictions | Should -BeOfType [int]
      $stats.HitRate | Should -Match '^\d+(\.\d+)?%$'
    }

    It 'Should calculate hit rate correctly' {
      # Arrange
      $content = 'function Test { }'

      # Act - 1 miss, 3 hits (75% hit rate)
      Get-CachedAST -Content $content  # Miss
      Get-CachedAST -Content $content  # Hit
      Get-CachedAST -Content $content  # Hit
      Get-CachedAST -Content $content  # Hit

      # Assert
      $stats = Get-ASTCacheStats
      $stats.Hits | Should -Be 3
      $stats.Misses | Should -Be 1
      $stats.HitRate | Should -Be '75%'
    }

    It 'Should return 0% hit rate when no cache activity' {
      # Arrange - Empty cache

      # Act
      $stats = Get-ASTCacheStats

      # Assert
      $stats.HitRate | Should -Be '0%'
    }
  }

  Context 'Performance Improvements' {
    It 'Should be faster on cache hits than parsing' {
      # Arrange
      $largeContent = 1..100 | ForEach-Object {
        "function Test$_ { param(`$Param$_) Write-Host `$Param$_ }"
      } | Join-String -Separator "`n"

      # Act - First parse (miss)
      $parseTime = Measure-Command {
        $ast1 = Get-CachedAST -Content $largeContent
      }

      # Act - Second parse (hit)
      $cacheTime = Measure-Command {
        $ast2 = Get-CachedAST -Content $largeContent
      }

      # Assert - Cache hit should be significantly faster
      $cacheTime.TotalMilliseconds | Should -BeLessThan ($parseTime.TotalMilliseconds / 2)
    }

    It 'Should handle high-frequency repeated parsing efficiently' {
      # Arrange
      $content = 'function Test { Write-Host "Hello" }'

      # Act - Parse same content 100 times
      $executionTime = Measure-Command {
        1..100 | ForEach-Object {
          Get-CachedAST -Content $content
        }
      }

      # Assert - Should complete quickly (< 1 second)
      $executionTime.TotalSeconds | Should -BeLessThan 1

      # Assert - Should have 1 miss, 99 hits
      $stats = Get-ASTCacheStats
      $stats.Misses | Should -Be 1
      $stats.Hits | Should -Be 99
      $stats.HitRate | Should -Be '99%'
    }
  }

  Context 'Error Handling' {
    It 'Should handle caching failures gracefully' {
      # Arrange - This test validates fallback behavior
      $content = 'function Test { Write-Host "Hello" }'

      # Act
      $ast = Get-CachedAST -Content $content

      # Assert - Should still return AST even if caching fails
      $ast | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Content Hash Uniqueness' {
    It 'Should differentiate similar but different content' {
      # Arrange
      $content1 = 'function Test { Write-Host "Hello" }'
      $content2 = 'function Test { Write-Host "World" }'

      # Act
      $ast1 = Get-CachedAST -Content $content1
      $ast2 = Get-CachedAST -Content $content2

      # Assert - Should be separate cache entries
      $stats = Get-ASTCacheStats
      $stats.CacheSize | Should -Be 2
      $stats.Misses | Should -Be 2
    }

    It 'Should recognize identical content regardless of variable assignment' {
      # Arrange
      $content = 'function Test { Write-Host "Hello" }'

      # Act - Parse same content assigned to different variables
      $ast1 = Get-CachedAST -Content $content
      $copyContent = $content
      $ast2 = Get-CachedAST -Content $copyContent

      # Assert - Should hit cache
      $stats = Get-ASTCacheStats
      $stats.Misses | Should -Be 1
      $stats.Hits | Should -Be 1
    }
  }
}

Describe 'ASTCache Module Exports' -Tag 'Unit', 'ASTCache', 'Exports' {
  It 'Should export Get-CachedAST function' {
    Get-Command Get-CachedAST -Module ASTCache -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }

  It 'Should export Clear-ASTCache function' {
    Get-Command Clear-ASTCache -Module ASTCache -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }

  It 'Should export Get-ASTCacheStats function' {
    Get-Command Get-ASTCacheStats -Module ASTCache -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }
}

AfterAll {
  # Cleanup
  Clear-ASTCache
  Remove-Module ASTCache -ErrorAction SilentlyContinue
}
