@{
    RootModule = '../tools/lib/Core.psm1'
    ModuleVersion = '3.0.0'
    GUID = 'f8a3d8e9-7b4c-4d5e-9f8a-3c2b1e0d9f7a'
    Author = 'Chad Boyd'
    CompanyName = 'PoshGuard'
    Copyright = '(c) 2025 Chad Boyd. All rights reserved.'
    Description = 'PowerShell auto-fix engine with 100% PSScriptAnalyzer general rules coverage. Automatically fixes security issues, best practices, formatting, and advanced patterns using AST-based transformations.'
    
    PowerShellVersion = '5.1'
    
    RequiredModules = @(
        @{ModuleName='PSScriptAnalyzer'; ModuleVersion='1.21.0'}
    )
    
    NestedModules = @(
        '../tools/lib/Security.psm1',
        '../tools/lib/BestPractices.psm1',
        '../tools/lib/Formatting.psm1',
        '../tools/lib/Advanced.psm1'
    )
    
    FunctionsToExport = @(
        'Invoke-PoshGuard',
        'Invoke-AutoFix',
        'Restore-PoshGuardBackup',
        'Test-ScriptCompliance',
        'Get-PoshGuardRules'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @(
                'security',
                'formatter',
                'linting',
                'powershell',
                'powershell-module',
                'static-analysis',
                'ast',
                'code-quality',
                'code-refactoring',
                'security-hardening',
                'pester',
                'psscriptanalyzer',
                'auto-fix'
            )
            LicenseUri = 'https://github.com/cboyd0319/PoshGuard/blob/main/LICENSE'
            ProjectUri = 'https://github.com/cboyd0319/PoshGuard'
            IconUri = 'https://raw.githubusercontent.com/cboyd0319/PoshGuard/main/.github/social-preview.png'
            ReleaseNotes = 'https://github.com/cboyd0319/PoshGuard/blob/main/CHANGELOG.md'
        }
    }
    
    HelpInfoURI = 'https://github.com/cboyd0319/PoshGuard/blob/main/README.md'
}
