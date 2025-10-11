# Contributing to PoshGuard

We welcome contributions. Follow these guidelines to ensure quality and consistency.

## Local Development Setup

### Prerequisites
- PowerShell ≥5.1 or ≥7.0
- PSScriptAnalyzer ≥1.21.0
- Pester ≥5.0 (for tests)

### Clone and Verify
```powershell
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard

# Load modules
Import-Module ./tools/lib/Core.psm1 -Force
Get-Command -Module Core

# Run tests
Invoke-Pester ./tests/
```

## Adding New Auto-Fixes

### Structure
1. Create submodule: `./tools/lib/{Category}/{RuleName}.psm1`
2. Implement function: `Invoke-{RuleName}Fix`
3. Import in category facade: `./tools/lib/{Category}.psm1`
4. Add call in main script: `./tools/Apply-AutoFix.ps1`

### Template
```powershell
function Invoke-MyRuleFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    # Parse AST
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $FilePath, [ref]$null, [ref]$null
    )
    
    # Find matches
    $matches = $ast.FindAll({ $args[0] -is [YourAstType] }, $true)
    
    # Apply transformations
    foreach ($match in $matches) {
        # Your fix logic here
    }
    
    # Return modified content
    return $modifiedContent
}

Export-ModuleMember -Function Invoke-MyRuleFix
```

## Testing Requirements

### Unit Tests
Test each fix function with:
- Valid input (should transform correctly)
- Already-fixed input (should be idempotent)
- Edge cases (complex syntax, nested structures)
- Invalid input (should handle gracefully)

### Integration Tests
Run full auto-fix pipeline on sample scripts:
```powershell
./tools/Apply-AutoFix.ps1 -Path ./tests/samples/test.ps1 -DryRun
```

### Test Coverage
Aim for >85% coverage on new functions. Run:
```powershell
Invoke-Pester -CodeCoverage './tools/lib/**/*.psm1'
```

## Code Style

### Formatting
- Indentation: 4 spaces (no tabs)
- Line length: <120 characters
- Opening brace: Same line for functions/statements
- Cmdlet casing: PascalCase (Get-Content, not get-content)

### Naming
- Functions: Verb-Noun (Invoke-MyFix, not Fix-My)
- Variables: camelCase ($filePath, not $file_path)
- Parameters: PascalCase ($FilePath, not $filepath)

### Documentation
- Comment-based help for all exported functions
- Inline comments for complex logic only
- Examples in help showing actual usage

## Pull Request Process

### Before Submitting
1. Run tests: `Invoke-Pester ./tests/`
2. Check syntax: `Invoke-ScriptAnalyzer ./tools/`
3. Format code consistently
4. Update CHANGELOG.md with your changes

### PR Template
```markdown
## Intent
What problem does this PR solve?

## Changes
- List specific changes made
- Include new files, modified functions, etc.

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing on sample scripts

## Screenshots/Logs
Paste relevant output showing fix in action

## Risk Assessment
LOW | MEDIUM | HIGH - Explain why

## Breaking Changes
YES | NO - If yes, describe migration path
```

### Review Process
- Maintainer reviews within 5 business days
- Address feedback in new commits (don't force-push)
- Squash-merge after approval

## Commit Guidelines

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New auto-fix or feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `chore`: Maintenance tasks

### Examples
```
feat(Advanced): Add PSAvoidUsingDeprecatedManifestFields fix

Implements Test-ModuleManifest integration to detect deprecated
manifest fields and adds warning comments.

Closes #123
```

```
fix(Security): Correct PSCredential parameter detection

Fixed regex to properly detect variations of PSCredential type
declarations including [pscredential] and [PSCredential].
```

## Documentation Standards

### README Updates
- Keep under 5 minutes read time
- Update coverage stats when adding fixes
- Add troubleshooting entries for new issues

### Code Comments
- Explain WHY, not WHAT
- Complex AST parsing needs brief explanation
- No redundant comments (`$x = 1 # Set x to 1`)

## Performance Guidelines

### AST Parsing
- Use `FindAll()` with specific predicates (not entire tree)
- Cache cmdlet lists (don't re-fetch built-in cmdlets)
- Avoid regex on large files (use AST where possible)

### Memory Management
- Dispose large objects after use
- Don't hold entire file content in memory unnecessarily
- Stream processing for very large files

## Security Checklist

- [ ] No secrets or credentials in code/logs
- [ ] Input validation on all external data
- [ ] No arbitrary code execution (Invoke-Expression)
- [ ] File operations use safe paths (no path traversal)
- [ ] Error messages don't leak sensitive data

## Issue Reporting

### Bug Reports
Include:
- PowerShell version (`$PSVersionTable`)
- PSScriptAnalyzer version
- Input script (or minimal reproducible example)
- Expected vs actual behavior
- Error messages/stack traces

### Feature Requests
Include:
- Use case (what problem are you solving?)
- Example code (before/after)
- Any workarounds you've tried
- Priority/impact (LOW | MEDIUM | HIGH)

## Code of Conduct

Be professional, respectful, and constructive. We don't tolerate harassment, discrimination, or unconstructive criticism. Focus on technical merit.

## Questions?

Open a discussion issue with the `question` label or contact maintainers directly.

---

**Maintainers**: See `.github/MAINTAINERS.md` for release process and additional responsibilities.
