@{
  # PSScriptAnalyzer configuration for PoshGuard
  # Enforces high-quality PowerShell standards aligned with Pester testing
  
  ExcludeRules = @()
  
  IncludeRules = @(
    'PSUseDeclaredVarsMoreThanAssignments',
    'PSAvoidUsingWriteHost',
    'PSUseConsistentIndentation',
    'PSUseConsistentWhitespace',
    'PSUseBOMForUnicodeEncodedFile',
    'PSUseApprovedVerbs',
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidDefaultValueForMandatoryParameter',
    'PSAvoidUsingComputerNameHardcoded',
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSAvoidUsingInvokeExpression',
    'PSAvoidUsingEmptyCatchBlock',
    'PSUseCmdletCorrectly',
    'PSReservedCmdletChar',
    'PSReservedParams',
    'PSUseShouldProcessForStateChangingFunctions',
    'PSUseOutputTypeCorrectly',
    'PSAvoidGlobalVars',
    'PSAvoidUsingPositionalParameters',
    'PSUseSingularNouns',
    'PSMissingModuleManifestField',
    'PSAvoidUsingDeprecatedManifestFields'
  )
  
  Rules = @{
    PSUseConsistentIndentation = @{
      Enable              = $true
      IndentationSize     = 2
      PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
      Kind                = 'space'
    }
    
    PSUseConsistentWhitespace = @{
      Enable                          = $true
      CheckInnerBrace                 = $true
      CheckOpenBrace                  = $true
      CheckOpenParen                  = $true
      CheckOperator                   = $true
      CheckPipe                       = $true
      CheckPipeForRedundantWhitespace = $true
      CheckSeparator                  = $true
      CheckParameter                  = $true
    }
    
    PSAlignAssignmentStatement = @{
      Enable         = $true
      CheckHashtable = $true
    }
    
    PSPlaceOpenBrace = @{
      Enable             = $true
      OnSameLine         = $true
      NewLineAfter       = $true
      IgnoreOneLineBlock = $true
    }
    
    PSPlaceCloseBrace = @{
      Enable             = $true
      NewLineAfter       = $false
      IgnoreOneLineBlock = $true
      NoEmptyLineBefore  = $false
    }
    
    PSUseCorrectCasing = @{
      Enable = $true
    }
    
    PSAvoidUsingDoubleQuotesForConstantString = @{
      Enable = $false  # Disabled - PoshGuard uses double quotes for consistency
    }
  }
  
  Severity = @('Error', 'Warning', 'Information')
}
