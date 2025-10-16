# GitHub Actions Workflows

All workflows follow CI/CD best practices: SHA-pinned actions, minimal permissions, timeouts, and proper error handling.

## Workflows Summary

| Workflow | Purpose | Triggers | Timeout | Status |
|----------|---------|----------|---------|--------|
| `ci.yml` | Main CI: Lint, test, package | Push/PR to main (PS files) | 15-20 min | ✅ Active |
| `code-scanning.yml` | Security scanning with SARIF upload | Push/PR (PS files), weekly, manual | 20 min | ✅ Active |
| `release.yml` | Create releases with SBOM and attestation | Tag push (v*), manual | 15 min | ✅ Active |
| `poshguard-quality-gate.yml` | Dogfooding: PoshGuard analyzing itself | Push/PR (PS files), manual | 20 min | ✅ Active |
| `actionlint.yml` | Validate workflow syntax | Push/PR to .github/workflows/ | 5 min | ✅ Active |
| `dependabot-auto-merge.yml` | Auto-merge safe Dependabot PRs | Dependabot PR events | N/A | ✅ Active |

## Workflow Details

### ci.yml - Main CI Pipeline
**Primary quality gate for all code changes.**

- **Jobs:**
  1. `lint` - Runs PSScriptAnalyzer on all PowerShell code
  2. `test` - Runs Pester tests with detailed reporting
  3. `package` - Creates release package (main branch only)

- **When it runs:** On every push/PR to main branch that modifies PowerShell files
- **Failure means:** PR cannot be merged (blocking)
- **Path filters:** Only runs when `**.ps1`, `**.psm1`, `**.psd1`, or test/config files change

### code-scanning.yml - Security Scanning
**Uploads security analysis results to GitHub Security tab.**

- **Jobs:**
  1. `code-scanning` - Runs PSScriptAnalyzer and converts results to SARIF format

- **When it runs:** 
  - Push/PR to main (PowerShell file changes)
  - Weekly on Sundays at 6 AM UTC (scheduled scan)
  - Manual dispatch
  
- **Why it's separate from ci.yml:** 
  - Requires special permissions (`security-events: write`)
  - Generates SARIF files for GitHub Advanced Security
  - Runs on a schedule for continuous security monitoring
  
- **Failure means:** Issues visible in Security tab, but doesn't block PRs

### poshguard-quality-gate.yml - Dogfooding Demo
**Demonstrates using PoshGuard in CI/CD (eating our own dog food).**

- **Jobs:**
  1. `poshguard-analysis` - Runs local PoshGuard module on codebase
  2. `security-scan` - Custom security pattern matching
  3. `quality-gate` - Evaluates thresholds and determines pass/fail

- **When it runs:** Push/PR to main/develop (PowerShell file changes)
- **Purpose:** 
  - Shows how to integrate PoshGuard in CI/CD
  - Tests PoshGuard's capabilities on real code
  - Provides example for users wanting to adopt PoshGuard
  
- **Failure means:** Quality thresholds exceeded (informational, may not block)

### release.yml - Release Automation
**Creates GitHub releases with signed artifacts.**

- **Jobs:**
  1. `validate` - Validates version format (semver)
  2. `release` - Creates package, generates SBOM, attests provenance, publishes release

- **When it runs:** 
  - When a tag matching `v*` is pushed (e.g., `v4.3.0`)
  - Manual dispatch with tag input
  
- **Features:**
  - Software Bill of Materials (SBOM) generation
  - Build provenance attestation with Sigstore
  - SHA256 checksums for artifacts
  - Automatic release notes from CHANGELOG

### actionlint.yml - Workflow Validation
**Prevents broken workflows from reaching main branch.**

- **Jobs:**
  1. `actionlint` - Lints workflow files with actionlint tool
  2. YAML syntax validation with yamllint

- **When it runs:** Push/PR that modifies files in `.github/workflows/` or `.github/actions/`
- **Purpose:** Catches workflow syntax errors, invalid action references, and shellcheck issues
- **Failure means:** Workflow has syntax errors or validation issues (blocking)

### dependabot-auto-merge.yml - Dependency Automation
**Automatically merges safe Dependabot updates.**

- **Jobs:**
  1. `dependabot` - Evaluates update type and auto-merges if safe

- **When it runs:** When Dependabot opens, synchronizes, or reopens a PR
- **Auto-merge strategy:**
  - ✅ Patch updates (1.2.3 → 1.2.4) - auto-merge with squash
  - ✅ Minor updates (1.2.3 → 1.3.0) - auto-merge with squash
  - ❌ Major updates (1.2.3 → 2.0.0) - require manual review (adds comment)
  
- **Note:** Depends on CI passing before merge executes

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

All third-party actions are pinned by commit SHA for security and supply chain protection.

| Action | Version | SHA (First 8 chars) | Used In |
|--------|---------|---------------------|---------|
| actions/checkout | v5.0.0 | 7884fcad | ci.yml, release.yml, code-scanning.yml, poshguard-quality-gate.yml |
| actions/cache | v4.3.0 | 5b8b28c6 | actionlint.yml, setup-powershell action |
| actions/upload-artifact | v4.6.2 | d0d5ba7e | ci.yml, code-scanning.yml, poshguard-quality-gate.yml |
| github/codeql-action/upload-sarif | v3.30.8 | 56b66b1d | code-scanning.yml |
| actions/github-script | v8 | (latest) | poshguard-quality-gate.yml |
| anchore/sbom-action | v0.20.6 | (latest) | release.yml |
| actions/attest-build-provenance | v3.0.0 | 977bb373 | release.yml |
| softprops/action-gh-release | v2.4.1 | 5d12f0f4 | release.yml |
| dependabot/fetch-metadata | v2.4.0 | e4347563 | dependabot-auto-merge.yml |

**Note:** PowerShell is pre-installed on all GitHub-hosted runners (Windows, Linux, macOS). No setup action is required. We use a composite action (`.github/actions/setup-powershell`) for module installation and caching.

Last updated: 2025-10-16

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

## Troubleshooting

### Workflow Not Running
- **Check path filters:** Workflow may be configured to run only when specific files change
- **Check branch filters:** Some workflows only run on `main` branch
- **Check event type:** Some workflows only run on push, not pull_request

### Workflow Failing
1. **Check the workflow run logs** in the Actions tab for detailed error messages
2. **Review file annotations** in PR Files changed tab for lint/test failures
3. **Check Security tab** for SARIF results from code-scanning.yml
4. **Review artifacts** uploaded by failed workflows for detailed reports

### Common Issues

**Issue:** `microsoft/setup-powershell@v2` not found  
**Solution:** This action doesn't exist. PowerShell is pre-installed on all runners. Use `shell: pwsh` in your steps or the `.github/actions/setup-powershell` composite action for module setup.

**Issue:** Module installation fails  
**Solution:** Check the `setup-powershell` composite action - it handles module caching and installation with proper flags.

**Issue:** PSScriptAnalyzer or Pester not found  
**Solution:** Ensure the workflow uses the `setup-powershell` composite action with the required modules parameter.

**Issue:** Dependabot PR not auto-merging  
**Solution:** 
- Verify CI checks pass first
- Check if update is major version (requires manual review)
- Verify repository settings allow auto-merge

### Validating Workflows Locally

```bash
# Install actionlint
curl -sSL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash -s -- 1.7.8 ./bin

# Run actionlint
./bin/actionlint .github/workflows/*.yml

# Install and run yamllint
pip install yamllint
yamllint -d "{extends: relaxed, rules: {line-length: {max: 160}}}" .github/workflows/*.yml
```

## Maintenance

### Updating Action Versions
1. Check for new versions on GitHub Marketplace or action's releases page
2. Update the SHA in the workflow file with version comment: `uses: actions/checkout@<new-sha> # v5.1.0`
3. Update the table in this README
4. Test with actionlint before committing

### Adding New Workflows
1. Create the workflow file in `.github/workflows/`
2. Follow the patterns in existing workflows (SHA-pinning, permissions, timeouts, etc.)
3. Add entry to the workflows summary table above
4. Run actionlint and yamllint before committing
5. Add any new composite actions to `.github/actions/` if needed

## References

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Security Hardening Guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [actionlint](https://github.com/rhysd/actionlint)
- [GitHub-hosted runners software](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
