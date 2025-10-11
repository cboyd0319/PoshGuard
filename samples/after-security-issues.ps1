# Sample script with security issues for PoshGuard demo
# This file shows the expected fixes after PoshGuard processing

function Connect-Service {
    param(
        [string]$Username,
        [SecureString]$Password,  # Fixed: PSAvoidUsingPlainTextForPassword
        [string]$ComputerName  # Fixed: PSAvoidUsingComputerNameHardcoded - removed hardcoded default
    )
    
    # Fixed: PSAvoidUsingConvertToSecureStringWithPlainText - parameter now expects SecureString
    $securePass = $Password
    
    # Fixed: PSAvoidUsingCmdletAliases
    Get-ChildItem C:\Logs | Where-Object { $_.Length -gt 1MB }
    
    # Fixed: PSAvoidUsingWriteHost
    Write-Information "Connecting to $ComputerName..." -InformationAction Continue
    
    # Fixed: PSAvoidUsingInvokeExpression
    $command = "Get-Process"
    & $command
}

# Fixed: PSAvoidGlobalVars - removed global scope
$ConnectionPool = @{}

# Fixed: PSAvoidUsingPositionalParameters
Get-ChildItem -Path 'C:\Temp' -Recurse $true

# Fixed: PSAvoidUsingDoubleQuotesForConstantString
$message = 'Hello World'

# Fixed: PSAvoidSemicolonsAsLineTerminators
$x = 1
$y = 2
$z = 3

# Fixed: PSAvoidTrailingWhitespace
$var = 'test'

# Fixed: PSAvoidUsingEmptyCatchBlock
try {
    Get-Item 'C:\nonexistent'
}
catch {
    Write-Error "Failed to get item: $_"
}
