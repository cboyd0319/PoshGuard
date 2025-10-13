# GitHub Copilot Instructions for PoshGuard

## Quick Reference (Most Common Commands)
```powershell
# Running PoshGuard
Invoke-PoshGuard -Path ./script.ps1                    # Analyze single script
Invoke-PoshGuard -Path ./scripts/ -Recurse             # Analyze directory
Invoke-PoshGuard -Path ./script.ps1 -Fix               # Auto-fix issues
Invoke-PoshGuard -Path ./script.ps1 -Severity High     # Only high severity
Invoke-PoshGuard -Path ./script.ps1 -Format JSON       # JSON output

# Development and Testing
Invoke-Pester ./tests/                                 # Run all tests
Invoke-Pester ./tests/MyRule.Tests.ps1                 # Run specific test
Invoke-Pester -CodeCoverage ./PoshGuard/PoshGuard.psm1 # Test with coverage

# Module Development
Import-Module ./PoshGuard/PoshGuard.psd1 -Force        # Reload module
Get-Help Invoke-PoshGuard -Full                        # View documentation

# Quality checks (run before every commit)
Invoke-ScriptAnalyzer -Path ./PoshGuard -Recurse       # Lint PowerShell code
Invoke-Pester ./tests/                                 # Run all tests
```

## Project Overview

PoshGuard is an advanced PowerShell QA and auto-fix engine that uses AST (Abstract Syntax Tree) analysis to detect and automatically fix code quality issues, security vulnerabilities, and style violations in PowerShell scripts.

**Current Version**: 4.3.0

**Key Technologies**:
- PowerShell 5.1+ and PowerShell 7+
- PSScriptAnalyzer for static analysis
- Pester for testing
- AST-based code transformations
- ML/AI integration with reinforcement learning
- Entropy-based secret detection
- OpenTelemetry tracing

## Project Structure

```
PoshGuard/
├── .github/                 # GitHub configuration and workflows
│   ├── copilot-mcp.json    # MCP server configuration
│   ├── workflows/          # CI/CD pipelines
│   └── ISSUE_TEMPLATE/     # Issue templates
├── PoshGuard/              # Main module directory
│   ├── PoshGuard.psd1      # Module manifest
│   ├── PoshGuard.psm1      # Module entry point
│   └── README.md           # Module documentation
├── tools/                  # Auto-fix tools and libraries
│   └── lib/                # Module libraries for fixes
├── tests/                  # Pester tests
├── docs/                   # Comprehensive documentation
├── config/                 # Configuration files
├── samples/                # Example scripts
└── benchmarks/             # Performance benchmarks
```

## Repository Standards & Configuration

### Workflow & Automation Standards
- **Dependabot:** Weekly schedule (Mondays 09:00 UTC), commit prefix `chore(deps):`, grouped updates for Actions/npm
- **Auto-merge:** Automatic approval for all Dependabot PRs, auto-merge for patch/minor versions only
- **CI/CD:** GitHub Actions workflows in `.github/workflows/` (see `poshguard-qa.yml`, `dependabot-auto-merge.yml`)
- **Quality Gates:** All PRs must pass PSScriptAnalyzer, Pester tests before merge

### File Organization Standards
- **`.github/` directory:** Contains only GitHub-specific configs (workflows, templates, Copilot instructions)
  - Templates: `pull_request_template.md`, `ISSUE_TEMPLATE/*.yml` (lowercase naming)
  - Ownership: `CODEOWNERS` defines code review requirements (@cboyd0319)
- **Documentation:** All docs in `/docs`, never in `.github/`
- **Configuration:** Module manifest (`PoshGuard/PoshGuard.psd1`), config files in `/config`
- **Tools:** Auto-fix libraries in `/tools/lib`, development scripts in root

### Inclusive Terminology Standards
- **Required replacements:**
  - Use "allowlist" instead of "whitelist"
  - Use "denylist" instead of "blacklist"
  - Use "main" branch instead of "master" branch
  - Use "primary/replica" instead of "master/slave" in architecture discussions
- **Code review:** All PRs checked for outdated terminology
- **PSScriptAnalyzer rules:** Custom rules detect these patterns in user code
- **Documentation:** All external links use `/tree/main/` not `/tree/master/`

### Configuration Management
- **Module manifest:** `PoshGuard/PoshGuard.psd1` — Version, dependencies, exports
- **PSScriptAnalyzer:** Rules configured for strict analysis
- **Pester tests:** Test configuration in `tests/` directory
- **Secrets:** Environment variables only (never commit credentials)
- **MCP integration:** `.github/copilot-mcp.json` for Model Context Protocol servers

### GitHub Configuration Files
- **Dependabot:** `.github/dependabot.yml` — Standardized across all repos
- **Workflows:** `.github/workflows/*.yml` — GitHub Actions automation
- **Templates:** `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/*.yml`
- **Copilot:** `.github/copilot-instructions.md` (this file), `.github/copilot-mcp.json`
- **Ownership:** `.github/CODEOWNERS` — Code review assignments (@cboyd0319)

## Coding Standards

### PowerShell Style Guide

1. **Naming Conventions**:
   - Functions: Use `Verb-Noun` format (e.g., `Invoke-PoshGuard`, `Get-PoshGuardRules`)
   - Variables: Use `camelCase` for private, `PascalCase` for parameters
   - Constants: Use `UPPER_SNAKE_CASE`

2. **Inclusive Terminology**: Use modern, inclusive language (see Repository Standards above for details)

3. **Function Structure**:
   ```powershell
   function Verb-Noun {
       [CmdletBinding()]
       param(
           [Parameter(Mandatory)]
           [string]$RequiredParam,
           
           [Parameter()]
           [switch]$OptionalSwitch
       )
       
       begin {
           # Initialization
       }
       
       process {
           # Main logic
       }
       
       end {
           # Cleanup
       }
   }
   ```

4. **Error Handling**:
   - Use `$ErrorActionPreference = 'Stop'` for strict error handling
   - Always include `try-catch` blocks for external operations
   - Use `Write-Error` for user-facing errors
   - Use `throw` for unrecoverable errors

5. **Comments**:
   - Use comment-based help for all exported functions
   - Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
   - Add inline comments for complex logic

6. **Testing**:
   - All new features must have Pester tests
   - Test both valid and invalid inputs
   - Ensure idempotent behavior
   - Include edge cases

## MCP Integration (Model Context Protocol)

PoshGuard integrates with MCP servers for enhanced AI capabilities:

### Built-in (GitHub Copilot)
- **github-mcp:** Repository operations, issues, PRs (OAuth, automatic - no config needed)

### External (Configured)
- **context7:** Version-specific PowerShell documentation (HTTP, needs API key)
  - Provides accurate docs for PSScriptAnalyzer, Pester, PowerShell Core, AST APIs
  - No hallucinations, direct from source
- **openai-websearch:** Web search via OpenAI for PowerShell best practices (local/uvx, needs API key)
  - Use for current community practices, security patterns, compliance frameworks
- **fetch:** Web content fetching (local/npx, ready)
  - Useful for PowerShell Gallery research, module documentation, security advisories
- **playwright:** Browser automation for testing (local/npx, ready)
  - Test PowerShell web interactions, validate auto-fix results

**Config:** `.github/copilot-mcp.json` (HTTP and local command servers)  
**Important:** GitHub MCP tools are built-in to Copilot. Do NOT add GitHub server to copilot-mcp.json. Personal Access Tokens (PAT) are NOT supported for GitHub MCP - it uses OAuth automatically.

**Environment Variables Required:**
- `COPILOT_MCP_CONTEXT7_API_KEY` — For Context7 documentation access
- `COPILOT_MCP_OPENAI_API_KEY` — For OpenAI web search capabilities

## Key Features and Implementation Details

### AST-Based Transformations

- All code fixes use PowerShell AST (Abstract Syntax Tree)
- Preserve code structure and intent
- Ensure minimal changes (surgical fixes)
- Validate syntax after transformations

### Auto-Fix Architecture

1. **Detection**: PSScriptAnalyzer rules identify violations
2. **Analysis**: AST parsing to understand code structure
3. **Transformation**: Apply minimal fixes using AST manipulation
4. **Validation**: Verify syntax and preserve functionality
5. **Reporting**: Generate detailed reports with confidence scores

### ML/AI Integration (v4.3.0)

- Reinforcement learning with Q-learning
- Entropy-based secret detection (Shannon entropy)
- Confidence scoring for all fixes
- Pattern recognition for security issues

### Standards Compliance

PoshGuard implements and validates against 25+ industry standards:
- NIST SP 800-53 Rev 5
- FedRAMP baselines
- OWASP ASVS
- MITRE ATT&CK
- CIS Benchmarks
- ISO 27001
- HIPAA Security Rule
- SOC 2
- PCI-DSS

## Data Contracts

### PSScriptAnalyzer Diagnostic Record
```powershell
# Standard diagnostic from PSScriptAnalyzer
@{
    RuleName = "PSAvoidUsingCmdletAliases"
    Severity = "Warning"  # Error, Warning, Information
    Message = "Alias 'gci' should not be used"
    ScriptPath = "C:\scripts\MyScript.ps1"
    Line = 42
    Column = 5
    Extent = <script extent object>
}
```

### PoshGuard Fix Result
```powershell
# Result from auto-fix operation
@{
    FilePath = "C:\scripts\MyScript.ps1"
    Success = $true
    FixesApplied = @(
        @{
            RuleName = "PSAvoidUsingCmdletAliases"
            Line = 42
            OldCode = "gci -Path ."
            NewCode = "Get-ChildItem -Path ."
            Confidence = 0.95  # ML confidence score
        }
    )
    BackupPath = "C:\scripts\MyScript.ps1.20251013_143022.bak"
    Warnings = @()
    Errors = @()
}
```

### PoshGuard Configuration
```powershell
# Configuration object (loaded from config files or parameters)
@{
    SeverityThreshold = "Warning"  # Minimum severity to report
    AutoFix = $false
    BackupEnabled = $true
    IncludeRules = @()  # Empty = all rules
    ExcludeRules = @("PSAvoidUsingWriteHost")
    Recurse = $false
    OutputFormat = "Console"  # Console, JSON, HTML, XML
    ComplianceFrameworks = @("NIST", "OWASP")
}
```

> If you add fields to these structures, maintain backward compatibility and document changes.

## Development Workflow

### Adding a New Auto-Fix Rule

1. Create rule module: `tools/lib/{Category}/{RuleName}.psm1`
2. Implement fix function: `Invoke-{RuleName}Fix`
3. Add Pester tests: `tests/{RuleName}.Tests.ps1`
4. Update documentation: `docs/RULES.md`
5. Run validation: `Invoke-Pester`

### Testing Changes

```powershell
# Run all tests
Invoke-Pester ./tests/

# Run specific test
Invoke-Pester ./tests/MyRule.Tests.ps1

# Test with coverage
Invoke-Pester -CodeCoverage ./PoshGuard/PoshGuard.psm1
```

### CI/CD Pipeline

GitHub Actions workflows automate quality gates and releases:

**Workflow Files** (`.github/workflows/`):
- `poshguard-qa.yml` — Main CI pipeline (PSScriptAnalyzer, Pester tests, multi-platform)
- `dependabot-auto-merge.yml` — Auto-merge safe dependency updates
- `release.yml` — Automated releases with versioning and changelog
- `poshguard-quality-gate.yml` — Quality checks and performance benchmarks

**CI/CD Features:**
1. **Multi-platform testing:** Windows, Linux, macOS (PowerShell 7)
2. **Quality gates:** PSScriptAnalyzer must pass, Pester tests must pass
3. **Path-based filtering:** Skips CI for docs-only changes
4. **Auto-merge:** Dependabot PRs for patch/minor versions
5. **Concurrency control:** Cancel outdated runs automatically

**Triggered by:**
- All PRs and pushes to `main` branch
- Manual workflow dispatch
- Dependabot PR creation

All checks must pass before merge. See `.github/workflows/` for details.

## Common Patterns

### Safe File Operations

```powershell
# Always create backups
$backupPath = "{0}.{1}.bak" -f $FilePath, (Get-Date -Format 'yyyyMMdd_HHmmss')
Copy-Item -Path $FilePath -Destination $backupPath

# Apply changes with error handling
try {
    $content = Get-Content -Path $FilePath -Raw
    $modified = Invoke-Transformation -Content $content
    Set-Content -Path $FilePath -Value $modified -NoNewline
} catch {
    # Rollback on error
    Copy-Item -Path $backupPath -Destination $FilePath -Force
    throw
}
```

### AST Parsing

```powershell
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $FilePath,
    [ref]$tokens,
    [ref]$errors
)

# Find specific AST nodes
$matches = $ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst]
}, $true)
```

### Idempotent Fixes

All fixes must be idempotent (running multiple times produces same result):

```powershell
# Check if already fixed
if ($content -match $expectedPattern) {
    Write-Verbose "Already compliant"
    return $content
}

# Apply fix only if needed
$modified = $content -replace $violationPattern, $fixPattern
return $modified
```

## Security Considerations

1. **Secret Detection**: Never log or expose secrets in output
2. **Input Validation**: Validate all user inputs and file paths
3. **Secure Defaults**: All features are secure by default
4. **Minimal Permissions**: Request only necessary permissions
5. **Audit Logging**: Log all operations for compliance

## Best Practices for AI/ML Features

1. **Confidence Scores**: Always include confidence metrics
2. **Explainability**: Provide clear reasoning for ML decisions
3. **Fallback Logic**: Have non-ML fallbacks for critical operations
4. **Validation**: Validate ML outputs before applying
5. **Privacy**: Never send sensitive data to external services without explicit consent

## MCP Integration

Model Context Protocol (MCP) servers provide enhanced capabilities:

- **Context7**: Up-to-date documentation and examples
- **OpenAI Web Search**: Web search capabilities
- **Fetch**: Web content retrieval
- **Playwright**: Browser automation

MCP is opt-in and requires explicit user consent. See `.github/MCP_SETUP.md` for details.

## Documentation

When adding new features or modifying existing ones:

1. Update relevant docs in `docs/` directory
2. Add examples to `samples/` directory
3. Update CHANGELOG.md with changes
4. Update README.md if user-facing
5. Include inline documentation in code

## Performance Considerations

1. **File Operations**: Use `-Raw` for single string operations
2. **AST Caching**: Cache parsed AST when processing multiple rules
3. **Parallel Processing**: Use `-Parallel` for batch operations in PS 7+
4. **Memory Management**: Dispose of large objects explicitly
5. **Streaming**: Use streaming for large files

## Common Pitfalls & Gotchas

1. **PowerShell Version:** Requires 5.1+ or 7+
   - Check with `$PSVersionTable.PSVersion`
   - Different behavior between Windows PowerShell 5.1 and PowerShell 7
   - Test fixes on both versions when possible

2. **Module Loading:** Always use `-Force` during development
   - Symptom: Changes to module not reflected
   - Fix: `Import-Module ./PoshGuard/PoshGuard.psd1 -Force`
   - Clear module cache: `Remove-Module PoshGuard -ErrorAction SilentlyContinue`

3. **AST Parse Errors:** Validate syntax before transformation
   - Symptom: `ParseError` when processing malformed scripts
   - Fix: Catch parse errors, log, continue with next file
   - Use `[System.Management.Automation.Language.Parser]::ParseFile()` with error refs

4. **Path Issues:** Always use absolute paths or resolve properly
   - ✅ GOOD: `Resolve-Path $FilePath` or `(Get-Item $FilePath).FullName`
   - ❌ AVOID: Relative paths without resolution
   - Cross-platform: Use `Join-Path` instead of string concatenation

5. **Platform Differences:** Test on Windows, Linux, and macOS
   - Path separators: Use `[System.IO.Path]::DirectorySeparatorChar`
   - Case sensitivity: Assume case-sensitive file systems
   - Line endings: Normalize with `-Raw` parameter

6. **Backup Files:** Always create backups before applying fixes
   - Format: `{filename}.{timestamp}.bak`
   - Cleanup: Document backup retention policy
   - Rollback: Provide easy restore mechanism

7. **Idempotent Fixes:** All auto-fixes must be idempotent
   - Running fix twice should be safe and produce same result
   - Check if already compliant before applying fix
   - Test with multiple fix passes

8. **Pester Test Isolation:** Tests must not depend on external state
   - Mock all external calls (Test-Path, Get-Content, etc.)
   - Use `TestDrive:` for file operations in tests
   - Clean up test artifacts in AfterEach blocks

9. **PSScriptAnalyzer Rules:** Keep rules updated
   - Update PSScriptAnalyzer regularly for new rules
   - Document custom rule suppressions with justification
   - Use `.pssasuppressfile` for known false positives

10. **Module Structure:** Respect development vs. installed structure
    - Development: `tools/lib/` for auto-fix modules
    - Installed: `PoshGuard/lib/` structure
    - Module manifest handles dynamic loading

## Troubleshooting

Common issues and solutions:

- **AST Parse Errors**: Validate syntax before transformation (see Common Pitfalls #3)
- **Path Issues**: Always use absolute paths or resolve with `Resolve-Path` (see Common Pitfalls #4)
- **Module Loading**: Use `Import-Module -Force` for development (see Common Pitfalls #2)
- **Test Failures**: Check for platform-specific differences (see Common Pitfalls #5)

## Resources

- [PowerShell AST Documentation](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/main/RuleDocumentation)
- [Pester Documentation](https://pester.dev/)
- [PoshGuard Documentation](../docs/)

## Code Review Checklist

When reviewing code:

- [ ] Follows PowerShell naming conventions
- [ ] Includes comment-based help
- [ ] Has comprehensive Pester tests
- [ ] Uses proper error handling
- [ ] Is idempotent where applicable
- [ ] Validates all inputs
- [ ] Updates relevant documentation
- [ ] Passes all CI checks
- [ ] Includes security considerations
- [ ] Has minimal performance impact

## Version Management

- Version format: `Major.Minor.Patch` (Semantic Versioning)
- Update `PoshGuard/VERSION.txt` and `PoshGuard/PoshGuard.psd1`
- Document changes in `docs/CHANGELOG.md`
- Create release notes in `docs/V{version}-RELEASE-NOTES.md`

## Contact and Support

- GitHub Issues: https://github.com/cboyd0319/PoshGuard/issues
- Project Homepage: https://github.com/cboyd0319/PoshGuard
- License: MIT (see LICENSE file)
