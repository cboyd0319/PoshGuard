# Dependabot Configuration

This repository uses [Dependabot](https://docs.github.com/en/code-security/dependabot) to automatically keep dependencies up to date.

## Configuration

### Monitored Dependencies

Dependabot monitors the following package ecosystems:

1. **GitHub Actions** (`.github/workflows/*.yml`)
   - Weekly updates on Mondays at 9:00 AM
   - Monitors: `actions/checkout`, `actions/cache`, `actions/upload-artifact`, etc.

2. **npm packages** (`vscode-extension/package.json`)
   - Weekly updates on Mondays at 9:00 AM
   - Major VSCode engine updates are ignored for compatibility

### Auto-Merge Policy

The `dependabot-auto-merge.yml` workflow automatically handles Dependabot PRs:

- ✅ **Auto-approved**: All Dependabot PRs are automatically approved
- ✅ **Auto-merged (patch/minor)**: Patch and minor version updates are automatically merged after CI passes
- ⚠️ **Manual review (major)**: Major version updates require manual review and approval

## How It Works

1. Dependabot creates a PR when a dependency update is available
2. The auto-merge workflow automatically approves the PR
3. For patch/minor updates:
   - Auto-merge is enabled
   - Once CI checks pass, the PR is automatically merged
4. For major updates:
   - A comment is added to the PR requesting manual review
   - Manual merge is required after review

## Security

- All Dependabot PRs are labeled with `dependencies` for easy tracking
- CI/CD checks must pass before any auto-merge occurs
- Major version updates require manual review to prevent breaking changes
- Auto-merge uses squash commits to maintain clean git history

## Disabling Auto-Merge

If you need to disable auto-merge temporarily:

1. Edit `.github/workflows/dependabot-auto-merge.yml`
2. Comment out or remove the "Enable auto-merge" step
3. Commit and push the changes

## Manual Merge

To manually merge a Dependabot PR:

```bash
# From the GitHub web UI:
# 1. Review the PR
# 2. Approve if satisfied
# 3. Click "Squash and merge"

# Or from CLI:
gh pr review <PR-NUMBER> --approve
gh pr merge <PR-NUMBER> --squash
```

## Further Reading

- [Dependabot documentation](https://docs.github.com/en/code-security/dependabot)
- [Dependabot configuration options](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
- [Auto-merge documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)
