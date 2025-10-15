# GitHub Actions Workflows

All workflows follow CI/CD best practices: SHA-pinned actions, minimal permissions, timeouts, and proper error handling.

## Workflows Summary

| Workflow | Purpose | Triggers | Timeout |
|----------|---------|----------|---------|
| `ci.yml` | Lint, test, package | Push/PR to main | 15-20 min |
| `code-scanning.yml` | Security scanning (SARIF) | Push/PR, weekly, manual | 20 min |
| `release.yml` | Create releases with SBOM | Tag push, manual | 15 min |
| `poshguard-quality-gate.yml` | Quality analysis demo | Push/PR, manual | 20 min |
| `actionlint.yml` | Validate workflows | Push/PR to workflows | 5 min |
| `dependabot-auto-merge.yml` | Auto-merge Dependabot | Dependabot PRs | N/A |

## Security Best Practices

✅ All third-party actions pinned by commit SHA  
✅ Minimal permissions (least-privilege principle)  
✅ Explicit timeouts on all jobs  
✅ Strict error handling (`$ErrorActionPreference = 'Stop'`)  
✅ Concurrency control (cancel duplicate runs)  
✅ Input validation and safe defaults  

## Composite Actions

### `setup-powershell/action.yml`

Reusable action for setting up PowerShell with required modules.

**Usage:**
```yaml
- uses: ./.github/actions/setup-powershell
  with:
    modules: 'PSScriptAnalyzer,Pester'
    cache-key-suffix: 'test'
```

## Action Versions (SHA-Pinned)

| Action | Version | SHA (First 8 chars) |
|--------|---------|---------------------|
| actions/checkout | v4.2.2 | 11bd7190 |
| actions/cache | v4.2.2 | 1bd1e32a |
| actions/upload-artifact | v4.5.0 | ea165f8d |
| github/codeql-action/upload-sarif | v3.29.0 | 6624720a |
| actions/github-script | v7.0.2 | 8ea07e23 |
| anchore/sbom-action | v0.18.1 | f8bdd1d8 |
| actions/attest-build-provenance | v1.5.1 | 703878a3 |
| softprops/action-gh-release | v2.2.2 | 7b4da115 |
| dependabot/fetch-metadata | v2.2.0 | dbb049ab |

Last updated: 2025-10-15

## Performance Optimizations

- **Caching:** PowerShell modules cached by OS, architecture, and config hash
- **Fetch Depth:** `fetch-depth: 1` for faster clones (except where history needed)
- **Path Filters:** Workflows run only when relevant files change
- **Concurrency:** Automatic cancellation of duplicate/outdated runs

## Observability

- **Step Summaries:** Rich markdown summaries in `$GITHUB_STEP_SUMMARY`
- **File Annotations:** `::error file=...` for linting/test failures
- **SARIF Upload:** Security issues visible in GitHub Security tab
- **Artifacts:** Results preserved for 30 days

## References

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Security Hardening Guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [actionlint](https://github.com/rhysd/actionlint)
