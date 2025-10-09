#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Discovers PowerShell files to be analyzed.

.DESCRIPTION
    Recursively finds all PowerShell files (`.ps1`, `.psm1`, `.psd1`) in the given path.
    It respects the `SupportedExtensions` and `ExcludePatterns` defined in the configuration.

.PARAMETER Path
    The root path to search for files. Can be a single file or a directory.

.EXAMPLE
    $files = Get-PSFile -Path './src'

.NOTES
    Returns a collection of FileInfo objects.
#>
function Get-PSFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($pscmdlet.ShouldProcess($Path, "Discover PowerShell files")) {
        $config = Get-PSQAConfig
        $supportedExtensions = $config.FileProcessing.SupportedExtensions
        $excludePatterns = $config.FileProcessing.ExcludePatterns

        if (Test-Path -Path $Path -PathType Leaf) {
            # Single file
            return @((Get-Item $Path))
        }

        # Directory - get all PowerShell files
        $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
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

        Write-Verbose "Found $($files.Count) PowerShell files to analyze"
        return $files
    }
}

Export-ModuleMember -Function Get-PSFile
