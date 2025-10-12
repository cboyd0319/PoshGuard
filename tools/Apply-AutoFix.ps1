#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Standalone idempotent auto-fix script for PowerShell code quality.

.DESCRIPTION
    Self-contained, idempotent script that applies safe automated fixes to PowerShell code:
    - Formats with Invoke-Formatter (if available)
    - Removes trailing whitespace
    - Expands cmdlet aliases
    - Normalizes line endings
    - Fixes common security issues
    - Creates backups automatically
    - Generates unified diffs
    - Safe to run multiple times (idempotent)

    MODULAR ARCHITECTURE (v2.16.0):
    All fix functions have been extracted to 5 specialized modules in ./lib/:
    - Core.psm1: Helper functions (backups, logging, file ops)
    - Formatting.psm1: Code formatting and style
    - Security.psm1: Security vulnerability fixes (100% PSSA security coverage)
    - BestPractices.psm1: PowerShell coding standards
    - Advanced.psm1: Complex AST-based transformations

.PARAMETER Path
    Path to PowerShell file(s) or directory to fix

.PARAMETER DryRun
    Preview changes without applying them

.PARAMETER NoBackup
    Skip creating backups (not recommended)

.PARAMETER ShowDiff
    Display unified diffs of changes

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./src -DryRun
    Preview fixes without applying

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./script.ps1 -ShowDiff
    Apply fixes and show unified diffs

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./src
    Apply all safe fixes to directory

.NOTES
    Author: https://github.com/cboyd0319
    Version: 4.0.0
    Idempotent: Safe to run multiple times
    Compatible: PowerShell 5.1+, PowerShell 7.x
    Architecture: Modular (9 modules, 107+ detection rules, AI/ML integration, 10+ standards compliance)
    AI: ML confidence scoring, pattern learning, MCP integration (optional)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ Test-Path -Path $_ -ErrorAction Stop })]
    [string]$Path,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$NoBackup,

    [Parameter()]
    [switch]$ShowDiff,

    [Parameter()]
    [switch]$CleanBackups,

    [Parameter()]
    [ValidateSet('Default', 'UTF8', 'UTF8BOM')]
    [string]$Encoding = 'Default'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Configuration

$script:Config = @{
    SupportedExtensions = @('.ps1', '.psm1', '.psd1')
    BackupDirectory     = '.psqa-backup'
    LogDirectory        = './logs'
    MaxFileSizeBytes    = 10485760  # 10MB
    TraceId             = (New-Guid).ToString()
    BackupRetentionDays = 1
}

#endregion

#region Module Imports

# Import all fix modules from lib/ directory
$libPath = Join-Path -Path $PSScriptRoot -ChildPath 'lib'

if (-not (Test-Path -Path $libPath -ErrorAction SilentlyContinue)) {
    Write-Error "Module directory not found: $libPath`nPlease ensure ./lib/ folder exists with all required modules."
    exit 1
}

try {
    Import-Module (Join-Path -Path $libPath -ChildPath 'Core.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'Formatting.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'Security.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'BestPractices.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'Advanced.psm1') -Force -ErrorAction Stop

    Write-Verbose "Successfully loaded all auto-fix modules from: $libPath"
}
catch {
    Write-Error "Failed to load modules from $libPath : $_"
    exit 1
}

#endregion

#region Main Processing

function Invoke-FileFix {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File
    )

    if ($pscmdlet.ShouldProcess($File.FullName, 'Analyzing file')) {
        Write-Log -Level Info -Message "Processing: $($File.Name)"

        if ($File.Length -gt $script:Config.MaxFileSizeBytes) {
            Write-Log -Level Warn -Message "Skipping (file too large): $($File.Name)"
            return $null
        }

        try {
            $originalContent = Get-Content -Path $File.FullName -Raw -ErrorAction Stop

            # Check for BOM (cross-platform compatible)
            $hasBom = $false
            try {
                $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
                if ($bytes.Length -ge 3) {
                    $hasBom = $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
                }
            }
            catch {
                Write-Verbose "Could not read bytes for BOM detection: $_"
            }

            if (-not $originalContent.Trim()) {
                Write-Log -Level Warn -Message "Skipping (empty file): $($File.Name)"
                return $null
            }

            # ┌─────────────────────────────────────────────────────────────┐
            # │ FIX PIPELINE - All functions imported from modules in ./lib/ │
            # └─────────────────────────────────────────────────────────────┘
            $fixedContent = $originalContent

            # Advanced fixes (parameters, complex AST)
            $fixedContent = Invoke-ReservedParamsFix -Content $fixedContent
            $fixedContent = Invoke-SwitchParameterDefaultFix -Content $fixedContent
            $fixedContent = Invoke-PSCredentialTypeFix -Content $fixedContent
            $fixedContent = Invoke-OutputTypeCorrectlyFix -Content $fixedContent

            # Manifest fixes (only for .psd1 files)
            $fixedContent = Invoke-MissingModuleManifestFieldFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-UseToExportFieldsInManifestFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-DeprecatedManifestFieldsFix -Content $fixedContent -FilePath $File.FullName

            # Security fixes (HIGH priority) - 100% PSSA security coverage
            $fixedContent = Invoke-PlainTextPasswordFix -Content $fixedContent
            $fixedContent = Invoke-ConvertToSecureStringFix -Content $fixedContent
            $fixedContent = Invoke-UsernamePasswordParamsFix -Content $fixedContent
            $fixedContent = Invoke-AllowUnencryptedAuthFix -Content $fixedContent
            $fixedContent = Invoke-HardcodedComputerNameFix -Content $fixedContent
            $fixedContent = Invoke-InvokeExpressionFix -Content $fixedContent
            $fixedContent = Invoke-EmptyCatchBlockFix -Content $fixedContent
            $fixedContent = Invoke-BrokenHashAlgorithmFix -Content $fixedContent

            # Complex analysis fixes (AST-heavy)
            $fixedContent = Invoke-UnusedParameterFix -Content $fixedContent
            $fixedContent = Invoke-LongLinesFix -Content $fixedContent
            $fixedContent = Invoke-InvokingEmptyMembersFix -Content $fixedContent
            $fixedContent = Invoke-OverwritingBuiltInCmdletsFix -Content $fixedContent
            $fixedContent = Invoke-DefaultValueForMandatoryParameterFix -ScriptContent $fixedContent

            # Help file encoding fix (only for help files)
            if ($File.Name -like '*.help.txt' -or $File.Name -like '*-help.xml' -or $File.Name -like 'about_*.txt') {
                $fixedContent = Invoke-UTF8EncodingForHelpFileFix -FilePath $File.FullName -ScriptContent $fixedContent
            }

            # Skip auto-generated comment help for module files (they already have proper help)
            if ($File.Extension -ne '.psm1') {
                $fixedContent = Invoke-CommentHelpFix -Content $fixedContent
            }

            $fixedContent = Invoke-SupportsShouldProcessFix -Content $fixedContent
            $fixedContent = Invoke-ShouldProcessForStateChangingFix -Content $fixedContent
            $fixedContent = Invoke-ShouldContinueWithoutForceFix -Content $fixedContent
            $fixedContent = Invoke-PSShouldProcessFix -Content $fixedContent  # HARDEST FIX - Full ShouldProcess wrapping
            $fixedContent = Invoke-ProcessBlockForPipelineFix -Content $fixedContent
            $fixedContent = Invoke-CmdletBindingFix -Content $fixedContent  # FIXED VERSION (was CmdletCorrectlyFix)
            $fixedContent = Invoke-WmiToCimFix -Content $fixedContent

            # Compatibility warnings (cross-platform/version)
            $fixedContent = Invoke-CompatibleCmdletsWarningFix -ScriptContent $fixedContent

            # Formatting fixes
            $fixedContent = Invoke-FormatterFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-WhitespaceFix -Content $fixedContent
            $fixedContent = Invoke-MisleadingBacktickFix -Content $fixedContent
            $fixedContent = Invoke-AliasFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-AvoidGlobalAliasesFix -Content $fixedContent
            $fixedContent = Invoke-CasingFix -Content $fixedContent
            $fixedContent = Invoke-WriteHostEnhancedFix -Content $fixedContent  # ENHANCED VERSION (was WriteHostFix)
            $fixedContent = Invoke-AlignAssignmentFix -Content $fixedContent

            # Best practices fixes
            $fixedContent = Invoke-SemicolonFix -Content $fixedContent
            $fixedContent = Invoke-ExclaimOperatorFix -Content $fixedContent
            $fixedContent = Invoke-IncorrectAssignmentOperatorFix -Content $fixedContent
            $fixedContent = Invoke-ApprovedVerbFix -Content $fixedContent
            $fixedContent = Invoke-SingularNounFix -Content $fixedContent
            $fixedContent = Invoke-ReservedCmdletCharFix -Content $fixedContent
            $fixedContent = Invoke-GlobalVarFix -Content $fixedContent

            # Skip global function scoping for module files (modules have their own scope)
            if ($File.Extension -ne '.psm1') {
                $fixedContent = Invoke-GlobalFunctionsFix -Content $fixedContent
            }

            $fixedContent = Invoke-DoubleQuoteFix -Content $fixedContent
            $fixedContent = Invoke-LiteralHashtableFix -Content $fixedContent
            $fixedContent = Invoke-NullComparisonFix -Content $fixedContent
            $fixedContent = Invoke-RedirectionOperatorFix -Content $fixedContent
            $fixedContent = Invoke-PositionalParametersFix -Content $fixedContent
            $fixedContent = Invoke-DeclaredVarsMoreThanAssignmentsFix -Content $fixedContent
            $fixedContent = Invoke-AutomaticVariableFix -Content $fixedContent
            $fixedContent = Invoke-MultipleTypeAttributesFix -Content $fixedContent
            $fixedContent = Invoke-NullHelpMessageFix -Content $fixedContent
            $fixedContent = Invoke-UsingScopeModifierFix -Content $fixedContent

            # Beyond-PSSA Code Quality Enhancements (v3.2.0)
            $fixedContent = Invoke-TodoCommentDetectionFix -Content $fixedContent
            $fixedContent = Invoke-ConvertFromJsonOptimizationFix -Content $fixedContent
            $fixedContent = Invoke-UnusedNamespaceDetectionFix -Content $fixedContent
            $fixedContent = Invoke-AsciiCharacterWarningFix -Content $fixedContent
            $fixedContent = Invoke-SecureStringDisclosureFix -Content $fixedContent

            # Final cleanup fixes
            $fixedContent = Invoke-DuplicateLineFix -Content $fixedContent
            $fixedContent = Invoke-CmdletParameterFix -Content $fixedContent
            $fixedContent = Invoke-SafetyFix -Content $fixedContent

            # ┌─────────────────────────────────────────────────────────────┐
            # │ ENCODING & OUTPUT                                            │
            # └─────────────────────────────────────────────────────────────┘

            $finalEncoding = $Encoding
            if ($Encoding -eq 'Default') {
                $containsNonAscii = $fixedContent | Select-String -Pattern '[^\u0000-\u007F]' -Quiet
                if ($containsNonAscii -and -not $hasBom) {
                    $finalEncoding = 'utf8BOM'
                    Write-Log -Level Info -Message 'File contains non-ASCII characters, ensuring UTF8-BOM encoding.'
                }
            }

            if (($fixedContent -eq $originalContent) -and ($finalEncoding -ne 'utf8BOM')) {
                Write-Log -Level Info -Message "No changes needed: $($File.Name)"
                return $null
            }

            if ($ShowDiff) {
                $diff = New-UnifiedDiff -Original $originalContent -Modified $fixedContent -FilePath $File.Name
                if ($diff) {
                    Write-Host "`n--- Unified Diff for $($File.Name) ---" -ForegroundColor Magenta
                    Write-Host $diff -ForegroundColor Gray
                    Write-Host "--- End Diff ---`n" -ForegroundColor Magenta
                }
            }

            if (-not $DryRun) {
                if (-not $NoBackup) {
                    $backupPath = New-FileBackup -FilePath $File.FullName
                    Write-Log -Level Info -Message "Backup created: $(Split-Path -Path $backupPath -Leaf)"
                }

                $tempPath = "$($File.FullName).tmp"
                Set-Content -Path $tempPath -Value $fixedContent -Encoding $finalEncoding -NoNewline -ErrorAction Stop
                Move-Item -Path $tempPath -Destination $File.FullName -Force -ErrorAction Stop

                Write-Log -Level Success -Message "Fixes applied: $($File.Name)"
            }
            else {
                Write-Log -Level Info -Message "Would fix: $($File.Name) (dry-run)"
            }

            return @{
                file    = $File.Name
                Changed = $true
            }

        }
        catch {
            Write-Log -Level Error -Message "Failed to process $($File.Name): $_ "
            return $null
        }
    }
}

#endregion

#region Main Execution

try {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         PowerShell QA Auto-Fix Engine v3.2.0                  ║" -ForegroundColor Cyan
    Write-Host "║      Beyond-PSSA - World's Best PowerShell QA Tool           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Log -Level Info -Message "Trace ID: $($script:Config.TraceId)"
    Write-Log -Level Info -Message "Mode: $(if ($DryRun) { 'DRY RUN (Preview)' } else { 'APPLY FIXES' })"
    Write-Log -Level Info -Message "Backups: $(if ($NoBackup) { 'Disabled' } else { 'Enabled' })"
    Write-Log -Level Info -Message "Target: $Path"

    $files = @(Get-PowerShellFiles -Path $Path)
    Write-Log -Level Info -Message "Found $($files.Count) PowerShell file(s) to process`n"

    if ($files.Count -eq 0) {
        Write-Log -Level Warn -Message "No PowerShell files found"
        exit 0
    }

    $results = @()
    $fixedCount = 0

    foreach ($file in $files) {
        $result = Invoke-FileFix -File $file
        if ($result) {
            $results += $result
            if ($result.Changed) {
                $fixedCount++
            }
        }
    }

    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                         SUMMARY                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Log -Level Info -Message "Files processed: $($files.Count)"
    Write-Log -Level Success -Message "Files $(if ($DryRun) { 'that would be ' })fixed: $fixedCount"
    Write-Log -Level Info -Message "Files unchanged: $($files.Count - $fixedCount)"

    if ($DryRun) {
        Write-Host "`n[DRY RUN MODE] No changes were applied." -ForegroundColor Yellow
        Write-Host "Run without -DryRun to apply fixes.`n" -ForegroundColor Yellow
    }
    else {
        Write-Host "`n[SUCCESS] Auto-fix complete!`n" -ForegroundColor Green
    }

    if ($CleanBackups) {
        Clean-Backups
    }

    exit 0

}
catch {
    Write-Log -Level Error -Message "Fatal error: $_ "
    Write-Host "`nStack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion
