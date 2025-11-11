# PoshGuard Quick Reference Guide

## At a Glance

```
PoshGuard v4.3.0
PowerShell Security & Quality Auto-Fix Engine
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ENTRY POINT: ./tools/Apply-AutoFix.ps1
or: Import-Module PoshGuard; Invoke-PoshGuard

SIZE: 6.4 MB | CODE: ~11K lines | TESTS: 50+ | DOCS: 40+
```

---

## Module Breakdown

### Foundation Layer
```
Core.psm1 (197 lines)
├─ Backup management
├─ Logging (Info, Warn, Error, Success, Critical, Debug)
├─ File discovery
├─ Diff generation
└─ File operations
```

### Security Layer (8 PSSA Rules - 100% Coverage)
```
Security.psm1 (542 lines)
├─ Plain text passwords → SecureString
├─ Secure string usage fixes
├─ Credential parameter replacement
├─ Authentication hardening
├─ Hardcoded computer name removal
├─ Invoke-Expression elimination
├─ Empty catch block fixes
└─ Hash algorithm updates
```

### Quality Layer (28+ Rules)
```
BestPractices.psm1 (93 lines)
├─ Syntax.psm1 - PowerShell syntax
├─ Naming.psm1 - Naming conventions
├─ Scoping.psm1 - Variable scoping
├─ StringHandling.psm1 - Quote handling
├─ TypeSafety.psm1 - Type checking
└─ UsagePatterns.psm1 - Pattern fixes

Formatting.psm1 (81 lines)
├─ Whitespace.psm1 - Indentation
├─ Aliases.psm1 - Alias expansion
├─ Casing.psm1 - Case normalization
├─ Output.psm1 - Write-Host fixes
├─ Alignment.psm1 - Statement alignment
├─ Runspaces.psm1 - Runspace management
└─ WriteHostEnhanced.psm1 - Output enhancement

Advanced.psm1 (135 lines)
├─ ASTTransformations.psm1
├─ ParameterManagement.psm1
├─ CodeAnalysis.psm1
├─ Documentation.psm1
├─ AttributeManagement.psm1
├─ ManifestManagement.psm1
├─ CompatibleCmdlets.psm1
├─ DefaultValueForMandatory.psm1
└─ UTF8EncodingForHelpFile.psm1
```

### Advanced Features Layer
```
RipGrep.psm1 (636 lines)        → 5-10x faster scanning
NISTSP80053Compliance.psm1 (822) → 14 control families
EntropySecretDetection.psm1 (568) → Secret detection
AIIntegration.psm1 (716 lines)  → ML-based analysis
MCPIntegration.psm1 (596 lines) → Claude/LLM support
OpenTelemetryTracing.psm1 (669) → Distributed tracing
SupplyChainSecurity.psm1 (744)  → Dependency scanning
```

---

## Quick Commands

```powershell
# Preview changes
Invoke-PoshGuard -Path ./script.ps1 -DryRun -ShowDiff

# Apply fixes
Invoke-PoshGuard -Path ./scripts -Recurse

# Fast scan (5-10x faster)
Invoke-PoshGuard -Path ./large-repo -Recurse -FastScan

# Export for GitHub Code Scanning
Invoke-PoshGuard -Path . -ExportSarif -SarifOutputPath ./results.sarif

# Skip specific rules
Invoke-PoshGuard -Path ./scripts -Skip PSAvoidUsingCmdletAliases

# Repository users
./tools/Apply-AutoFix.ps1 -Path ./script.ps1 -DryRun
```

---

## Security Rules (100+)

### High-Risk Rules
- Hardcoded credentials/passwords
- Invoke-Expression with user input
- Unsafe deserialization
- Broken hash algorithms
- Hardcoded computer names
- Plain text passwords in parameters

### Medium-Risk Rules
- Missing error handling
- Empty catch blocks
- Unsafe script block construction
- Unvalidated file operations
- Broken cmdlet compatibility
- Missing parameter validation

### Low-Risk Rules
- Alias usage
- Case inconsistencies
- Whitespace/indentation
- Naming conventions
- Code organization
- Documentation gaps

---

## Configuration Files

| File | Purpose |
|------|---------|
| `.psscriptanalyzer.psd1` | PSScriptAnalyzer main config |
| `config/PSScriptAnalyzerSettings.psd1` | Rule inclusion/exclusion |
| `config/SecurityRules.psd1` | Security rule definitions |
| `config/QASettings.psd1` | QA thresholds |
| `config/poshguard.json` | Main configuration |
| `config/ai.json` | AI integration settings |

---

## CI/CD Workflows (20+)

```
├── Core Testing
│   ├── ci.yml - Main pipeline
│   ├── pester-tests.yml
│   ├── comprehensive-tests.yml
│   └── coverage.yml
├── Security
│   ├── code-scanning.yml
│   ├── codeql.yml
│   └── scorecard.yml
├── Quality
│   ├── poshguard-quality-gate.yml
│   └── poshguard-incremental.yml
└── Release
    ├── release.yml
    └── docs-ci.yml
```

---

## File Locations

| Type | Location | Count |
|------|----------|-------|
| Main Module | `/PoshGuard/PoshGuard.psm1` | 1 |
| Tool Scripts | `/tools/*.ps1` | 8 |
| Core Libraries | `/tools/lib/*.psm1` | 20+ |
| Submodules | `/tools/lib/{Category}/*.psm1` | 28 |
| Tests | `/tests/Unit/**/*.Tests.ps1` | 50+ |
| Config | `/config/*.psd1` or `.json` | 5 |
| Docs | `/docs/**/*.md` | 40+ |
| Samples | `/samples/*.ps1` | 7 |
| Workflows | `/.github/workflows/*.yml` | 20+ |

---

## Key Capabilities Matrix

```
┌─────────────────────────┬──────────────────────────────┐
│ FEATURE                 │ STATUS / NOTES               │
├─────────────────────────┼──────────────────────────────┤
│ AST-based fixes         │ ✓ All fixes use AST parsing  │
│ Security rules          │ ✓ 100+ rules                 │
│ Performance opt         │ ✓ RipGrep integration        │
│ GitHub integration      │ ✓ SARIF export, 20+ workflows│
│ Compliance mapping      │ ✓ NIST/OWASP/CIS/ISO/FedRAMP│
│ Automated testing       │ ✓ 95%+ coverage              │
│ AI integration          │ ✓ Claude/LLM support         │
│ Observability           │ ✓ OpenTelemetry tracing      │
│ Privacy                 │ ✓ Zero telemetry             │
│ Multi-platform          │ ✓ Windows/macOS/Linux        │
└─────────────────────────┴──────────────────────────────┘
```

---

## Performance Benchmarks

| Codebase Size | Standard Scan | Fast Scan | Speedup |
|---------------|---------------|-----------|---------|
| 1,000 scripts | ~48s | ~9s | **5.3x** |
| 10,000 scripts | ~480s | ~52s | **9.2x** |

(RipGrep required for Fast Scan)

---

## Compliance Frameworks

### NIST SP 800-53 (14 Control Families)
- SI-7: Information System Monitoring
- SC-7: Boundary Protection
- AC-2: Account Management
- IA-2: Authentication
- AU-12: Audit Generation
- ... and 9 more

### OWASP ASVS v4.0
- All v4.0 requirements mapped
- Attack pattern detection
- Input validation checks

### CIS PowerShell Benchmarks
- Community standards aligned
- Best practice enforcement

### ISO 27001 & FedRAMP
- Applicable security controls
- Compliance verification

---

## Testing Strategy

```
Unit Tests (50+)
├── Core.Tests.ps1
├── Security.Tests.ps1
├── BestPractices/
│   ├── Syntax.Tests.ps1
│   ├── Naming.Tests.ps1
│   ├── Scoping.Tests.ps1
│   ├── TypeSafety.Tests.ps1
│   └── ...
├── Formatting/
│   ├── Whitespace.Tests.ps1
│   ├── Aliases.Tests.ps1
│   └── ...
├── Advanced/
│   └── [14 submodule tests]
└── Tools/
    └── [7 tool script tests]

Coverage: 95%+
Framework: Pester v5+
Mocking: Advanced builders included
Data: Fixtures in TestData.psm1
```

---

## Documentation Map

### Start Here
1. **README.md** (5 min) - Overview
2. **docs/quick-start.md** (5 min) - Get started
3. **docs/usage.md** (10 min) - Basic usage

### Understand It
4. **docs/ARCHITECTURE.md** (15 min) - How it works
5. **docs/how-it-works.md** (20 min) - Technical details

### Deep Dive
6. **docs/reference/SECURITY-FRAMEWORK.md** - Security
7. **docs/RIPGREP_INTEGRATION.md** - Performance
8. **docs/MCP-GUIDE.md** - AI integration

### Advanced
9. **docs/development/** - For contributors
10. **docs/PESTER_ARCHITECT_ANALYSIS.md** - Testing

---

## Installation

```powershell
# Method 1: PowerShell Gallery (Recommended)
Install-Module -Name PoshGuard -Scope CurrentUser -Force
Import-Module PoshGuard

# Method 2: From Repository
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard
./tools/Apply-AutoFix.ps1 -Path ./samples

# Optional: Install RipGrep for speed
# Windows: choco install ripgrep
# macOS: brew install ripgrep
# Linux: apt install ripgrep
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Module not found | `Install-Module PoshGuard -Force` |
| Slow scanning | Install RipGrep, use `-FastScan` |
| SARIF export fails | Ensure output directory exists |
| Fix didn't apply | Check rule is enabled in config |
| Backup not created | Verify write permissions |

---

## Entry Points

```powershell
┌─────────────────────────────────────┐
│ Invoke-PoshGuard (PowerShell Gallery)│
│ ./tools/Apply-AutoFix.ps1 (Repo)    │
│ PoshGuard module                    │
└─────────────────────────────────────┘
           ↓
    Apply-AutoFix.ps1
           ↓
    Load Modules (Facade pattern)
    ├─ Core.psm1
    ├─ Security.psm1
    ├─ BestPractices.psm1
    ├─ Formatting.psm1
    └─ Advanced.psm1
           ↓
    Call Specialized Modules
    ├─ RipGrep.psm1
    ├─ EntropySecretDetection.psm1
    ├─ AIIntegration.psm1
    └─ ...
           ↓
    Execute Fixes & Generate Output
```

---

## Key Statistics

- **Version:** 4.3.0
- **License:** MIT
- **Repository Size:** 6.4 MB
- **Code Lines:** ~11,380 (core)
- **PowerShell Files:** 70+
- **Test Files:** 50+
- **Documentation:** 40+ files
- **GitHub Workflows:** 20+
- **Security Rules:** 100+
- **Compliance Frameworks:** 5+ (NIST, OWASP, CIS, ISO, FedRAMP)
- **Test Coverage:** 95%+
- **Success Rate:** 95%+
- **Target Platforms:** Windows, macOS, Linux
- **PowerShell Version:** 5.1+ (7+ recommended)

---

## Resources

- **GitHub:** https://github.com/cboyd0319/PoshGuard
- **PowerShell Gallery:** https://www.powershellgallery.com/packages/PoshGuard
- **Documentation Index:** docs/DOCUMENTATION_INDEX.md
- **Contributing Guide:** CONTRIBUTING.md
- **Security Policy:** SECURITY.md
- **Code of Conduct:** CODE_OF_CONDUCT.md

---

**Last Updated:** 2025-11-11  
**Version:** v4.3.0  
**Repository Health:** Excellent  
**Status:** Production Ready
