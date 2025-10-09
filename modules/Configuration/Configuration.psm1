#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Initializes the QA engine's configuration from files.

.DESCRIPTION
    Loads configuration from the specified path. It looks for three files:
    - QASettings.psd1: Main configuration for the engine.
    - PSScriptAnalyzerSettings.psd1: Settings for PSScriptAnalyzer.
    - SecurityRules.psd1: Custom security rules for the security scan.

.PARAMETER ConfigPath
    The path to the directory containing the configuration files.

.EXAMPLE
    Initialize-Configuration -ConfigPath './config'

.NOTES
    This function is critical for the engine's operation. If it fails, the script will terminate.
#>
function Initialize-Configuration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if ($pscmdlet.ShouldProcess($ConfigPath, "Load configuration")) {
        try {
            Write-Verbose "Loading configuration from: $ConfigPath"

            # Load main QA settings
            $qaSettingsPath = Join-Path -Path $ConfigPath -ChildPath 'QASettings.psd1'
            if (Test-Path -Path $qaSettingsPath) {
                $global:PSQAConfig = Import-PowerShellDataFile -Path $qaSettingsPath
            } else {
                throw "QA settings file not found: $qaSettingsPath"
            }

            # Load PSScriptAnalyzer settings
            $pssaSettingsPath = Join-Path -Path $ConfigPath -ChildPath 'PSScriptAnalyzerSettings.psd1'
            if (Test-Path -Path $pssaSettingsPath) {
                $global:PSQAConfig.PSScriptAnalyzerSettings = $pssaSettingsPath
            }

            # Load security rules
            $securityRulesPath = Join-Path -Path $ConfigPath -ChildPath 'SecurityRules.psd1'
            if (Test-Path -Path $securityRulesPath) {
                $global:PSQAConfig.SecurityRules = Import-PowerShellDataFile -Path $securityRulesPath
            }

            Write-Verbose "Configuration loaded successfully"

        } catch {
            Write-Error "Failed to load configuration: $_"
            throw
        }
    }
}

function Get-PSQAConfig {
    <#
    .SYNOPSIS
        Returns the global QA engine configuration.
    .DESCRIPTION
        This function provides a standard way to access the configuration loaded by Initialize-Configuration.
    .EXAMPLE
        $config = Get-PSQAConfig
    .NOTES
        This function should only be called after Initialize-Configuration has been run.
    #>
    [CmdletBinding()]
    param()

    return $global:PSQAConfig
}

Export-ModuleMember -Function Initialize-Configuration, Get-PSQAConfig
