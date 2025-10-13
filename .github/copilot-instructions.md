# GitHub Copilot Instructions for PoshGuard

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

## Coding Standards

### PowerShell Style Guide

1. **Naming Conventions**:
   - Functions: Use `Verb-Noun` format (e.g., `Invoke-PoshGuard`, `Get-PoshGuardRules`)
   - Variables: Use `camelCase` for private, `PascalCase` for parameters
   - Constants: Use `UPPER_SNAKE_CASE`

2. **Function Structure**:
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

3. **Error Handling**:
   - Use `$ErrorActionPreference = 'Stop'` for strict error handling
   - Always include `try-catch` blocks for external operations
   - Use `Write-Error` for user-facing errors
   - Use `throw` for unrecoverable errors

4. **Comments**:
   - Use comment-based help for all exported functions
   - Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
   - Add inline comments for complex logic

5. **Testing**:
   - All new features must have Pester tests
   - Test both valid and invalid inputs
   - Ensure idempotent behavior
   - Include edge cases

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

- GitHub Actions workflows in `.github/workflows/`
- `ci.yml`: Runs on all PRs (linting, testing, security scans)
- `release.yml`: Automated releases with versioning
- `poshguard-quality-gate.yml`: Quality checks and benchmarks

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

## Troubleshooting

Common issues and solutions:

- **AST Parse Errors**: Validate syntax before transformation
- **Path Issues**: Always use absolute paths or resolve with `Resolve-Path`
- **Module Loading**: Use `Import-Module -Force` for development
- **Test Failures**: Check for platform-specific differences (Windows/Linux/macOS)

## Resources

- [PowerShell AST Documentation](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation)
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
