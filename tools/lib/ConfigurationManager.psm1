<#
.SYNOPSIS
    Unified Configuration Management for PoshGuard

.DESCRIPTION
    Centralized configuration loading and validation for all PoshGuard modules.
    Supports:
    - JSON configuration files
    - Environment variable overrides
    - Runtime configuration updates
    - Configuration validation and defaults

.NOTES
    Version: 4.3.0
    Part of PoshGuard Ultimate Genius Engineer (UGE) Framework
    Reference: SWEBOK v4.0 - Configuration Management (KA 6)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Module Variables

$script:Config = $null
$script:ConfigPath = Join-Path $PSScriptRoot "../../config/poshguard.json"
$script:ConfigLoaded = $false

#endregion

#region Configuration Loading

function Initialize-PoshGuardConfiguration {
  <#
    .SYNOPSIS
        Load and validate PoshGuard configuration
    
    .DESCRIPTION
        Loads configuration from JSON file, applies environment variable overrides,
        and validates all settings.
    
    .PARAMETER ConfigPath
        Path to configuration JSON file (optional, uses default if not provided)
    
    .PARAMETER Force
        Force reload configuration even if already loaded
    
    .EXAMPLE
        Initialize-PoshGuardConfiguration
        # Loads default configuration
    
    .EXAMPLE
        Initialize-PoshGuardConfiguration -ConfigPath "./custom-config.json"
        # Loads custom configuration
    
    .OUTPUTS
        System.Collections.Hashtable - Loaded configuration
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [Parameter()]
    [string]$ConfigPath,
        
    [Parameter()]
    [switch]$Force
  )
    
  if ($script:ConfigLoaded -and -not $Force) {
    Write-Verbose "Configuration already loaded"
    return $script:Config
  }
    
  # Determine config path
  if (-not $ConfigPath) {
    $ConfigPath = $script:ConfigPath
  }
    
  # Load default configuration
  $script:Config = Get-DefaultConfiguration
    
  # Load from file if exists
  if (Test-Path $ConfigPath) {
    try {
      $fileConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
      $script:Config = Merge-Configuration -Base $script:Config -Override (ConvertTo-Hashtable $fileConfig)
      Write-Verbose "Configuration loaded from: $ConfigPath"
    }
    catch {
      Write-Warning "Failed to load configuration from ${ConfigPath}: $_. Using defaults."
    }
  }
  else {
    Write-Verbose "Configuration file not found: $ConfigPath. Using defaults."
  }
    
  # Apply environment variable overrides
  Set-EnvironmentOverrides -Config $script:Config
    
  # Validate configuration
  if (-not (Test-ConfigurationValid -Config $script:Config)) {
    throw "Configuration validation failed. Please check your settings."
  }
    
  $script:ConfigLoaded = $true
    
  return $script:Config
}

function Get-DefaultConfiguration {
  <#
    .SYNOPSIS
        Get default configuration values
    
    .OUTPUTS
        System.Collections.Hashtable - Default configuration
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param()
    
  return @{
    Core = @{
      MaxFileSizeBytes = 10485760  # 10MB
      BackupRetentionDays = 7
      Encoding = 'UTF8BOM'
      LogLevel = 'Info'
    }
    AI = @{
      Enabled = $true
      ConfidenceScoring = $true
      PatternLearning = $true
      MinConfidenceThreshold = 0.75
    }
    ReinforcementLearning = @{
      Enabled = $true
      LearningRate = 0.1
      DiscountFactor = 0.95
      ExplorationRate = 0.2
      MinExplorationRate = 0.01
      ExplorationDecay = 0.995
      ExperienceReplaySize = 1000
      BatchSize = 32
      ModelPath = "./ml/rl-model.jsonl"
      MetricsPath = "./ml/rl-metrics.jsonl"
      AutoSaveInterval = 100
    }
    SecretDetection = @{
      Enabled = $true
      EntropyThresholds = @{
        Base64 = 4.5
        Hex = 3.0
        Ascii = 3.5
      }
      MinLengths = @{
        Base64 = 20
        Hex = 20
        Ascii = 16
      }
      ScanComments = $true
      ScanStrings = $true
      ReportFalsePositives = $false
    }
    MCP = @{
      Enabled = $false
      UserConsent = $false
      Servers = @()
      CachePath = "./cache/mcp"
      CacheExpirationHours = 24
      Timeout = 5000
      RetryCount = 2
    }
    Observability = @{
      Enabled = $true
      StructuredLogging = $true
      Metrics = $true
      Tracing = $true
      ExportFormat = 'JSONL'
      LogPath = './logs'
      MetricsPath = './metrics'
    }
    SLO = @{
      AvailabilityTarget = 99.5
      LatencyP95Target = 5000
      QualityTarget = 95.0
      CorrectnessTarget = 100.0
    }
    Security = @{
      ScanForSecrets = $true
      EnforceSecureStrings = $true
      BlockDangerousCommands = $true
      ValidateCertificates = $true
    }
    Performance = @{
      ParallelProcessing = $false
      MaxParallelFiles = 4
      CacheAST = $true
      IncrementalAnalysis = $false
    }
    Standards = @{
      OwaspAsvs = $true
      NistSp80053 = $true
      Cis = $true
      Iso27001 = $true
      PciDss = $true
      Hipaa = $true
      Soc2 = $true
      Fedramp = $true
      Cmmc = $true
    }
  }
}

function Get-PoshGuardConfiguration {
  <#
    .SYNOPSIS
        Get current PoshGuard configuration
    
    .DESCRIPTION
        Returns the loaded configuration. Initializes if not already loaded.
    
    .OUTPUTS
        System.Collections.Hashtable - Current configuration
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param()
    
  if (-not $script:ConfigLoaded) {
    Initialize-PoshGuardConfiguration
  }
    
  return $script:Config
}

function Set-PoshGuardConfigurationValue {
  <#
    .SYNOPSIS
        Update a configuration value at runtime
    
    .PARAMETER Path
        Configuration path (e.g., "AI.Enabled", "MCP.UserConsent")
    
    .PARAMETER Value
        New value to set
    
    .EXAMPLE
        Set-PoshGuardConfigurationValue -Path "MCP.Enabled" -Value $true
    #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    [string]$Path,
        
    [Parameter(Mandatory)]
    [object]$Value
  )
    
  if (-not $script:ConfigLoaded) {
    Initialize-PoshGuardConfiguration
  }
    
  if ($PSCmdlet.ShouldProcess("Configuration: $Path", "Set value to $Value")) {
    $parts = $Path -split '\.'
    $current = $script:Config
    
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
      if (-not $current.ContainsKey($parts[$i])) {
        $current[$parts[$i]] = @{}
      }
      $current = $current[$parts[$i]]
    }
    
    $current[$parts[-1]] = $Value
    Write-Verbose "Configuration updated: $Path = $Value"
  }
}

#endregion

#region Helper Functions

function ConvertTo-Hashtable {
  <#
    .SYNOPSIS
        Convert PSCustomObject to Hashtable recursively
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$InputObject
  )
    
  process {
    if ($null -eq $InputObject) { return $null }
        
    if ($InputObject -is [System.Collections.IDictionary]) {
      $hash = @{}
      foreach ($key in $InputObject.Keys) {
        $hash[$key] = ConvertTo-Hashtable $InputObject[$key]
      }
      return $hash
    }
        
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
      return @($InputObject | ForEach-Object { ConvertTo-Hashtable $_ })
    }
        
    if ($InputObject -is [psobject]) {
      $hash = @{}
      foreach ($property in $InputObject.PSObject.Properties) {
        $hash[$property.Name] = ConvertTo-Hashtable $property.Value
      }
      return $hash
    }
        
    return $InputObject
  }
}

function Merge-Configuration {
  <#
    .SYNOPSIS
        Merge two configuration hashtables
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [Parameter(Mandatory)]
    [hashtable]$Base,
        
    [Parameter(Mandatory)]
    [hashtable]$Override
  )
    
  $result = $Base.Clone()
    
  foreach ($key in $Override.Keys) {
    if ($result.ContainsKey($key) -and 
      $result[$key] -is [hashtable] -and 
      $Override[$key] -is [hashtable]) {
      $result[$key] = Merge-Configuration -Base $result[$key] -Override $Override[$key]
    }
    else {
      $result[$key] = $Override[$key]
    }
  }
    
  return $result
}

function Set-EnvironmentOverride {
  <#
    .SYNOPSIS
        Apply environment variable overrides to configuration
    #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    [hashtable]$Config
  )
    
  # Example: POSHGUARD_AI_ENABLED=false
  $prefix = 'POSHGUARD_'
    
  Get-ChildItem env: | Where-Object Name -like "${prefix}*" | ForEach-Object {
    $envName = $_.Name.Substring($prefix.Length)
    $path = $envName.Replace('_', '.')
    $value = $_.Value
        
    # Convert string values to appropriate types
    if ($value -ieq 'true') { $value = $true }
    elseif ($value -ieq 'false') { $value = $false }
    elseif ($value -match '^\d+$') { $value = [int]$value }
    elseif ($value -match '^\d+\.\d+$') { $value = [double]$value }
        
    try {
      Set-PoshGuardConfigurationValue -Path $path -Value $value
      Write-Verbose "Environment override applied: $path = $value"
    }
    catch {
      Write-Warning "Failed to apply environment override for ${path}: $_"
    }
  }
}

function Test-ConfigurationValid {
  <#
    .SYNOPSIS
        Validate configuration values
    #>
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Mandatory)]
    [hashtable]$Config
  )
    
  $valid = $true
    
  # Validate ranges
  if ($Config.Core.MaxFileSizeBytes -lt 1024) {
    Write-Error "Core.MaxFileSizeBytes must be at least 1024 bytes"
    $valid = $false
  }
    
  if ($Config.ReinforcementLearning.LearningRate -le 0 -or 
    $Config.ReinforcementLearning.LearningRate -gt 1) {
    Write-Error "ReinforcementLearning.LearningRate must be between 0 and 1"
    $valid = $false
  }
    
  if ($Config.SLO.AvailabilityTarget -le 0 -or 
    $Config.SLO.AvailabilityTarget -gt 100) {
    Write-Error "SLO.AvailabilityTarget must be between 0 and 100"
    $valid = $false
  }
    
  return $valid
}

#endregion

#region Export

Export-ModuleMember -Function @(
  'Initialize-PoshGuardConfiguration',
  'Get-PoshGuardConfiguration',
  'Set-PoshGuardConfigurationValue',
  'Get-DefaultConfiguration'
)

#endregion