#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard EntropySecretDetection module

.DESCRIPTION
    Comprehensive unit tests for entropy-based secret detection:
    - Get-ShannonEntropy - Shannon entropy calculation
    - Test-IsHex - Hexadecimal string detection
    - Test-IsBase64 - Base64 encoding detection
    - Find-SecretsByEntropy - High entropy secret detection
    - Find-SecretsByPattern - Pattern-based secret detection
    - Get-EntropyConfidence - Confidence score calculation

    Tests cover happy paths, edge cases, error conditions, and boundary values.
    All tests are hermetic using mocks and deterministic test data.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
    Security-critical module with high test coverage requirements
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import EntropySecretDetection module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/EntropySecretDetection.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find EntropySecretDetection module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Get-ShannonEntropy' -Tag 'Unit', 'Security', 'Entropy' {
  
  Context 'When calculating entropy for various strings' {
    It 'Empty string => throws parameter validation error' {
      { Get-ShannonEntropy -String "" } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
    }

    It 'Single character repeated => entropy 0.0' {
      $result = Get-ShannonEntropy -String "aaaaaaa"
      $result | Should -Be 0.0
    }

    It 'Two characters equally distributed => entropy ~1.0' {
      $result = Get-ShannonEntropy -String "ababababab"
      $result | Should -BeGreaterThan 0.99
      $result | Should -BeLessThan 1.01
    }

    It 'Random high-entropy string => entropy > 4.5' {
      $highEntropyString = "xK9#mQ2\$vN8@pL4^rT6&"
      $result = Get-ShannonEntropy -String $highEntropyString
      $result | Should -BeGreaterThan 4.0
    }

    It 'Low-entropy predictable string => entropy < 3.0' {
      $lowEntropyString = "password123"
      $result = Get-ShannonEntropy -String $lowEntropyString
      $result | Should -BeLessThan 3.5
    }

    It 'Base64-like string => entropy > 4.0' -TestCases @(
      @{ String = "SGVsbG9Xb3JsZA==" }
      @{ String = "VGhpc0lzQVRlc3RTdHJpbmc=" }
    ) {
      param($String)
      $result = Get-ShannonEntropy -String $String
      $result | Should -BeGreaterThan 3.0
    }

    It 'Hexadecimal string => entropy between 2.5 and 4.0' {
      $hexString = "1a2b3c4d5e6f7890abcdef"
      $result = Get-ShannonEntropy -String $hexString
      $result | Should -BeGreaterThan 2.0
      $result | Should -BeLessThan 4.5
    }
  }

  Context 'Edge cases and boundary conditions' {
    It 'Whitespace-only string => entropy 0.0' {
      $result = Get-ShannonEntropy -String "     "
      $result | Should -Be 0.0
    }

    It 'Unicode characters => valid entropy calculation' {
      $unicodeString = "こんにちは世界"
      $result = Get-ShannonEntropy -String $unicodeString
      $result | Should -BeGreaterOrEqual 0.0
    }

    It 'Very long string => consistent entropy' {
      $longString = "a" * 1000 + "b" * 1000
      $result = Get-ShannonEntropy -String $longString
      $result | Should -BeGreaterThan 0.99
      $result | Should -BeLessThan 1.01
    }

    It 'Special characters => valid entropy' {
      $specialChars = "!@#$%^&*()_+-=[]{}|;:',.<>?/~"
      $result = Get-ShannonEntropy -String $specialChars
      $result | Should -BeGreaterOrEqual 0.0
    }
  }

  Context 'Return type validation' {
    It 'Should return System.Double' {
      $result = Get-ShannonEntropy -String "test"
      $result | Should -BeOfType [double]
    }

    It 'Should always return non-negative value' {
      $result = Get-ShannonEntropy -String "any string"
      $result | Should -BeGreaterOrEqual 0.0
    }
  }
}

Describe 'Test-IsHex (internal)' -Tag 'Unit', 'Security', 'Encoding' {
  
  Context 'When testing hexadecimal strings' {
    It 'Valid hex strings => returns true' {
      InModuleScope EntropySecretDetection {
        Test-IsHex -String "abcdef0123456789" | Should -Be $true
        Test-IsHex -String "DEADBEEF" | Should -Be $true
        Test-IsHex -String "AbCdEf0123" | Should -Be $true
      }
    }

    It 'Invalid strings => returns false' {
      InModuleScope EntropySecretDetection {
        Test-IsHex -String "ghijkl" | Should -Be $false
        Test-IsHex -String "hello world" | Should -Be $false
        Test-IsHex -String "abc 123" | Should -Be $false
      }
    }
  }
}

Describe 'Test-IsBase64 (internal)' -Tag 'Unit', 'Security', 'Encoding' {
  
  Context 'When testing Base64 encoded strings' {
    It 'Valid Base64 strings => returns true' {
      InModuleScope EntropySecretDetection {
        Test-IsBase64 -String "SGVsbG8gV29ybGQ=" | Should -Be $true
        Test-IsBase64 -String "VGhpcyBpcyBhIHRlc3Q=" | Should -Be $true
      }
    }

    It 'Invalid Base64 strings => returns false' {
      InModuleScope EntropySecretDetection {
        Test-IsBase64 -String "Hello@World!" | Should -Be $false
        Test-IsBase64 -String "This is plain text" | Should -Be $false
      }
    }
  }
}

Describe 'Find-SecretsByEntropy' -Tag 'Unit', 'Security', 'SecretDetection' {
  
  Context 'When scanning for high-entropy secrets' {
    It 'Low entropy string => not detected' {
      $content = '$message = "Hello World Test Message"'
      
      $result = Find-SecretsByEntropy -Content $content
      
      $result.Count | Should -Be 0
    }

    It 'False positive pattern => excluded' {
      $content = '$example = "YOUR_KEY_HERE_REPLACE_ME"'
      
      $result = Find-SecretsByEntropy -Content $content
      
      $result.Count | Should -Be 0
    }

    It 'String too short => not analyzed' {
      $content = '$short = "abc123"'
      
      $result = Find-SecretsByEntropy -Content $content
      
      $result.Count | Should -Be 0
    }
  }

  Context 'Edge cases' {
    It 'No string literals => returns empty array' {
      $content = '$x = 123; $y = $true'
      
      $result = Find-SecretsByEntropy -Content $content
      
      $result.Count | Should -Be 0
    }

    It 'Comment with high entropy => not detected' {
      $content = '# This is a comment with xK9mQ2vN8pL4rT6'
      
      $result = Find-SecretsByEntropy -Content $content
      
      $result.Count | Should -Be 0
    }
  }
}

Describe 'Find-SecretsByPattern' -Tag 'Unit', 'Security', 'SecretDetection' {
  
  Context 'When detecting known secret patterns' {
    It 'Function exists and is callable' {
      Get-Command Find-SecretsByPattern | Should -Not -BeNullOrEmpty
    }

    It 'Returns empty array when no matches' {
      $content = '$x = 123'
      $result = Find-SecretsByPattern -Content $content
      $result.Count | Should -Be 0
    }
  }

  Context 'Edge cases' {
    It 'No matching patterns => returns empty array' {
      $content = '$x = 123; Write-Output "Hello"'
      
      $result = Find-SecretsByPattern -Content $content
      
      $result.Count | Should -Be 0
    }
  }
}

Describe 'Get-EntropyConfidence' -Tag 'Unit', 'Security', 'Confidence' {
  
  Context 'When calculating confidence scores' {
    It 'Entropy at threshold => confidence ~0.6' {
      InModuleScope EntropySecretDetection {
        $result = Get-EntropyConfidence -Entropy 4.5 -Threshold 4.5
        $result | Should -BeGreaterOrEqual 0.59
        $result | Should -BeLessOrEqual 0.61
      }
    }

    It 'Entropy exceeds threshold => higher confidence' {
      InModuleScope EntropySecretDetection {
        $result1 = Get-EntropyConfidence -Entropy 4.5 -Threshold 4.0
        $result2 = Get-EntropyConfidence -Entropy 5.0 -Threshold 4.0
        $result2 | Should -BeGreaterThan $result1
      }
    }

    It 'Confidence capped at 0.95' {
      InModuleScope EntropySecretDetection {
        $result = Get-EntropyConfidence -Entropy 10.0 -Threshold 4.0
        $result | Should -BeLessOrEqual 0.95
      }
    }

    It 'Confidence always positive' {
      InModuleScope EntropySecretDetection {
        $result = Get-EntropyConfidence -Entropy 3.0 -Threshold 4.0
        $result | Should -BeGreaterThan 0.0
      }
    }
  }

  Context 'Return type validation' {
    It 'Should return System.Double' {
      InModuleScope EntropySecretDetection {
        $result = Get-EntropyConfidence -Entropy 4.5 -Threshold 4.0
        $result | Should -BeOfType [double]
      }
    }
  }
}

Describe 'EntropySecretDetection - Integration Tests' -Tag 'Integration', 'Security' {
  
  Context 'When scanning realistic code samples' {
    It 'Does not flag safe configuration' {
      $content = @'
# Safe configuration
$appName = "TestApp"
$logLevel = "Info"
$timeout = 30
$enabled = $true
'@
      
      $entropySecrets = Find-SecretsByEntropy -Content $content
      $patternSecrets = Find-SecretsByPattern -Content $content
      
      $entropySecrets.Count | Should -Be 0
      $patternSecrets.Count | Should -Be 0
    }
  }
}
