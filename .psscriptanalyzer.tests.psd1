@{
    # PSScriptAnalyzer configuration for test files
    # Enforces Pester Architect principles

    ExcludeRules = @(
        # Allow unapproved verbs in test helpers
        'PSUseApprovedVerbs'
    )

    IncludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSUseBOMForUnicodeEncodedFile'
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 2
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckPipe = $true
            CheckSeparator = $true
        }

        # Ban Start-Sleep in test files - anti-pattern for Pester Architect
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            Whitelist = @()
        }
    }

    Severity = @('Error', 'Warning', 'Information')

    # Custom rules
    CustomRulePath = @()
}
