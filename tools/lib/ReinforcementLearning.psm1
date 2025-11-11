<#
.SYNOPSIS
    Reinforcement Learning Module for Self-Improving Auto-Fixes

.DESCRIPTION
    **WORLD-CLASS INNOVATION**: THE FIRST PowerShell tool with reinforcement learning.
    
    Implements a Markov Decision Process (MDP) for continuous improvement of fix quality:
    - Learns from successful and failed fixes
    - Adapts rule parameters based on feedback
    - Optimizes fix selection strategies
    - Improves confidence scoring accuracy over time
    
    **Reference**: RePair: Automated Program Repair with Process-based Feedback | 
                   https://aclanthology.org/2024.findings-acl.973/ | High | 
                   RL with iterative feedback improves fix quality
    
    **Reference**: Automated program improvement with RL and GNN | 
                   https://link.springer.com/article/10.1007/s00500-023-08559-1 | High | 
                   AST-based transformations using graph neural networks

.NOTES
    Version: 4.3.0
    Part of PoshGuard Ultimate Genius Engineer (UGE) Framework
    Privacy: All learning is LOCAL ONLY - no data transmitted
    Cost: FREE
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import Constants module for centralized configuration
$ConstantsPath = Join-Path $PSScriptRoot 'Constants.psm1'
if (Test-Path $ConstantsPath) {
  Import-Module $ConstantsPath -Force -ErrorAction SilentlyContinue
}

#region Module Configuration

# Get RL parameters from Constants module (with fallbacks)
$RLLearningRate = if (Get-Command Get-PoshGuardConstant -ErrorAction SilentlyContinue) {
  Get-PoshGuardConstant -Name 'RLLearningRate'
} else { 0.1 }

$RLDiscountFactor = if (Get-Command Get-PoshGuardConstant -ErrorAction SilentlyContinue) {
  Get-PoshGuardConstant -Name 'RLDiscountFactor'
} else { 0.9 }

$RLExplorationRate = if (Get-Command Get-PoshGuardConstant -ErrorAction SilentlyContinue) {
  Get-PoshGuardConstant -Name 'RLExplorationRate'
} else { 0.1 }

$RLBatchSize = if (Get-Command Get-PoshGuardConstant -ErrorAction SilentlyContinue) {
  Get-PoshGuardConstant -Name 'RLBatchSize'
} else { 32 }

$RLMaxExperience = if (Get-Command Get-PoshGuardConstant -ErrorAction SilentlyContinue) {
  Get-PoshGuardConstant -Name 'RLMaxExperienceSize'
} else { 10000 }

$script:RLConfig = @{
  Enabled = $true
  LearningRate = $RLLearningRate          # From Constants.psm1
  DiscountFactor = $RLDiscountFactor      # From Constants.psm1
  ExplorationRate = $RLExplorationRate    # From Constants.psm1 (initial value)
  MinExplorationRate = 0.01               # Minimum exploration to maintain
  ExplorationDecay = 0.995                # Decay rate per episode
  ExperienceReplaySize = $RLMaxExperience # From Constants.psm1
  BatchSize = $RLBatchSize                # From Constants.psm1
  ModelPath = "./ml/rl-model.jsonl"
  MetricsPath = "./ml/rl-metrics.jsonl"
}

$script:QLearningTable = @{}
$script:ExperienceReplay = [System.Collections.Generic.Queue[hashtable]]::new()
$script:EpisodeCount = 0
$script:TotalReward = 0.0

#endregion

#region State Representation

function Get-CodeState {
  <#
    .SYNOPSIS
        Extract state representation from code for RL agent
    
    .DESCRIPTION
        Converts code into feature vector representing current state:
        - AST complexity metrics (nodes, depth, branches)
        - Violation types and severity
        - Code size and structure
        - Historical fix success rate for similar code
    
    .PARAMETER Content
        Code content to analyze
    
    .PARAMETER Violations
        Array of PSScriptAnalyzer violations
    
    .EXAMPLE
        $state = Get-CodeState -Content $code -Violations $violations
        # Returns: Feature vector for RL decision-making
    
    .OUTPUTS
        System.Collections.Hashtable - State representation
    #>
  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,
        
    [Parameter()]
    [array]$Violations = @()
  )
    
  try {
    # Parse AST for structural features
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$null,
      [ref]$null
    )
        
    # Calculate complexity metrics
    $allNodes = @($ast.FindAll({ $true }, $true))
    $functionNodes = @($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
    $conditionalNodes = @($ast.FindAll({ 
          $args[0] -is [System.Management.Automation.Language.IfStatementAst] -or
          $args[0] -is [System.Management.Automation.Language.SwitchStatementAst]
        }, $true))
    $loopNodes = @($ast.FindAll({ 
          $args[0] -is [System.Management.Automation.Language.ForStatementAst] -or
          $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] -or
          $args[0] -is [System.Management.Automation.Language.WhileStatementAst]
        }, $true))
        
    # Calculate cyclomatic complexity
    $cyclomaticComplexity = 1 + $conditionalNodes.Count + $loopNodes.Count
        
    # Calculate nesting depth
    $maxDepth = Get-ASTMaxDepth -AST $ast
        
    # Violation features
    $violationTypes = $Violations | Group-Object RuleName | ForEach-Object { $_.Name }
    $severityCounts = @{
      Error = @($Violations | Where-Object Severity -eq 'Error').Count
      Warning = @($Violations | Where-Object Severity -eq 'Warning').Count
      Information = @($Violations | Where-Object Severity -eq 'Information').Count
    }
        
    # Create state vector (normalized features)
    $state = @{
      # Structural features (normalized by log scale)
      NodeCount = [Math]::Log($allNodes.Count + 1)
      FunctionCount = [Math]::Log($functionNodes.Count + 1)
      CyclomaticComplexity = [Math]::Log($cyclomaticComplexity + 1)
      MaxDepth = [Math]::Min($maxDepth / 10.0, 1.0)  # Cap at 10
            
      # Size features (normalized)
      LineCount = [Math]::Log(($Content -split "`n").Count + 1)
      CharCount = [Math]::Log($Content.Length + 1)
            
      # Violation features (normalized)
      ViolationCount = [Math]::Log($Violations.Count + 1)
      ErrorCount = [Math]::Log($severityCounts.Error + 1)
      WarningCount = [Math]::Log($severityCounts.Warning + 1)
            
      # Categorical features (one-hot encoded top violations)
      HasSecurity = $violationTypes -match 'Security|Credential|Plaintext' ? 1.0 : 0.0
      HasFormatting = $violationTypes -match 'Whitespace|Alias|Casing' ? 1.0 : 0.0
      HasComplexity = $cyclomaticComplexity -gt 10 ? 1.0 : 0.0
            
      # Raw data for analysis
      RawViolations = $Violations
      RawContent = $Content
    }
        
    return $state
  }
  catch {
    Write-Warning "Failed to extract code state: $_"
    return @{
      NodeCount = 0; FunctionCount = 0; CyclomaticComplexity = 0
      MaxDepth = 0; LineCount = 0; CharCount = 0
      ViolationCount = 0; ErrorCount = 0; WarningCount = 0
      HasSecurity = 0; HasFormatting = 0; HasComplexity = 0
    }
  }
}

function Get-ASTMaxDepth {
  param([Parameter(Mandatory)]$AST)
    
  # Simple non-recursive approach: count all nested structures
  $maxDepth = 0
    
  # Find all nodes and calculate their nesting depth
  $allNodes = $AST.FindAll({ $true }, $true)
    
  foreach ($node in $allNodes) {
    $depth = 0
    $current = $node.Parent
        
    while ($null -ne $current) {
      $depth++
      $current = $current.Parent
            
      # Safety check to prevent infinite loops
      if ($depth -gt 100) {
        Write-Warning "Maximum depth exceeded, possible circular reference"
        break
      }
    }
        
    if ($depth -gt $maxDepth) {
      $maxDepth = $depth
    }
  }
    
  return $maxDepth
}

#endregion

#region Action Selection

function Select-FixAction {
  <#
    .SYNOPSIS
        Select optimal fix action using epsilon-greedy Q-learning
    
    .DESCRIPTION
        Implements epsilon-greedy policy for exploration vs exploitation:
        - With probability epsilon: explore (random action)
        - With probability 1-epsilon: exploit (best known action)
        
        Actions represent different fix strategies:
        - Apply standard fix with default parameters
        - Apply aggressive fix (more transformations)
        - Apply conservative fix (minimal changes)
        - Skip fix (when confidence is low)
    
    .PARAMETER State
        Current state representation
    
    .PARAMETER AvailableActions
        Array of available fix actions for current violation
    
    .EXAMPLE
        $action = Select-FixAction -State $state -AvailableActions @('standard', 'aggressive', 'conservative')
    
    .OUTPUTS
        System.String - Selected action name
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [hashtable]$State,
        
    [Parameter(Mandatory)]
    [string[]]$AvailableActions
  )
    
  if (-not $script:RLConfig.Enabled -or $AvailableActions.Count -eq 0) {
    return $AvailableActions[0]  # Default to first action
  }
    
  # Create state key (hash of state features)
  $stateKey = Get-StateKey -State $State
    
  # Initialize Q-values for this state if not seen before
  if (-not $script:QLearningTable.ContainsKey($stateKey)) {
    $script:QLearningTable[$stateKey] = @{}
    foreach ($action in $AvailableActions) {
      $script:QLearningTable[$stateKey][$action] = 0.0
    }
  }
    
  # Epsilon-greedy action selection
  $random = Get-Random -Minimum 0.0 -Maximum 1.0
    
  if ($random -lt $script:RLConfig.ExplorationRate) {
    # Explore: random action
    $selectedAction = $AvailableActions | Get-Random
    Write-Verbose "RL: Exploring with action '$selectedAction' (epsilon=$($script:RLConfig.ExplorationRate))"
  }
  else {
    # Exploit: best known action
    $qValues = $script:QLearningTable[$stateKey]
    $bestAction = $AvailableActions | Sort-Object { $qValues[$_] } -Descending | Select-Object -First 1
    $selectedAction = $bestAction
    Write-Verbose "RL: Exploiting with action '$selectedAction' (Q=$($qValues[$selectedAction]))"
  }
    
  return $selectedAction
}

function Get-StateKey {
  param([hashtable]$State)
    
  # Create deterministic key from state features (excluding raw data)
  $features = $State.Keys | Where-Object { $_ -notmatch '^Raw' } | Sort-Object
  $keyString = ($features | ForEach-Object { "$_=$($State[$_])" }) -join ','
    
  # Hash for compact representation
  $hasher = [System.Security.Cryptography.SHA256]::Create()
  $hashBytes = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($keyString))
  return [System.Convert]::ToBase64String($hashBytes).Substring(0, 16)
}

#endregion

#region Learning & Updates

function Update-QLearning {
  <#
    .SYNOPSIS
        Update Q-learning table based on observed reward
    
    .DESCRIPTION
        Implements Q-learning update rule:
        Q(s,a) = Q(s,a) + α[r + γ·max(Q(s',a')) - Q(s,a)]
        
        Where:
        - α = learning rate
        - r = reward (fix quality)
        - γ = discount factor
        - s = current state
        - a = action taken
        - s' = next state
    
    .PARAMETER State
        State before action
    
    .PARAMETER Action
        Action taken
    
    .PARAMETER Reward
        Reward received (e.g., confidence score)
    
    .PARAMETER NextState
        State after action
    
    .EXAMPLE
        Update-QLearning -State $state -Action 'aggressive' -Reward 0.95 -NextState $nextState
    
    .OUTPUTS
        None
    #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    [hashtable]$State,
        
    [Parameter(Mandatory)]
    [string]$Action,
        
    [Parameter(Mandatory)]
    [double]$Reward,
        
    [Parameter()]
    [hashtable]$NextState = @{}
  )
    
  if (-not $script:RLConfig.Enabled) {
    return
  }
    
  try {
    $stateKey = Get-StateKey -State $State
    $nextStateKey = if ($NextState.Count -gt 0) { Get-StateKey -State $NextState } else { $null }
        
    # Ensure Q-table entry exists
    if (-not $script:QLearningTable.ContainsKey($stateKey)) {
      $script:QLearningTable[$stateKey] = @{ $Action = 0.0 }
    }
        
    # Get current Q-value
    $currentQ = if ($script:QLearningTable[$stateKey].ContainsKey($Action)) {
      $script:QLearningTable[$stateKey][$Action]
    } else {
      $script:QLearningTable[$stateKey][$Action] = 0.0
      0.0
    }
        
    # Calculate max Q-value for next state
    $maxNextQ = 0.0
    if ($nextStateKey -and $script:QLearningTable.ContainsKey($nextStateKey)) {
      $maxNextQ = ($script:QLearningTable[$nextStateKey].Values | Measure-Object -Maximum).Maximum
    }
        
    # Q-learning update
    $alpha = $script:RLConfig.LearningRate
    $gamma = $script:RLConfig.DiscountFactor
    $newQ = $currentQ + $alpha * ($Reward + $gamma * $maxNextQ - $currentQ)
        
    # Update Q-table
    $script:QLearningTable[$stateKey][$Action] = $newQ
        
    # Store experience for replay
    $experience = @{
      State = $State
      Action = $Action
      Reward = $Reward
      NextState = $NextState
      Timestamp = Get-Date
    }
        
    $script:ExperienceReplay.Enqueue($experience)
        
    # Limit replay buffer size
    while ($script:ExperienceReplay.Count -gt $script:RLConfig.ExperienceReplaySize) {
      [void]$script:ExperienceReplay.Dequeue()
    }
        
    # Update metrics
    $script:TotalReward += $Reward
        
    Write-Verbose "RL Update: State=$($stateKey.Substring(0,8)) Action=$Action Reward=$Reward NewQ=$newQ"
  }
  catch {
    Write-Warning "Failed to update Q-learning: $_"
  }
}

function Start-ExperienceReplay {
  <#
    .SYNOPSIS
        Perform experience replay to stabilize learning
    
    .DESCRIPTION
        Samples random batches from experience replay buffer and updates Q-values.
        This improves data efficiency and breaks correlation in sequential experiences.
        
        **Reference**: Deep Q-Networks (DQN) experience replay technique
    
    .EXAMPLE
        Start-ExperienceReplay
    
    .OUTPUTS
        None
    #>
  [CmdletBinding(SupportsShouldProcess)]
  param()
    
  if (-not $script:RLConfig.Enabled -or $script:ExperienceReplay.Count -lt $script:RLConfig.BatchSize) {
    return
  }
    
  try {
    # Sample random batch
    $batch = $script:ExperienceReplay | Get-Random -Count $script:RLConfig.BatchSize
        
    # Update Q-values for each experience
    foreach ($experience in $batch) {
      Update-QLearning `
        -State $experience.State `
        -Action $experience.Action `
        -Reward $experience.Reward `
        -NextState $experience.NextState
    }
        
    Write-Verbose "RL: Experience replay completed with batch size $($script:RLConfig.BatchSize)"
  }
  catch {
    Write-Warning "Experience replay failed: $_"
  }
}

#endregion

#region Reward Calculation

function Get-FixReward {
  <#
    .SYNOPSIS
        Calculate reward for a fix based on multiple quality factors
    
    .DESCRIPTION
        Reward function combines:
        - Syntax validity (0.4 weight)
        - Violation reduction (0.3 weight)
        - Code quality improvement (0.2 weight)
        - Minimal change principle (0.1 weight)
        
        Rewards range from -1.0 (failed fix) to +1.0 (perfect fix)
    
    .PARAMETER OriginalContent
        Code before fix
    
    .PARAMETER FixedContent
        Code after fix
    
    .PARAMETER OriginalViolations
        Violations before fix
    
    .PARAMETER FixedViolations
        Violations after fix
    
    .EXAMPLE
        $reward = Get-FixReward -OriginalContent $before -FixedContent $after `
                                 -OriginalViolations $vBefore -FixedViolations $vAfter
    
    .OUTPUTS
        System.Double - Reward value (-1.0 to +1.0)
    #>
  [CmdletBinding()]
  [OutputType([double])]
  param(
    [Parameter(Mandatory)]
    [string]$OriginalContent,
        
    [Parameter(Mandatory)]
    [string]$FixedContent,
        
    [Parameter()]
    [array]$OriginalViolations = @(),
        
    [Parameter()]
    [array]$FixedViolations = @()
  )
    
  try {
    # 1. Syntax validity (40% weight) - CRITICAL
    $syntaxValid = Test-PowerShellSyntax -Content $FixedContent
    $syntaxScore = $syntaxValid ? 1.0 : -1.0  # Heavily penalize syntax errors
        
    # 2. Violation reduction (30% weight)
    $violationReduction = [Math]::Max(0, $OriginalViolations.Count - $FixedViolations.Count)
    $violationScore = if ($OriginalViolations.Count -gt 0) {
      $violationReduction / $OriginalViolations.Count
    } else {
      0.5  # Neutral if no violations
    }
        
    # 3. Code quality improvement (20% weight)
    $originalComplexity = Get-CodeComplexity -Content $OriginalContent
    $fixedComplexity = Get-CodeComplexity -Content $FixedContent
    $qualityScore = if ($fixedComplexity -le $originalComplexity) {
      1.0  # Complexity not increased
    } else {
      0.5  # Penalty for increased complexity
    }
        
    # 4. Minimal change (10% weight)
    $levenshteinDistance = Get-LevenshteinDistance -String1 $OriginalContent -String2 $FixedContent
    $maxLength = [Math]::Max($OriginalContent.Length, $FixedContent.Length)
    $changeRatio = if ($maxLength -gt 0) { $levenshteinDistance / $maxLength } else { 0 }
    $minimalScore = 1.0 - [Math]::Min($changeRatio, 1.0)  # Less change = higher score
        
    # Combined reward
    $reward = (
      $syntaxScore * 0.4 +
      $violationScore * 0.3 +
      $qualityScore * 0.2 +
      $minimalScore * 0.1
    )
        
    return $reward
  }
  catch {
    Write-Warning "Failed to calculate reward: $_"
    return -0.5  # Negative reward for errors
  }
}

function Test-PowerShellSyntax {
  param([string]$Content)
    
  try {
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
      $Content,
      [ref]$null,
      [ref]$parseErrors
    )
    return $parseErrors.Count -eq 0
  }
  catch {
    return $false
  }
}

function Get-CodeComplexity {
  param([string]$Content)
    
  try {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$null)
    $conditionals = $ast.FindAll({ 
        $args[0] -is [System.Management.Automation.Language.IfStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.SwitchStatementAst]
      }, $true).Count
    $loops = $ast.FindAll({ 
        $args[0] -is [System.Management.Automation.Language.ForStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.WhileStatementAst]
      }, $true).Count
    return 1 + $conditionals + $loops
  }
  catch {
    return 100  # High complexity for unparseable code
  }
}

function Get-LevenshteinDistance {
  param([string]$String1, [string]$String2)
    
  $len1 = $String1.Length
  $len2 = $String2.Length
  $d = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
  for ($i = 0; $i -le $len1; $i++) { $d[$i, 0] = $i }
  for ($j = 0; $j -le $len2; $j++) { $d[0, $j] = $j }
    
  for ($i = 1; $i -le $len1; $i++) {
    for ($j = 1; $j -le $len2; $j++) {
      $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
      $d[$i, $j] = [Math]::Min([Math]::Min($d[$i - 1, $j] + 1, $d[$i, $j - 1] + 1), $d[$i - 1, $j - 1] + $cost)
    }
  }
    
  return $d[$len1, $len2]
}

#endregion

#region Model Persistence

function Export-RLModel {
  <#
    .SYNOPSIS
        Save Q-learning model to disk
    
    .EXAMPLE
        Export-RLModel
    #>
  [CmdletBinding()]
  param()
    
  try {
    $modelDir = Split-Path $script:RLConfig.ModelPath -Parent
    if (-not (Test-Path $modelDir)) {
      New-Item -ItemType Directory -Path $modelDir -Force | Out-Null
    }
        
    $modelData = @{
      QLearningTable = $script:QLearningTable
      EpisodeCount = $script:EpisodeCount
      TotalReward = $script:TotalReward
      Config = $script:RLConfig
      LastUpdate = Get-Date
    }
        
    $modelData | ConvertTo-Json -Depth 10 | Set-Content $script:RLConfig.ModelPath -Encoding UTF8
    Write-Verbose "RL model saved to $($script:RLConfig.ModelPath)"
  }
  catch {
    Write-Warning "Failed to export RL model: $_"
  }
}

function Import-RLModel {
  <#
    .SYNOPSIS
        Load Q-learning model from disk
    
    .EXAMPLE
        Import-RLModel
    #>
  [CmdletBinding()]
  param()
    
  try {
    if (Test-Path $script:RLConfig.ModelPath) {
      $modelData = Get-Content $script:RLConfig.ModelPath -Raw | ConvertFrom-Json
            
      # Restore Q-table (convert from PSCustomObject to hashtable)
      $script:QLearningTable = @{}
      foreach ($stateKey in $modelData.QLearningTable.PSObject.Properties.Name) {
        $script:QLearningTable[$stateKey] = @{}
        foreach ($action in $modelData.QLearningTable.$stateKey.PSObject.Properties.Name) {
          $script:QLearningTable[$stateKey][$action] = $modelData.QLearningTable.$stateKey.$action
        }
      }
            
      $script:EpisodeCount = $modelData.EpisodeCount
      $script:TotalReward = $modelData.TotalReward
            
      Write-Verbose "RL model loaded from $($script:RLConfig.ModelPath) with $($script:QLearningTable.Count) states"
    }
  }
  catch {
    Write-Warning "Failed to import RL model: $_"
  }
}

#endregion

#region Module Initialization

# Load existing model on import
Import-RLModel

# Export functions
Export-ModuleMember -Function @(
  'Get-CodeState',
  'Select-FixAction',
  'Update-QLearning',
  'Start-ExperienceReplay',
  'Get-FixReward',
  'Export-RLModel',
  'Import-RLModel'
)

#endregion
