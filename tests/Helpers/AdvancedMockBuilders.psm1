<#
.SYNOPSIS
    Advanced mock builders for complex test scenarios

.DESCRIPTION
    Provides utilities for creating mock objects, AST nodes, and test data
    for comprehensive testing of PoshGuard modules. Follows Pester v5+ patterns
    and ensures deterministic test execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Version: 1.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-MockAstNode {
  <#
  .SYNOPSIS
      Create mock AST nodes for testing AST-based functions
  
  .DESCRIPTION
      Generates PSCustomObject representations of PowerShell AST nodes
      with properties commonly accessed during code analysis.
  
  .PARAMETER NodeType
      Type of AST node to create (Function, Parameter, Command, IfStatement, ScriptBlock)
  
  .PARAMETER Properties
      Hashtable of additional properties to set on the node
  
  .EXAMPLE
      $funcNode = New-MockAstNode -NodeType 'Function' -Properties @{
          Name = 'Test-Function'
          Parameters = @()
      }
  
  .OUTPUTS
      PSCustomObject representing an AST node
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('Function', 'Parameter', 'Command', 'IfStatement', 'ScriptBlock', 'StringConstant', 'Variable')]
    [string]$NodeType,
    
    [Parameter()]
    [hashtable]$Properties = @{}
  )
  
  # Base properties common to all AST nodes
  $baseProperties = @{
    NodeType = $NodeType
    Extent   = [PSCustomObject]@{
      StartLineNumber   = 1
      StartColumnNumber = 1
      EndLineNumber     = 1
      EndColumnNumber   = 10
      Text              = ''
    }
    Parent   = $null
  }
  
  # Type-specific default properties
  $typeProperties = switch ($NodeType) {
    'Function' {
      @{
        Name       = 'MockFunction'
        Parameters = @()
        Body       = $null
        IsFilter   = $false
      }
    }
    'Parameter' {
      @{
        Name         = [PSCustomObject]@{
          VariablePath = [PSCustomObject]@{ UserPath = 'TestParam' }
        }
        StaticType   = [string]
        Attributes   = @()
        DefaultValue = $null
      }
    }
    'Command' {
      @{
        CommandElements = @()
        InvocationOperator = 'Unknown'
        Redirections = @()
      }
    }
    'IfStatement' {
      @{
        Clauses    = @()
        ElseClause = $null
      }
    }
    'ScriptBlock' {
      @{
        ParamBlock = $null
        BeginBlock = $null
        ProcessBlock = $null
        EndBlock = $null
        Statements = @()
      }
    }
    'StringConstant' {
      @{
        Value = ''
        StringConstantType = 'BareWord'
      }
    }
    'Variable' {
      @{
        VariablePath = [PSCustomObject]@{ UserPath = 'Variable' }
      }
    }
  }
  
  # Merge properties
  $allProperties = $baseProperties + $typeProperties + $Properties
  
  return [PSCustomObject]$allProperties
}

function New-MockConfiguration {
  <#
  .SYNOPSIS
      Create test configuration hashtables with realistic values
  
  .DESCRIPTION
      Generates configuration hashtables for testing configuration management
      functions with various presets and custom overrides.
  
  .PARAMETER Preset
      Configuration preset to use as a base
  
  .PARAMETER Overrides
      Hashtable of values to override in the preset
  
  .EXAMPLE
      $config = New-MockConfiguration -Preset 'Minimal'
  
  .EXAMPLE
      $config = New-MockConfiguration -Preset 'Default' -Overrides @{
          'Core.LogLevel' = 'Debug'
          'AI.Enabled' = $false
      }
  
  .OUTPUTS
      Hashtable representing a PoshGuard configuration
  #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [Parameter()]
    [ValidateSet('Minimal', 'Default', 'Full', 'Testing')]
    [string]$Preset = 'Default',
    
    [Parameter()]
    [hashtable]$Overrides = @{}
  )
  
  $config = switch ($Preset) {
    'Minimal' {
      @{
        Core = @{
          MaxFileSizeBytes    = 1048576  # 1MB
          BackupRetentionDays = 1
          Encoding            = 'UTF8BOM'
          LogLevel            = 'Error'
        }
        AI   = @{
          Enabled = $false
        }
      }
    }
    'Default' {
      @{
        Core                   = @{
          MaxFileSizeBytes    = 10485760  # 10MB
          BackupRetentionDays = 7
          Encoding            = 'UTF8BOM'
          LogLevel            = 'Info'
        }
        AI                     = @{
          Enabled                 = $true
          ConfidenceScoring       = $true
          PatternLearning         = $true
          MinConfidenceThreshold  = 0.75
        }
        ReinforcementLearning  = @{
          Enabled              = $true
          LearningRate         = 0.1
          DiscountFactor       = 0.95
          ExplorationRate      = 0.2
          MinExplorationRate   = 0.01
          ExplorationDecay     = 0.995
        }
        SecretDetection        = @{
          Enabled          = $true
          EntropyThresholds = @{
            Base64 = 4.5
            Hex    = 3.0
            Ascii  = 3.5
          }
        }
      }
    }
    'Full' {
      @{
        Core                   = @{
          MaxFileSizeBytes    = 10485760
          BackupRetentionDays = 7
          Encoding            = 'UTF8BOM'
          LogLevel            = 'Info'
        }
        AI                     = @{
          Enabled                = $true
          ConfidenceScoring      = $true
          PatternLearning        = $true
          MinConfidenceThreshold = 0.75
        }
        ReinforcementLearning  = @{
          Enabled             = $true
          LearningRate        = 0.1
          DiscountFactor      = 0.95
          ExplorationRate     = 0.2
          MinExplorationRate  = 0.01
          ExplorationDecay    = 0.995
          ExperienceReplaySize = 1000
          BatchSize           = 32
        }
        SecretDetection        = @{
          Enabled          = $true
          EntropyThresholds = @{
            Base64 = 4.5
            Hex    = 3.0
            Ascii  = 3.5
          }
          MinLengths       = @{
            Base64 = 20
            Hex    = 20
            Ascii  = 16
          }
        }
        MCP                    = @{
          Enabled    = $false
          UserConsent = $false
          Servers    = @()
        }
        Observability          = @{
          Enabled           = $true
          StructuredLogging = $true
          Metrics           = $true
          Tracing           = $true
        }
        SLO                    = @{
          AvailabilityTarget = 99.5
          LatencyP95Target   = 5000
          QualityTarget      = 95.0
          CorrectnessTarget  = 100.0
        }
        Security               = @{
          ScanForSecrets          = $true
          EnforceSecureStrings    = $true
          BlockDangerousCommands  = $true
          ValidateCertificates    = $true
        }
        Performance            = @{
          ParallelProcessing  = $false
          MaxParallelFiles    = 4
          CacheAST            = $true
          IncrementalAnalysis = $false
        }
      }
    }
    'Testing' {
      @{
        Core = @{
          MaxFileSizeBytes    = 1024
          BackupRetentionDays = 0
          Encoding            = 'UTF8'
          LogLevel            = 'Debug'
        }
        AI   = @{
          Enabled = $true
          MinConfidenceThreshold = 0.5
        }
        ReinforcementLearning = @{
          Enabled = $false
        }
      }
    }
  }
  
  # Apply overrides
  foreach ($key in $Overrides.Keys) {
    $parts = $key -split '\.'
    $current = $config
    
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
      if (-not $current.ContainsKey($parts[$i])) {
        $current[$parts[$i]] = @{}
      }
      $current = $current[$parts[$i]]
    }
    
    $current[$parts[-1]] = $Overrides[$key]
  }
  
  return $config
}

function New-TestScript {
  <#
  .SYNOPSIS
      Generate test PowerShell scripts with specific patterns
  
  .DESCRIPTION
      Creates PowerShell script content with various characteristics for testing
      code analysis, formatting, and security detection functions.
  
  .PARAMETER Pattern
      Type of script pattern to generate
  
  .PARAMETER Lines
      Approximate number of lines to generate
  
  .PARAMETER Seed
      Random seed for deterministic generation
  
  .EXAMPLE
      $script = New-TestScript -Pattern 'WithSecrets' -Lines 30
  
  .OUTPUTS
      String containing PowerShell script content
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter()]
    [ValidateSet('Clean', 'WithSecrets', 'WithComplexity', 'WithSecurityIssues', 'WithFormatting')]
    [string]$Pattern = 'Clean',
    
    [Parameter()]
    [ValidateRange(5, 1000)]
    [int]$Lines = 50,
    
    [Parameter()]
    [int]$Seed
  )
  
  if ($Seed) {
    Get-Random -SetSeed $Seed | Out-Null
  }
  
  $script = switch ($Pattern) {
    'Clean' {
      @"
function Get-TestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]`$Path
    )
    
    if (-not (Test-Path `$Path)) {
        throw "Path not found: `$Path"
    }
    
    `$data = Get-Content -Path `$Path -Raw
    return `$data
}

function Set-TestData {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]`$Path,
        
        [Parameter(Mandatory)]
        [string]`$Content
    )
    
    if (`$PSCmdlet.ShouldProcess(`$Path, 'Write content')) {
        Set-Content -Path `$Path -Value `$Content -Encoding UTF8
    }
}
"@
    }
    
    'WithSecrets' {
      @"
function Connect-Service {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]`$Username,
        
        [Parameter(Mandatory)]
        [string]`$Password
    )
    
    # BAD: Plain text password parameter
    `$apiKey = 'ghp_xK3m9Zq2Lp5Jn8Rt4Yc1Wf6Hb7Vd0Aa3'
    `$connectionString = "Server=myserver;Database=mydb;User Id=sa;Password=P@ssw0rd123;"
    
    `$cred = [PSCredential]::new(`$Username, (ConvertTo-SecureString -String `$Password -AsPlainText -Force))
    
    return `$cred
}
"@
    }
    
    'WithComplexity' {
      @"
function Get-ComplexData {
    param(`$Input)
    
    if (`$Input) {
        if (`$Input.Type -eq 'A') {
            if (`$Input.SubType -eq '1') {
                if (`$Input.Value -gt 10) {
                    if (`$Input.Enabled) {
                        return 'DeepNest'
                    }
                }
            }
        }
    }
    
    for (`$i = 0; `$i -lt 100; `$i++) {
        for (`$j = 0; `$j -lt 100; `$j++) {
            for (`$k = 0; `$k -lt 100; `$k++) {
                `$result += `$i * `$j * `$k
            }
        }
    }
    
    return `$result
}
"@
    }
    
    'WithSecurityIssues' {
      @"
function Invoke-UnsafeCommand {
    param([string]`$Command)
    
    # BAD: Using Invoke-Expression
    Invoke-Expression `$Command
    
    # BAD: Empty catch block
    try {
        Get-Content 'file.txt'
    }
    catch {
    }
    
    # BAD: Hardcoded computer name
    `$computer = 'PROD-SERVER-01'
    Invoke-Command -ComputerName `$computer -ScriptBlock { Get-Process }
    
    # BAD: Allowing unencrypted authentication
    Invoke-RestMethod -Uri 'http://api.example.com' -AllowUnencryptedAuthentication
}
"@
    }
    
    'WithFormatting' {
      @"
function    Get-Data{
param(\$a,\$b,\$c)
if(\$a  -eq   \$b){
return   \$c
}
else    {
return    \$a
}
}

function Set-Value ( \$x , \$y ) {
\$result=\$x+\$y
Write-Host   "Result: \$result"
return     \$result
}
"@
    }
  }
  
  return $script
}

function New-MockFileInfo {
  <#
  .SYNOPSIS
      Create mock FileInfo objects for testing file operations
  
  .PARAMETER Path
      File path
  
  .PARAMETER Extension
      File extension (e.g., '.ps1', '.psm1')
  
  .PARAMETER Size
      File size in bytes
  
  .EXAMPLE
      $file = New-MockFileInfo -Path 'C:\test\script.ps1' -Extension '.ps1' -Size 1024
  
  .OUTPUTS
      PSCustomObject representing a FileInfo object
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [string]$Path,
    
    [Parameter()]
    [string]$Extension = '.ps1',
    
    [Parameter()]
    [int]$Size = 1024
  )
  
  return [PSCustomObject]@{
    FullName      = $Path
    Name          = Split-Path -Path $Path -Leaf
    Extension     = $Extension
    DirectoryName = Split-Path -Path $Path -Parent
    Length        = $Size
    Exists        = $true
    CreationTime  = Get-Date
    LastWriteTime = Get-Date
  }
}

# Export functions
Export-ModuleMember -Function @(
  'New-MockAstNode',
  'New-MockConfiguration',
  'New-TestScript',
  'New-MockFileInfo'
)
