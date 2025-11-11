# COMPREHENSIVE POSHGUARD REPOSITORY MAP

## PROJECT OVERVIEW

**PoshGuard** is a PowerShell security and quality auto-fix engine that uses Abstract Syntax Tree (AST) transformations to automatically detect and fix security vulnerabilities and code quality issues in PowerShell scripts.

**Current Version:** 4.3.0  
**License:** MIT  
**Repository Size:** 6.4 MB  
**Total Lines of Code:** ~11,380 lines (core modules)  
**Platform Support:** Windows, macOS, Linux (PowerShell 7+)

**Key Differentiators:**
- AST-based safe transformations (not regex-based hacks)
- 100+ security and quality rules
- NIST SP 800-53, OWASP, CIS, ISO 27001, FedRAMP compliance mapping
- RipGrep integration for 5-10x faster scanning on large codebases
- SARIF export for GitHub Code Scanning integration
- Zero telemetry, no external dependencies
- Automatic backup creation

---

## DIRECTORY STRUCTURE

```
PoshGuard/
├── PoshGuard/                      # Main module package
│   ├── PoshGuard.psm1             # Root module (exports Invoke-PoshGuard)
│   ├── PoshGuard.psd1             # Module manifest (v4.3.0)
│   └── VERSION.txt                # Version file
│
├── tools/                         # Main tool and library location
│   ├── Apply-AutoFix.ps1         # PRIMARY ENTRY POINT - Main auto-fix orchestrator
│   ├── Create-Release.ps1         # Release management script
│   ├── Restore-Backup.ps1         # Backup restoration utility
│   ├── Prepare-PSGalleryPackage.ps1 # PowerShell Gallery packaging
│   ├── Run-Benchmark.ps1          # Performance benchmarking tool
│   ├── Show-GettingStarted.ps1    # Interactive getting started guide
│   ├── Start-InteractiveTutorial.ps1 # Interactive tutorial
│   ├── Analyze-TestPerformance.ps1   # Test performance analysis
│   └── lib/                       # Core library modules (11,380 lines)
│       ├── Core.psm1             # Foundation utilities (197 lines)
│       ├── Security.psm1         # Security fixes (542 lines)
│       ├── BestPractices.psm1    # Best practice fixes (93 lines)
│       ├── Formatting.psm1       # Code formatting (81 lines)
│       ├── Advanced.psm1         # Advanced transformations (135 lines)
│       ├── AdvancedDetection.psm1    # Advanced detection (752 lines)
│       ├── AdvancedCodeAnalysis.psm1 # Code analysis (648 lines)
│       ├── AIIntegration.psm1    # AI integration features (716 lines)
│       ├── ConfigurationManager.psm1 # Configuration (432 lines)
│       ├── EnhancedDetection.psm1    # Enhanced detection (n/a)
│       ├── EnhancedMetrics.psm1  # Metrics collection (533 lines)
│       ├── EnhancedSecurityDetection.psm1 # Enhanced security (715 lines)
│       ├── EntropySecretDetection.psm1 # Entropy-based secret detection (568 lines)
│       ├── MCPIntegration.psm1   # MCP (Model Context Protocol) integration (596 lines)
│       ├── NISTSP80053Compliance.psm1 # NIST SP 800-53 compliance (822 lines)
│       ├── Observability.psm1    # Observability/tracing (533 lines)
│       ├── OpenTelemetryTracing.psm1 # OpenTelemetry integration (669 lines)
│       ├── PerformanceOptimization.psm1 # Performance tuning (527 lines)
│       ├── ReinforcementLearning.psm1 # ML-based learning (690 lines)
│       ├── RipGrep.psm1          # RipGrep integration (636 lines)
│       ├── SecurityDetectionEnhanced.psm1 # Enhanced security detection (751 lines)
│       ├── SupplyChainSecurity.psm1 # Supply chain security (744 lines)
│       ├── Advanced/             # Advanced category submodules
│       │   ├── ASTTransformations.psm1 (15,703 bytes)
│       │   ├── AttributeManagement.psm1 (12,312 bytes)
│       │   ├── CmdletBindingFix.psm1 (4,127 bytes)
│       │   ├── CodeAnalysis.psm1 (7,499 bytes)
│       │   ├── CompatibleCmdletsWarning.psm1 (6,425 bytes)
│       │   ├── DefaultValueForMandatoryParameter.psm1 (5,552 bytes)
│       │   ├── DeprecatedManifestFields.psm1 (4,356 bytes)
│       │   ├── Documentation.psm1 (5,937 bytes)
│       │   ├── InvokingEmptyMembers.psm1 (5,310 bytes)
│       │   ├── ManifestManagement.psm1 (6,677 bytes)
│       │   ├── OverwritingBuiltInCmdlets.psm1 (4,725 bytes)
│       │   ├── ParameterManagement.psm1 (15,120 bytes)
│       │   ├── ShouldProcessTransformation.psm1 (8,247 bytes)
│       │   └── UTF8EncodingForHelpFile.psm1 (5,092 bytes)
│       ├── BestPractices/        # Best practices category submodules
│       │   ├── CodeQuality.psm1 (14,357 bytes)
│       │   ├── Naming.psm1 (12,676 bytes)
│       │   ├── Scoping.psm1 (4,986 bytes)
│       │   ├── StringHandling.psm1 (5,111 bytes)
│       │   ├── Syntax.psm1 (8,818 bytes)
│       │   ├── TypeSafety.psm1 (8,018 bytes)
│       │   └── UsagePatterns.psm1 (6,907 bytes)
│       └── Formatting/           # Formatting category submodules
│           ├── Aliases.psm1 (4,462 bytes)
│           ├── Alignment.psm1 (3,292 bytes)
│           ├── Casing.psm1 (3,911 bytes)
│           ├── Output.psm1 (4,775 bytes)
│           ├── Runspaces.psm1 (5,559 bytes)
│           ├── Whitespace.psm1 (3,710 bytes)
│           └── WriteHostEnhanced.psm1 (5,452 bytes)
│
├── config/                       # Configuration files
│   ├── PSScriptAnalyzerSettings.psd1  # PSScriptAnalyzer rule configuration
│   ├── QASettings.psd1          # Quality assurance settings
│   ├── SecurityRules.psd1       # Security-specific rule definitions
│   ├── poshguard.json           # Main configuration
│   └── ai.json                  # AI integration configuration
│
├── tests/                        # Comprehensive test suite
│   ├── Unit/                    # Unit tests organized by module
│   │   ├── Advanced.Tests.ps1
│   │   ├── Advanced/            # Advanced module tests
│   │   ├── AIIntegration.Tests.ps1
│   │   ├── AdvancedCodeAnalysis.Tests.ps1
│   │   ├── AdvancedDetection.Tests.ps1
│   │   ├── BestPractices.Tests.ps1
│   │   ├── BestPractices/       # BestPractices submodule tests
│   │   ├── Core.Tests.ps1
│   │   ├── ConfigurationManager.Tests.ps1
│   │   ├── EnhancedMetrics.Tests.ps1
│   │   ├── EnhancedSecurityDetection.Tests.ps1
│   │   ├── EntropySecretDetection.Tests.ps1
│   │   ├── Formatting.Tests.ps1
│   │   ├── Formatting/          # Formatting submodule tests
│   │   ├── MCPIntegration.Tests.ps1
│   │   ├── NISTSP80053Compliance.Tests.ps1
│   │   ├── Observability.Tests.ps1
│   │   ├── OpenTelemetryTracing.Tests.ps1
│   │   ├── PerformanceOptimization.Tests.ps1
│   │   ├── PoshGuard.Tests.ps1
│   │   ├── ReinforcementLearning.Tests.ps1
│   │   ├── RipGrep.Tests.ps1
│   │   ├── Security.Tests.ps1
│   │   ├── SecurityDetectionEnhanced.Tests.ps1
│   │   ├── SupplyChainSecurity.Tests.ps1
│   │   └── Tools/               # Tool script tests
│   ├── Helpers/                 # Test helper modules
│   │   ├── TestHelper.psm1
│   │   ├── TestHelpers.psm1
│   │   ├── AdvancedMockBuilders.psm1
│   │   ├── MockBuilders.psm1
│   │   ├── PropertyTesting.psm1
│   │   └── TestData.psm1
│   ├── run-local-tests.ps1      # Local test runner
│   ├── Test-Quality-Analysis.ps1 # Test quality analysis
│   ├── Phase2-AutoFix.Tests.ps1  # Phase 2 tests
│   ├── CodeQuality.Tests.ps1
│   ├── EnhancedMetrics.Tests.ps1
│   ├── AdvancedDetection.Tests.ps1
│   └── [Multiple .md files]     # Test documentation and reports
│
├── docs/                         # Comprehensive documentation
│   ├── ARCHITECTURE.md          # System design and data flow
│   ├── BEGINNERS-GUIDE.md       # Introduction for new users
│   ├── CHANGELOG.md             # Release history
│   ├── DOCUMENTATION_INDEX.md   # Documentation navigation map
│   ├── MCP-GUIDE.md             # Model Context Protocol guide
│   ├── RIPGREP_INTEGRATION.md   # RipGrep optimization guide
│   ├── RIPGREP_USAGE_GUIDE.md   # RipGrep usage examples
│   ├── ROADMAP.md               # Future development roadmap
│   ├── PESTER_ARCHITECT_ANALYSIS.md # Pester testing analysis
│   ├── TESTING_IMPLEMENTATION.md # Testing framework details
│   ├── TEST_*.md                # Various testing guides
│   ├── quick-start.md           # Quick start guide
│   ├── install.md               # Installation instructions
│   ├── usage.md                 # Usage documentation
│   ├── how-it-works.md          # Technical explanation with examples
│   ├── api.md                   # API reference
│   ├── checks.md                # Catalog of all checks/rules
│   ├── config.md                # Configuration guide
│   ├── demo-instructions.md     # Demo setup instructions
│   ├── reference.md             # Reference documentation
│   ├── development/             # Development-focused docs
│   │   ├── README.md
│   │   ├── DEPENDABOT.md
│   │   ├── ENGINEERING-STANDARDS.md
│   │   ├── VERSION-MANAGEMENT.md
│   │   ├── ci-integration.md
│   │   ├── tools/               # Tool documentation
│   │   └── workflows/           # Workflow documentation
│   ├── examples/                # Usage examples
│   ├── reference/               # Deep-dive references
│   │   ├── ADVANCED-DETECTION.md
│   │   ├── GITHUB-SARIF-INTEGRATION.md
│   │   ├── SARIF-IMPLEMENTATION-SUMMARY.md
│   │   ├── SECURITY-FRAMEWORK.md
│   │   └── README.md
│   ├── runbooks/                # Operational runbooks
│   └── images/                  # Documentation images
│
├── samples/                      # Sample PowerShell scripts
│   ├── before-security-issues.ps1    # Example script with security issues
│   ├── after-security-issues.ps1     # Fixed version
│   ├── before-formatting.ps1
│   ├── before-beyond-pssa.ps1
│   ├── after-beyond-pssa.ps1
│   ├── pre-commit-hook.ps1           # Git pre-commit hook example
│   └── ripgrep-examples.ps1          # RipGrep usage examples
│
├── .github/                      # GitHub Actions and configuration
│   ├── workflows/               # 20+ CI/CD workflows
│   │   ├── ci.yml              # Main CI pipeline
│   │   ├── coverage.yml         # Code coverage reporting
│   │   ├── code-scanning.yml    # Security scanning
│   │   ├── codeql.yml           # CodeQL analysis
│   │   ├── comprehensive-tests.yml # Comprehensive test suite
│   │   ├── pester-tests.yml     # Pester test runner
│   │   ├── pester-architect-tests.yml # Advanced Pester tests
│   │   ├── poshguard-quality-gate.yml # Quality gate enforcement
│   │   ├── poshguard-incremental.yml  # Incremental analysis
│   │   ├── release.yml          # Release automation
│   │   ├── docs-ci.yml          # Documentation CI
│   │   ├── actionlint.yml       # GitHub Actions linting
│   │   ├── path-guard.yml       # Path-based triggering
│   │   ├── dependency-review.yml # Dependency scanning
│   │   ├── dependabot-auto-merge.yml # Dependabot automation
│   │   ├── pr-labeler.yml       # PR labeling
│   │   ├── scorecard.yml        # Security scorecard
│   │   └── stale.yml            # Stale issue management
│   ├── actions/                 # Custom GitHub Actions
│   ├── scripts/                 # Helper scripts
│   ├── ISSUE_TEMPLATE/          # Issue templates
│   ├── copilot-instructions.md  # GitHub Copilot setup
│   ├── copilot-mcp.json         # Copilot MCP configuration
│   ├── copilot-setup-steps.yml  # Copilot setup automation
│   ├── dependabot.yml           # Dependabot configuration
│   ├── labeler.yml              # PR labeler configuration
│   ├── CODEOWNERS              # Code ownership rules
│   ├── FUNDING.yml              # Sponsorship information
│   ├── ACTIONS_VERSIONS.md      # GitHub Actions version tracking
│   └── social-preview.png       # Social media preview image
│
├── benchmarks/                   # Performance benchmarking data
├── Styles/                       # Code style definitions
│   ├── Spelling/                # Spell-check dictionaries
│   └── TechDocs/                # Technical documentation styles
├── man/                          # Manual pages (if any)
├── vscode-extension/            # VSCode extension files
├── .vscode.recommended/         # Recommended VSCode settings
│
├── config files (root):
│   ├── .editorconfig            # EditorConfig standards
│   ├── .gitignore               # Git ignore rules
│   ├── .psscriptanalyzer.psd1   # PSScriptAnalyzer main config
│   ├── .psscriptanalyzer.tests.psd1 # PSScriptAnalyzer test config
│   ├── .pssasuppressfile        # PSScriptAnalyzer suppressions
│   ├── .lycheeignore            # Link checker ignore rules
│   ├── .markdownlint.json       # Markdown linting rules
│   ├── .markdownlint.jsonc      # Markdown linting (alternate)
│   ├── .vale.ini                # Vale prose linting config
│   └── codecov.yml              # CodeCov configuration
│
├── Root documentation files:
│   ├── README.md                # Main project README
│   ├── LICENSE                  # MIT License
│   ├── CODE_OF_CONDUCT.md       # Community guidelines
│   ├── CONTRIBUTING.md          # Contribution guidelines
│   ├── SECURITY.md              # Security policy
│   ├── test-results.xml         # Latest test results (XML format)
│   ├── test-quality-output.txt  # Test quality metrics
│   ├── TEST_*.md files          # Various test documentation
│   ├── RIPGREP_*.md files       # RipGrep documentation
│   └── [Various analysis files] # Reports and analysis outputs
│
└── .git/                        # Git repository metadata
```

---

## CORE MODULES EXPLAINED

### 1. **Core.psm1** (197 lines) - Foundation Utilities
- **Purpose:** Provides baseline utilities used by all other modules
- **Functions:**
  - `Clear-Backup`: Cleanup old backup files (>1 day old)
  - `Write-Log`: Structured logging with levels (Info, Warn, Error, Success, Critical, Debug)
  - `Get-ScriptFiles`: Find PowerShell scripts in directories
  - `New-Backup`: Create timestamped backups before modifications
  - `ConvertTo-UnifiedDiff`: Generate unified diff output
  - Other file operation helpers

### 2. **Security.psm1** (542 lines) - 8 PSSA Security Fixes
Fixes for all PSSA security rules (100% coverage):
- `Invoke-PlainTextPasswordFix`: Convert plain-text passwords to SecureString
- `Invoke-ConvertToSecureStringFix`: Fix improper SecureString usage
- `Invoke-UsernameAndPasswordParamsFix`: Replace with credential parameters
- `Invoke-AllowUnencryptedAuthenticationFix`: Remove insecure auth flags
- `Invoke-ComputerNameHardcodedFix`: Remove hardcoded computer names
- `Invoke-InvokeExpressionFix`: Replace Invoke-Expression with safer alternatives
- `Invoke-EmptyCatchBlockFix`: Add error handling to empty catch blocks
- `Invoke-BrokenHashAlgorithmFix`: Replace deprecated hash algorithms

### 3. **BestPractices.psm1** (93 lines) - Best Practice Coordinator
Facade module that coordinates 28 best practice fixes across 6 submodules:
- **BestPractices/Syntax.psm1** (8,818 bytes): PowerShell syntax standards
- **BestPractices/Naming.psm1** (12,676 bytes): Naming conventions
- **BestPractices/Scoping.psm1** (4,986 bytes): Variable scoping best practices
- **BestPractices/StringHandling.psm1** (5,111 bytes): Quote and string processing
- **BestPractices/TypeSafety.psm1** (8,018 bytes): Type checking and safety
- **BestPractices/UsagePatterns.psm1** (6,907 bytes): Common usage patterns

### 4. **Formatting.psm1** (81 lines) - Code Formatting Coordinator
Facade module for 11 formatting fixes across 7 submodules:
- **Formatting/Whitespace.psm1** (3,710 bytes): Indentation and trailing spaces
- **Formatting/Aliases.psm1** (4,462 bytes): Alias expansion to full cmdlet names
- **Formatting/Casing.psm1** (3,911 bytes): Cmdlet and parameter case normalization
- **Formatting/Output.psm1** (4,775 bytes): Write-Host to Write-Information conversion
- **Formatting/Alignment.psm1** (3,292 bytes): Assignment statement alignment
- **Formatting/Runspaces.psm1** (5,559 bytes): Runspace pool management
- **Formatting/WriteHostEnhanced.psm1** (5,452 bytes): Enhanced Write-Host handling

### 5. **Advanced.psm1** (135 lines) - Advanced Transformation Coordinator
Coordinates 24 advanced fixes across 9 specialized submodules for complex AST transformations

### 6. **AdvancedDetection.psm1** (752 lines) - Advanced Vulnerability Detection
- Advanced pattern matching beyond basic rules
- Behavioral analysis of code patterns
- Risk scoring and categorization

### 7. **RipGrep.psm1** (636 lines) - High-Performance Scanning Integration
- Pre-filtering for faster AST analysis
- 5-10x speedup for large codebases
- Secret pattern detection with regex
- Automatic fallback if RipGrep unavailable
- **Key Functions:**
  - `Test-RipGrepAvailable`: Check RipGrep installation
  - `Get-RipGrepMatches`: Execute RipGrep search patterns
  - `ConvertFrom-RipGrepOutput`: Parse results
  - `Measure-ScanPerformance`: Benchmark scanning

### 8. **EntropySecretDetection.psm1** (568 lines) - Entropy-Based Secret Detection
- Entropy analysis for detecting high-entropy strings (likely secrets)
- API key pattern detection
- Database connection string detection
- AWS/Azure credential detection

### 9. **EnhancedSecurityDetection.psm1** (715 lines) - Extended Security Analysis
- Detects security vulnerabilities beyond PSSA rules
- OWASP attack pattern detection
- Cryptographic weakness identification

### 10. **SecurityDetectionEnhanced.psm1** (751 lines) - Enhanced Security Scanning
- Extended security rule coverage
- Supply chain attack detection
- Dependency vulnerability scanning

### 11. **NISTSP80053Compliance.psm1** (822 lines) - Compliance Mapping
- Maps detected issues to NIST SP 800-53 control families
- 14 security control families covered
- Audit trail generation
- **Key Controls:**
  - SI-7 (Information System Monitoring)
  - SC-7 (Boundary Protection)
  - AC-2 (Account Management)
  - IA-2 (Authentication)
  - AU-12 (Audit Generation)
  - CM-3 (Access Restrictions for Change)
  - SC-4 (Information Confidentiality)
  - And more...

### 12. **SupplyChainSecurity.psm1** (744 lines) - Supply Chain Protection
- Dependency scanning and validation
- Integrity verification
- Source verification
- Provenance tracking

### 13. **PerformanceOptimization.psm1** (527 lines) - Performance Tuning
- Code performance analysis
- Optimization recommendations
- Benchmark metrics collection

### 14. **EnhancedMetrics.psm1** (533 lines) - Metrics Collection & Analysis
- Code quality metrics
- Security metrics
- Performance metrics
- Trend analysis

### 15. **AIIntegration.psm1** (716 lines) - AI-Powered Analysis
- Machine learning-based vulnerability detection
- Pattern recognition for new threat categories
- Confidence scoring
- **Features:**
  - Semantic code analysis
  - Anomaly detection
  - Predictive vulnerability identification

### 16. **ReinforcementLearning.psm1** (690 lines) - Adaptive Learning
- Learns from fix success/failure patterns
- Adapts detection rules based on user environment
- Confidence scoring refinement

### 17. **MCPIntegration.psm1** (596 lines) - Model Context Protocol
- Integration with Claude and other AI models
- Context-aware fixes based on AI assistance
- Bi-directional communication with LLMs

### 18. **OpenTelemetryTracing.psm1** (669 lines) - Observability
- Distributed tracing support
- Span creation and tracking
- Performance monitoring
- Integration with observability platforms

### 19. **Observability.psm1** (533 lines) - System Observability
- Logging and metrics export
- Health checks
- Status reporting

### 20. **ConfigurationManager.psm1** (432 lines) - Configuration Management
- Load and validate configuration files
- Rule enable/disable management
- Setting overrides
- Configuration validation

---

## MAIN TOOL SCRIPTS

### Apply-AutoFix.ps1 (Primary Entry Point)
- **Purpose:** Main orchestrator for all auto-fix operations
- **Responsibilities:**
  - Discover PowerShell files in target directory
  - Invoke PSScriptAnalyzer for detection
  - Parse scripts into AST
  - Select and apply appropriate fixes
  - Generate backups
  - Output diffs
  - Export SARIF reports (GitHub Code Scanning)
  - Validate fixes
- **Key Features:**
  - Idempotent (safe to run multiple times)
  - Modular architecture using lib/*.psm1 modules
  - DryRun mode for preview
  - Recursive directory processing
  - RipGrep integration for fast scanning
  - SARIF 2.1.0 export support

### Create-Release.ps1
- Release version management
- Git tag creation
- GitHub release creation
- Changelog generation
- Version number updates

### Prepare-PSGalleryPackage.ps1
- Package module for PowerShell Gallery
- Manifest validation
- Module structure reorganization
- Metadata preparation

### Restore-Backup.ps1
- Restore files from backup directory
- Selective file restoration
- Backup management

### Run-Benchmark.ps1
- Performance benchmarking
- Speed comparison (Standard vs. Fast Scan)
- RipGrep impact measurement
- Memory usage tracking
- Report generation

### Show-GettingStarted.ps1
- Interactive getting started guide
- Configuration wizard
- Sample demonstration

### Start-InteractiveTutorial.ps1
- Interactive step-by-step tutorial
- Live code analysis demonstrations
- Real-time fix application
- Learning paths

---

## CONFIGURATION FILES

### PSScriptAnalyzerSettings.psd1
- Main PSScriptAnalyzer rule configuration
- Rule inclusion/exclusion
- Severity levels
- Custom rule parameters
- Exclude patterns

### QASettings.psd1
- Quality assurance thresholds
- Coverage targets
- Compliance requirements
- Test expectations

### SecurityRules.psd1
- Security rule definitions
- Credential handling rules
- Code injection prevention
- LDAP injection prevention
- XSS prevention
- Pattern definitions
- Risk level classifications

### poshguard.json
- Main PoshGuard configuration
- Feature flags
- Default parameters
- Integration settings
- Output formats

### ai.json
- AI integration configuration
- LLM parameters
- Model selection
- Context settings
- Confidence thresholds

---

## CI/CD WORKFLOW INFRASTRUCTURE

### 20+ GitHub Actions Workflows:

**Core Workflows:**
- `ci.yml` - Main continuous integration pipeline (linting, testing, analysis)
- `coverage.yml` - Code coverage collection and reporting
- `code-scanning.yml` - Advanced security scanning
- `codeql.yml` - GitHub CodeQL analysis

**Test Workflows:**
- `comprehensive-tests.yml` - Full test suite execution
- `pester-tests.yml` - Pester test framework execution
- `pester-architect-tests.yml` - Advanced Pester testing

**Quality Gates:**
- `poshguard-quality-gate.yml` - Quality enforcement
- `poshguard-incremental.yml` - Incremental PR analysis

**Release & Deployment:**
- `release.yml` - Automated release creation
- `docs-ci.yml` - Documentation building and deployment

**Security & Compliance:**
- `actionlint.yml` - GitHub Actions linting
- `path-guard.yml` - Path-based rule enforcement
- `dependency-review.yml` - Dependency vulnerability scanning
- `scorecard.yml` - Security scorecard integration

**Automation:**
- `dependabot-auto-merge.yml` - Dependabot PR automation
- `pr-labeler.yml` - Automatic PR labeling
- `stale.yml` - Stale issue/PR management

---

## TEST INFRASTRUCTURE

### Test Coverage:
- **24 Core Module Tests** in tests/Unit/
- **14 Advanced Module Tests** in tests/Unit/Advanced/
- **7 BestPractices Module Tests** in tests/Unit/BestPractices/
- **7 Formatting Module Tests** in tests/Unit/Formatting/
- **7 Tool Script Tests** in tests/Unit/Tools/
- **Total: 50+ comprehensive test files**

### Test Helpers (tests/Helpers/):
- `TestHelper.psm1` - Basic test utilities
- `TestHelpers.psm1` - Extended test helpers
- `MockBuilders.psm1` - Mock object creation
- `AdvancedMockBuilders.psm1` - Complex mock construction
- `PropertyTesting.psm1` - Property-based testing
- `TestData.psm1` - Test data fixtures

### Test Runners:
- `run-local-tests.ps1` - Run tests locally
- Pester framework integration
- CodeCov integration for coverage metrics

### Test Documentation:
- Multiple comprehensive test strategy documents
- Performance benchmarking guides
- Pester architect analysis
- Test implementation summaries

---

## KEY CAPABILITIES AND FEATURES

### Security Scanning (15+ Rules)
- Hardcoded credentials detection
- Command injection prevention
- Weak cryptography detection
- Invoke-Expression (eval) warnings
- Unsafe deserialization checks
- Path traversal detection
- LDAP injection prevention
- XSS detection in HTML
- Entropy-based secret detection
- API key/token detection
- Database connection string detection

### Code Quality Fixes (28+ Rules)
- Missing error handling detection
- Inconsistent formatting
- Parameter validation enforcement
- Output encoding verification
- Naming conventions
- Scoping issues
- String handling improvements
- Type safety enhancements
- Usage pattern correction

### Compliance Framework Mapping
- **NIST 800-53** (14 control families)
- **OWASP ASVS** v4.0
- **CIS PowerShell Benchmarks**
- **ISO 27001** standards
- **FedRAMP** requirements
- **PCI DSS** data protection

### Performance Features
- RipGrep integration (5-10x faster scanning)
- Incremental analysis
- Parallel processing support
- Caching mechanisms
- Benchmarking tools

### Integration Capabilities
- **GitHub Code Scanning** (SARIF 2.1.0 export)
- **GitHub Actions** (20+ workflows)
- **Model Context Protocol** (Claude/LLM integration)
- **OpenTelemetry** (distributed tracing)
- **CodeCov** (coverage reporting)
- **VSCode** (extension support)
- **Azure DevOps** (pipeline support)
- **Docker** (container support)

### Developer Experience
- Dry-run mode (preview changes without applying)
- Diff visualization (unified diffs)
- Recursive directory scanning
- Configurable rule sets
- Privacy-first (zero telemetry)
- Automatic backup creation
- Interactive tutorials
- Getting started guides

---

## DOCUMENTATION STRUCTURE

### Quick Start Documents
- `README.md` - Main project overview
- `quick-start.md` - 5-minute setup guide
- `install.md` - Installation instructions
- `usage.md` - Basic usage examples

### Architecture & Design
- `ARCHITECTURE.md` - System design and data flow
- `how-it-works.md` - Technical mechanics with examples
- `RIPGREP_INTEGRATION.md` - Performance optimization details

### Advanced Guides
- `BEGINNERS-GUIDE.md` - Comprehensive introduction
- `MCP-GUIDE.md` - AI model integration guide
- `RIPGREP_USAGE_GUIDE.md` - RipGrep advanced usage
- `demo-instructions.md` - Demonstration setup

### Reference Documentation
- `api.md` - Command and function reference
- `checks.md` - Complete catalog of rules and fixes
- `config.md` - Configuration guide
- `reference/SECURITY-FRAMEWORK.md` - Security rule details
- `reference/GITHUB-SARIF-INTEGRATION.md` - GitHub integration guide

### Testing & Quality
- `TESTING_IMPLEMENTATION.md` - Testing framework details
- `PESTER_ARCHITECT_ANALYSIS.md` - Pester testing analysis
- `TEST_PLAN.md` - Comprehensive test strategy
- Multiple test performance guides

### Development Documentation
- `development/ENGINEERING-STANDARDS.md` - Code standards
- `development/VERSION-MANAGEMENT.md` - Version control
- `development/ci-integration.md` - CI/CD setup
- `CONTRIBUTING.md` - Contribution guidelines

### Roadmap & Operations
- `ROADMAP.md` - Future development plans
- `CHANGELOG.md` - Release history
- `SECURITY.md` - Security policy
- `runbooks/` - Operational procedures

---

## SAMPLE FILES

### before-security-issues.ps1
Example script with common security vulnerabilities:
- Hardcoded credentials
- Invoke-Expression usage
- Unsafe deserialization
- Missing error handling
- Other security anti-patterns

### after-security-issues.ps1
Fixed version of the above demonstrating PoshGuard's transformations

### before-formatting.ps1 / before-beyond-pssa.ps1
Example scripts with formatting and best practice issues

### pre-commit-hook.ps1
Git pre-commit hook template for automated analysis

### ripgrep-examples.ps1
RipGrep integration usage examples and patterns

---

## CONFIGURATION & CUSTOMIZATION

### Rule Configuration
- Enable/disable specific security checks
- Set severity levels
- Configure exclusion patterns
- Custom rule parameters

### Output Options
- Standard console output
- Verbose logging
- Diff visualization (unified diffs)
- SARIF export (GitHub Code Scanning)
- JSON reports
- XML reports

### Performance Tuning
- RipGrep pre-filtering
- Parallel processing
- Caching settings
- Memory optimization

### Compliance Settings
- Framework selection (NIST, OWASP, CIS, ISO, FedRAMP)
- Custom rule mapping
- Audit trail configuration

---

## REPOSITORY STATISTICS

- **Total Size:** 6.4 MB
- **Total Lines:** ~11,380 (core modules)
- **PowerShell Files:** 70+ .ps1 and .psm1 files
- **Test Files:** 50+ comprehensive test files
- **Documentation:** 40+ markdown files
- **CI/CD Workflows:** 20+ GitHub Actions workflows
- **Supported Rules:** 100+ security and quality rules
- **Fix Success Rate:** 95%+
- **Module Version:** 4.3.0
- **Target PowerShell:** 5.1+ (7+ recommended for full features)
- **Platforms:** Windows, macOS, Linux

---

## MAIN ENTRY POINTS

### For Module Users (PowerShell Gallery)
```powershell
Import-Module PoshGuard
Invoke-PoshGuard -Path ./scripts -DryRun -ShowDiff
```
**Main Function:** `Invoke-PoshGuard` (exported from PoshGuard.psm1)

### For Repository Users
```powershell
./tools/Apply-AutoFix.ps1 -Path ./scripts -DryRun -ShowDiff
```
**Main Script:** `/tools/Apply-AutoFix.ps1`

### For GitHub Integration
```powershell
Invoke-PoshGuard -Path . -DryRun -ExportSarif -SarifOutputPath ./poshguard-results.sarif
```
Generates SARIF report for GitHub Code Scanning

### For Large Codebases
```powershell
Invoke-PoshGuard -Path ./large-repo -Recurse -FastScan
```
Uses RipGrep for 5-10x faster scanning

---

## DEVELOPMENT NOTES

**Architecture Principles:**
- **Modularity:** Each category (Security, Formatting, BestPractices, Advanced) is independently testable
- **AST-Based:** All fixes use Abstract Syntax Tree parsing, not regex (safer, more reliable)
- **Idempotent:** Safe to run multiple times; produces same result
- **Privacy-First:** No telemetry, no external API calls, all processing is local
- **Extensible:** Easy to add new fixes via module pattern
- **Performant:** RipGrep integration enables enterprise-scale scanning

**Quality Standards:**
- 95%+ test coverage
- Comprehensive code analysis
- NIST/OWASP compliance validation
- Security scanning integration
- Performance benchmarking
- Automated CI/CD checks

