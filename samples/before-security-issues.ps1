# Sample script with security issues for PoshGuard demo
# This file intentionally contains multiple PSSA violations

function Connect-Service {
    param(
        [string]$Username,
        [string]$Password,  # PSAvoidUsingPlainTextForPassword
        [string]$ComputerName = "prod-server-01"  # PSAvoidUsingComputerNameHardcoded
    )
    
    # PSAvoidUsingConvertToSecureStringWithPlainText
    $securePass = ConvertTo-SecureString $Password -AsPlainText -Force
    
    # PSAvoidUsingCmdletAliases
    gci C:\Logs | ? { $_.Length -gt 1MB }
    
    # PSAvoidUsingWriteHost
    Write-Host "Connecting to $ComputerName..."
    
    # PSAvoidUsingInvokeExpression
    $command = "Get-Process"
    Invoke-Expression $command
}

# PSAvoidGlobalVars
$global:ConnectionPool = @{}

# PSAvoidUsingPositionalParameters
Get-ChildItem "C:\Temp" $true

# PSAvoidUsingDoubleQuotesForConstantString
$message = "Hello World"

# PSAvoidSemicolonsAsLineTerminators
$x = 1; $y = 2; $z = 3;

# PSAvoidTrailingWhitespace
$var = "test"   

# PSAvoidUsingEmptyCatchBlock
try {
    Get-Item "C:\nonexistent"
}
catch {
}
