<#
.SYNOPSIS
    Validate MCP (Model Context Protocol) server configurations

.DESCRIPTION
    Comprehensive validation script for testing all MCP server configurations
    in .github/copilot-mcp.json. Checks connectivity, authentication, and
    proper configuration for each server type.

.PARAMETER ConfigPath
    Path to copilot-mcp.json file (default: .github/copilot-mcp.json)

.PARAMETER Verbose
    Show detailed validation output

.EXAMPLE
    .\Test-MCPConfiguration.ps1

.EXAMPLE
    .\Test-MCPConfiguration.ps1 -ConfigPath .github/copilot-mcp.json -Verbose

.NOTES
    Version: 1.0.0
    Author: PoshGuard Team
    Privacy: Only validates configuration structure and connectivity, does not transmit data
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConfigPath = ".github/copilot-mcp.json",
    
    [Parameter()]
    [switch]$SkipConnectivityTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helper Functions

function Write-TestResult {
    param(
        [string]$Test,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    if ($Passed) {
        Write-Host "  ✓ $Test" -ForegroundColor Green
        if ($Message) {
            Write-Host "    $Message" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  ✗ $Test" -ForegroundColor Red
        if ($Message) {
            Write-Host "    $Message" -ForegroundColor Yellow
        }
    }
}

function Test-JsonValidity {
    param([string]$Path)
    
    try {
        $content = Get-Content -Path $Path -Raw
        $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
        return @{ Valid = $true; Message = "Valid JSON structure" }
    }
    catch {
        return @{ Valid = $false; Message = $_.Exception.Message }
    }
}

function Test-MCPServerConfiguration {
    param(
        [string]$ServerName,
        [PSCustomObject]$Config
    )
    
    $results = @{
        ServerName = $ServerName
        Tests = @()
        Passed = $true
    }
    
    # Helper function to check if property exists
    function Test-PropertyExists {
        param($Object, $PropertyName)
        return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $PropertyName })
    }
    
    # Test 1: Required fields
    $requiredFields = @('type')
    foreach ($field in $requiredFields) {
        $hasField = Test-PropertyExists -Object $Config -PropertyName $field
        $results.Tests += @{
            Name = "Has required field '$field'"
            Passed = $hasField
            Message = if ($hasField) { "Present" } else { "Missing required field" }
        }
        if (-not $hasField) { $results.Passed = $false }
    }
    
    # Test 2: Valid type
    $validTypes = @('http', 'local', 'stdio')
    $typeValid = $Config.type -in $validTypes
    $results.Tests += @{
        Name = "Valid server type"
        Passed = $typeValid
        Message = if ($typeValid) { "Type: $($Config.type)" } else { "Invalid type: $($Config.type)" }
    }
    if (-not $typeValid) { $results.Passed = $false }
    
    # Test 3: Type-specific validation
    switch ($Config.type) {
        'http' {
            $hasUrl = Test-PropertyExists -Object $Config -PropertyName 'url'
            $results.Tests += @{
                Name = "HTTP server has URL"
                Passed = $hasUrl
                Message = if ($hasUrl) { "URL: $($Config.url)" } else { "Missing URL for HTTP server" }
            }
            if (-not $hasUrl) { $results.Passed = $false }
            
            # Check for deprecated PAT authentication
            $hasHeaders = Test-PropertyExists -Object $Config -PropertyName 'headers'
            if ($hasHeaders) {
                $hasAuth = Test-PropertyExists -Object $Config.headers -PropertyName 'Authorization'
                if ($hasAuth) {
                    $authHeader = $Config.headers.Authorization
                    $usesPAT = $authHeader -match 'Bearer \$COPILOT_MCP_GITHUB_PERSONAL_ACCESS_TOKEN'
                    $results.Tests += @{
                        Name = "Not using deprecated PAT authentication"
                        Passed = -not $usesPAT
                        Message = if ($usesPAT) { 
                            "WARNING: Personal Access Tokens are deprecated for GitHub Copilot MCP. Use OAuth or remove explicit auth." 
                        } else { 
                            "Authentication method OK" 
                        }
                    }
                    if ($usesPAT) { $results.Passed = $false }
                }
            }
        }
        
        'local' {
            $hasCommand = Test-PropertyExists -Object $Config -PropertyName 'command'
            $results.Tests += @{
                Name = "Local server has command"
                Passed = $hasCommand
                Message = if ($hasCommand) { "Command: $($Config.command)" } else { "Missing command for local server" }
            }
            if (-not $hasCommand) { $results.Passed = $false }
            
            # Verify command exists
            if ($hasCommand) {
                $commandExists = $null -ne (Get-Command $Config.command -ErrorAction SilentlyContinue)
                $results.Tests += @{
                    Name = "Command executable exists"
                    Passed = $commandExists
                    Message = if ($commandExists) { 
                        "Command '$($Config.command)' found" 
                    } else { 
                        "Command '$($Config.command)' not found in PATH. Install may be required." 
                    }
                }
                # Note: This is a warning, not a failure (command may be auto-installed)
            }
        }
        
        'stdio' {
            $hasCommand = Test-PropertyExists -Object $Config -PropertyName 'command'
            $results.Tests += @{
                Name = "STDIO server has command"
                Passed = $hasCommand
                Message = if ($hasCommand) { "Command: $($Config.command)" } else { "Missing command for stdio server" }
            }
            if (-not $hasCommand) { $results.Passed = $false }
        }
    }
    
    # Test 4: Environment variable validation
    $hasEnv = Test-PropertyExists -Object $Config -PropertyName 'env'
    if ($hasEnv) {
        foreach ($prop in $Config.env.PSObject.Properties) {
            $envVar = $prop.Name
            $value = $prop.Value
            if ($value -match '^\$(.+)$') {
                $varName = $Matches[1]
                $varExists = Test-Path "env:$varName"
                $results.Tests += @{
                    Name = "Environment variable $varName"
                    Passed = $varExists
                    Message = if ($varExists) { 
                        "Set (value hidden for security)" 
                    } else { 
                        "Not set. Server may not function correctly." 
                    }
                }
                # Note: Missing env vars are warnings, not failures (may be optional)
            }
        }
    }
    
    # Test 5: Headers environment variable validation
    $hasHeaders = Test-PropertyExists -Object $Config -PropertyName 'headers'
    if ($hasHeaders) {
        foreach ($prop in $Config.headers.PSObject.Properties) {
            $header = $prop.Name
            $value = $prop.Value
            if ($value -match '^\$(.+)$') {
                $varName = $Matches[1]
                $varExists = Test-Path "env:$varName"
                $results.Tests += @{
                    Name = "Environment variable $varName (header: $header)"
                    Passed = $varExists
                    Message = if ($varExists) { 
                        "Set (value hidden for security)" 
                    } else { 
                        "Not set. Server may require authentication." 
                    }
                }
                # Note: Missing API keys are warnings, not failures (may be optional)
            }
        }
    }
    
    # Test 6: Tools configuration
    $hasTools = Test-PropertyExists -Object $Config -PropertyName 'tools'
    if ($hasTools) {
        $toolsCount = $Config.tools.Count
        $results.Tests += @{
            Name = "Has tools configured"
            Passed = $toolsCount -gt 0
            Message = if ($toolsCount -gt 0) { 
                "Tools: $($Config.tools -join ', ')" 
            } else { 
                "No tools configured" 
            }
        }
        # Note: Empty tools is warning, not failure
    }
    
    return $results
}

function Test-ServerConnectivity {
    param(
        [string]$ServerName,
        [PSCustomObject]$Config
    )
    
    Write-Host "`n  Testing connectivity for $ServerName..." -ForegroundColor Cyan
    
    function Test-PropertyExists {
        param($Object, $PropertyName)
        return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $PropertyName })
    }
    
    if ($Config.type -eq 'http' -and (Test-PropertyExists -Object $Config -PropertyName 'url')) {
        try {
            # Test HTTP connectivity (HEAD request, no data transmitted)
            $uri = [System.Uri]$Config.url
            $baseUrl = "$($uri.Scheme)://$($uri.Host)"
            
            Write-Verbose "Testing connectivity to $baseUrl"
            $response = Invoke-WebRequest -Uri $baseUrl -Method Head -TimeoutSec 5 -ErrorAction Stop
            
            Write-TestResult "HTTP connectivity" $true "Server reachable (Status: $($response.StatusCode))"
        }
        catch {
            Write-TestResult "HTTP connectivity" $false "Unable to reach server: $($_.Exception.Message)"
        }
    }
    elseif ($Config.type -eq 'local' -and (Test-PropertyExists -Object $Config -PropertyName 'command')) {
        # Test local command availability
        $command = $Config.command
        $commandPath = Get-Command $command -ErrorAction SilentlyContinue
        
        if ($commandPath) {
            Write-TestResult "Local command availability" $true "Found at: $($commandPath.Source)"
        }
        else {
            Write-TestResult "Local command availability" $false "Command '$command' not found. May be auto-installed on first use."
        }
    }
}

#endregion

#region Main Validation

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  MCP Configuration Validation" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Test 1: File exists
Write-Host "[1/6] Checking configuration file..." -ForegroundColor Yellow
if (-not (Test-Path $ConfigPath)) {
    Write-TestResult "Configuration file exists" $false "File not found: $ConfigPath"
    exit 1
}
Write-TestResult "Configuration file exists" $true "Found at: $ConfigPath"

# Test 2: Valid JSON
Write-Host "`n[2/6] Validating JSON structure..." -ForegroundColor Yellow
$jsonTest = Test-JsonValidity -Path $ConfigPath
Write-TestResult "Valid JSON" $jsonTest.Valid $jsonTest.Message
if (-not $jsonTest.Valid) {
    exit 1
}

# Load configuration
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

# Test 3: Has mcpServers section
Write-Host "`n[3/6] Checking MCP servers section..." -ForegroundColor Yellow
$hasMcpServers = $null -ne $config.mcpServers
Write-TestResult "Has mcpServers section" $hasMcpServers
if (-not $hasMcpServers) {
    Write-Host "`nNo MCP servers configured. This is valid but MCP features will be unavailable." -ForegroundColor Yellow
    exit 0
}

$serverCount = ($config.mcpServers | Get-Member -MemberType NoteProperty).Count
Write-Host "  Found $serverCount MCP server(s) configured" -ForegroundColor Gray

# Test 4: Validate each server
Write-Host "`n[4/6] Validating individual server configurations..." -ForegroundColor Yellow

$allResults = @()

foreach ($serverProperty in $config.mcpServers.PSObject.Properties) {
    $serverName = $serverProperty.Name
    $serverConfig = $serverProperty.Value
    
    Write-Host "`n  Validating: $serverName" -ForegroundColor Cyan
    $result = Test-MCPServerConfiguration -ServerName $serverName -Config $serverConfig
    $allResults += $result
    
    foreach ($test in $result.Tests) {
        Write-TestResult $test.Name $test.Passed $test.Message
    }
}

# Test 5: Known good configurations
Write-Host "`n[5/6] Checking for known good configurations..." -ForegroundColor Yellow

$knownServers = @{
    'context7' = @{
        ExpectedType = 'http'
        ExpectedUrl = 'https://mcp.context7.com/mcp'
        RequiredEnv = 'COPILOT_MCP_CONTEXT7_API_KEY'
    }
    'openai-websearch' = @{
        ExpectedType = 'local'
        ExpectedCommand = 'uvx'
        RequiredEnv = 'COPILOT_MCP_OPENAI_API_KEY'
    }
    'fetch' = @{
        ExpectedType = 'local'
        ExpectedCommand = 'npx'
    }
    'playwright' = @{
        ExpectedType = 'local'
        ExpectedCommand = 'npx'
    }
}

foreach ($serverProperty in $config.mcpServers.PSObject.Properties) {
    $serverName = $serverProperty.Name
    if ($knownServers.ContainsKey($serverName)) {
        $expected = $knownServers[$serverName]
        $actual = $serverProperty.Value
        
        # Validate type
        $typeMatches = $actual.type -eq $expected.ExpectedType
        Write-TestResult "Server '$serverName' has correct type" $typeMatches "Expected: $($expected.ExpectedType), Actual: $($actual.type)"
        
        # Validate URL for HTTP servers
        if ($expected.ContainsKey('ExpectedUrl')) {
            $urlMatches = $actual.url -eq $expected.ExpectedUrl
            Write-TestResult "Server '$serverName' has correct URL" $urlMatches "Expected: $($expected.ExpectedUrl)"
        }
        
        # Validate command for local servers
        if ($expected.ContainsKey('ExpectedCommand')) {
            $commandMatches = $actual.command -eq $expected.ExpectedCommand
            Write-TestResult "Server '$serverName' has correct command" $commandMatches "Expected: $($expected.ExpectedCommand)"
        }
    }
}

# Test 6: Connectivity tests (optional)
if (-not $SkipConnectivityTests) {
    Write-Host "`n[6/6] Testing server connectivity..." -ForegroundColor Yellow
    Write-Host "  (Note: Some servers may not be reachable without proper authentication)" -ForegroundColor Gray
    
    foreach ($serverProperty in $config.mcpServers.PSObject.Properties) {
        $serverName = $serverProperty.Name
        $serverConfig = $serverProperty.Value
        
        Test-ServerConnectivity -ServerName $serverName -Config $serverConfig
    }
}
else {
    Write-Host "`n[6/6] Skipping connectivity tests (use -SkipConnectivityTests:`$false to enable)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$totalServers = $allResults.Count
$passedServers = ($allResults | Where-Object { $_.Passed }).Count
$failedServers = $totalServers - $passedServers

Write-Host "  Total Servers: $totalServers" -ForegroundColor White
Write-Host "  Passed: $passedServers" -ForegroundColor Green
Write-Host "  Failed: $failedServers" -ForegroundColor $(if ($failedServers -gt 0) { 'Red' } else { 'Green' })

if ($failedServers -gt 0) {
    Write-Host "`n  ⚠️  Some servers have configuration issues" -ForegroundColor Yellow
    Write-Host "  Review the messages above and fix any errors" -ForegroundColor Yellow
    Write-Host "  See docs/MCP-GUIDE.md for help" -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "`n  ✓ All servers configured correctly!" -ForegroundColor Green
    Write-Host "  Your MCP configuration is ready to use" -ForegroundColor Cyan
    exit 0
}

#endregion
