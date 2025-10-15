# Dependabot Dependency Management

## TL;DR

Dependabot runs **every Monday at 9:00 AM UTC**, automatically updating GitHub Actions and npm dependencies. Patch/minor updates auto-merge after CI passes. Major updates require manual review. Zero-config security updates.

## Quick Reference

| Update Type | Action | Speed |
|-------------|--------|-------|
| **Patch** (1.2.3 → 1.2.4) | Auto-merge | ~5 minutes after CI ✅ |
| **Minor** (1.2.3 → 1.3.0) | Auto-merge | ~5 minutes after CI ✅ |
| **Major** (1.2.3 → 2.0.0) | Manual review | Human required ⚠️ |
| **Security** | Immediate PR | Any severity 🔒 |

## What Gets Updated

### GitHub Actions

**Location:** `.github/workflows/*.yml`

Dependabot monitors workflow files and updates action versions:

```yaml
# Before
- uses: actions/checkout@v3

# After Dependabot
- uses: actions/checkout@v5
```

**Schedule:** Weekly, Mondays at 09:00 UTC

**Why:** Keep workflows secure, get new features, avoid deprecated actions.

### npm Packages

**Location:** `vscode-extension/package.json`

Dependabot updates npm dependencies for the VS Code extension:

```json
{
  "devDependencies": {
    "@types/node": "^18.0.0",  // Gets updated
    "typescript": "^5.0.0"     // Gets updated
  }
}
```

**Schedule:** Weekly, Mondays at 09:00 UTC

**Exception:** Major VSCode engine updates are ignored (set via `ignore` config).

**Why:** Security patches, bug fixes, new APIs.

## How Auto-Merge Works

### The Workflow

1. **Dependabot creates PR** - Labels it with `dependencies`
2. **Auto-approve workflow runs** - Automatically approves the PR
3. **CI checks run** - Tests, linting, security scans
4. **Decision point:**
   - **Patch/Minor:** Auto-merge enabled → Merges after CI ✅
   - **Major:** Comment added → Manual review required ⚠️

### Auto-Merge Logic

**Patch updates (1.2.3 → 1.2.4):**
- Low risk: Bug fixes, security patches
- Auto-merge: ✅ Enabled
- CI required: ✅ Must pass
- Human review: ❌ Not required

**Minor updates (1.2.3 → 1.3.0):**
- Medium risk: New features, backward compatible
- Auto-merge: ✅ Enabled
- CI required: ✅ Must pass
- Human review: ❌ Not required

**Major updates (1.2.3 → 2.0.0):**
- High risk: Breaking changes
- Auto-merge: ❌ Disabled
- CI required: ✅ Must pass
- Human review: ✅ Required

### Configuration

**File:** `.github/workflows/dependabot-auto-merge.yml`

```yaml
name: Dependabot Auto-Merge

on:
  pull_request:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
      - name: Approve PR
        run: gh pr review --approve "$PR_URL"
        env:
          PR_URL: ${{github.event.pull_request.html_url}}
          GH_TOKEN: ${{secrets.GITHUB_TOKEN}}

      - name: Enable auto-merge for patch/minor
        if: |
          contains(github.event.pull_request.title, 'bump') &&
          !contains(github.event.pull_request.title, 'major')
        run: gh pr merge --auto --squash "$PR_URL"

      - name: Comment on major updates
        if: contains(github.event.pull_request.title, 'major')
        run: gh pr comment "$PR_URL" --body "⚠️ Major version update requires manual review"
```

**Key features:**
- Only runs on Dependabot PRs (`github.actor == 'dependabot[bot]'`)
- Auto-approves all Dependabot PRs
- Enables auto-merge for patch/minor (after CI)
- Adds comment for major updates

## Dependabot Configuration

**File:** `.github/dependabot.yml`

```yaml
version: 2
updates:
  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "UTC"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "github-actions"

  # npm packages
  - package-ecosystem: "npm"
    directory: "/vscode-extension"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "UTC"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "npm"
    ignore:
      # Ignore major VSCode engine updates
      - dependency-name: "@types/vscode"
        update-types: ["version-update:semver-major"]
```

**Settings explained:**
- `interval: "weekly"` - Check once per week (not daily—reduces noise)
- `day: "monday"` - Monday mornings when you're fresh
- `time: "09:00"` - 9 AM UTC (adjust mentally for your timezone)
- `open-pull-requests-limit: 10` - Max 10 open PRs per ecosystem
- `labels` - Tags PRs for filtering/automation
- `ignore` - Skip specific updates (VSCode major versions)

## Security

### How Security Updates Work

1. **Dependabot scans dependencies** - Checks for known vulnerabilities
2. **Creates immediate PR** - Doesn't wait for weekly schedule
3. **Labels with `security`** - High visibility
4. **Auto-merge applies** - Patch/minor security fixes auto-merge
5. **Notifications sent** - GitHub notifies maintainers

### Security Levels

| Severity | Action | Speed |
|----------|--------|-------|
| **Critical** | Immediate PR | Same day 🚨 |
| **High** | Immediate PR | Same day ⚠️ |
| **Moderate** | Next scheduled run | Within 7 days 📋 |
| **Low** | Next scheduled run | Within 7 days 📝 |

### Best Practices

1. **Don't disable auto-merge for security patches** - These are urgent
2. **Review major security updates manually** - Breaking changes + security = risky
3. **Check Security Advisories** - GitHub → Security → Advisories
4. **Subscribe to notifications** - Watch repo for security alerts

## Managing Dependabot PRs

### Viewing PRs

```bash
# List all open Dependabot PRs
gh pr list --author "dependabot[bot]" --state open

# List by label
gh pr list --label "dependencies"

# View details
gh pr view <PR-NUMBER>
```

### Manually Merging

If auto-merge fails or you want manual control:

```bash
# Review the PR
gh pr view <PR-NUMBER>

# Check CI status
gh pr checks <PR-NUMBER>

# Approve
gh pr review <PR-NUMBER> --approve

# Merge (squash commit)
gh pr merge <PR-NUMBER> --squash
```

### Closing PRs

Sometimes you don't want an update:

```bash
# Close without merging
gh pr close <PR-NUMBER>

# Close with comment
gh pr close <PR-NUMBER> --comment "Not updating due to breaking changes"
```

### Ignoring Future Updates

Add to `.github/dependabot.yml`:

```yaml
ignore:
  - dependency-name: "package-name"
    update-types: ["version-update:semver-major"]
```

Options:
- `version-update:semver-major` - Ignore major versions
- `version-update:semver-minor` - Ignore minor versions
- `version-update:semver-patch` - Ignore patch versions (not recommended)

## Troubleshooting

### Dependabot not creating PRs

**Check:**
1. Dependabot enabled? → Settings → Security → Dependabot
2. Configuration valid? → `.github/dependabot.yml` syntax
3. Rate limits hit? → GitHub API rate limits

**Fix:**
```bash
# Validate dependabot.yml
cat .github/dependabot.yml | yq eval '.'

# Trigger manual update
# Go to: Insights → Dependency graph → Dependabot → Check for updates
```

### Auto-merge not working

**Check:**
1. Branch protection rules? → May require reviews
2. CI checks failing? → Auto-merge waits for green CI
3. Major update? → These don't auto-merge
4. Permissions? → Workflow needs `contents: write`, `pull-requests: write`

**Fix:**
```yaml
# Verify workflow has permissions
permissions:
  contents: write
  pull-requests: write
```

### Too many open PRs

**Problem:** 10+ PRs, hard to review.

**Fix:**
```yaml
# Reduce limit in dependabot.yml
open-pull-requests-limit: 5

# Or batch updates by ecosystem
- package-ecosystem: "npm"
  groups:
    development-dependencies:
      dependency-type: "development"
```

### Merge conflicts

**Problem:** Dependabot PR has conflicts.

**Fix:**
```bash
# Dependabot can rebase automatically
gh pr comment <PR-NUMBER> --body "@dependabot rebase"

# Or close and let Dependabot recreate
gh pr close <PR-NUMBER>
# Dependabot will open a new PR on next run
```

## Disabling/Modifying Auto-Merge

### Disable for specific update types

Edit `.github/workflows/dependabot-auto-merge.yml`:

```yaml
# Only auto-merge patch updates
- name: Enable auto-merge for patch only
  if: |
    contains(github.event.pull_request.title, 'bump') &&
    !contains(github.event.pull_request.title, 'minor') &&
    !contains(github.event.pull_request.title, 'major')
  run: gh pr merge --auto --squash "$PR_URL"
```

### Disable auto-merge entirely

```yaml
# Comment out or remove this step
# - name: Enable auto-merge
#   run: gh pr merge --auto --squash "$PR_URL"
```

### Require additional checks

Add to workflow:

```yaml
- name: Run additional validation
  run: |
    # Custom checks here
    npm audit
    ./scripts/validate-dependencies.sh

- name: Enable auto-merge (after validation)
  run: gh pr merge --auto --squash "$PR_URL"
```

## Change Log Integration

Dependabot PRs include:
- Release notes from upstream
- Changelog entries
- Commit details
- CVE information (for security fixes)

**Viewing:**
```bash
gh pr view <PR-NUMBER>
# Scroll to "Release Notes" section
```

**Adding to project changelog:**
```markdown
## [Unreleased]

### Changed
- Updated actions/checkout to v4 (#123)
- Updated TypeScript to v5.0.0 (#124)

### Security
- Fixed vulnerability in package-x (CVE-2024-1234) (#125)
```

## Best Practices

1. **Set weekly schedule** - Daily is too noisy, monthly is too slow
2. **Monday mornings** - Start the week with updates
3. **Auto-merge patch/minor** - Low risk, high value
4. **Manual review major** - Worth your time
5. **Label consistently** - `dependencies`, ecosystem labels
6. **Limit open PRs** - 5-10 max per ecosystem
7. **Group related updates** - Use Dependabot groups for clarity
8. **Monitor security tab** - Catch issues early
9. **Keep CI fast** - Slow CI = slow auto-merge
10. **Document exceptions** - Why you ignore certain updates

## Monitoring

### GitHub UI

**Insights → Dependency graph → Dependabot:**
- View all open PRs
- Check for updates manually
- See ignored dependencies
- Review security alerts

### CLI Commands

```bash
# List Dependabot PRs
gh pr list --author "dependabot[bot]"

# Check for failed auto-merges
gh pr list --author "dependabot[bot]" --label "dependencies" --state open | grep "CI failed"

# View security alerts
gh api /repos/:owner/:repo/dependabot/alerts
```

### Automation

**Slack notifications:**
```yaml
# Add to dependabot-auto-merge.yml
- name: Notify Slack
  if: failure()
  run: |
    curl -X POST -H 'Content-type: application/json' \
      --data '{"text":"Dependabot auto-merge failed for ${{ github.event.pull_request.html_url }}"}' \
      ${{ secrets.SLACK_WEBHOOK_URL }}
```

## Resources

- **[Dependabot Documentation](https://docs.github.com/code-security/dependabot)** - Official GitHub docs
- **[Dependabot Configuration Reference](https://docs.github.com/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)** - All configuration options
- **[Auto-merge Documentation](https://docs.github.com/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)** - GitHub's auto-merge feature
- **[GitHub Actions Security](https://docs.github.com/actions/security-guides)** - Securing workflows

## Support

**Questions?**
- Open an issue
- Check Security tab for alerts
- Review Insights → Dependency graph

**Problems with auto-merge?**
- Check workflow runs: Actions tab
- Review branch protection: Settings → Branches
- Verify permissions: `.github/workflows/dependabot-auto-merge.yml`

---

**Last Updated:** 2025-01-XX  
**Maintained By:** PoshGuard Team
