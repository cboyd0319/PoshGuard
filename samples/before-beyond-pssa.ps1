#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sample script demonstrating Beyond-PSSA code quality issues

.DESCRIPTION
    This script intentionally contains issues that PoshGuard's Beyond-PSSA
    enhancements can detect and fix:
    - Inconsistent TODO comments
    - Potentially unused namespaces
    - Non-ASCII characters
    - Inefficient JSON parsing
    - Potential SecureString disclosure

.NOTES
    Part of PoshGuard v3.2.0 demonstration
    Run: ./tools/Apply-AutoFix.ps1 -Path ./samples/before-beyond-pssa.ps1 -DryRun
#>

# Inconsistent TODO comments (should be standardized)
# todo implement better error handling
# FIXME performance issue here
#hack temporary workaround

using namespace System.Collections.Generic
using namespace System.Net
using namespace System.Text

function Get-Configuration {
    [CmdletBinding()]
    param(
        [string]$Path = "config.json"
    )
    
    # Inefficient JSON parsing (missing -Raw parameter)
    $config = Get-Content $Path | ConvertFrom-Json
    
    # Non-ASCII character (em dash instead of hyphen)
    Write-Host "Loading config—please wait"
    
    return $config
}

function Test-Credentials {
    [CmdletBinding()]
    param(
        [SecureString]$Password
    )
    
    # Potential SecureString disclosure
    Write-Host "Testing password: $Password"
    Write-Verbose "Credential check with $Password"
}

function Process-Data {
    [CmdletBinding()]
    param()
    
    # Only Generic namespace is used (others are unused)
    $list = [Generic.List[string]]::new()
    $list.Add("Item 1")
    $list.Add("Item 2")
    
    # todo add more items
    
    return $list
}

# More inconsistent comments
#NOTE review this section
# FIXME needs testing

Write-Host "Script complete"
