<div align="center">

<img src="docs/images/logo.png" alt="PoshGuard Logo" width="200">

# PoshGuard

### **PowerShell security and quality auto-fixes**

Safe AST-based transformations • NIST/OWASP/CIS compliant • Zero telemetry

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PoshGuard.svg)](https://www.powershellgallery.com/packages/PoshGuard)
[![License](https://img.shields.io/github/license/cboyd0319/PoshGuard.svg)](LICENSE)
[![CI](https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/ci.yml)
[![Coverage](https://github.com/cboyd0319/PoshGuard/actions/workflows/coverage.yml/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/coverage.yml)
[![codecov](https://codecov.io/github/cboyd0319/PoshGuard/graph/badge.svg?token=R4DPM6WAKV)](https://codecov.io/github/cboyd0319/PoshGuard)
[![Scorecard](https://github.com/cboyd0319/PoshGuard/actions/workflows/scorecard.yml/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions/workflows/scorecard.yml)

[Quickstart](#-quickstart) •
[Features](#-features) •
[Documentation](docs/DOCUMENTATION_INDEX.md) •
[Contributing](CONTRIBUTING.md)

</div>

---

## What is PoshGuard?

**The problem:** PowerShell scripts are prone to security vulnerabilities (hardcoded credentials, command injection, weak crypto) and quality issues (missing error handling, inconsistent formatting). Manual fixes are time-consuming and error-prone.

**The solution:** PoshGuard uses AST-based analysis to automatically detect and fix security vulnerabilities and code quality issues in PowerShell scripts—preserving your code's intent while enforcing best practices.

### Who is this for?

- **DevOps engineers** automating infrastructure and deployments
- **Security teams** enforcing NIST, OWASP, CIS, and ISO compliance
- **IT administrators** maintaining PowerShell scripts across Windows/Linux/macOS
- **Compliance officers** requiring auditable security standards

### What's New

- **RipGrep integration** for 5-10x faster scanning on large codebases
- **AST-based transformations** preserve code intent (no regex hacks)
- **Secrets hardening** detects and fixes hardcoded credentials
- **Compliance frameworks** mapped to NIST, OWASP, CIS, ISO 27001, FedRAMP
- **SARIF export** for GitHub Code Scanning integration
- **Cross-platform** works on Windows, macOS, Linux (PowerShell 7+)

---

## Quickstart

### Option 1: Install from PowerShell Gallery

```powershell
# Install from PowerShell Gallery
Install-Module -Name PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard

# Preview changes (dry run)
Invoke-PoshGuard -Path ./script.ps1 -DryRun -ShowDiff

# Apply fixes to entire directory
Invoke-PoshGuard -Path ./scripts -Recurse

# Fast scan with RipGrep (5-10x faster)
Invoke-PoshGuard -Path ./large-codebase -Recurse -FastScan
```

### Option 2: Install from Source

```powershell
# Clone repository
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard

# Run directly from source
./tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -ShowDiff
```

### Option 3: GitHub Code Scanning

```powershell
# Generate SARIF report for GitHub Security tab
Invoke-PoshGuard -Path . -DryRun -ExportSarif -SarifOutputPath ./poshguard-results.sarif

# Upload SARIF to GitHub (via GitHub Actions)
# See docs/reference/GITHUB-SARIF-INTEGRATION.md
```

**What it does:**
- Scans PowerShell scripts for security issues
- Shows diff of proposed changes
- Applies fixes automatically (preserving intent)
- Generates SARIF reports for GitHub

New to PoshGuard? Follow the [documentation index](docs/DOCUMENTATION_INDEX.md)

---

## Features

<table>
<tr>
<td width="50%">

**Security Scanning**
- Hardcoded credentials detection
- Command injection prevention
- Weak cryptography detection
- Invoke-Expression (eval) warnings
- Unsafe deserialization checks
- Path traversal detection
- LDAP injection prevention
- Cross-site scripting (XSS) in HTML

**RipGrep Integration** (NEW)
- 5-10x faster scanning on large codebases
- Secret scanning with pattern matching
- Multi-repo batch analysis
- CI/CD pipeline optimization
- Automatic fallback if unavailable
- Zero configuration required

**Code Quality**
- Missing error handling detection
- Inconsistent formatting fixes
- Parameter validation enforcement
- Output encoding verification
- Best practices compliance
- Documentation completeness checks

</td>
<td width="50%">

**Compliance Frameworks**
- **NIST 800-53** controls mapping
- **OWASP ASVS** v4.0 compliance
- **CIS PowerShell Benchmarks**
- **ISO 27001** security standards
- **FedRAMP** requirements
- **PCI DSS** data protection

**GitHub Integration**
- SARIF 2.1.0 export format
- GitHub Code Scanning support
- Security tab integration
- Automated PR checks
- Policy enforcement

**Cross-Platform Support**
- Windows (PowerShell 7+)
- macOS (PowerShell 7+)
- Linux (PowerShell 7+)
- Docker/container environments
- Azure DevOps pipelines
- GitHub Actions

**Developer Experience**
- Dry-run mode (preview changes)
- Diff visualization
- Recursive directory scanning
- Configurable rule sets
- Privacy-first (no telemetry)
- Zero external dependencies

</td>
</tr>
</table>

---

## Installation

### Prerequisites

<table>
  <thead>
    <tr>
      <th>Tool</th>
      <th>Version</th>
      <th>Purpose</th>
      <th>Required</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>PowerShell</strong></td>
      <td>≥ 7.0</td>
      <td>Runtime (Windows/macOS/Linux)</td>
      <td>Yes</td>
    </tr>
    <tr>
      <td><strong>PSGallery</strong></td>
      <td>N/A</td>
      <td>Module installation</td>
      <td>Yes</td>
    </tr>
    <tr>
      <td><strong>RipGrep</strong></td>
      <td>≥ 14.0</td>
      <td>Fast pre-filtering (5-10x speedup)</td>
      <td>No (optional)</td>
    </tr>
  </tbody>
</table>

### RipGrep Installation (Optional, Recommended)

```powershell
# Windows
choco install ripgrep
# Or: winget install BurntSushi.ripgrep.MSVC

# macOS
brew install ripgrep

# Linux (Ubuntu/Debian)
apt install ripgrep

# Verify installation
rg --version
```

---

## Performance

### Fast Scan Mode

For large codebases with thousands of PowerShell scripts, enable RipGrep pre-filtering:

```powershell
# Standard scan (full AST analysis on all files)
Invoke-PoshGuard -Path ./enterprise-scripts -Recurse

# Fast scan (5-10x faster with RipGrep)
Invoke-PoshGuard -Path ./enterprise-scripts -Recurse -FastScan
```

### How It Works

1. **RipGrep pre-filtering** - Quickly identifies scripts with security patterns (credentials, Invoke-Expression, etc.)
2. **AST analysis** - Only candidate files undergo expensive parsing
3. **Skip safe files** - Clean scripts are skipped entirely

### Performance Benchmarks

| Codebase Size | Standard Scan | Fast Scan | Speedup |
|---------------|---------------|-----------|---------|
| 1,000 scripts | ~48s | ~9s | 5.3x |
| 10,000 scripts | ~480s | ~52s | 9.2x |

See [RipGrep Integration Guide](docs/RIPGREP_INTEGRATION.md) for advanced usage.

---

## Configuration

PoshGuard uses sensible defaults. Advanced configuration available via:

- `config/PSScriptAnalyzerSettings.psd1` - PSScriptAnalyzer rules
- `config/QASettings.psd1` - Quality assurance settings
- `config/SecurityRules.psd1` - Security rule mappings
- `config/poshguard.json` - Main configuration

See [Configuration Guide](docs/config.md) for details.

---

## Troubleshooting

### Common Issues

<details>
<summary><strong>Error: Module not found</strong></summary>

**Cause:** PoshGuard not installed or not imported

**Fix:**

```powershell
# Install from Gallery
Install-Module -Name PoshGuard -Scope CurrentUser -Force

# Import module
Import-Module PoshGuard

# Verify installation
Get-Module PoshGuard -ListAvailable
```

</details>

<details>
<summary><strong>Slow performance on large codebases</strong></summary>

**Cause:** Full AST analysis on all files

**Fix:** Enable Fast Scan mode with RipGrep:

```powershell
# Install RipGrep first (see prerequisites)
Invoke-PoshGuard -Path ./large-repo -Recurse -FastScan
```

See [Performance Guide](docs/RIPGREP_INTEGRATION.md)

</details>

<details>
<summary><strong>SARIF export fails</strong></summary>

**Cause:** Invalid output path or permissions

**Fix:**

```powershell
# Ensure directory exists
New-Item -ItemType Directory -Force -Path ./reports

# Export with full path
Invoke-PoshGuard -Path . -DryRun -ExportSarif -SarifOutputPath ./reports/poshguard.sarif
```

</details>

**More help:**
- [Documentation Index](docs/DOCUMENTATION_INDEX.md)
- [GitHub Issues](https://github.com/cboyd0319/PoshGuard/issues)
- [GitHub Discussions](https://github.com/cboyd0319/PoshGuard/discussions)

---

## Documentation

### Getting Started
- **[Documentation Index](docs/DOCUMENTATION_INDEX.md)** - Complete documentation map
- **[Architecture Guide](docs/ARCHITECTURE.md)** - System design and data flow
- **[Checks & Fixes](docs/checks.md)** - Security rules and transformations
- **[API Reference](docs/api.md)** - Command reference

### Advanced Features
- **[RipGrep Integration](docs/RIPGREP_INTEGRATION.md)** - Fast scanning for large codebases
- **[GitHub SARIF Integration](docs/reference/GITHUB-SARIF-INTEGRATION.md)** - Code Scanning setup
- **[Configuration Guide](docs/config.md)** - Customizing rules and settings

### Operations
- **[Changelog](docs/CHANGELOG.md)** - Release history and updates
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

---

## License

**MIT License** - See [LICENSE](LICENSE) for full text.

```
✅ Commercial use allowed
✅ Modification allowed
✅ Distribution allowed
✅ Private use allowed
📋 License and copyright notice required
```

**TL;DR:** Use it however you want. Just include the license.

Learn more: https://choosealicense.com/licenses/mit/

---

## Support & Community

**Need help?**
- 🐛 [File a bug report](https://github.com/cboyd0319/PoshGuard/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/cboyd0319/PoshGuard/discussions/new?category=feature-requests)
- 💬 [Ask a question](https://github.com/cboyd0319/PoshGuard/discussions/new?category=q-a)
- 🔒 [Report a security issue](SECURITY.md) (private)

**Resources:**
- [PowerShell Gallery](https://www.powershellgallery.com/packages/PoshGuard)
- [Contributing Guide](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)

---

<div align="center">

## ⭐ Spread the Word

If PoshGuard helps secure your PowerShell scripts, **give us a star** ⭐

[![Star History](https://img.shields.io/github/stars/cboyd0319/PoshGuard?style=social)](https://github.com/cboyd0319/PoshGuard/stargazers)

**Active Development** • **Production-Ready** • **Community-Driven**

Made with ❤️ for PowerShell developers who value security

[⬆ Back to top](#poshguard)

</div>
