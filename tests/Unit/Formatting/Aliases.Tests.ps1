#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard Formatting/Aliases module

.DESCRIPTION
    Unit tests for Formatting/Aliases.psm1 functions:
    - Invoke-AliasFix
    - Invoke-AliasFixAst

    Tests cover common alias expansions and edge cases.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import Aliases module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/Formatting/Aliases.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Aliases module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-AliasFix' -Tag 'Unit', 'Formatting', 'Aliases' {
  
  Context 'When expanding common aliases' {
    It 'Should expand gci to Get-ChildItem' {
      $testContent = 'gci C:\Temp'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Match 'Get-ChildItem'
    }

    It 'Should expand ls to Get-ChildItem' {
      $testContent = 'ls -Recurse'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Match 'Get-ChildItem'
    }

    It 'Should expand cat to Get-Content' {
      $testContent = 'cat file.txt'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Match 'Get-Content'
    }

    It 'Should expand cp to Copy-Item' {
      $testContent = 'cp file1.txt file2.txt'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Match 'Copy-Item'
    }

    It 'Should expand rm to Remove-Item' {
      $testContent = 'rm file.txt'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Match 'Remove-Item'
    }
  }

  Context 'When handling multiple aliases' {
    It 'Should expand multiple different aliases' {
      $testContent = 'gci C:\; cat file.txt; rm temp.log'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Match 'Get-ChildItem'
      $result | Should -Match 'Get-Content'
      $result | Should -Match 'Remove-Item'
    }
  }

  Context 'When handling special cases' {
    It 'Should skip PSQAAutoFixer file' {
      $testContent = 'gci C:\Temp'
      
      $result = Invoke-AliasFix -Content $testContent -FilePath 'C:\Scripts\PSQAAutoFixer.psm1'
      
      # Should NOT expand when FilePath matches PSQAAutoFixer
      $result | Should -Be $testContent
    }

    It 'Should process other files normally' {
      $testContent = 'gci C:\Temp'
      
      $result = Invoke-AliasFix -Content $testContent -FilePath 'C:\Scripts\MyScript.ps1'
      
      # Should expand normally
      $result | Should -Match 'Get-ChildItem'
    }
  }

  Context 'When content has no aliases' {
    It 'Should return content' {
      $testContent = 'Get-ChildItem -Path C:\Temp'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle simple content' {
      $testContent = '# Comment only'
      
      { Invoke-AliasFix -Content $testContent } | Should -Not -Throw
    }
  }

  Context 'Edge cases' {
    It 'Should handle case variations' {
      $testContent = 'GCI C:\Temp'
      
      $result = Invoke-AliasFix -Content $testContent
      
      # PowerShell is case-insensitive, should still expand
      $result | Should -Match 'Get-ChildItem'
    }
  }
}

Describe 'Invoke-AliasFixAst' -Tag 'Unit', 'Formatting', 'Aliases' {
  
  Context 'AST-based alias expansion' {
    It 'Should expand aliases using AST parsing' {
      $testContent = 'gci | select Name'
      
      $result = Invoke-AliasFixAst -Content $testContent
      
      $result | Should -Match 'Get-ChildItem'
    }

    It 'Should handle piped commands' {
      $testContent = 'gci | ? {$_.Extension -eq ".txt"}'
      
      $result = Invoke-AliasFixAst -Content $testContent
      
      $result | Should -Match 'Get-ChildItem'
    }
  }

  Context 'Error handling' {
    It 'Should handle invalid syntax gracefully' {
      $testContent = 'function { invalid'
      
      { Invoke-AliasFixAst -Content $testContent } | Should -Not -Throw
    }

    It 'Should handle simple content' {
      $testContent = '# Comment'
      
      { Invoke-AliasFixAst -Content $testContent } | Should -Not -Throw
    }
  }
}

Describe 'Alias Integration' -Tag 'Integration', 'Formatting' {
  
  Context 'Real-world alias patterns' {
    It 'Should handle typical script with multiple aliases' {
      $testContent = '$files = gci *.txt; foreach ($file in $files) { $content = cat $file }'
      
      $result = Invoke-AliasFix -Content $testContent
      
      $result | Should -Match 'Get-ChildItem'
      $result | Should -Match 'Get-Content'
    }

    It 'Should preserve script structure' {
      $testContent = 'if (gci) { echo "Found files" }'
      
      $result = Invoke-AliasFix -Content $testContent
      
      # Structure should be preserved
      $result | Should -Match 'if'
    }
  }
}
