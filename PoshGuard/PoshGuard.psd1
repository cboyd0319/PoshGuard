@{
    # Note: This manifest uses relative paths that work in development.
    # For PowerShell Gallery deployment, the module structure must be reorganized
    # with all .psm1 files under the PoshGuard/ directory.
    RootModule = 'PoshGuard.psm1'
    ModuleVersion = '3.0.0'
    GUID = 'f8a3d8e9-7b4c-4d5e-9f8a-3c2b1e0d9f7a'
    Author = 'Chad Boyd'
    CompanyName = 'PoshGuard'
    Copyright = '(c) 2025 Chad Boyd. All rights reserved.'
    Description = 'PowerShell auto-fix engine with 100% PSScriptAnalyzer general rules coverage. Automatically fixes security issues, best practices, formatting, and advanced patterns using AST-based transformations.'

    PowerShellVersion = '5.1'

    RequiredModules = @(
        @{ ModuleName = 'PSScriptAnalyzer'; MinimumVersion = '1.21.0' }
    )

    # Note: Module loading is handled dynamically in PoshGuard.psm1
    # This allows the module to work both in development (with tools/lib/)
    # and when installed via PowerShell Gallery (with PoshGuard/lib/)

    FunctionsToExport = @(
        'Invoke-PoshGuard'
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
