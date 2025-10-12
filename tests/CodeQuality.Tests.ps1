#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for Beyond-PSSA Code Quality enhancements

.DESCRIPTION
    Tests for v3.2.0 community-requested features:
    - TODO/FIXME comment detection
    - Unused namespace optimization
    - ASCII character warnings
    - Get-Content | ConvertFrom-Json optimization
    - SecureString disclosure detection

.NOTES
    Part of PoshGuard v3.2.0 - Innovation leadership in PowerShell tooling
#>

BeforeAll {
    # Import the CodeQuality module
    $modulePath = Join-Path $PSScriptRoot '../tools/lib/BestPractices/CodeQuality.psm1'
    if (-not (Test-Path $modulePath)) {
        throw "Cannot find CodeQuality module at: $modulePath"
    }
    Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'Beyond-PSSA Code Quality Enhancements' {
    
    Context 'Invoke-TodoCommentDetectionFix' {
        
        It 'Should standardize TODO comments' {
            $input = @'
# todo fix this later
function Test-Function {
    # FIXME performance issue
}
'@
            $result = Invoke-TodoCommentDetectionFix -Content $input
            
            # Should convert to standard format
            $result | Should -Match '# TODO: fix this later'
            $result | Should -Match '# FIXME: performance issue'
        }
        
        It 'Should handle various comment formats' {
            $input = @'
# TODO:needs spaces
#FIXME no space after hash
# hack this is temporary
'@
            $result = Invoke-TodoCommentDetectionFix -Content $input
            
            # Should standardize all formats
            $result | Should -Match '# TODO:'
            $result | Should -Match '# FIXME:'
            $result | Should -Match '# HACK:'
        }
        
        It 'Should preserve already formatted comments' {
            $input = @'
# TODO: This is already correct
# FIXME: So is this
'@
            $result = Invoke-TodoCommentDetectionFix -Content $input
            
            # Should remain unchanged
            $result | Should -BeExactly $input
        }
        
        It 'Should handle empty TODO descriptions' {
            $input = @'
# TODO
function Test {}
'@
            $result = Invoke-TodoCommentDetectionFix -Content $input
            
            # Should add default description
            $result | Should -Match 'TODO: Review and address this item'
        }
    }
    
    Context 'Invoke-UnusedNamespaceDetectionFix' {
        
        It 'Should detect and warn about unused namespaces' {
            $input = @'
using namespace System.Collections.Generic
using namespace System.Net

function Test-Function {
    $list = [Generic.List[int]]::new()
}
'@
            $result = Invoke-UnusedNamespaceDetectionFix -Content $input
            
            # System.Net is not used, should get a warning
            $result | Should -Match '# REVIEW: Namespace may be unused.*System.Net'
            # Generic is used, should NOT get a warning
            $result | Should -Not -Match '# REVIEW.*System.Collections.Generic'
            # Both using statements should still be present
            $result | Should -Match 'using namespace System.Collections.Generic'
            $result | Should -Match 'using namespace System.Net'
        }
        
        It 'Should not warn about used namespaces' {
            $input = @'
using namespace System.Collections.Generic

function Test-Function {
    $list = [Generic.List[string]]::new()
    $list.Add("test")
}
'@
            $result = Invoke-UnusedNamespaceDetectionFix -Content $input
            
            # Should not add review warning for used namespace
            $result | Should -Not -Match '# REVIEW'
            $result | Should -Match 'using namespace System.Collections.Generic'
        }
        
        It 'Should handle scripts without namespace imports' {
            $input = @'
function Test-Function {
    Write-Output "No namespaces here"
}
'@
            $result = Invoke-UnusedNamespaceDetectionFix -Content $input
            
            # Should remain unchanged
            $result | Should -BeExactly $input
        }
    }
    
    Context 'Invoke-AsciiCharacterWarningFix' {
        
        It 'Should detect non-ASCII characters' {
            $input = @'
Write-Host "Hello—world"
$text = "Smart quotes"
'@
            $result = Invoke-AsciiCharacterWarningFix -Content $input
            
            # Should add warnings for non-ASCII characters
            $result | Should -Match 'WARNING: Non-ASCII character detected'
            $result | Should -Match 'U\+[0-9A-F]{4}'
        }
        
        It 'Should not modify ASCII-only content' {
            $input = @'
Write-Host "Hello world"
$text = "Regular quotes"
'@
            $result = Invoke-AsciiCharacterWarningFix -Content $input
            
            # Should remain unchanged
            $result | Should -BeExactly $input
        }
        
        It 'Should not duplicate warnings' {
            $input = @'
Write-Host "Hello—world"  # WARNING: Non-ASCII character detected (U+2014). Consider using ASCII equivalent.
'@
            $result = Invoke-AsciiCharacterWarningFix -Content $input
            
            # Should not add duplicate warning
            $result | Should -BeExactly $input
        }
    }
    
    Context 'Invoke-ConvertFromJsonOptimizationFix' {
        
        It 'Should add -Raw to Get-Content | ConvertFrom-Json' {
            $input = @'
$config = Get-Content "config.json" | ConvertFrom-Json
$data = Get-Content $path | ConvertFrom-Json
'@
            $result = Invoke-ConvertFromJsonOptimizationFix -Content $input
            
            # Should add -Raw parameter
            $result | Should -Match 'Get-Content "config.json" -Raw \| ConvertFrom-Json'
            $result | Should -Match 'Get-Content \$path -Raw \| ConvertFrom-Json'
        }
        
        It 'Should not modify if -Raw already present' {
            $input = @'
$config = Get-Content "config.json" -Raw | ConvertFrom-Json
'@
            $result = Invoke-ConvertFromJsonOptimizationFix -Content $input
            
            # Should remain unchanged
            $result | Should -BeExactly $input
        }
        
        It 'Should handle multiline patterns' {
            $input = @'
$config = Get-Content "config.json" |
    ConvertFrom-Json
'@
            $result = Invoke-ConvertFromJsonOptimizationFix -Content $input
            
            # Should add -Raw even with line breaks
            $result | Should -Match '-Raw'
        }
    }
    
    Context 'Invoke-SecureStringDisclosureFix' {
        
        It 'Should detect SecureString disclosure in Write-Host' {
            $input = @'
Write-Host "Password: $securePassword"
Write-Output "Key: $apiKey"
'@
            $result = Invoke-SecureStringDisclosureFix -Content $input
            
            # Should add security warnings
            $result | Should -Match 'SECURITY WARNING: Potential SecureString disclosure'
        }
        
        It 'Should detect SecureString in string concatenation' {
            $input = @'
$message = "Password is $securePass"
$log = "Token: $secureToken"
'@
            $result = Invoke-SecureStringDisclosureFix -Content $input
            
            # Should add warnings
            $result | Should -Match 'SECURITY WARNING'
        }
        
        It 'Should not warn for safe password handling' {
            $input = @'
$securePassword = ConvertTo-SecureString -String $plainText -AsPlainText -Force
$credential = [PSCredential]::new($user, $securePassword)
'@
            $result = Invoke-SecureStringDisclosureFix -Content $input
            
            # Should not add warnings for proper SecureString usage
            $result | Should -BeExactly $input
        }
        
        It 'Should not duplicate warnings' {
            $input = @'
Write-Host "Password: $securePassword"  # SECURITY WARNING: Potential SecureString disclosure
'@
            $result = Invoke-SecureStringDisclosureFix -Content $input
            
            # Should not add duplicate warning
            $result | Should -BeExactly $input
        }
    }
}
