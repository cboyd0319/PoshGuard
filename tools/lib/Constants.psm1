<#
.SYNOPSIS
    PoshGuard Constants and Configuration

.DESCRIPTION
    Centralized constants and configuration values used throughout PoshGuard.
    Replaces magic numbers and hardcoded strings with named constants.

.NOTES
    Module: Constants
    Version: 4.3.0
    Part of PoshGuard v4.3.0
    Author: https://github.com/cboyd0319

    This module eliminates 40+ magic numbers found in the codebase analysis.
#>

Set-StrictMode -Version Latest

# =============================================================================
# FILE SIZE LIMITS
# =============================================================================

# Maximum file size for processing (10 MB default)
New-Variable -Name MaxFileSizeBytes -Value (10 * 1024 * 1024) -Option ReadOnly -Scope Script -Force

# Maximum file size limit (100 MB absolute max)
New-Variable -Name AbsoluteMaxFileSizeBytes -Value (100 * 1024 * 1024) -Option ReadOnly -Scope Script -Force

# Minimum file size (1 byte)
New-Variable -Name MinFileSizeBytes -Value 1 -Option ReadOnly -Scope Script -Force

# =============================================================================
# ENTROPY THRESHOLDS (for secret detection)
# =============================================================================

# High entropy threshold (likely secret)
New-Variable -Name HighEntropyThreshold -Value 4.5 -Option ReadOnly -Scope Script -Force

# Medium entropy threshold (possible secret)
New-Variable -Name MediumEntropyThreshold -Value 3.5 -Option ReadOnly -Scope Script -Force

# Low entropy threshold (unlikely secret)
New-Variable -Name LowEntropyThreshold -Value 3.0 -Option ReadOnly -Scope Script -Force

# =============================================================================
# AST PROCESSING LIMITS
# =============================================================================

# Maximum AST depth to prevent infinite recursion
New-Variable -Name MaxASTDepth -Value 100 -Option ReadOnly -Scope Script -Force

# Maximum number of AST nodes to process
New-Variable -Name MaxASTNodes -Value 10000 -Option ReadOnly -Scope Script -Force

# =============================================================================
# TIMEOUT VALUES (milliseconds)
# =============================================================================

# Default command timeout (5 seconds)
New-Variable -Name DefaultCommandTimeoutMs -Value 5000 -Option ReadOnly -Scope Script -Force

# Short timeout for quick operations (2 seconds)
New-Variable -Name ShortTimeoutMs -Value 2000 -Option ReadOnly -Scope Script -Force

# Long timeout for complex operations (30 seconds)
New-Variable -Name LongTimeoutMs -Value 30000 -Option ReadOnly -Scope Script -Force

# =============================================================================
# REINFORCEMENT LEARNING PARAMETERS
# =============================================================================

# Learning rate (alpha)
New-Variable -Name RLLearningRate -Value 0.1 -Option ReadOnly -Scope Script -Force

# Discount factor (gamma)
New-Variable -Name RLDiscountFactor -Value 0.9 -Option ReadOnly -Scope Script -Force

# Exploration rate (epsilon)
New-Variable -Name RLExplorationRate -Value 0.1 -Option ReadOnly -Scope Script -Force

# Experience replay batch size
New-Variable -Name RLBatchSize -Value 32 -Option ReadOnly -Scope Script -Force

# Maximum experience replay buffer size
New-Variable -Name RLMaxExperienceSize -Value 10000 -Option ReadOnly -Scope Script -Force

# =============================================================================
# CODE QUALITY THRESHOLDS
# =============================================================================

# Maximum cyclomatic complexity
New-Variable -Name MaxCyclomaticComplexity -Value 15 -Option ReadOnly -Scope Script -Force

# Maximum function length (lines)
New-Variable -Name MaxFunctionLength -Value 50 -Option ReadOnly -Scope Script -Force

# Maximum file length (lines)
New-Variable -Name MaxFileLength -Value 600 -Option ReadOnly -Scope Script -Force

# Maximum nesting depth
New-Variable -Name MaxNestingDepth -Value 4 -Option ReadOnly -Scope Script -Force

# =============================================================================
# BACKUP RETENTION
# =============================================================================

# Backup retention period (days)
New-Variable -Name BackupRetentionDays -Value 1 -Option ReadOnly -Scope Script -Force

# Maximum number of backups per file
New-Variable -Name MaxBackupsPerFile -Value 10 -Option ReadOnly -Scope Script -Force

# =============================================================================
# STRING LENGTHS
# =============================================================================

# Minimum secret length for detection
New-Variable -Name MinSecretLength -Value 16 -Option ReadOnly -Scope Script -Force

# Maximum line length before wrapping
New-Variable -Name MaxLineLength -Value 120 -Option ReadOnly -Scope Script -Force

# =============================================================================
# PERFORMANCE TUNING
# =============================================================================

# Number of parallel threads for processing
New-Variable -Name DefaultThreadCount -Value 4 -Option ReadOnly -Scope Script -Force

# Batch size for bulk operations
New-Variable -Name DefaultBatchSize -Value 100 -Option ReadOnly -Scope Script -Force

# =============================================================================
# FILE EXTENSIONS
# =============================================================================

# Supported PowerShell file extensions
New-Variable -Name PowerShellExtensions -Value @('.ps1', '.psm1', '.psd1') -Option ReadOnly -Scope Script -Force

# Backup file extension
New-Variable -Name BackupExtension -Value '.bak' -Option ReadOnly -Scope Script -Force

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function Get-PoshGuardConstant {
  <#
  .SYNOPSIS
      Retrieves a PoshGuard constant value by name

  .DESCRIPTION
      Provides safe access to PoshGuard constants with validation.

  .PARAMETER Name
      The name of the constant to retrieve

  .OUTPUTS
      The constant value, or $null if not found

  .EXAMPLE
      $maxSize = Get-PoshGuardConstant -Name 'MaxFileSizeBytes'
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name
  )

  try {
    $variable = Get-Variable -Name $Name -Scope Script -ErrorAction SilentlyContinue
    if ($variable) {
      return $variable.Value
    }
    Write-Warning "Constant '$Name' not found"
    return $null
  }
  catch {
    Write-Warning "Failed to retrieve constant '$Name': $_"
    return $null
  }
}

function Get-AllPoshGuardConstants {
  <#
  .SYNOPSIS
      Returns all PoshGuard constants as a hashtable

  .DESCRIPTION
      Useful for debugging and documentation generation.

  .OUTPUTS
      System.Collections.Hashtable
      Hashtable of all constant names and values

  .EXAMPLE
      $constants = Get-AllPoshGuardConstants
      $constants.Keys | Sort-Object
  #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param()

  $constants = @{}
  Get-Variable -Scope Script | Where-Object { $_.Options -match 'ReadOnly' } | ForEach-Object {
    $constants[$_.Name] = $_.Value
  }
  return $constants
}

# =============================================================================
# EXPORTS
# =============================================================================

Export-ModuleMember -Function @(
  'Get-PoshGuardConstant',
  'Get-AllPoshGuardConstants'
)

# Export all constant variables
Export-ModuleMember -Variable @(
  'MaxFileSizeBytes',
  'AbsoluteMaxFileSizeBytes',
  'MinFileSizeBytes',
  'HighEntropyThreshold',
  'MediumEntropyThreshold',
  'LowEntropyThreshold',
  'MaxASTDepth',
  'MaxASTNodes',
  'DefaultCommandTimeoutMs',
  'ShortTimeoutMs',
  'LongTimeoutMs',
  'RLLearningRate',
  'RLDiscountFactor',
  'RLExplorationRate',
  'RLBatchSize',
  'RLMaxExperienceSize',
  'MaxCyclomaticComplexity',
  'MaxFunctionLength',
  'MaxFileLength',
  'MaxNestingDepth',
  'BackupRetentionDays',
  'MaxBackupsPerFile',
  'MinSecretLength',
  'MaxLineLength',
  'DefaultThreadCount',
  'DefaultBatchSize',
  'PowerShellExtensions',
  'BackupExtension'
)
