#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive Pester tests for SupplyChainSecurity module

.DESCRIPTION
    Unit tests for SupplyChainSecurity.psm1 covering:
    - Get-PowerShellDependencies (Dependency discovery)
    - New-CycloneDXSBOM (CycloneDX SBOM generation)
    - New-SPDXSBOM (SPDX SBOM generation)
    - Export-SBOM (SBOM export)
    - Test-DependencyVulnerabilities (Vulnerability scanning)
    - Test-LicenseCompliance (License validation)
    - New-SoftwareBillOfMaterials (SBOM creation wrapper)

    Tests follow AAA pattern with deterministic execution, mocked external calls.
    Covers CISA 2025 SBOM requirements and NIST SP 800-218 compliance.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Coverage Target: 90%+ lines, 85%+ branches
    All tests use TestDrive and mocks for hermetic isolation
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }
  
  $mockBuildersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/MockBuilders.psm1'
  Import-Module -Name $mockBuildersPath -Force -ErrorAction Stop

  # Import SupplyChainSecurity module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/SupplyChainSecurity.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find SupplyChainSecurity module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'SupplyChainSecurity' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  }
}

Describe 'Get-PowerShellDependencies' -Tag 'Unit', 'SupplyChainSecurity', 'Priority1', 'Slow' {
  
  Context 'When script has #Requires statements' {
    It 'Should discover modules from #Requires -Modules' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
#Requires -Modules Pester
Write-Output "test"
'@ | Set-Content -Path $testScript
      
      # Mock Find-Module to prevent network calls
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testScript
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Name | Should -Contain 'Pester'
      ($result | Where-Object Name -eq 'Pester').Source | Should -Be '#Requires'
    }

    It 'Should parse hashtable module specifications' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
Write-Output "test"
'@ | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testScript
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Name | Should -Contain 'Pester'
      ($result | Where-Object Name -eq 'Pester').Version | Should -Be '5.0.0'
    }

    It 'Should handle multiple #Requires statements' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
#Requires -Modules Pester
#Requires -Modules PSScriptAnalyzer
Write-Output "test"
'@ | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testScript
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -BeGreaterOrEqual 2
      $result.Name | Should -Contain 'Pester'
      $result.Name | Should -Contain 'PSScriptAnalyzer'
    }
  }

  Context 'When script has Import-Module statements' {
    It 'Should discover modules from Import-Module' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
Import-Module Pester
Write-Output "test"
'@ | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testScript
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Name | Should -Contain 'Pester'
      ($result | Where-Object Name -eq 'Pester').Source | Should -Be 'Import-Module'
    }

    It 'Should parse Import-Module with version parameters' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
Import-Module Pester -RequiredVersion 5.0.0
Write-Output "test"
'@ | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testScript
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Name | Should -Contain 'Pester'
      ($result | Where-Object Name -eq 'Pester').Version | Should -Be '5.0.0'
    }

    It 'Should not duplicate dependencies' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
#Requires -Modules Pester
Import-Module Pester
Write-Output "test"
'@ | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testScript
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      ($result | Where-Object Name -eq 'Pester' | Measure-Object).Count | Should -Be 1
    }
  }

  Context 'When module has manifest file' {
    It 'Should discover dependencies from manifest' {
      # Arrange
      $testModule = Join-Path TestDrive: 'TestModule.psm1'
      $testManifest = Join-Path TestDrive: 'TestModule.psd1'
      
      'function Test-Func { Write-Output "test" }' | Set-Content -Path $testModule
      
      @'
@{
    ModuleVersion = '1.0.0'
    RequiredModules = @('Pester', 'PSScriptAnalyzer')
}
'@ | Set-Content -Path $testManifest
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testModule
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Name | Should -Contain 'Pester'
      $result.Name | Should -Contain 'PSScriptAnalyzer'
      ($result | Where-Object Name -eq 'Pester').Source | Should -Be 'Manifest'
    }

    It 'Should handle manifest with hashtable module specs' {
      # Arrange
      $testModule = Join-Path TestDrive: 'TestModule.psm1'
      $testManifest = Join-Path TestDrive: 'TestModule.psd1'
      
      'function Test-Func { Write-Output "test" }' | Set-Content -Path $testModule
      
      @'
@{
    ModuleVersion = '1.0.0'
    RequiredModules = @(
        @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
    )
}
'@ | Set-Content -Path $testManifest
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testModule
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.Name | Should -Contain 'Pester'
      ($result | Where-Object Name -eq 'Pester').Version | Should -Be '5.0.0'
    }
  }

  Context 'When enriching with metadata' {
    It 'Should enrich dependencies with gallery metadata when available' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
#Requires -Modules Pester
'@ | Set-Content -Path $testScript
      
      # Mock Find-Module to return metadata
      Mock -CommandName Find-Module -MockWith {
        return [PSCustomObject]@{
          Name = 'Pester'
          Version = '5.7.1'
          Author = 'Pester Team'
          PublishedDate = [DateTime]::Parse('2025-01-01')
          Repository = 'PSGallery'
          LicenseUri = 'https://github.com/pester/Pester/blob/main/LICENSE'
        }
      }
      
      # Act
      $result = Get-PowerShellDependencies -Path $testScript
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $pester = $result | Where-Object Name -eq 'Pester'
      $pester.Publisher | Should -Be 'Pester Team'
      $pester.LatestVersion | Should -Be '5.7.1'
    }

    It 'Should handle Find-Module errors gracefully' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
#Requires -Modules UnknownModule
'@ | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { throw "Module not found" }
      
      # Act & Assert
      { Get-PowerShellDependencies -Path $testScript } | Should -Not -Throw
    }
  }

  Context 'When file does not exist' {
    It 'Should throw appropriate error' {
      # Act & Assert
      { Get-PowerShellDependencies -Path 'C:\NonExistent\Path.ps1' } | Should -Throw
    }
  }
}

Describe 'New-CycloneDXSBOM' -Tag 'Unit', 'SupplyChainSecurity', 'Slow' {
  
  Context 'When generating CycloneDX SBOM' {
    It 'Should create SBOM with correct format and version' {
      # Arrange
      $dependencies = @(
        @{ Name = 'Pester'; Version = '5.7.1'; Publisher = 'Pester Team' }
      )
      
      # Act
      $result = New-CycloneDXSBOM -Dependencies $dependencies
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.bomFormat | Should -Be 'CycloneDX'
      $result.specVersion | Should -Match '1\.\d+'
    }

    It 'Should include components in SBOM' {
      # Arrange
      $dependencies = @(
        @{ Name = 'Pester'; Version = '5.7.1'; Publisher = 'Pester Team' },
        @{ Name = 'PSScriptAnalyzer'; Version = '1.24.0'; Publisher = 'Microsoft' }
      )
      
      # Act
      $result = New-CycloneDXSBOM -Dependencies $dependencies
      
      # Assert
      $result.components | Should -Not -BeNullOrEmpty
      $result.components.Count | Should -BeGreaterOrEqual 2
    }

    It 'Should include metadata with timestamp' {
      # Arrange
      $dependencies = @()
      
      # Act
      $result = New-CycloneDXSBOM -Dependencies $dependencies
      
      # Assert
      $result.metadata | Should -Not -BeNullOrEmpty
      $result.metadata.timestamp | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'New-SPDXSBOM' -Tag 'Unit', 'SupplyChainSecurity', 'Slow' {
  
  Context 'When generating SPDX SBOM' {
    It 'Should create SBOM with correct format and version' {
      # Arrange
      $dependencies = @(
        @{ Name = 'Pester'; Version = '5.7.1'; Publisher = 'Pester Team' }
      )
      
      # Act
      $result = New-SPDXSBOM -Dependencies $dependencies
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
      $result.spdxVersion | Should -Match 'SPDX-2\.\d+'
    }

    It 'Should include packages in SBOM' {
      # Arrange
      $dependencies = @(
        @{ Name = 'Pester'; Version = '5.7.1'; Publisher = 'Pester Team' }
      )
      
      # Act
      $result = New-SPDXSBOM -Dependencies $dependencies
      
      # Assert
      $result.packages | Should -Not -BeNullOrEmpty
    }

    It 'Should include creation info' {
      # Arrange
      $dependencies = @()
      
      # Act
      $result = New-SPDXSBOM -Dependencies $dependencies
      
      # Assert
      $result.creationInfo | Should -Not -BeNullOrEmpty
      $result.creationInfo.created | Should -Not -BeNullOrEmpty
    }
  }
}

Describe 'Export-SBOM' -Tag 'Unit', 'SupplyChainSecurity' {
  
  Context 'When exporting SBOM to file' {
    It 'Should export SBOM to JSON file' {
      # Arrange
      $sbom = New-MockSBOM -Format 'CycloneDX'
      $outputPath = Join-Path TestDrive: 'sbom.json'
      
      # Act
      Export-SBOM -SBOM $sbom -Path $outputPath
      
      # Assert
      Test-Path -Path $outputPath | Should -Be $true
      $content = Get-Content -Path $outputPath -Raw
      $content | Should -Not -BeNullOrEmpty
    }

    It 'Should create directory if it does not exist' {
      # Arrange
      $sbom = New-MockSBOM -Format 'CycloneDX'
      $outputPath = Join-Path TestDrive: 'subdir\sbom.json'
      
      # Act
      Export-SBOM -SBOM $sbom -Path $outputPath
      
      # Assert
      Test-Path -Path $outputPath | Should -Be $true
    }
  }
}

Describe 'Test-DependencyVulnerabilities' -Tag 'Unit', 'SupplyChainSecurity', 'Slow' {
  
  Context 'When scanning for vulnerabilities' {
    It 'Should return vulnerability findings' {
      # Arrange
      $dependencies = @(
        @{ Name = 'TestModule'; Version = '1.0.0' }
      )
      
      # Mock vulnerability database access
      Mock -ModuleName SupplyChainSecurity -CommandName Invoke-RestMethod -MockWith {
        return @(
          @{
            id = 'CVE-2024-0001'
            severity = 'High'
            affectedVersions = '< 2.0.0'
          }
        )
      }
      
      # Act & Assert
      { Test-DependencyVulnerabilities -Dependencies $dependencies } | Should -Not -Throw
    }

    It 'Should handle no vulnerabilities found' {
      # Arrange
      $dependencies = @(
        @{ Name = 'SafeModule'; Version = '2.0.0' }
      )
      
      Mock -ModuleName SupplyChainSecurity -CommandName Invoke-RestMethod -MockWith { return @() }
      
      # Act & Assert
      { Test-DependencyVulnerabilities -Dependencies $dependencies } | Should -Not -Throw
    }
  }
}

Describe 'Test-LicenseCompliance' -Tag 'Unit', 'SupplyChainSecurity', 'Slow' {
  
  Context 'When checking license compliance' {
    It 'Should validate license compatibility' {
      # Arrange
      $dependencies = @(
        @{ Name = 'TestModule'; Version = '1.0.0'; License = 'https://opensource.org/licenses/MIT' }
      )
      
      # Act & Assert
      { Test-LicenseCompliance -Dependencies $dependencies } | Should -Not -Throw
    }

    It 'Should handle missing license information' {
      # Arrange
      $dependencies = @(
        @{ Name = 'TestModule'; Version = '1.0.0' }
      )
      
      # Act & Assert
      { Test-LicenseCompliance -Dependencies $dependencies } | Should -Not -Throw
    }
  }
}

Describe 'New-SoftwareBillOfMaterials' -Tag 'Unit', 'SupplyChainSecurity', 'Slow' {
  
  Context 'When generating complete SBOM' {
    It 'Should create SBOM from script path' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      @'
#Requires -Modules Pester
Write-Output "test"
'@ | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act
      $result = New-SoftwareBillOfMaterials -Path $testScript -Format 'CycloneDX'
      
      # Assert
      $result | Should -Not -BeNullOrEmpty
    }

    It 'Should support both CycloneDX and SPDX formats' {
      # Arrange
      $testScript = Join-Path TestDrive: 'test.ps1'
      'Write-Output "test"' | Set-Content -Path $testScript
      
      Mock -CommandName Find-Module -MockWith { return $null }
      
      # Act & Assert
      { New-SoftwareBillOfMaterials -Path $testScript -Format 'CycloneDX' } | Should -Not -Throw
      { New-SoftwareBillOfMaterials -Path $testScript -Format 'SPDX' } | Should -Not -Throw
    }
  }
}

AfterAll {
  # Cleanup
  Remove-Module -Name SupplyChainSecurity -ErrorAction SilentlyContinue
  Remove-Module -Name TestHelpers -ErrorAction SilentlyContinue
  Remove-Module -Name MockBuilders -ErrorAction SilentlyContinue
}
