<#
.SYNOPSIS
    PoshGuard Alias Expansion Module

.DESCRIPTION
    PowerShell alias expansion functionality including:
    - Common alias mapping (gci → Get-ChildItem, ls → Get-ChildItem)
    - AST-based alias detection and replacement
    - Context-aware expansion (skips PSQAAutoFixer)

    Expands aliases to full cmdlet names for improved readability.

.NOTES
    Part of PoshGuard v2.4.0
    Requires PowerShell 5.1 or higher for AST functionality
#>

Set-StrictMode -Version Latest

function Invoke-AliasFix {
    <#
    .SYNOPSIS
        Expands PowerShell aliases to full cmdlet names

    .DESCRIPTION
        Detects and expands common PowerShell aliases.
        Skips PSQAAutoFixer.psm1 to prevent self-corruption.

    .PARAMETER Content
        The script content to process

    .PARAMETER FilePath
        Optional file path for context-aware skipping

    .EXAMPLE
        Invoke-AliasFix -Content $scriptContent
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        [Parameter()]
        [string]$FilePath = ''
    )

    if ($FilePath -match 'PSQAAutoFixer\.psm1$') {
        Write-Verbose "Skipping alias expansion on PSQAAutoFixer to prevent self-corruption"
        return $Content
    }

    return Invoke-AliasFixAst -Content $Content
}

function Invoke-AliasFixAst {
    <#
    .SYNOPSIS
        AST-based alias expansion

    .DESCRIPTION
        Uses PowerShell AST parsing to find and expand common aliases.
        Supports aliases like gci, ls, cat, echo, etc.

    .EXAMPLE
        Invoke-AliasFixAst -Content $scriptContent
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $aliasMap = @{
        # Common file/directory operations
        'gci' = 'Get-ChildItem'; 'ls' = 'Get-ChildItem'; 'dir' = 'Get-ChildItem'
        'cat' = 'Get-Content'; 'type' = 'Get-Content'
        'cp' = 'Copy-Item'; 'copy' = 'Copy-Item'; 'cpi' = 'Copy-Item'
        'mv' = 'Move-Item'; 'move' = 'Move-Item'; 'mi' = 'Move-Item'
        'rm' = 'Remove-Item'; 'del' = 'Remove-Item'; 'erase' = 'Remove-Item'; 'ri' = 'Remove-Item'
        'pwd' = 'Get-Location'; 'gl' = 'Get-Location'
        'cd' = 'Set-Location'; 'chdir' = 'Set-Location'; 'sl' = 'Set-Location'
        
        # Pipeline and filtering
        '?' = 'Where-Object'; 'where' = 'Where-Object'
        '%' = 'ForEach-Object'; 'foreach' = 'ForEach-Object'
        
        # Output formatting
        'fl' = 'Format-List'
        'ft' = 'Format-Table'
        'fw' = 'Format-Wide'
        'echo' = 'Write-Output'; 'write' = 'Write-Output'
        
        # Process and service management
        'ps' = 'Get-Process'; 'gps' = 'Get-Process'
        'kill' = 'Stop-Process'; 'spps' = 'Stop-Process'
        'gsv' = 'Get-Service'
        'sasv' = 'Start-Service'
        'spsv' = 'Stop-Service'
        
        # Other common cmdlets
        'gcm' = 'Get-Command'
        'gm' = 'Get-Member'
        'iwr' = 'Invoke-WebRequest'; 'curl' = 'Invoke-WebRequest'; 'wget' = 'Invoke-WebRequest'
        'irm' = 'Invoke-RestMethod'
        'cls' = 'Clear-Host'; 'clear' = 'Clear-Host'
        'sleep' = 'Start-Sleep'
        'tee' = 'Tee-Object'
        'diff' = 'Compare-Object'
        'select' = 'Select-Object'
        'sort' = 'Sort-Object'
        'group' = 'Group-Object'
        'measure' = 'Measure-Object'
    }

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)

    if ($errors.Count -gt 0) {
        # Cannot safely fix aliases in a script with parsing errors
        return $Content
    }

    $commandAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
    $fixes = @{}

    foreach ($commandAst in $commandAsts) {
        $commandName = $commandAst.GetCommandName()
        if ($aliasMap.ContainsKey($commandName)) {
            $extent = $commandAst.Extent
            $fixes[$extent.StartOffset] = @{
                Length      = $extent.EndOffset - $extent.StartOffset
                Replacement = $aliasMap[$commandName]
            }
        }
    }

    $newContent = $Content
    $offset = 0

    foreach ($startOffset in $fixes.Keys | Sort-Object) {
        $fix = $fixes[$startOffset]
        $length = $fix.Length
        $replacement = $fix.Replacement

        $newContent = $newContent.Remove($startOffset + $offset, $length).Insert($startOffset + $offset, $replacement)
        $offset += $replacement.Length - $length
    }

    return $newContent
}

# Export all alias fix functions
Export-ModuleMember -Function @(
    'Invoke-AliasFix',
    'Invoke-AliasFixAst'
)
