#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard BestPractices/UsagePatterns module

.DESCRIPTION
    Comprehensive unit tests for BestPractices/UsagePatterns.psm1 covering:
    - Common usage pattern detection
    - Anti-pattern identification
    - Best practice recommendations
    
    Tests verify usage pattern analysis and fixes.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/BestPractices/UsagePatterns.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find UsagePatterns module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Test-UsagePatterns' -Tag 'Unit', 'BestPractices', 'UsagePatterns' {
  
  Context 'When analyzing usage patterns' {
    It 'Should detect proper cmdlet usage' {
      $code = 'Get-ChildItem -Path $folder -Filter *.ps1'
      
      $result = Test-UsagePatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect anti-patterns' {
      $code = 'Write-Host "Output"'
      
      $result = Test-UsagePatterns -Content $code
      
      $result.Issues | Should -Not -BeNullOrEmpty
    }
  }

  Context 'When detecting specific patterns' {
    It 'Should detect pipeline usage patterns' {
      $code = 'Get-Process | Where-Object { $_.CPU -gt 10 } | Select-Object Name'
      
      $result = Test-UsagePatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect error handling patterns' {
      $code = @'
try {
    Get-Content -Path $file
} catch {
    Write-Error $_
}
'@
      
      $result = Test-UsagePatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect scope usage patterns' {
      $code = '$global:Config = @{ }'
      
      $result = Test-UsagePatterns -Content $code
      
      $result.Issues | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Find-AntiPatterns' -Tag 'Unit', 'BestPractices', 'UsagePatterns' {
  
  Context 'When finding anti-patterns' {
    It 'Should detect Select-Object * anti-pattern' {
      $code = 'Get-Process | Select-Object *'
      
      $result = Find-AntiPatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect suppressed error handling' {
      $code = 'Get-Content $file -ErrorAction SilentlyContinue | Out-Null'
      
      $result = Find-AntiPatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect empty catch blocks' {
      $code = @'
try {
    Do-Something
} catch {
}
'@
      
      $result = Find-AntiPatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Get-BestPracticeRecommendation' -Tag 'Unit', 'BestPractices', 'UsagePatterns' {
  
  Context 'When getting recommendations' {
    It 'Should provide recommendations for anti-patterns' {
      $result = Get-BestPracticeRecommendation -Pattern 'WriteHost'
      
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match 'Write-Output|Write-Information'
    }

    It 'Should provide recommendations for error handling' {
      $result = Get-BestPracticeRecommendation -Pattern 'EmptyCatch'
      
      $result | Should -Not -BeNullOrEmpty
      $result | Should -Match 'error|log|handle'
    }

    It 'Should provide recommendations for pipeline usage' {
      $result = Get-BestPracticeRecommendation -Pattern 'Pipeline'
      
      $result | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Test-PerformancePatterns' -Tag 'Unit', 'BestPractices', 'UsagePatterns' {
  
  Context 'When testing performance patterns' {
    It 'Should detect inefficient loop patterns' {
      $code = @'
foreach ($item in Get-ChildItem) {
    Write-Output $item
}
'@
      
      $result = Test-PerformancePatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should detect string concatenation in loops' {
      $code = @'
$result = ""
foreach ($i in 1..100) {
    $result += $i
}
'@
      
      $result = Test-PerformancePatterns -Content $code
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should recommend StringBuilder for string building' {
      $code = '$str = ""; for ($i=0; $i -lt 1000; $i++) { $str += $i }'
      
      $result = Test-PerformancePatterns -Content $code
      
      $result.Recommendation | Should -Match 'StringBuilder|ArrayList|-join'
    }
  }
}
