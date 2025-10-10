#!/usr/bin/env pwsh
#requires -Version 5.1

[CmdletBinding()]
param()


function Get-PSFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($pscmdlet.ShouldProcess($Path, "Discover PowerShell files")) {
        $config = Get-PSQAConfig
        $supportedExtensions = $config.FileProcessing.SupportedExtensions
        $excludePatterns = $config.FileProcessing.ExcludePatterns

        Write-Host "Supported Extensions: $($supportedExtensions -join ', ')"
        Write-Host "Exclude Patterns: $($excludePatterns -join ', ')"

        if (Test-Path -Path $Path -PathType Leaf -ErrorAction 'Stop') {
            # Single file
            $item = Get-Item -Path $Path -ErrorAction 'Stop'
            return @($item)
        }

        # Directory - get all PowerShell files
        $files = Get-ChildItem -Path $Path -Recurse -File

        Write-Host "Found $($files.Count) files before filtering"

        $files = $files | Where-Object {
            $extension = $_.Extension
            $fullPath = $_.FullName

            # Check supported extensions
            $isSupported = $supportedExtensions -contains $extension

            # Check exclude patterns
            $isExcluded = $false
            foreach ($pattern in $excludePatterns) {
                if ($fullPath -like $pattern) {
                    $isExcluded = $true
                    break
                }
            }

            return $isSupported -and (-not $isExcluded)
        }

        Write-Host "Found $($files.Count) PowerShell files to analyze"
        return $files
    }
}

Export-ModuleMember -Function Get-PSFile
