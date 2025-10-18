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

.PARAMETER ExportSarif
    Export analysis results in SARIF format for GitHub Code Scanning

.PARAMETER SarifOutputPath
    Path where SARIF file should be saved (default: ./poshguard-results.sarif)

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./src -DryRun
    Preview fixes without applying

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./script.ps1 -ShowDiff
    Apply fixes and show unified diffs

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./src
    Apply all safe fixes to directory

.EXAMPLE
    .\Apply-AutoFix.ps1 -Path ./src -DryRun -ExportSarif -SarifOutputPath ./results.sarif
    Analyze code and export results in SARIF format for GitHub Security tab

.NOTES
    Author: https://github.com/cboyd0319
    Version: 4.3.0
    Idempotent: Safe to run multiple times
    Compatible: PowerShell 5.1+, PowerShell 7.x
    Architecture: Modular (12 modules, 107+ detection rules, AI/ML integration, 25+ standards compliance)
    AI/ML: Reinforcement Learning (Q-learning), ML confidence scoring, entropy secret detection, MCP integration (optional)
    Features: Self-improving fixes, Shannon entropy analysis, OpenTelemetry tracing, SBOM generation, NIST SP 800-53 compliance
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
    [string]$Encoding = 'Default',

    [Parameter()]
    [switch]$ExportSarif,

    [Parameter()]
    [string]$SarifOutputPath = './poshguard-results.sarif',

    [Parameter()]
    [switch]$FastScan
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

# Initialize RL episode counter (used for tracking learning progress)
$script:EpisodeCount = 0

#endregion

#region Module Imports

# Import all fix modules from lib/ directory
$libPath = Join-Path -Path $PSScriptRoot -ChildPath 'lib'

if (-not (Test-Path -Path $libPath -ErrorAction SilentlyContinue)) {
    Write-Error "Module directory not found: $libPath`nPlease ensure ./lib/ folder exists with all required modules."
    exit 1
}

try {
    # Core infrastructure modules
    Import-Module (Join-Path -Path $libPath -ChildPath 'ConfigurationManager.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'Core.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'Observability.psm1') -Force -ErrorAction Stop
    
    # RipGrep integration module (v4.3.0+)
    Import-Module (Join-Path -Path $libPath -ChildPath 'RipGrep.psm1') -Force -ErrorAction Stop
    
    # Fix modules
    Import-Module (Join-Path -Path $libPath -ChildPath 'Formatting.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'Security.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'BestPractices.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'Advanced.psm1') -Force -ErrorAction Stop
    
    # Advanced AI/ML modules (v4.3.0+)
    Import-Module (Join-Path -Path $libPath -ChildPath 'AIIntegration.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'ReinforcementLearning.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'EntropySecretDetection.psm1') -Force -ErrorAction Stop
    Import-Module (Join-Path -Path $libPath -ChildPath 'MCPIntegration.psm1') -Force -ErrorAction Stop
    
    Write-Verbose "Successfully loaded all modules including advanced AI/ML capabilities"
    
    # Initialize unified configuration
    $script:GlobalConfig = Initialize-PoshGuardConfiguration
    Write-Verbose "Configuration loaded: AI=$($script:GlobalConfig.AI.Enabled), RL=$($script:GlobalConfig.ReinforcementLearning.Enabled), Secrets=$($script:GlobalConfig.SecretDetection.Enabled)"
    
    # Initialize observability
    if ($script:GlobalConfig.Observability.Enabled) {
        $traceId = Initialize-Observability
        $script:Config.TraceId = $traceId
        Write-Verbose "Observability initialized with TraceId: $traceId"
    }
    
    # Initialize MCP if enabled and user consented
    if ($script:GlobalConfig.MCP.Enabled -and $script:GlobalConfig.MCP.UserConsent) {
        Initialize-MCPConfiguration
        Write-Verbose "MCP integration initialized"
    }
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
            # │ V4.3.0: Now with AI/ML, RL optimization, and secret scanning │
            # └─────────────────────────────────────────────────────────────┘
            
            # Phase 0: Secret Detection (CRITICAL - run first before any modifications)
            if ($script:GlobalConfig.SecretDetection.Enabled) {
                try {
                    Write-Verbose "Running entropy-based secret detection..."
                    $secretScanResult = Invoke-SecretScan -Content $originalContent -FilePath $File.FullName
                    if ($secretScanResult -and $secretScanResult.SecretsFound -gt 0) {
                        Write-Warning "⚠️  SECRETS DETECTED in $($File.Name): $($secretScanResult.SecretsFound) potential secrets found"
                        foreach ($secret in $secretScanResult.Secrets) {
                            Write-Warning "  - Line $($secret.LineNumber): $($secret.Type) (entropy: $([Math]::Round($secret.Entropy, 2)), confidence: $([Math]::Round($secret.Confidence, 2)))"
                        }
                        Write-Warning "  Please review and remove these secrets before proceeding!"
                        # Log for metrics
                        if ($script:GlobalConfig.Observability.Enabled) {
                            Write-StructuredLog -Level WARN -Message "Secrets detected" -Properties @{
                                file = $File.Name
                                secret_count = $secretScanResult.SecretsFound
                                secret_types = ($secretScanResult.Secrets | Select-Object -ExpandProperty Type -Unique)
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Secret detection error (non-critical): $_"
                }
            }
            
            $fixedContent = $originalContent
            
            # Phase 1: Initialize RL state if enabled
            $rlState = $null
            $rlEnabled = $script:GlobalConfig.ReinforcementLearning.Enabled
            if ($rlEnabled) {
                # Get PSScriptAnalyzer violations for state representation
                $violations = @()
                try {
                    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
                        $violations = @(Invoke-ScriptAnalyzer -ScriptDefinition $fixedContent -ErrorAction SilentlyContinue)
                    }
                }
                catch {
                    Write-Verbose "Could not run PSScriptAnalyzer for RL state: $_"
                }
                
                try {
                    $rlState = Get-CodeState -Content $fixedContent -Violations $violations
                    Write-Verbose "RL state initialized: Complexity=$($rlState.CyclomaticComplexity), Violations=$($rlState.ViolationCount)"
                }
                catch {
                    Write-Verbose "Could not initialize RL state: $_"
                    $rlEnabled = $false
                }
            }

            # Phase 2: Advanced fixes (parameters, complex AST)
            $fixedContent = Invoke-ReservedParamsFix -Content $fixedContent
            $fixedContent = Invoke-SwitchParameterDefaultFix -Content $fixedContent
            $fixedContent = Invoke-PSCredentialTypeFix -Content $fixedContent
            $fixedContent = Invoke-OutputTypeCorrectlyFix -Content $fixedContent

            # Phase 3: Manifest fixes (only for .psd1 files)
            $fixedContent = Invoke-MissingModuleManifestFieldFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-UseToExportFieldsInManifestFix -Content $fixedContent -FilePath $File.FullName
            $fixedContent = Invoke-DeprecatedManifestFieldsFix -Content $fixedContent -FilePath $File.FullName

            # Phase 4: Security fixes (HIGH priority) - 100% PSSA security coverage
            $fixedContent = Invoke-PlainTextPasswordFix -Content $fixedContent
            $fixedContent = Invoke-ConvertToSecureStringFix -Content $fixedContent
            $fixedContent = Invoke-UsernamePasswordParamsFix -Content $fixedContent
            $fixedContent = Invoke-AllowUnencryptedAuthFix -Content $fixedContent
            $fixedContent = Invoke-HardcodedComputerNameFix -Content $fixedContent
            $fixedContent = Invoke-InvokeExpressionFix -Content $fixedContent
            $fixedContent = Invoke-EmptyCatchBlockFix -Content $fixedContent
            $fixedContent = Invoke-BrokenHashAlgorithmFix -Content $fixedContent

            # Phase 5: Complex analysis fixes (AST-heavy)
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

            # Phase 6: Calculate AI confidence score if enabled
            $confidence = 1.0
            if ($script:GlobalConfig.AI.ConfidenceScoring -and $originalContent -ne $fixedContent) {
                try {
                    $confidence = Get-FixConfidenceScore -OriginalContent $originalContent -FixedContent $fixedContent
                    Write-Verbose "Fix confidence score: $confidence"
                    
                    if ($confidence -lt $script:GlobalConfig.AI.MinConfidenceThreshold) {
                        Write-Warning "⚠️  Low confidence fix ($confidence) for $($File.Name). Manual review recommended."
                    }
                }
                catch {
                    Write-Verbose "Could not calculate confidence score: $_"
                }
            }
            
            # Phase 7: RL reward and learning if enabled
            if ($rlEnabled -and $originalContent -ne $fixedContent) {
                try {
                    # Calculate reward based on fix quality
                    $reward = Get-FixReward -OriginalContent $originalContent -FixedContent $fixedContent -Confidence $confidence
                    
                    # Update Q-learning (state, action='fix', reward, next_state)
                    $nextViolations = @()
                    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
                        $nextViolations = Invoke-ScriptAnalyzer -ScriptDefinition $fixedContent -ErrorAction SilentlyContinue
                    }
                    $nextState = Get-CodeState -Content $fixedContent -Violations $nextViolations
                    
                    Update-QLearning -State $rlState -Action 'fix' -Reward $reward -NextState $nextState
                    Write-Verbose "RL updated: Reward=$reward, ViolationsReduced=$($rlState.ViolationCount - $nextState.ViolationCount)"
                    
                    # Periodic experience replay for batch learning
                    $script:EpisodeCount++
                    if ($script:EpisodeCount % 10 -eq 0) {
                        Start-ExperienceReplay
                        Write-Verbose "Experience replay executed (episode $script:EpisodeCount)"
                    }
                }
                catch {
                    Write-Verbose "RL learning error (non-critical): $_"
                }
            }
            
            if (($fixedContent -eq $originalContent) -and ($finalEncoding -ne 'utf8BOM')) {
                Write-Log -Level Info -Message "No changes needed: $($File.Name)"
                
                # Track no-change metrics
                if ($script:GlobalConfig.Observability.Enabled) {
                    Write-Metric -Name "fix.no_change" -Value 1 -Properties @{
                        file = $File.Name
                    }
                }
                
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

                Write-Log -Level Success -Message "Fixes applied: $($File.Name) (confidence: $([Math]::Round($confidence, 2)))"
                
                # Track metrics if observability enabled
                if ($script:GlobalConfig.Observability.Enabled) {
                    Write-Metric -Name "fix.applied" -Value 1 -Properties @{
                        file = $File.Name
                        confidence = $confidence
                        size_bytes = $fixedContent.Length
                    }
                }
            }
            else {
                Write-Log -Level Info -Message "Would fix: $($File.Name) (dry-run) (confidence: $([Math]::Round($confidence, 2)))"
            }

            return @{
                file    = $File.Name
                Changed = $true
                Confidence = $confidence
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
    # Enhanced banner with better visual hierarchy
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "🛡️  PoshGuard" -ForegroundColor White -NoNewline
    Write-Host " - PowerShell QA & Security Auto-Fix " -ForegroundColor Gray -NoNewline
    Write-Host "v4.3.0     " -ForegroundColor DarkGray -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "🤖 AI/ML Powered  " -ForegroundColor Magenta -NoNewline
    Write-Host "│ " -ForegroundColor DarkGray -NoNewline
    Write-Host "🔐 Secret Detection  " -ForegroundColor Yellow -NoNewline
    Write-Host "│ " -ForegroundColor DarkGray -NoNewline
    Write-Host "🎯 98%+ Fix Rate       " -ForegroundColor Green -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Configuration section with clear visual separation
    Write-Host "  ┌─ Configuration ─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │" -ForegroundColor DarkGray
    
    $modeIcon = if ($DryRun) { '👁️' } else { '🔧' }
    $modeText = if ($DryRun) { 'DRY RUN (Preview Only)' } else { 'LIVE MODE (Applying Fixes)' }
    $modeColor = if ($DryRun) { 'Yellow' } else { 'Green' }
    Write-Host "  │  Mode:        " -ForegroundColor DarkGray -NoNewline
    Write-Host "$modeIcon $modeText" -ForegroundColor $modeColor
    
    $backupIcon = if ($NoBackup) { '⚠️' } else { '💾' }
    $backupText = if ($NoBackup) { 'Disabled (Not Recommended!)' } else { 'Enabled' }
    $backupColor = if ($NoBackup) { 'Red' } else { 'Green' }
    Write-Host "  │  Backups:     " -ForegroundColor DarkGray -NoNewline
    Write-Host "$backupIcon $backupText" -ForegroundColor $backupColor
    
    Write-Host "  │  Target:      " -ForegroundColor DarkGray -NoNewline
    Write-Host "📁 $Path" -ForegroundColor White
    
    Write-Host "  │  Trace ID:    " -ForegroundColor DarkGray -NoNewline
    Write-Host "🔗 $($script:Config.TraceId)" -ForegroundColor DarkCyan
    Write-Host "  │" -ForegroundColor DarkGray
    Write-Host "  └──────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""

    $files = @(Get-PowerShellFiles -Path $Path -FastScan:$FastScan)
    
    # Enhanced file discovery message
    if (-not $FastScan) {
        Write-Host "  🔍 Discovering files..." -ForegroundColor Cyan
        Start-Sleep -Milliseconds 200  # Brief pause for better UX
    }
    Write-Host "  ✓ Found " -ForegroundColor Green -NoNewline
    Write-Host $files.Count -ForegroundColor White -NoNewline
    Write-Host " PowerShell file(s)" -ForegroundColor Green
    Write-Host ""

    if ($files.Count -eq 0) {
        Write-Host ""
        Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "  ║                                                                      ║" -ForegroundColor Yellow
        Write-Host "  ║  " -ForegroundColor Yellow -NoNewline
        Write-Host "⚠️  No PowerShell Files Found" -ForegroundColor White -NoNewline
        Write-Host "                                          ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                      ║" -ForegroundColor Yellow
        Write-Host "  ╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
        Write-Host "  ║                                                                      ║" -ForegroundColor Yellow
        Write-Host "  ║  " -ForegroundColor Yellow -NoNewline
        Write-Host "PoshGuard couldn't find any PowerShell files (.ps1, .psm1, .psd1)" -ForegroundColor White -NoNewline
        Write-Host "     ║" -ForegroundColor Yellow
        Write-Host "  ║  " -ForegroundColor Yellow -NoNewline
        Write-Host "in the path: " -ForegroundColor White -NoNewline
        Write-Host $Path -ForegroundColor Cyan -NoNewline
        $padding = 52 - $Path.Length
        if ($padding -lt 0) { $padding = 0 }
        Write-Host (" " * $padding) -NoNewline
        Write-Host "║" -ForegroundColor Yellow
        Write-Host "  ║                                                                      ║" -ForegroundColor Yellow
        Write-Host "  ╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
        Write-Host "  ║                                                                      ║" -ForegroundColor Yellow
        Write-Host "  ║  " -ForegroundColor Yellow -NoNewline
        Write-Host "💡 Tips:" -ForegroundColor White -NoNewline
        Write-Host "                                                                 ║" -ForegroundColor Yellow
        Write-Host "  ║     " -ForegroundColor Yellow -NoNewline
        Write-Host "• Make sure the path points to a PowerShell file or folder" -ForegroundColor White -NoNewline
        Write-Host "           ║" -ForegroundColor Yellow
        Write-Host "  ║     " -ForegroundColor Yellow -NoNewline
        Write-Host "• Check that files have .ps1, .psm1, or .psd1 extensions" -ForegroundColor White -NoNewline
        Write-Host "          ║" -ForegroundColor Yellow
        Write-Host "  ║     " -ForegroundColor Yellow -NoNewline
        Write-Host "• Verify the path exists and is accessible" -ForegroundColor White -NoNewline
        Write-Host "                        ║" -ForegroundColor Yellow
        Write-Host "  ║                                                                      ║" -ForegroundColor Yellow
        Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
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

    # Export SARIF if requested
    if ($ExportSarif) {
        Write-Verbose "Exporting results to SARIF format..."
        try {
            # Try to import ConvertToSARIF module
            if (Get-Module -ListAvailable ConvertToSARIF) {
                Import-Module ConvertToSARIF -ErrorAction Stop
                Write-Verbose "ConvertToSARIF module loaded"
            }
            else {
                Write-Warning "ConvertToSARIF module not found. Install with: Install-Module ConvertToSARIF -Force -AcceptLicense"
                continue
            }

            # Collect all PSScriptAnalyzer violations from results
            $allViolations = @()
            foreach ($result in $results) {
                if ($result.PSObject.Properties['Violations'] -and $result.Violations) {
                    $allViolations += $result.Violations
                }
            }

            # Run PSScriptAnalyzer on all files to get comprehensive results
            if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
                foreach ($file in $files) {
                    $fileViolations = Invoke-ScriptAnalyzer -Path $file.FullName -ErrorAction SilentlyContinue
                    if ($fileViolations) {
                        $allViolations += $fileViolations
                    }
                }
            }

            # Convert to SARIF
            if ($allViolations.Count -gt 0) {
                $allViolations | ConvertTo-SARIF -FilePath $SarifOutputPath
                Write-Host "  ✓ SARIF results exported to: $SarifOutputPath" -ForegroundColor Green
                Write-Verbose "  Exported $($allViolations.Count) violation(s) to SARIF"
            }
            else {
                Write-Verbose "No violations to export to SARIF"
                # Create empty SARIF file
                @() | ConvertTo-SARIF -FilePath $SarifOutputPath
                Write-Host "  ✓ Empty SARIF file created: $SarifOutputPath" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Failed to export SARIF: $_"
        }
    }

    # Enhanced summary section with statistics
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                                                      ║" -ForegroundColor Green
    Write-Host "  ║  " -ForegroundColor Green -NoNewline
    Write-Host "📊 SUMMARY" -ForegroundColor White -NoNewline
    Write-Host "                                                              ║" -ForegroundColor Green
    Write-Host "  ║                                                                      ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    # Calculate statistics
    $successRate = if ($files.Count -gt 0) { [Math]::Round(($fixedCount / $files.Count) * 100, 1) } else { 0 }
    $unchangedCount = $files.Count - $fixedCount
    
    # Files processed
    Write-Host "  " -NoNewline
    Write-Host "📁 Files Processed:  " -ForegroundColor Cyan -NoNewline
    Write-Host $files.Count -ForegroundColor White -NoNewline
    Write-Host " total" -ForegroundColor Gray
    
    # Files fixed
    Write-Host "  " -NoNewline
    if ($DryRun) {
        Write-Host "🔧 Would Fix:        " -ForegroundColor Yellow -NoNewline
        Write-Host $fixedCount -ForegroundColor White -NoNewline
        Write-Host " file(s) " -ForegroundColor Gray -NoNewline
        Write-Host "($successRate%)" -ForegroundColor Yellow
    }
    else {
        Write-Host "✅ Successfully Fixed: " -ForegroundColor Green -NoNewline
        Write-Host $fixedCount -ForegroundColor White -NoNewline
        Write-Host " file(s) " -ForegroundColor Gray -NoNewline
        Write-Host "($successRate%)" -ForegroundColor Green
    }
    
    # Files unchanged
    Write-Host "  " -NoNewline
    Write-Host "⚪ Unchanged:        " -ForegroundColor Gray -NoNewline
    Write-Host $unchangedCount -ForegroundColor White -NoNewline
    Write-Host " file(s)" -ForegroundColor Gray
    Write-Host ""
    
    # Save RL model if enabled and episodes completed
    if ($script:GlobalConfig.ReinforcementLearning.Enabled -and $script:EpisodeCount -gt 0) {
        try {
            Export-RLModel -OutputPath $script:GlobalConfig.ReinforcementLearning.ModelPath
            Write-Verbose "RL model saved ($script:EpisodeCount episodes)"
        }
        catch {
            Write-Verbose "Could not save RL model: $_"
        }
    }
    
    # Export observability metrics if enabled
    if ($script:GlobalConfig.Observability.Enabled) {
        try {
            $metricsPath = Export-OperationMetrics
            Write-Verbose "Metrics exported to: $metricsPath"
            
            # Check SLO compliance
            $sloStatus = Test-SLO
            if ($sloStatus.AllSLOsMet) {
                Write-Verbose "✅ All SLOs met (Availability: $($sloStatus.Availability.Actual)%, Quality: $($sloStatus.Quality.Actual)%)"
            }
            else {
                Write-Warning "⚠️  SLO breach detected. Check metrics for details."
            }
        }
        catch {
            Write-Verbose "Could not export metrics: $_"
        }
    }

    if ($DryRun) {
        Write-Host "  ┌──────────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
        Write-Host "  │ " -ForegroundColor Yellow -NoNewline
        Write-Host "👁️  DRY RUN MODE - No changes were made to your files" -ForegroundColor Yellow -NoNewline
        Write-Host "              │" -ForegroundColor Yellow
        Write-Host "  │                                                                      │" -ForegroundColor Yellow
        Write-Host "  │ " -ForegroundColor Yellow -NoNewline
        Write-Host "To apply these fixes, run the same command without " -ForegroundColor White -NoNewline
        Write-Host "-DryRun" -ForegroundColor Cyan -NoNewline
        Write-Host "        │" -ForegroundColor Yellow
        Write-Host "  │                                                                      │" -ForegroundColor Yellow
        Write-Host "  │ " -ForegroundColor Yellow -NoNewline
        Write-Host "Example: " -ForegroundColor Gray -NoNewline
        Write-Host "Invoke-PoshGuard -Path $Path" -ForegroundColor White -NoNewline
        $spacePadding = 29 - $Path.Length
        if ($spacePadding -lt 0) { $spacePadding = 0 }
        Write-Host (" " * $spacePadding) -NoNewline
        Write-Host "│" -ForegroundColor Yellow
        Write-Host "  └──────────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "  ║                                                                      ║" -ForegroundColor Green
        Write-Host "  ║  " -ForegroundColor Green -NoNewline
        Write-Host "✨ SUCCESS! Auto-fix complete! 🎉" -ForegroundColor White -NoNewline
        Write-Host "                                  ║" -ForegroundColor Green
        Write-Host "  ║                                                                      ║" -ForegroundColor Green
        Write-Host "  ╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-Host "  ║                                                                      ║" -ForegroundColor Green
        Write-Host "  ║  " -ForegroundColor Green -NoNewline
        Write-Host "Your PowerShell code has been improved!" -ForegroundColor White -NoNewline
        Write-Host "                             ║" -ForegroundColor Green
        Write-Host "  ║                                                                      ║" -ForegroundColor Green
        if ($script:GlobalConfig.ReinforcementLearning.Enabled -and $script:EpisodeCount -gt 0) {
            Write-Host "  ║  " -ForegroundColor Green -NoNewline
            Write-Host "🤖 AI Learning: " -ForegroundColor Cyan -NoNewline
            Write-Host "$script:EpisodeCount episodes completed" -ForegroundColor White -NoNewline
            $rlPadding = 38 - $script:EpisodeCount.ToString().Length
            if ($rlPadding -lt 0) { $rlPadding = 0 }
            Write-Host (" " * $rlPadding) -NoNewline
            Write-Host "║" -ForegroundColor Green
            Write-Host "  ║     " -ForegroundColor Green -NoNewline
            Write-Host "(PoshGuard gets smarter with every run!)" -ForegroundColor Gray -NoNewline
            Write-Host "                      ║" -ForegroundColor Green
            Write-Host "  ║                                                                      ║" -ForegroundColor Green
        }
        Write-Host "  ║  " -ForegroundColor Green -NoNewline
        Write-Host "💾 Backups saved to: " -ForegroundColor Cyan -NoNewline
        Write-Host ".psqa-backup/" -ForegroundColor White -NoNewline
        Write-Host "                                ║" -ForegroundColor Green
        Write-Host "  ║     " -ForegroundColor Green -NoNewline
        Write-Host "(Use Restore-Backup.ps1 if you need to rollback)" -ForegroundColor Gray -NoNewline
        Write-Host "               ║" -ForegroundColor Green
        Write-Host "  ║                                                                      ║" -ForegroundColor Green
        Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
    }

    if ($CleanBackups) {
        Clean-Backups
    }

    exit 0

}
catch {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║                                                                      ║" -ForegroundColor Red
    Write-Host "  ║  " -ForegroundColor Red -NoNewline
    Write-Host "❌ ERROR: PoshGuard encountered a problem" -ForegroundColor White -NoNewline
    Write-Host "                          ║" -ForegroundColor Red
    Write-Host "  ║                                                                      ║" -ForegroundColor Red
    Write-Host "  ╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "  ║                                                                      ║" -ForegroundColor Red
    Write-Host "  ║  " -ForegroundColor Red -NoNewline
    Write-Host "Error Message:" -ForegroundColor Yellow -NoNewline
    Write-Host "                                                         ║" -ForegroundColor Red
    Write-Host "  ║  " -ForegroundColor Red -NoNewline
    Write-Host $_.Exception.Message -ForegroundColor White
    $msgLength = $_.Exception.Message.Length
    $padding = 68 - $msgLength
    if ($padding -lt 0) { $padding = 0 }
    Write-Host (" " * $padding) -NoNewline
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ║                                                                      ║" -ForegroundColor Red
    Write-Host "  ╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "  ║                                                                      ║" -ForegroundColor Red
    Write-Host "  ║  " -ForegroundColor Red -NoNewline
    Write-Host "💡 What to do:" -ForegroundColor White -NoNewline
    Write-Host "                                                         ║" -ForegroundColor Red
    Write-Host "  ║     " -ForegroundColor Red -NoNewline
    Write-Host "• Check that the path exists and is accessible" -ForegroundColor White -NoNewline
    Write-Host "                        ║" -ForegroundColor Red
    Write-Host "  ║     " -ForegroundColor Red -NoNewline
    Write-Host "• Ensure you have permission to read/write the files" -ForegroundColor White -NoNewline
    Write-Host "                ║" -ForegroundColor Red
    Write-Host "  ║     " -ForegroundColor Red -NoNewline
    Write-Host "• Try running with -Verbose for more details" -ForegroundColor White -NoNewline
    Write-Host "                        ║" -ForegroundColor Red
    Write-Host "  ║     " -ForegroundColor Red -NoNewline
    Write-Host "• Report issues at: https://github.com/cboyd0319/PoshGuard/issues" -ForegroundColor Cyan -NoNewline
    Write-Host "  ║" -ForegroundColor Red
    Write-Host "  ║                                                                      ║" -ForegroundColor Red
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    
    if ($VerbosePreference -eq 'Continue') {
        Write-Host "  Stack Trace:" -ForegroundColor DarkRed
        Write-Host "  $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        Write-Host ""
    }
    exit 1
}
finally {
    # Cleanup: Always save RL state on exit
    if ($script:GlobalConfig.ReinforcementLearning.Enabled) {
        try {
            Export-RLModel -OutputPath $script:GlobalConfig.ReinforcementLearning.ModelPath
        }
        catch {
            # Silently fail - don't disrupt main execution
            # Log for debugging if verbose logging is enabled
            Write-Verbose "Failed to export RL model during cleanup: $_"
        }
    }
}

#endregion
