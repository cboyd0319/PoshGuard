<#
.SYNOPSIS
    Detects and warns about deprecated module manifest fields.

.DESCRIPTION
    The PSAvoidUsingDeprecatedManifestFields rule checks module manifests (.psd1)
    for deprecated or obsolete fields using Test-ModuleManifest. This ensures
    manifests are compatible with modern PowerShell versions (3.0+).

.NOTES
    Module: PoshGuard
    Category: Advanced
    Rule: PSAvoidUsingDeprecatedManifestFields
    Severity: Warning
    Auto-Fix: Detection only (manual review required)
#>

function Invoke-DeprecatedManifestFieldsFix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$FilePath
    )

    try {
        # Only process .psd1 files
        if ($FilePath -and $FilePath -notlike "*.psd1") {
            return $Content
        }

        # Parse AST
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
        if (-not $ast) {
            return $Content
        }

        # Check if this is a module manifest (contains a hashtable)
        $hashTableAst = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.HashtableAst]
        }, $false) | Select-Object -First 1

        if (-not $hashTableAst) {
            return $Content
        }

        # Check PowerShell version requirement (skip if < 3.0)
        $psVersionKey = $hashTableAst.KeyValuePairs | Where-Object {
            $_.Item1 -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $_.Item1.Value -eq 'PowerShellVersion'
        } | Select-Object -First 1

        if ($psVersionKey -and $psVersionKey.Item2) {
            $versionValue = $psVersionKey.Item2.Find({
                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst]
            }, $false)

            if ($versionValue) {
                $version = $null
                if ([version]::TryParse($versionValue.Value, [ref]$version)) {
                    if ($version.Major -lt 3) {
                        # Skip for PS < 3.0 (deprecated fields may be valid)
                        return $Content
                    }
                }
            }
        }

        # If FilePath is provided, use Test-ModuleManifest to detect issues
        if ($FilePath -and (Test-Path $FilePath)) {
            $warnings = @()
            
            try {
                # Test module manifest and capture warnings
                $null = Test-ModuleManifest -Path $FilePath -WarningVariable warnings -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                
                if ($warnings.Count -gt 0) {
                    # Add warning comments to the top of the file
                    $warningText = @"
<#
WARNING: Deprecated Module Manifest Fields Detected
The following warnings were found by Test-ModuleManifest:

$($warnings | ForEach-Object { "  - $_" } | Out-String)

Action Required:
- Review and remove deprecated manifest fields
- Update to use current PowerShell manifest schema
- Run Test-ModuleManifest to verify changes
- See: https://docs.microsoft.com/powershell/module/microsoft.powershell.core/new-modulemanifest

Common deprecated fields in PowerShell 3.0+:
- ModuleToProcess (use RootModule instead)
- RequiredAssemblies without explicit version
- Certain FunctionsToExport wildcards

#>

"@
                    # Check if warning already exists
                    if ($Content -notmatch 'WARNING: Deprecated Module Manifest Fields Detected') {
                        $Content = $warningText + $Content
                    }
                }
            } catch {
                # If Test-ModuleManifest fails, add a generic warning
                Write-Verbose "Could not test manifest: $_"
            }
        } else {
            # No file path - add generic check comment
            $genericWarning = @"
<#
NOTE: Module Manifest Field Check Recommended
This file appears to be a module manifest (.psd1). Please run:
  Test-ModuleManifest -Path <manifest.psd1>
to check for deprecated or obsolete fields.

Common deprecated fields in PowerShell 3.0+:
- ModuleToProcess (use RootModule instead)
- Use specific exports instead of wildcards where possible

#>

"@
            if ($Content -notmatch 'NOTE: Module Manifest Field Check Recommended') {
                $Content = $genericWarning + $Content
            }
        }

        return $Content

    } catch {
        Write-Warning "Error in Invoke-DeprecatedManifestFieldsFix: $_"
        return $Content
    }
}

Export-ModuleMember -Function @(
    'Invoke-DeprecatedManifestFieldsFix'
)
