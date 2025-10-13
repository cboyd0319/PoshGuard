# Contributing

## Prereqs

| Item | Version | Why |
|------|---------|-----|
| PowerShell | ≥5.1 or ≥7.0 | Runtime |
| PSScriptAnalyzer | ≥1.21.0 | Detection |
| Pester | ≥5.0 | Tests |

## Setup

```powershell
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard
Import-Module ./tools/lib/Core.psm1 -Force
Invoke-Pester ./tests/
```

## Adding Auto-Fixes

Steps:
1. Create `./tools/lib/{Category}/{RuleName}.psm1`
2. Implement `Invoke-{RuleName}Fix`
3. Import in `./tools/lib/{Category}.psm1`
4. Call in `./tools/Apply-AutoFix.ps1`

Template:
```powershell
function Invoke-MyRuleFix {
    param([Parameter(Mandatory)][string]$FilePath)
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)
    $matches = $ast.FindAll({ $args[0] -is [YourAstType] }, $true)
    # Apply transformations
    return $modifiedContent
}
Export-ModuleMember -Function Invoke-MyRuleFix
```

## Tests

Required:
- Valid input (transforms correctly)
- Already-fixed input (idempotent)
- Edge cases (complex syntax, nested)
- Invalid input (graceful handling)

Run:
```powershell
./tools/Apply-AutoFix.ps1 -Path ./tests/samples/test.ps1 -DryRun
Invoke-Pester -CodeCoverage './tools/lib/**/*.psm1'
```

Target: >85% coverage

## Style

**Formatting**: 4 spaces, <120 chars, opening brace same line, PascalCase cmdlets

**Naming**: Functions (Verb-Noun), Variables (camelCase), Parameters (PascalCase)

**Docs**: Comment-based help for exported functions, inline comments for complex logic only

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

## Commits

Format: `<type>(<scope>): <subject>`

Types: feat, fix, docs, test, refactor, perf, chore

Example:
```
feat(Advanced): Add PSAvoidUsingDeprecatedManifestFields fix

Implements Test-ModuleManifest integration. Closes #123
```

## Docs

- Keep README <5 min read time
- Update coverage stats when adding fixes
- Explain WHY, not WHAT in comments
- No redundant comments

## Performance

- Use `FindAll()` with specific predicates
- Cache cmdlet lists
- Prefer AST over regex on large files
- Dispose large objects
- Stream large files

## Security

Required:
- No secrets in code/logs
- Validate all external inputs
- No Invoke-Expression
- Safe file paths (no traversal)
- No sensitive data in errors

## Issues

**Bug reports**: PowerShell version, PSScriptAnalyzer version, minimal repro, expected vs actual, error messages

**Feature requests**: Use case, before/after code, priority (LOW/MEDIUM/HIGH)

## Code of Conduct

See [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md). Be professional.

## Questions

Open issue with `question` label or contact maintainers.
