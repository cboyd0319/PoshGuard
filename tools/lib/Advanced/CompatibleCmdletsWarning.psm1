# CompatibleCmdletsWarning.psm1
# Simplified PSUseCompatibleCmdlets - warns about potentially incompatible cmdlets

function Invoke-CompatibleCmdletsWarningFix {
    <#
    .SYNOPSIS
        Adds warning comments for potentially incompatible cmdlets.
    
    .DESCRIPTION
        Detects cmdlets that may not be available in all PowerShell versions
        and adds warning comments with compatibility information.
        
        This is a simplified version focused on the most common compatibility issues:
        - Windows-only cmdlets used in cross-platform scripts
        - PowerShell 7+ exclusive cmdlets
        - Deprecated cmdlets
    
    .PARAMETER ScriptContent
        The PowerShell script content to analyze.
    
    .PARAMETER TargetVersion
        Target PowerShell version (5.1, 7.0, 7.2, 7.4, etc.)
        Default: 5.1 (most restrictive)
    
    .EXAMPLE
        # Before:
        Get-WinEvent -LogName System
        
        # After:
        # WARNING: Get-WinEvent is Windows-only, not available on Linux/macOS
        Get-WinEvent -LogName System
    
    .NOTES
        Rule: PSUseCompatibleCmdlets (Simplified)
        Severity: Warning
        Focus: Cross-platform and version compatibility
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$ScriptContent,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('5.1', '7.0', '7.2', '7.4')]
        [string]$TargetVersion = '5.1'
    )
    
    if ([string]::IsNullOrWhiteSpace($ScriptContent)) {
        return $ScriptContent
    }
    
    # Compatibility database - common incompatible cmdlets
    $incompatibleCmdlets = @{
        # Windows-only cmdlets (not on Linux/macOS)
        'Get-WinEvent' = @{
            Issue = 'Windows-only'
            Alternative = 'Use Get-EventLog on Windows PowerShell, or platform-agnostic logging'
            Platforms = 'Windows'
        }
        'Get-EventLog' = @{
            Issue = 'Windows-only, deprecated in PS 7+'
            Alternative = 'Use Get-WinEvent or cross-platform logging solution'
            Platforms = 'Windows (PS 5.1)'
        }
        'Get-Counter' = @{
            Issue = 'Windows-only'
            Alternative = 'Platform-specific performance monitoring'
            Platforms = 'Windows'
        }
        'Get-WindowsFeature' = @{
            Issue = 'Windows Server only'
            Alternative = 'Use DISM or platform-agnostic configuration management'
            Platforms = 'Windows Server'
        }
        'Get-Acl' = @{
            Issue = 'Windows-only (NTFS ACLs)'
            Alternative = 'Platform-specific permission management'
            Platforms = 'Windows'
        }
        'Set-Acl' = @{
            Issue = 'Windows-only (NTFS ACLs)'
            Alternative = 'Platform-specific permission management'
            Platforms = 'Windows'
        }
        'New-WebServiceProxy' = @{
            Issue = 'Not available in PowerShell 7+'
            Alternative = 'Use Invoke-RestMethod or HttpClient'
            Platforms = 'PowerShell 5.1 only'
        }
        'ConvertFrom-String' = @{
            Issue = 'Not available in PowerShell 7+'
            Alternative = 'Use -match, Select-String, or regex'
            Platforms = 'PowerShell 5.1 only'
        }
        'Get-ControlPanelItem' = @{
            Issue = 'Windows-only, not in PS 7+'
            Alternative = 'Direct system API calls'
            Platforms = 'Windows PowerShell 5.1'
        }
    }
    
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $ScriptContent,
            [ref]$null,
            [ref]$null
        )
        
        # Find all command invocations
        $commands = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst]
        }, $true)
        
        if (-not $commands) {
            return $ScriptContent
        }
        
        $warnings = @()
        
        foreach ($cmd in $commands) {
            $cmdName = $cmd.GetCommandName()
            if (-not $cmdName) {
                continue
            }
            
            if ($incompatibleCmdlets.ContainsKey($cmdName)) {
                $info = $incompatibleCmdlets[$cmdName]
                
                # Check if there's already a warning comment above this line
                $cmdLine = $ScriptContent.Substring(0, $cmd.Extent.StartOffset).Split("`n").Count
                $linesAbove = $ScriptContent.Split("`n")[($cmdLine - 2)..($cmdLine - 1)]
                
                $hasWarning = $false
                foreach ($line in $linesAbove) {
                    if ($line -match "WARNING:.*$cmdName" -or $line -match "COMPAT:.*$cmdName") {
                        $hasWarning = $true
                        break
                    }
                }
                
                if (-not $hasWarning) {
                    $warnings += @{
                        Offset = $cmd.Extent.StartOffset
                        CmdName = $cmdName
                        Issue = $info.Issue
                        Alternative = $info.Alternative
                        Platforms = $info.Platforms
                        Indent = Get-LineIndentation -Content $ScriptContent -Offset $cmd.Extent.StartOffset
                    }
                }
            }
        }
        
        if ($warnings.Count -eq 0) {
            return $ScriptContent
        }
        
        # Apply warnings in reverse order
        $fixed = $ScriptContent
        foreach ($warning in ($warnings | Sort-Object -Property Offset -Descending)) {
            $indent = $warning.Indent
            $warningText = "${indent}# WARNING: $($warning.CmdName) - $($warning.Issue) [$($warning.Platforms)]`n"
            $warningText += "${indent}# Alternative: $($warning.Alternative)`n"
            
            $before = $fixed.Substring(0, $warning.Offset)
            $after = $fixed.Substring($warning.Offset)
            $fixed = $before + $warningText + $after
            
            Write-Verbose "Added compatibility warning for: $($warning.CmdName)"
        }
        
        return $fixed
        
    } catch {
        Write-Warning "CompatibleCmdlets warning fix failed: $_"
        return $ScriptContent
    }
}

function Get-LineIndentation {
    <#
    .SYNOPSIS
        Gets the indentation (leading whitespace) of a line at the given offset.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Content,
        [int]$Offset
    )
    
    # Find the start of the current line
    $lineStart = $Offset
    while ($lineStart -gt 0 -and $Content[$lineStart - 1] -ne "`n") {
        $lineStart--
    }
    
    # Extract leading whitespace
    $indent = ''
    for ($i = $lineStart; $i -lt $Content.Length; $i++) {
        $char = $Content[$i]
        if ($char -eq ' ' -or $char -eq "`t") {
            $indent += $char
        } else {
            break
        }
    }
    
    return $indent
}

Export-ModuleMember -Function Invoke-CompatibleCmdletsWarningFix
