@{
  # PSScriptAnalyzer configuration specifically for test files
  # Enforces high-quality test standards aligned with Pester Architect principles
  
  ExcludeRules = @(
    # Allow Write-Host in tests for debugging output
    'PSAvoidUsingWriteHost'
    # Allow positional parameters in test assertions (Pester style)
    'PSAvoidUsingPositionalParameters'
    # Allow ConvertTo-SecureString with -AsPlainText in test context for test data setup
    'PSAvoidUsingConvertToSecureStringWithPlainText'
  )
  
  IncludeRules = @(
    # Critical rules for test quality
    'PSUseDeclaredVarsMoreThanAssignments',
    'PSUseConsistentIndentation',
    'PSUseConsistentWhitespace',
    'PSUseBOMForUnicodeEncodedFile',
    'PSUseApprovedVerbs',
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidDefaultValueForMandatoryParameter',
    'PSAvoidUsingComputerNameHardcoded',
    'PSAvoidUsingInvokeExpression',
    'PSAvoidUsingEmptyCatchBlock',
    'PSUseCmdletCorrectly',
    'PSReservedCmdletChar',
    'PSReservedParams',
    'PSUseOutputTypeCorrectly',
    'PSAvoidGlobalVars',
    'PSUseSingularNouns'
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
      Enable = $false  # Disabled - tests use double quotes for consistency with production code
    }
  }
  
  Severity = @('Error', 'Warning', 'Information')
}
