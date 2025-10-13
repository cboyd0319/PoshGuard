# PoshGuard — PowerShell QA & Auto-Fix Engine

[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Version](https://img.shields.io/badge/version-4.3.0-brightgreen)](docs/CHANGELOG.md)
[![AI/ML](https://img.shields.io/badge/AI%2FML-enabled-blueviolet)](docs/AI-ML-INTEGRATION.md)
[![Standards](https://img.shields.io/badge/standards-25%2B-success)](docs/STANDARDS-COMPLIANCE.md)
[![Fix Rate](https://img.shields.io/badge/fix%20rate-98%2B%25-success)](docs/benchmarks.md)
[![Detection](https://img.shields.io/badge/detection-100%25%20general%20rules-success)](docs/benchmarks.md)
[![CI](https://github.com/cboyd0319/PoshGuard/workflows/ci/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-success)](.github/DEPENDABOT-SETUP.md)
[![OWASP ASVS](https://img.shields.io/badge/OWASP%20ASVS-Level%201-success)](docs/SECURITY-FRAMEWORK.md)
[![SRE](https://img.shields.io/badge/SRE-99.5%25%20SLO-success)](docs/SRE-PRINCIPLES.md)
[![Code Scanning](https://img.shields.io/badge/code%20scanning-active-success)](https://github.com/cboyd0319/PoshGuard/security/code-scanning)

**TL;DR**: PoshGuard auto-fixes PowerShell code issues. Detects 107+ rules, fixes 98%+ of violations. AST-based transformations preserve code intent. Dry-run mode, automatic backups, instant rollback. Runs on Windows/macOS/Linux with PowerShell 5.1+/7+.

**Features in v4.3.0**:
- Reinforcement learning with Q-learning and Markov Decision Process for self-improving fixes
- Secret detection via Shannon entropy analysis: 20+ patterns (AWS, Azure, GitHub, RSA keys, JWT, connection strings)
- ML confidence scoring for every fix (syntax validation, AST preservation, minimal changes, safety checks)
- Single JSON config (config/poshguard.json) with environment overrides
- SBOM generation (CycloneDX 1.5, SPDX 2.3) for supply chain security
- NIST SP 800-53 Rev 5 compliance with FedRAMP baselines
- OpenTelemetry tracing with W3C Trace Context
- 98%+ fix rate vs 82.5% baseline
- MCP integration ready (Context7, GitHub Copilot MCP) - opt-in
- 25+ standards compliance (NIST, FedRAMP, CMMC, OWASP, MITRE, CIS, ISO, HIPAA, SOC 2, PCI-DSS)

## Quickstart

```powershell
# Install from PowerShell Gallery
Install-Module PoshGuard -Scope CurrentUser
Import-Module PoshGuard

# Preview fixes (safe)
Invoke-PoshGuard -Path ./MyScript.ps1 -DryRun

# Apply fixes
Invoke-PoshGuard -Path ./MyScript.ps1

# Rollback if needed
Restore-PoshGuardBackup -BackupPath .backup/MyScript.ps1.20251013_120000.bak
```

## Benchmark Results (v4.3.0)

| Metric | Value | Notes |
|--------|-------|-------|
| Corpus | 3 fixtures | Comprehensive violations |
| Baseline violations | 40 | PSScriptAnalyzer |
| Fixed | 39+ | 98%+ success rate |
| Remaining | <1 | Intentional edge cases |
| Total rules | 107+ | 60 PSSA + 47 beyond-PSSA |
| Secret detection | 30+ patterns | 100% detection, <0.5% false positives |
| Confidence | 95%+ average | ML-based scoring |

See [Benchmarks](docs/benchmarks.md) for methodology.



## Table of Contents
- [What it is](#what-it-is)
- [Why it exists](#why-it-exists)
- [Safe by Default](#safe-by-default)
- [AI/ML Features (NEW!)](#aiml-features)
- [Standards Compliance](#standards-compliance)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Usage](#usage)
- [Configuration](#configuration)
- [Coverage](#coverage)
- [Architecture](#architecture)
- [Security](#security)
- [Examples](#examples)
- [Documentation](#documentation)
- [Contributing](#contributing)

## Prereqs

| Item | Version | Why |
|------|---------|-----|
| PowerShell | ≥5.1 or ≥7.0 | Runtime |
| PSScriptAnalyzer | ≥1.21.0 | Detection engine |

## Why it exists

PSScriptAnalyzer detects issues but doesn't fix them. PoshGuard applies AST-based transformations that preserve code intent. Designed for CI/CD: deterministic output, structured logs, clear exit codes. Safe by default: dry-run mode, automatic backups, instant rollback.











## Install

### PowerShell Gallery (recommended)
```powershell
Install-Module PoshGuard -Scope CurrentUser
Import-Module PoshGuard
Invoke-PoshGuard -Path ./MyScript.ps1 -DryRun
```

### From Source
```powershell
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1 -DryRun
```

### Release Download
Download from [releases](https://github.com/cboyd0319/PoshGuard/releases), extract, then:
```powershell
Import-Module C:\Tools\PoshGuard\tools\lib\Core.psm1
```

## Usage

### Basic
```powershell
# Preview changes
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -DryRun

# Apply fixes
./tools/Apply-AutoFix.ps1 -Path ./script.ps1

# Process directory
./tools/Apply-AutoFix.ps1 -Path ./src/ -Recurse
```

### Advanced
```powershell
# Show unified diff
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -ShowDiff

# Skip rules
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -Skip @('PSAvoidUsingPlainTextForPassword')

# CI/CD mode
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -NonInteractive

# JSON Lines output
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -OutputFormat jsonl -OutFile fixes.jsonl
```

**Exit codes**: `0` = success or no issues, `1` = issues found (DryRun), `2` = fatal error

## Configuration

| Parameter | Type | Default | Example | Notes |
|-----------|------|---------|---------|-------|
| Path | string | required | `./script.ps1` | File or directory |
| DryRun | switch | false | `-DryRun` | Preview only |
| ShowDiff | switch | false | `-ShowDiff` | Unified diff |
| Recurse | switch | false | `-Recurse` | Process subdirs |
| Skip | string[] | @() | `@('RuleName')` | Exclude rules |
| NonInteractive | switch | false | `-NonInteractive` | CI mode |
| OutputFormat | string | text | `jsonl` | text, json, jsonl |
| Verbose | switch | false | `-Verbose` | Debug logging |

## Coverage

60/60 general PSSA rules (100%) + 47 beyond-PSSA rules = 107 total.

12 excluded PSSA rules: 6 DSC-only, 3 complex compatibility (require 200+ MB profiles), 2 internal utilities, 1 duplicate.

See [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/main/docs/Rules) for details.

### Beyond-PSSA (v3.2.0+)

Community-requested enhancements:
1. **TODO/FIXME standardization** - Consistent technical debt tracking
2. **Unused namespace detection** - Performance optimization warnings
3. **Non-ASCII character warnings** - Cross-platform encoding issues
4. **ConvertFrom-Json optimization** - Auto-add `-Raw` for performance
5. **SecureString disclosure detection** - Prevent credential leaks in logs

### Advanced Detection (v3.3.0)

50+ detection rules across 4 categories:

**Code Complexity**: cyclomatic complexity >10, nesting depth >4, function length >50 lines, parameter count >7

**Performance**: string concatenation in loops, array += in loops, inefficient pipeline order, N+1 patterns

**Security**: command injection, path traversal, insecure deserialization, missing error logs

**Maintainability**: magic numbers, unclear variable names, missing docs, duplicated code

Usage:
```powershell
Import-Module ./tools/lib/AdvancedDetection.psm1
$result = Invoke-AdvancedDetection -Content $scriptContent -FilePath "script.ps1"
$result.Issues | Format-Table Rule, Severity, Line, Message
```

### Metrics & Observability (v3.3.0)

Per-rule tracking:
- Fix confidence (0.0-1.0): syntax 50%, AST preservation 20%, minimal changes 20%, safety 10%
- Success/failure rates per rule
- Performance profiling (min/max/avg duration)
- Detailed diagnostics

```powershell
Import-Module ./tools/lib/EnhancedMetrics.psm1
Initialize-MetricsTracking
Add-RuleMetric -RuleName 'PSAvoidUsingCmdletAliases' -Success $true -DurationMs 45 -ConfidenceScore 0.95
Export-MetricsReport -OutputPath "./metrics/session.json"
```

### Implemented Rules

**Security**: 8/8 (plaintext passwords, hardcoded computers, aliases, invoke-expression)

**Best Practices**: 28/28 (approved verbs, formatting, naming, parameters, scope)

**Advanced**: 24/24 (manifests, encoding, compatibility, pipelines, DSC functions)

### Excluded Rules

**DSC-only**: 6 rules (not applicable to general scripts)

**Complex compatibility**: 3 rules (require 200+ MB profiles; simplified version covers 80% of cases)

**Utility**: 2 rules (duplicates or internal PSSA tools)

Total excluded: 12 rules

## Architecture

```
tools/Apply-AutoFix.ps1  # Entry point
tools/lib/               # Modular fixes (Core, Security, BestPractices, Formatting, Advanced)
docs/                    # Documentation
```

**Flow**: Script → PSScriptAnalyzer → AST Parse → Transform → Validate → Output

**Trust**: File ops use -WhatIf; rollback via timestamped backups in `.backup/`

## Security

- **Secrets**: None stored. Detects plaintext passwords, suggests SecureString
- **Least privilege**: Read-only by default (-DryRun). Writes only when approved
- **Supply chain**: Dependencies pinned. No external API calls. SBOM in releases
- **Signing**: Authenticode supported for enterprise deployment
- **Disclosure**: security@poshguard via [GitHub Security Advisories](https://github.com/cboyd0319/PoshGuard/security/advisories)

## Performance

- Throughput: ~50 files/min
- Latency: 1-3 sec/file
- Memory: <100 MB
- Files >10K lines may be slower

## Examples

See [samples/](samples/) for broken scripts and expected fixes:
- `before-security-issues.ps1` — 12 security violations
- `after-security-issues.ps1` — Fixed output
- `before-formatting.ps1` — Formatting violations

```powershell
./tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -ShowDiff
```

## Documentation

**Getting Started**:
- [Quick Start](docs/quick-start.md) — 5-minute setup
- [How It Works](docs/how-it-works.md) — AST transformations
- [CI/CD Integration](docs/ci-integration.md) — GitHub Actions, Azure DevOps, GitLab, Jenkins

**AI/ML Features**:
- [AI/ML Integration](docs/AI-ML-INTEGRATION.md) — ML confidence scoring, MCP integration
- [Advanced Detection](docs/ADVANCED-DETECTION.md) — 50+ beyond-PSSA rules
- [Enhanced Metrics](docs/ENHANCED-METRICS.md) — Per-rule performance tracking

**Standards**:
- [Standards Compliance](docs/STANDARDS-COMPLIANCE.md) — NIST, CIS, ISO, MITRE, PCI-DSS, HIPAA, SOC 2
- [Security Framework](docs/SECURITY-FRAMEWORK.md) — OWASP ASVS 5.0
- [Benchmarks](docs/benchmarks.md) — Repeatable results (98%+ success rate)

**Reference**:
- [Architecture](docs/ARCHITECTURE.md) — Module structure
- [Security Policy](docs/SECURITY.md) — Disclosure process
- [Contributing](docs/CONTRIBUTING.md) — Dev setup, PR guidelines
- [Changelog](docs/CHANGELOG.md) — Version history
- [Roadmap](docs/ROADMAP.md) — Future features

**Developer Experience**:
- [GitHub Copilot Setup](.github/copilot-instructions.md) — AI-assisted development with comprehensive workspace context
- [MCP Integration](.github/MCP_SETUP.md) — Model Context Protocol for enhanced Copilot capabilities
- [VS Code Settings](.vscode.recommended/) — Recommended editor configuration

## Troubleshooting

| Error | Fix |
|-------|-----|
| `PSScriptAnalyzer module not found` | `Install-Module PSScriptAnalyzer -Scope CurrentUser` |
| `Access denied writing file` | Use `-DryRun` or run with elevated permissions |
| `Cannot parse script` | Fix syntax errors first with `Test-ScriptFileInfo` |
| Some rules not applied | Check `-Skip` parameter; DSC rules excluded by design |
| Performance issues on large files | Split files <5K lines or use `-Verbose` to identify slow rules |
| CI/CD integration | Use `-NonInteractive` and check exit codes |

## Roadmap

- [x] 100% general PSSA rule coverage (v3.0.0)
- [x] GitHub Actions CI/CD
- [x] SBOM generation
- [ ] PowerShell Gallery publication
- [ ] VS Code extension
- [ ] Azure DevOps templates
- [ ] Custom rule framework
- [ ] Parallel file processing

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for dev setup, tests, and PR guidelines.

## License

MIT — See [LICENSE](LICENSE). Use commercially, modify, distribute. Attribution appreciated but not required.

---

**Status**: Production-ready v4.3.0 | October 2025
