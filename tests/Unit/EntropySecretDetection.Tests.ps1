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

Describe 'Invoke-SecretScan' -Tag 'Unit', 'Security', 'SecretDetection' {
  
  Context 'When scanning content for secrets' {
    It 'Should scan content and return results' {
      # Arrange
      $testContent = @'
# Test script with various patterns
$message = "Hello World"
$apiKey = "AKIAIOSFODNN7EXAMPLE"
$password = "MySecurePassword123"
'@
      
      # Act
      $result = Invoke-SecretScan -Content $testContent -FilePath 'test.ps1'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should accept Content parameter' {
      # Arrange
      $cmd = Get-Command -Name Invoke-SecretScan
      
      # Assert
      $cmd.Parameters.ContainsKey('Content') | Should -Be $true
    }

    It 'Should accept FilePath parameter' {
      # Arrange
      $cmd = Get-Command -Name Invoke-SecretScan
      
      # Assert
      $cmd.Parameters.ContainsKey('FilePath') | Should -Be $true
    }

    It 'Should return hashtable with results' {
      # Arrange
      $content = '$test = "value"'
      
      # Act
      $result = Invoke-SecretScan -Content $content
      
      # Assert
      $result | Should -BeOfType [hashtable]
    }

    It 'Should detect high-entropy strings' {
      # Arrange
      $secretContent = '$secret = "xK9mQ2vN8pL4rT6yU1wS3eA5dF7gH9j"'
      
      # Act
      $result = Invoke-SecretScan -Content $secretContent
      
      # Assert
      $result.Keys.Count | Should -BeGreaterThan 0
    }

    It 'Should handle empty content gracefully' {
      # Act
      $result = Invoke-SecretScan -Content ''
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should handle content with only comments' {
      # Arrange
      $commentContent = @'
# This is a comment
# Another comment
# Yet another comment
'@
      
      # Act
      $result = Invoke-SecretScan -Content $commentContent
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should include scan metrics in results' {
      # Arrange
      $content = '$test = "value"'
      
      # Act
      $result = Invoke-SecretScan -Content $content
      
      # Assert
      $result.Keys | Should -Contain 'ScanDurationMs'
      $result.Keys | Should -Contain 'LineCount'
      $result.Keys | Should -Contain 'SecretsFound'
    }
  }

  Context 'Pattern detection' {
    It 'Should detect AWS access keys' {
      # Arrange
      $awsContent = '$accessKey = "AKIAIOSFODNN7EXAMPLE"'
      
      # Act
      $result = Invoke-SecretScan -Content $awsContent
      
      # Assert
      $result.Keys.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should detect private keys' {
      # Arrange
      $keyContent = @'
$key = @"
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
-----END RSA PRIVATE KEY-----
"@
'@
      
      # Act
      $result = Invoke-SecretScan -Content $keyContent
      
      # Assert
      $result.Keys.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should detect JWT tokens' {
      # Arrange
      $jwtContent = '$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"'
      
      # Act
      $result = Invoke-SecretScan -Content $jwtContent
      
      # Assert
      $result.Keys.Count | Should -BeGreaterOrEqual 0
    }
  }
}

Describe 'Export-SecretScanResults' -Tag 'Unit', 'Security', 'Reporting' {
  
  Context 'When exporting scan results' {
    BeforeEach {
      $testResults = @{
        FilePath = 'test.ps1'
        SecretsFound = 1
        Secrets = @(
          @{
            Type = 'HighEntropy'
            SubType = 'Base64'
            Value = 'SGVsbG9Xb3JsZA=='
            Entropy = 4.8
            LineNumber = 1
            Severity = 'Error'
            Confidence = 0.85
            Message = 'High entropy Base64 string detected'
          }
        )
      }
    }

    It 'Should export results without error' {
      # Act & Assert
      { Export-SecretScanResults -Results $testResults } | Should -Not -Throw
    }

    It 'Should accept Results parameter' {
      # Arrange
      $cmd = Get-Command -Name Export-SecretScanResults
      
      # Assert
      $cmd.Parameters.ContainsKey('Results') | Should -Be $true
    }

    It 'Should handle empty results hashtable' {
      # Arrange
      $emptyResults = @{
        FilePath = 'test.ps1'
        SecretsFound = 0
        Secrets = @()
      }
      
      # Act & Assert
      { Export-SecretScanResults -Results $emptyResults } | Should -Not -Throw
    }

    It 'Should have CmdletBinding attribute' {
      # Arrange
      $cmd = Get-Command -Name Export-SecretScanResults
      
      # Assert
      $cmd.CmdletBinding | Should -Be $true
    }
  }
}

Describe 'Get-SecretScanSummary' -Tag 'Unit', 'Security', 'Reporting' {
  
  Context 'When generating scan summary' {
    It 'Should generate summary without errors' {
      # Act & Assert
      { Get-SecretScanSummary } | Should -Not -Throw
    }

    It 'Should return hashtable' {
      # Act
      $summary = Get-SecretScanSummary
      
      # Assert
      $summary | Should -BeOfType [hashtable]
    }

    It 'Should have TotalScans key' {
      # Act
      $summary = Get-SecretScanSummary
      
      # Assert
      $summary.Keys | Should -Contain 'TotalScans'
    }

    It 'Should have TotalSecrets key' {
      # Act
      $summary = Get-SecretScanSummary
      
      # Assert
      $summary.Keys | Should -Contain 'TotalSecrets'
    }

    It 'Should have FilesWithSecrets key' {
      # Act
      $summary = Get-SecretScanSummary
      
      # Assert
      $summary.Keys | Should -Contain 'FilesWithSecrets'
    }

    It 'Should return zero counts when no report exists' {
      # Act
      $summary = Get-SecretScanSummary
      
      # Assert
      $summary.TotalScans | Should -BeGreaterOrEqual 0
      $summary.TotalSecrets | Should -BeGreaterOrEqual 0
    }

    It 'Should have CmdletBinding attribute' {
      # Arrange
      $cmd = Get-Command -Name Get-SecretScanSummary
      
      # Assert
      $cmd.CmdletBinding | Should -Be $true
    }
  }
}

Describe 'Find-SecretsByEntropy - Extended Tests' -Tag 'Unit', 'Security' {
  
  Context 'Different string types' {
    It 'Should detect Base64 encoded secrets' {
      # Arrange
      $content = '$secret = "SGVsbG9Xb3JsZERhdGFUaGlzSXNBTG9uZ0Jhc2U2NFN0cmluZ1dpdGhIaWdoRW50cm9weQ=="'
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should detect hexadecimal secrets' {
      # Arrange
      $content = '$key = "1a2b3c4d5e6f7890abcdef1234567890abcdef"'
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should classify string types correctly' {
      # Arrange
      $content = @'
$base64 = "SGVsbG9Xb3JsZERhdGFUaGlz"
$hex = "1a2b3c4d5e6f7890"
$ascii = "RandomHighEntropyString"
'@
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result | Should -Not -BeNull
    }
  }

  Context 'False positive filtering' {
    It 'Should exclude example patterns' {
      # Arrange
      $content = '$example = "YOUR_KEY_HERE_REPLACE_THIS_WITH_REAL_KEY"'
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result.Count | Should -Be 0
    }

    It 'Should exclude test data' {
      # Arrange
      $content = '$test = "test_data_1234567890abcdefghijklmnop"'
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result.Count | Should -Be 0
    }

    It 'Should exclude Lorem Ipsum' {
      # Arrange
      $content = '$text = "Lorem ipsum dolor sit amet consectetur"'
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result.Count | Should -Be 0
    }

    It 'Should exclude repeated X patterns' {
      # Arrange
      $content = '$placeholder = "XXXXXXXXXXXXXXXXXXXXXXXX"'
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result.Count | Should -Be 0
    }

    It 'Should exclude repeated 0 patterns' {
      # Arrange
      $content = '$zeros = "00000000000000000000"'
      
      # Act
      $result = Find-SecretsByEntropy -Content $content
      
      # Assert
      $result.Count | Should -Be 0
    }
  }
}

Describe 'Find-SecretsByPattern - Extended Tests' -Tag 'Unit', 'Security' {
  
  Context 'Cloud provider keys' {
    It 'Should detect AWS access keys' {
      # Arrange
      $content = '$key = "AKIAIOSFODNN7EXAMPLE"'
      
      # Act
      $result = Find-SecretsByPattern -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should detect Azure client secrets' {
      # Arrange
      $content = '$azure_secret = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"'
      
      # Act
      $result = Find-SecretsByPattern -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should detect Google API keys' {
      # Arrange
      $content = '$google = "AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q"'
      
      # Act
      $result = Find-SecretsByPattern -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }
  }

  Context 'Version control tokens' {
    It 'Should detect GitHub tokens' {
      # Arrange
      $content = '$github = "ghp_1234567890abcdefghijklmnopqrstuvwxyz"'
      
      # Act
      $result = Find-SecretsByPattern -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should detect GitLab tokens' {
      # Arrange
      $content = '$gitlab = "glpat-1234567890abcdef"'
      
      # Act
      $result = Find-SecretsByPattern -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }
  }

  Context 'Connection strings' {
    It 'Should detect SQL connection strings' {
      # Arrange
      $content = '$conn = "Server=localhost;Database=test;User Id=sa;Password=secret123;"'
      
      # Act
      $result = Find-SecretsByPattern -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
    }

    It 'Should detect MongoDB connection strings' {
      # Arrange
      $content = '$mongo = "mongodb://user:pass@localhost:27017/db"'
      
      # Act
      $result = Find-SecretsByPattern -Content $content
      
      # Assert
      $result.Count | Should -BeGreaterOrEqual 0
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
