# PoshGuard — PowerShell security and quality auto‑fixes

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PoshGuard.svg)](https://www.powershellgallery.com/packages/PoshGuard)
[![License](https://img.shields.io/github/license/cboyd0319/PoshGuard.svg)](LICENSE)
[![CI](https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml)
[![Coverage](https://github.com/cboyd0319/PoshGuard/actions/workflows/coverage.yml/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/coverage.yml)
[![codecov](https://codecov.io/github/cboyd0319/PoshGuard/graph/badge.svg?token=R4DPM6WAKV)](https://codecov.io/github/cboyd0319/PoshGuard)
[![Scorecard](https://github.com/cboyd0319/PoshGuard/actions/workflows/scorecard.yml/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/scorecard.yml)
[![Docs](https://github.com/cboyd0319/PoshGuard/actions/workflows/docs-ci.yml/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/docs-ci.yml)

TL;DR: Install from Gallery and fix scripts with safe, AST‑based transformations.

```powershell
# Quickstart
Install-Module -Name PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard
Invoke-PoshGuard -Path ./script.ps1 -DryRun -ShowDiff
```

## Features

- AST‑based fixes that preserve intent
- Secrets hardening and credential safety
- Practical standards coverage (NIST, OWASP, CIS, ISO, FedRAMP)
- Optional SARIF export for GitHub Code Scanning
- Sensible defaults; privacy first; no telemetry

## Prerequisites

| Item | Version | Why |
|------|---------|-----|
| PowerShell | 7+ (Windows/macOS/Linux) | runtime |
| PSGallery access | N/A | module install |

## Install & Use

```powershell
# Install
Install-Module -Name PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard

# Preview changes (safe)
Invoke-PoshGuard -Path ./script.ps1 -DryRun -ShowDiff

# Apply fixes recursively
Invoke-PoshGuard -Path ./scripts -Recurse

# Export SARIF (for GitHub Code Scanning)
Invoke-PoshGuard -Path . -DryRun -ExportSarif -SarifOutputPath ./poshguard-results.sarif
```

From source (no install):

```powershell
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard
./tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -ShowDiff
```

## Configuration

Defaults are usually enough. When needed, see `docs/config.md` for `config/PSScriptAnalyzerSettings.psd1`, `config/QASettings.psd1`, `config/SecurityRules.psd1`, and `config/poshguard.json`.

## Docs

- Start here: docs/DOCUMENTATION_INDEX.md
- Architecture: docs/ARCHITECTURE.md
- Checks & Fixes: docs/checks.md
- API: docs/api.md

## Testing

PoshGuard has a comprehensive test suite with 1000+ tests following Pester v5+ best practices:

```powershell
# Quick test run
./tests/Run-Tests.ps1

# With code coverage
./tests/Run-Tests.ps1 -Mode Coverage

# Test specific module
./tests/Run-Tests.ps1 -Module Core

# Debug mode
./tests/Run-Tests.ps1 -Mode Debug -Module Security -StopOnFailure
```

**Documentation:**
- [Test Architecture](tests/COMPREHENSIVE_PESTER_ARCHITECTURE.md) — Complete testing guide and standards
- [Quick Start](tests/QUICKSTART_TESTING.md) — Testing patterns and examples
- [Run Tests](tests/Run-Tests.ps1) — Automated test runner

**Coverage:** 90%+ lines, 85%+ branches across all modules (enforced in CI)

## Troubleshooting

- Validate PowerShell scripts: .github/workflows/docs-ci.yml (Windows job)
- If `Invoke-PoshGuard` fails, try `-DryRun -NonInteractive` and check output
- For SARIF usage and GitHub Security integration, see docs/reference/GITHUB-SARIF-INTEGRATION.md

## What’s new

See docs/CHANGELOG.md.

## Community and support

- Issues: <https://github.com/cboyd0319/PoshGuard/issues>
- Discussions: <https://github.com/cboyd0319/PoshGuard/discussions>
- Security policy: SECURITY.md

## License

MIT — see LICENSE
