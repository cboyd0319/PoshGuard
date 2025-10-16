# GitHub Actions Workflow Status Badges

This document provides ready-to-use status badges for all PoshGuard workflows. Copy these badges to display workflow status in README files, documentation, or project dashboards.

## Usage

Add these badges to your `README.md` to show real-time workflow status:

```markdown
![CI Status](https://github.com/cboyd0319/PoshGuard/workflows/CI/badge.svg)
```

## All Workflow Badges

### CI Pipeline
**Markdown:**
```markdown
[![CI](https://github.com/cboyd0319/PoshGuard/workflows/CI/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml)
```

**HTML:**
```html
<a href="https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml">
  <img src="https://github.com/cboyd0319/PoshGuard/workflows/CI/badge.svg" alt="CI Status">
</a>
```

### Code Coverage
**Markdown:**
```markdown
[![Coverage](https://github.com/cboyd0319/PoshGuard/workflows/PowerShell%20Code%20Coverage/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/coverage.yml)
```

### Code Scanning
**Markdown:**
```markdown
[![Code Scanning](https://github.com/cboyd0319/PoshGuard/workflows/Code%20Scanning/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/code-scanning.yml)
```

### CodeQL Analysis
**Markdown:**
```markdown
[![CodeQL](https://github.com/cboyd0319/PoshGuard/workflows/CodeQL%20Security%20Analysis/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/codeql.yml)
```

### PoshGuard Quality Gate
**Markdown:**
```markdown
[![Quality Gate](https://github.com/cboyd0319/PoshGuard/workflows/PoshGuard%20Quality%20Gate/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/poshguard-quality-gate.yml)
```

### Workflow Linting
**Markdown:**
```markdown
[![Actionlint](https://github.com/cboyd0319/PoshGuard/workflows/Lint%20GitHub%20Actions%20Workflows/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/actionlint.yml)
```

### Release
**Markdown:**
```markdown
[![Release](https://github.com/cboyd0319/PoshGuard/workflows/Release/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/release.yml)
```

## Badge Styles

GitHub supports different badge styles using shields.io:

### Default Style (GitHub)
```markdown
![CI](https://github.com/cboyd0319/PoshGuard/workflows/CI/badge.svg)
```

### Shields.io Styles
For more customization, use shields.io:

**Flat:**
```markdown
![CI](https://img.shields.io/github/actions/workflow/status/cboyd0319/PoshGuard/ci.yml?branch=main&style=flat&label=CI)
```

**Flat-Square:**
```markdown
![CI](https://img.shields.io/github/actions/workflow/status/cboyd0319/PoshGuard/ci.yml?branch=main&style=flat-square&label=CI)
```

**For-the-Badge:**
```markdown
![CI](https://img.shields.io/github/actions/workflow/status/cboyd0319/PoshGuard/ci.yml?branch=main&style=for-the-badge&label=CI)
```

**Plastic:**
```markdown
![CI](https://img.shields.io/github/actions/workflow/status/cboyd0319/PoshGuard/ci.yml?branch=main&style=plastic&label=CI)
```

## Combined Badge Section

Add this complete section to your README for comprehensive status visibility:

```markdown
## Build Status

| Workflow | Status | Description |
|----------|--------|-------------|
| CI Pipeline | [![CI](https://github.com/cboyd0319/PoshGuard/workflows/CI/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml) | Main quality gate |
| Code Coverage | [![Coverage](https://github.com/cboyd0319/PoshGuard/workflows/PowerShell%20Code%20Coverage/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/coverage.yml) | Test coverage analysis |
| Code Scanning | [![Scanning](https://github.com/cboyd0319/PoshGuard/workflows/Code%20Scanning/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/code-scanning.yml) | Security scanning (SARIF) |
| CodeQL | [![CodeQL](https://github.com/cboyd0319/PoshGuard/workflows/CodeQL%20Security%20Analysis/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/codeql.yml) | Advanced security analysis |
| Quality Gate | [![Quality](https://github.com/cboyd0319/PoshGuard/workflows/PoshGuard%20Quality%20Gate/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/poshguard-quality-gate.yml) | Dogfooding quality checks |
| Actionlint | [![Actionlint](https://github.com/cboyd0319/PoshGuard/workflows/Lint%20GitHub%20Actions%20Workflows/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/actionlint.yml) | Workflow validation |
```

## External Badges

### Codecov Coverage
```markdown
[![codecov](https://codecov.io/gh/cboyd0319/PoshGuard/branch/main/graph/badge.svg)](https://codecov.io/gh/cboyd0319/PoshGuard)
```

### PowerShell Gallery
```markdown
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PoshGuard.svg?style=flat-square&label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/PoshGuard)
```

### License
```markdown
[![License](https://img.shields.io/github/license/cboyd0319/PoshGuard.svg?style=flat-square)](https://github.com/cboyd0319/PoshGuard/blob/main/LICENSE)
```

### Last Commit
```markdown
[![Last Commit](https://img.shields.io/github/last-commit/cboyd0319/PoshGuard.svg?style=flat-square)](https://github.com/cboyd0319/PoshGuard/commits/main)
```

### Issues
```markdown
[![Issues](https://img.shields.io/github/issues/cboyd0319/PoshGuard.svg?style=flat-square)](https://github.com/cboyd0319/PoshGuard/issues)
```

### Pull Requests
```markdown
[![Pull Requests](https://img.shields.io/github/issues-pr/cboyd0319/PoshGuard.svg?style=flat-square)](https://github.com/cboyd0319/PoshGuard/pulls)
```

## Recommended Badge Configuration

For the main README.md, we recommend this concise badge bar:

```markdown
# PoshGuard

[![CI](https://github.com/cboyd0319/PoshGuard/workflows/CI/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml)
[![CodeQL](https://github.com/cboyd0319/PoshGuard/workflows/CodeQL%20Security%20Analysis/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/codeql.yml)
[![codecov](https://codecov.io/gh/cboyd0319/PoshGuard/branch/main/graph/badge.svg)](https://codecov.io/gh/cboyd0319/PoshGuard)
[![License](https://img.shields.io/github/license/cboyd0319/PoshGuard.svg)](LICENSE)

> Advanced PowerShell QA and auto-fix engine using AST analysis
```

This provides essential status information without cluttering the README.

## Badge Status States

Badges automatically display different colors based on workflow status:

- 🟢 **Green (passing)** - All checks passed
- 🔴 **Red (failing)** - One or more checks failed
- 🟡 **Yellow (running)** - Workflow currently in progress
- ⚪ **Gray (no status)** - Workflow hasn't run yet or was cancelled

## Troubleshooting

### Badge Not Updating
1. Check that workflow has run at least once
2. Verify workflow name matches exactly (case-sensitive, spaces must be URL-encoded as `%20`)
3. Clear browser cache
4. Wait a few minutes for GitHub's CDN to update

### Badge Shows "Unknown"
- Workflow file may have syntax errors
- Workflow may not have run yet on the specified branch
- Check workflow name spelling

### Badge Not Found (404)
- Verify repository owner and name
- Ensure workflow file exists in `.github/workflows/`
- Check that workflow has been committed to the branch

## Advanced: Dynamic Badges with Parameters

You can customize badges with additional parameters:

```markdown
![CI](https://img.shields.io/github/actions/workflow/status/cboyd0319/PoshGuard/ci.yml?branch=main&event=push&style=flat-square&label=CI&logo=github)
```

Parameters:
- `branch` - Specify branch (e.g., `main`, `develop`)
- `event` - Filter by trigger event (e.g., `push`, `pull_request`)
- `style` - Badge style (e.g., `flat`, `flat-square`, `for-the-badge`)
- `label` - Custom label text
- `logo` - Add logo (e.g., `github`, `powershell`)
- `color` - Custom color (for shields.io badges)

## Resources

- [GitHub Actions Badge Documentation](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/adding-a-workflow-status-badge)
- [Shields.io Badge Customization](https://shields.io/)
- [Codecov Badge Documentation](https://docs.codecov.com/docs/status-badges)

---

**Last Updated:** October 16, 2025  
**Maintained By:** PoshGuard Project
