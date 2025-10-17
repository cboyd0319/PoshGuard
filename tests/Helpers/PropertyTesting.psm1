<#
.SYNOPSIS
    Property-based testing utilities for generating test data

.DESCRIPTION
    Provides functions for generating random but deterministic test data
    for property-based testing patterns. All functions support seeded
    random generation for reproducibility.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Version: 1.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RandomString {
  <#
  .SYNOPSIS
      Generate random strings with controlled characteristics
  
  .DESCRIPTION
      Creates random strings with specified length range and character sets.
      Supports seeding for deterministic generation in tests.
  
  .PARAMETER MinLength
      Minimum string length
  
  .PARAMETER MaxLength
      Maximum string length
  
  .PARAMETER CharacterSet
      Type of characters to include in the string
  
  .PARAMETER Seed
      Random seed for deterministic generation
  
  .EXAMPLE
      $str = Get-RandomString -MinLength 10 -MaxLength 20 -CharacterSet 'Alphanumeric' -Seed 42
  
  .EXAMPLE
      $base64 = Get-RandomString -MinLength 32 -MaxLength 32 -CharacterSet 'Base64' -Seed 123
  
  .OUTPUTS
      String with random content
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter()]
    [ValidateRange(0, 10000)]
    [int]$MinLength = 1,
    
    [Parameter()]
    [ValidateRange(1, 10000)]
    [int]$MaxLength = 100,
    
    [Parameter()]
    [ValidateSet('Alphanumeric', 'Ascii', 'Unicode', 'Base64', 'Hex', 'LowEntropy', 'HighEntropy')]
    [string]$CharacterSet = 'Alphanumeric',
    
    [Parameter()]
    [int]$Seed
  )
  
  if ($Seed) {
    Get-Random -SetSeed $Seed | Out-Null
  }
  
  $length = Get-Random -Minimum $MinLength -Maximum ($MaxLength + 1)
  
  if ($length -eq 0) {
    return ''
  }
  
  $chars = switch ($CharacterSet) {
    'Alphanumeric' {
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    }
    'Ascii' {
      -join (32..126 | ForEach-Object { [char]$_ })
    }
    'Unicode' {
      # Mix of ASCII and common Unicode characters
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ'
    }
    'Base64' {
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
    }
    'Hex' {
      '0123456789ABCDEF'
    }
    'LowEntropy' {
      # Repeated characters for low entropy
      'aaaaaaaaaa'
    }
    'HighEntropy' {
      # Mix for high entropy
      '!@#$%^&*()_+-=[]{}|;:,.<>?/~`ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    }
  }
  
  $result = -join (1..$length | ForEach-Object {
      $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
    })
  
  return $result
}

function Get-RandomInteger {
  <#
  .SYNOPSIS
      Generate random integers within a range
  
  .PARAMETER Minimum
      Minimum value (inclusive)
  
  .PARAMETER Maximum
      Maximum value (inclusive)
  
  .PARAMETER Seed
      Random seed for deterministic generation
  
  .EXAMPLE
      $num = Get-RandomInteger -Minimum 1 -Maximum 100 -Seed 42
  
  .OUTPUTS
      Integer within specified range
  #>
  [CmdletBinding()]
  [OutputType([int])]
  param(
    [Parameter()]
    [int]$Minimum = 0,
    
    [Parameter()]
    [int]$Maximum = 100,
    
    [Parameter()]
    [int]$Seed
  )
  
  if ($Seed) {
    Get-Random -SetSeed $Seed | Out-Null
  }
  
  return Get-Random -Minimum $Minimum -Maximum ($Maximum + 1)
}

function Get-RandomBoolean {
  <#
  .SYNOPSIS
      Generate random boolean value
  
  .PARAMETER Seed
      Random seed for deterministic generation
  
  .EXAMPLE
      $bool = Get-RandomBoolean -Seed 42
  
  .OUTPUTS
      Boolean value
  #>
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter()]
    [int]$Seed
  )
  
  if ($Seed) {
    Get-Random -SetSeed $Seed | Out-Null
  }
  
  return (Get-Random -Minimum 0 -Maximum 2) -eq 1
}

function Get-TestCaseMatrix {
  <#
  .SYNOPSIS
      Generate test case matrices for -TestCases parameter
  
  .DESCRIPTION
      Creates Cartesian product of input dimensions to generate comprehensive
      test case matrices for Pester -TestCases parameter.
  
  .PARAMETER Dimensions
      Array of hashtables, each representing a dimension with possible values
  
  .EXAMPLE
      $cases = Get-TestCaseMatrix -Dimensions @(
          @{ Name = 'Type'; Values = @('String', 'Int', 'Bool') },
          @{ Name = 'Valid'; Values = @($true, $false) }
      )
      # Returns 6 test cases (3 × 2)
  
  .OUTPUTS
      Array of hashtables for use with Pester -TestCases
  #>
  [CmdletBinding()]
  [OutputType([hashtable[]])]
  param(
    [Parameter(Mandatory)]
    [hashtable[]]$Dimensions
  )
  
  if ($Dimensions.Count -eq 0) {
    return @()
  }
  
  if ($Dimensions.Count -eq 1) {
    return $Dimensions[0].Values | ForEach-Object {
      @{ $Dimensions[0].Name = $_ }
    }
  }
  
  # Recursive Cartesian product
  $firstDim = $Dimensions[0]
  $remainingDims = $Dimensions[1..($Dimensions.Count - 1)]
  $subCases = Get-TestCaseMatrix -Dimensions $remainingDims
  
  $result = @()
  foreach ($value in $firstDim.Values) {
    foreach ($subCase in $subCases) {
      $newCase = @{ $firstDim.Name = $value }
      foreach ($key in $subCase.Keys) {
        $newCase[$key] = $subCase[$key]
      }
      $result += $newCase
    }
  }
  
  return $result
}

function Get-RandomSecret {
  <#
  .SYNOPSIS
      Generate random secret-like strings for testing
  
  .DESCRIPTION
      Creates strings that resemble various types of secrets (API keys, tokens, etc.)
      for testing secret detection functionality.
  
  .PARAMETER Type
      Type of secret to generate
  
  .PARAMETER Seed
      Random seed for deterministic generation
  
  .EXAMPLE
      $apiKey = Get-RandomSecret -Type 'GitHubToken' -Seed 42
  
  .OUTPUTS
      String resembling a secret
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter()]
    [ValidateSet('GitHubToken', 'AWSAccessKey', 'AzureKey', 'JWTToken', 'Base64Secret', 'HexSecret', 'APIKey')]
    [string]$Type = 'APIKey',
    
    [Parameter()]
    [int]$Seed
  )
  
  if ($Seed) {
    Get-Random -SetSeed $Seed | Out-Null
  }
  
  $secret = switch ($Type) {
    'GitHubToken' {
      'ghp_' + (Get-RandomString -MinLength 36 -MaxLength 36 -CharacterSet 'Alphanumeric' -Seed $Seed)
    }
    'AWSAccessKey' {
      'AKIA' + (Get-RandomString -MinLength 16 -MaxLength 16 -CharacterSet 'Alphanumeric' -Seed $Seed).ToUpper()
    }
    'AzureKey' {
      Get-RandomString -MinLength 44 -MaxLength 44 -CharacterSet 'Base64' -Seed $Seed
    }
    'JWTToken' {
      $header = Get-RandomString -MinLength 20 -MaxLength 20 -CharacterSet 'Base64' -Seed $Seed
      $payload = Get-RandomString -MinLength 30 -MaxLength 30 -CharacterSet 'Base64' -Seed $Seed
      $signature = Get-RandomString -MinLength 25 -MaxLength 25 -CharacterSet 'Base64' -Seed $Seed
      "$header.$payload.$signature"
    }
    'Base64Secret' {
      Get-RandomString -MinLength 32 -MaxLength 64 -CharacterSet 'Base64' -Seed $Seed
    }
    'HexSecret' {
      Get-RandomString -MinLength 32 -MaxLength 64 -CharacterSet 'Hex' -Seed $Seed
    }
    'APIKey' {
      Get-RandomString -MinLength 32 -MaxLength 48 -CharacterSet 'HighEntropy' -Seed $Seed
    }
  }
  
  return $secret
}

function Get-BoundaryValues {
  <#
  .SYNOPSIS
      Get boundary values for testing numeric ranges
  
  .DESCRIPTION
      Returns boundary values (min, min+1, mid, max-1, max) for testing
      numeric validation and edge cases.
  
  .PARAMETER Minimum
      Minimum value in range
  
  .PARAMETER Maximum
      Maximum value in range
  
  .PARAMETER IncludeInvalid
      Include invalid values (below min, above max)
  
  .EXAMPLE
      $values = Get-BoundaryValues -Minimum 0 -Maximum 100 -IncludeInvalid
  
  .OUTPUTS
      Array of boundary values
  #>
  [CmdletBinding()]
  [OutputType([int[]])]
  param(
    [Parameter(Mandatory)]
    [int]$Minimum,
    
    [Parameter(Mandatory)]
    [int]$Maximum,
    
    [Parameter()]
    [switch]$IncludeInvalid
  )
  
  $values = @(
    $Minimum,
    $Minimum + 1,
    [Math]::Floor(($Minimum + $Maximum) / 2),
    $Maximum - 1,
    $Maximum
  )
  
  if ($IncludeInvalid) {
    $values = @($Minimum - 1) + $values + @($Maximum + 1)
  }
  
  return $values | Select-Object -Unique
}

function Get-StringBoundaryValues {
  <#
  .SYNOPSIS
      Get boundary string values for testing
  
  .DESCRIPTION
      Returns string values representing common edge cases:
      null, empty, whitespace, single char, very long, unicode, etc.
  
  .PARAMETER MaxLength
      Maximum length for "very long" string
  
  .PARAMETER Seed
      Random seed for deterministic generation
  
  .EXAMPLE
      $strings = Get-StringBoundaryValues -MaxLength 1000
  
  .OUTPUTS
      Array of test strings
  #>
  [CmdletBinding()]
  [OutputType([object[]])]
  param(
    [Parameter()]
    [int]$MaxLength = 1000,
    
    [Parameter()]
    [int]$Seed
  )
  
  if ($Seed) {
    Get-Random -SetSeed $Seed | Out-Null
  }
  
  $values = @(
    $null,
    '',
    ' ',
    '  ',
    "`t",
    "`n",
    'a',
    'abc',
    'Hello World',
    (Get-RandomString -MinLength $MaxLength -MaxLength $MaxLength -CharacterSet 'Alphanumeric' -Seed $Seed),
    'Ñoño',  # Unicode
    '你好',   # Chinese
    '🎉🎊',   # Emoji
    "Line1`nLine2",  # Multiline
    '"quoted"',
    "'quoted'",
    '$variable',
    '$(command)',
    'path\to\file',
    'C:\Windows\System32'
  )
  
  return $values
}

# Export functions
Export-ModuleMember -Function @(
  'Get-RandomString',
  'Get-RandomInteger',
  'Get-RandomBoolean',
  'Get-TestCaseMatrix',
  'Get-RandomSecret',
  'Get-BoundaryValues',
  'Get-StringBoundaryValues'
)
