#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard MCPIntegration module

.DESCRIPTION
    Comprehensive unit tests for MCPIntegration.psm1 functions:
    - Initialize-MCPConfiguration
    - Add-MCPServer
    - Invoke-MCPQuery
    - Enable-MCPIntegration
    
    Tests cover happy paths, edge cases, error conditions, and parameter validation.
    All tests are hermetic using TestDrive and mocks.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import MCPIntegration module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/MCPIntegration.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find MCPIntegration module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Initialize-MCPConfiguration' -Tag 'Unit', 'MCPIntegration' {
  
  Context 'When config file does not exist' {
    It 'Should initialize with default disabled state' {
      InModuleScope MCPIntegration {
        Mock Test-Path { return $false }
        
        { Initialize-MCPConfiguration } | Should -Not -Throw
        
        $script:MCPConfig.Enabled | Should -Be $false
      }
    }
  }

  Context 'When config file exists and is valid' {
    It 'Should load configuration from file' {
      InModuleScope MCPIntegration {
        $testConfig = @{
          Enabled = $true
          UserConsent = $true
          Servers = @(
            @{ Name = 'TestServer'; Type = 'Custom'; Endpoint = 'http://test' }
          )
        } | ConvertTo-Json

        Mock Test-Path { return $true }
        Mock Get-Content { return $testConfig }
        
        { Initialize-MCPConfiguration } | Should -Not -Throw
        
        $script:MCPConfig.Enabled | Should -Be $true
        $script:MCPConfig.UserConsent | Should -Be $true
      }
    }
  }

  Context 'When config file is malformed' {
    It 'Should handle JSON parse errors gracefully' {
      InModuleScope MCPIntegration {
        Mock Test-Path { return $true }
        Mock Get-Content { return 'invalid json{' }
        
        { Initialize-MCPConfiguration } | Should -Not -Throw
      }
    }
  }
}

Describe 'Add-MCPServer' -Tag 'Unit', 'MCPIntegration' {
  
  BeforeEach {
    InModuleScope MCPIntegration {
      $script:MCPConfig = @{
        Enabled = $false
        Servers = @()
        CachePath = "./cache/mcp"
        CacheExpirationHours = 24
        Timeout = 5000
        RetryCount = 2
        UserConsent = $false
      }
    }
  }

  Context 'When adding valid servers' {
    It 'Should add server of type <Type>' -TestCases @(
      @{ Type = 'Context7' }
      @{ Type = 'GitHub' }
      @{ Type = 'Filesystem' }
      @{ Type = 'Custom' }
    ) {
      param($Type)
      
      InModuleScope MCPIntegration -Parameters @{ Type = $Type } {
        param($Type)
        Add-MCPServer -Name "TestServer" -Type $Type -Endpoint "http://test"
        
        $script:MCPConfig.Servers.Count | Should -Be 1
        $script:MCPConfig.Servers[0].Type | Should -Be $Type
        $script:MCPConfig.Servers[0].Name | Should -Be "TestServer"
      }
    }

    It 'Should add server with ApiKey' {
      InModuleScope MCPIntegration {
        $secureKey = ConvertTo-SecureString -String "test-key" -AsPlainText -Force
        
        Add-MCPServer -Name "TestServer" -Type "Context7" -Endpoint "http://test" -ApiKey $secureKey
        
        $script:MCPConfig.Servers.Count | Should -Be 1
        $script:MCPConfig.Servers[0].ApiKey | Should -Not -BeNullOrEmpty
      }
    }

    It 'Should add multiple servers' {
      InModuleScope MCPIntegration {
        Add-MCPServer -Name "Server1" -Type "Context7" -Endpoint "http://test1"
        Add-MCPServer -Name "Server2" -Type "GitHub" -Endpoint "http://test2"
        
        $script:MCPConfig.Servers.Count | Should -Be 2
      }
    }
  }

  Context 'When parameters are invalid' {
    It 'Should throw on missing mandatory parameter Name' {
      { Add-MCPServer -Type "Context7" -Endpoint "http://test" -ErrorAction Stop } | Should -Throw
    }

    It 'Should throw on missing mandatory parameter Type' {
      { Add-MCPServer -Name "Test" -Endpoint "http://test" -ErrorAction Stop } | Should -Throw
    }

    It 'Should throw on invalid Type value' {
      { Add-MCPServer -Name "Test" -Type "InvalidType" -Endpoint "http://test" -ErrorAction Stop } | Should -Throw
    }
  }
}

Describe 'Invoke-MCPQuery' -Tag 'Unit', 'MCPIntegration' {
  
  BeforeEach {
    InModuleScope MCPIntegration {
      $script:MCPConfig = @{
        Enabled = $true
        Servers = @(
          @{ Name = 'TestServer'; Type = 'Context7'; Endpoint = 'http://test'; Enabled = $true; Priority = 1 }
        )
        CachePath = "./cache/mcp"
        CacheExpirationHours = 24
        Timeout = 5000
        RetryCount = 2
        UserConsent = $true
      }
      $script:MCPCache = @{}
    }
  }

  Context 'When MCP is disabled' {
    It 'Should return null when MCP is disabled' {
      InModuleScope MCPIntegration {
        $script:MCPConfig.Enabled = $false
        
        $result = Invoke-MCPQuery -Query "test query"
        
        $result | Should -BeNullOrEmpty
      }
    }

    It 'Should return null when user consent is not granted' {
      InModuleScope MCPIntegration {
        $script:MCPConfig.UserConsent = $false
        
        $result = Invoke-MCPQuery -Query "test query"
        
        $result | Should -BeNullOrEmpty
      }
    }
  }

  Context 'When querying with cache' {
    It 'Should use cached response when available and fresh' {
      InModuleScope MCPIntegration {
        $cachedResponse = [PSCustomObject]@{ Data = "cached" }
        $cacheKey = "All|test query"
        $script:MCPCache[$cacheKey] = @{
          Timestamp = (Get-Date)
          Response = $cachedResponse
        }
        
        Mock Invoke-MCPServerQuery { throw "Should not be called" }
        
        $result = Invoke-MCPQuery -Query "test query"
        
        $result.Data | Should -Be "cached"
      }
    }

    It 'Should refresh cache when expired' {
      InModuleScope MCPIntegration {
        $oldResponse = [PSCustomObject]@{ Data = "old" }
        $cacheKey = "All|test query"
        $script:MCPCache[$cacheKey] = @{
          Timestamp = (Get-Date).AddHours(-25)  # Expired
          Response = $oldResponse
        }
        
        Mock Invoke-MCPServerQuery { return [PSCustomObject]@{ Data = "new" } }
        Mock Merge-MCPResponses { return $args[0][0] }
        
        $result = Invoke-MCPQuery -Query "test query"
        
        $result.Data | Should -Be "new"
      }
    }
  }

  Context 'When querying servers' {
    It 'Should query all enabled servers by default' {
      InModuleScope MCPIntegration {
        $script:MCPConfig.Servers = @(
          @{ Name = 'Server1'; Type = 'Context7'; Endpoint = 'http://test1'; Enabled = $true; Priority = 1 }
          @{ Name = 'Server2'; Type = 'GitHub'; Endpoint = 'http://test2'; Enabled = $true; Priority = 2 }
        )
        
        $queryCount = 0
        Mock Invoke-MCPServerQuery { 
          $script:queryCount++
          return [PSCustomObject]@{ Data = "response$queryCount" }
        }
        Mock Merge-MCPResponses { return [PSCustomObject]@{ Data = "merged" } }
        
        $result = Invoke-MCPQuery -Query "test query"
        
        $queryCount | Should -Be 2
      }
    }

    It 'Should skip disabled servers' {
      InModuleScope MCPIntegration {
        $script:MCPConfig.Servers = @(
          @{ Name = 'Server1'; Type = 'Context7'; Endpoint = 'http://test1'; Enabled = $true; Priority = 1 }
          @{ Name = 'Server2'; Type = 'GitHub'; Endpoint = 'http://test2'; Enabled = $false; Priority = 2 }
        )
        
        $queryCount = 0
        Mock Invoke-MCPServerQuery { 
          $script:queryCount++
          return [PSCustomObject]@{ Data = "response" }
        }
        Mock Merge-MCPResponses { return [PSCustomObject]@{ Data = "merged" } }
        
        $result = Invoke-MCPQuery -Query "test query"
        
        $queryCount | Should -Be 1
      }
    }

    It 'Should handle server query failures gracefully' {
      InModuleScope MCPIntegration {
        Mock Invoke-MCPServerQuery { throw "Server error" }
        
        $result = Invoke-MCPQuery -Query "test query"
        
        $result | Should -BeNullOrEmpty
      }
    }
  }

  Context 'When filtering by server type' {
    It 'Should query only specified server type' {
      InModuleScope MCPIntegration {
        $script:MCPConfig.Servers = @(
          @{ Name = 'Server1'; Type = 'Context7'; Endpoint = 'http://test1'; Enabled = $true; Priority = 1 }
          @{ Name = 'Server2'; Type = 'GitHub'; Endpoint = 'http://test2'; Enabled = $true; Priority = 2 }
        )
        
        $queriedTypes = @()
        Mock Invoke-MCPServerQuery { 
          $queriedTypes += $Server.Type
          return [PSCustomObject]@{ Data = "response" }
        }
        Mock Merge-MCPResponses { return [PSCustomObject]@{ Data = "merged" } }
        
        $result = Invoke-MCPQuery -Query "test query" -ServerType "Context7"
        
        $queriedTypes.Count | Should -Be 1
        $queriedTypes[0] | Should -Be "Context7"
      }
    }
  }

  Context 'When providing context' {
    It 'Should pass context to server query' {
      InModuleScope MCPIntegration {
        $contextPassed = $null
        Mock Invoke-MCPServerQuery { 
          $script:contextPassed = $Context
          return [PSCustomObject]@{ Data = "response" }
        }
        Mock Merge-MCPResponses { return [PSCustomObject]@{ Data = "merged" } }
        
        $testContext = @{ FilePath = "test.ps1"; RuleName = "TestRule" }
        $result = Invoke-MCPQuery -Query "test query" -Context $testContext
        
        $contextPassed.FilePath | Should -Be "test.ps1"
        $contextPassed.RuleName | Should -Be "TestRule"
      }
    }
  }
}

Describe 'Enable-MCPIntegration' -Tag 'Unit', 'MCPIntegration' {
  
  BeforeEach {
    InModuleScope MCPIntegration {
      $script:MCPConfig = @{
        Enabled = $false
        Servers = @()
        CachePath = "./cache/mcp"
        CacheExpirationHours = 24
        Timeout = 5000
        RetryCount = 2
        UserConsent = $false
      }
    }
  }

  Context 'When enabling MCP integration' {
    It 'Should enable MCP when consent is granted' {
      InModuleScope MCPIntegration {
        Enable-MCPIntegration -Consent
        
        $script:MCPConfig.Enabled | Should -Be $true
        $script:MCPConfig.UserConsent | Should -Be $true
      }
    }

    It 'Should disable MCP when called without consent' {
      InModuleScope MCPIntegration {
        $script:MCPConfig.Enabled = $true
        $script:MCPConfig.UserConsent = $true
        
        Enable-MCPIntegration
        
        $script:MCPConfig.Enabled | Should -Be $false
        $script:MCPConfig.UserConsent | Should -Be $false
      }
    }
  }
}
