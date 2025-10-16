# PoshGuard — PowerShell security and quality auto‑fixes

[![CI Status](https://github.com/cboyd0319/PoshGuard/workflows/CI/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions)
[![codecov](https://codecov.io/github/cboyd0319/PoshGuard/graph/badge.svg?token=R4DPM6WAKV)](https://codecov.io/github/cboyd0319/PoshGuard)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PoshGuard.svg)](https://www.powershellgallery.com/packages/PoshGuard)
[![License](https://img.shields.io/github/license/cboyd0319/PoshGuard.svg)](LICENSE)

TL;DR: Install from Gallery and fix scripts with safe, AST‑based transformations. Preview with `-DryRun -ShowDiff`.

## Features

- AST‑based fixes that preserve intent
- Secrets hardening and credential safety
- Practical standards coverage (NIST, OWASP, CIS, ISO, FedRAMP)
- Optional SARIF export for GitHub Code Scanning
- Sensible defaults; privacy first; no telemetry

## Quickstart

Install
```powershell
Install-Module -Name PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard
```

Use
```powershell
# Preview changes (safe)
Invoke-PoshGuard -Path ./script.ps1 -DryRun -ShowDiff

# Apply fixes recursively
Invoke-PoshGuard -Path ./scripts -Recurse

# Export SARIF
Invoke-PoshGuard -Path . -DryRun -ExportSarif -SarifOutputPath ./poshguard-results.sarif
```

From source (no install)
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

## What’s new

See docs/CHANGELOG.md and docs/V4.3.0-RELEASE-NOTES.md.

## Community and support

- Issues: https://github.com/cboyd0319/PoshGuard/issues
- Discussions: https://github.com/cboyd0319/PoshGuard/discussions
- Security policy: docs/SECURITY.md

## License

MIT — see LICENSE
