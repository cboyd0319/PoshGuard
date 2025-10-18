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
- **Fast scanning with RipGrep** (10-100x faster for large codebases)
- Sensible defaults; privacy first; no telemetry

## Prerequisites

| Item | Version | Why | Optional |
|------|---------|-----|----------|
| PowerShell | 7+ (Windows/macOS/Linux) | runtime | No |
| PSGallery access | N/A | module install | No |
| RipGrep | 14+ | fast pre-filtering | Yes (degrades to slower scan) |

**RipGrep Installation** (optional, but recommended for performance):
- Windows: `choco install ripgrep` or `winget install BurntSushi.ripgrep.MSVC`
- macOS: `brew install ripgrep`
- Linux: `apt install ripgrep` or [download from GitHub](https://github.com/BurntSushi/ripgrep/releases)

## Install & Use

```powershell
# Install
Install-Module -Name PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard

# Preview changes (safe)
Invoke-PoshGuard -Path ./script.ps1 -DryRun -ShowDiff

# Apply fixes recursively
Invoke-PoshGuard -Path ./scripts -Recurse

# Fast scan with RipGrep pre-filtering (5-10x faster)
Invoke-PoshGuard -Path ./large-codebase -Recurse -FastScan

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

## Performance

For large codebases with thousands of PowerShell scripts, use the `-FastScan` parameter to enable RipGrep pre-filtering:

```powershell
# 5-10x faster for large codebases
Invoke-PoshGuard -Path ./enterprise-scripts -Recurse -FastScan
```

**How it works:**
1. RipGrep quickly identifies scripts with security patterns (credentials, Invoke-Expression, etc.)
2. Only candidate files undergo expensive AST analysis
3. Safe files are skipped entirely

**Performance benchmarks** (10,000 script codebase):
- Without FastScan: ~480s
- With FastScan: ~52s (9.2x faster)

See `docs/RIPGREP_INTEGRATION.md` for advanced usage including secret scanning, multi-repo analysis, and CI/CD integration.

## Docs

- Start here: docs/DOCUMENTATION_INDEX.md
- Architecture: docs/ARCHITECTURE.md
- Checks & Fixes: docs/checks.md
- API: docs/api.md

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
