# Changelog

All notable changes to PoshGuard are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/).

## [3.0.0] - 2025-10-11

### Achievement
**100% PSSA General Rules Coverage** - First PowerShell auto-fix tool to achieve complete coverage of all 60 general-purpose PSScriptAnalyzer rules.

### Added
- GitHub Actions CI/CD pipeline with 3 jobs (lint, test, package)
- SARIF upload to GitHub Code Scanning for security insights
- Automated release workflow with SBOM generation and build attestation
- PowerShell module manifest (PoshGuard.psd1) for gallery publication
- Sample scripts demonstrating before/after fixes in `samples/` directory
- Comprehensive "How It Works" documentation with AST transformation examples
- JSONL report output format for CI/CD integration
- `-NonInteractive` flag for deterministic CI/CD execution
- Exit code documentation (0=success, 1=issues found, 2=error)
- Authenticode signing instructions for enterprise deployment
- Module installation via PowerShell Gallery (Install-Module PoshGuard)
- "Safe by Default" security callouts in README
- Table of Contents for improved README navigation
- Real-world examples in samples/ with expected diffs

### Changed
- Updated README with enhanced badges (CI status, Code Scanning)
- Converted prerequisite and configuration lists to proper markdown tables
- Enhanced installation documentation with 3 options (Gallery, Git, Release)
- Improved security section with code signing guidance
- Expanded coverage section with PSScriptAnalyzer rules catalog link
- Restructured documentation with clear examples and troubleshooting
- Updated roadmap to reflect completed milestones

### Infrastructure
- `.github/workflows/ci.yml` - Continuous integration pipeline
- `.github/workflows/release.yml` - Automated release creation with attestation
- `.github/social-preview.png` - Repository social preview image

### Documentation
- `docs/how-it-works.md` - Deep dive into AST transformations
- `docs/sample-report.jsonl` - Example JSONL output format
- `docs/demo-instructions.md` - Guide for creating demo GIF
- `samples/README.md` - Sample scripts documentation
- Enhanced README with TOC and comprehensive examples

### Excluded
- 6 DSC-specific rules (not applicable to general scripts)
- 3 complex compatibility rules (require 200+ MB profile data; simplified version implemented)
- 2 internal utility rules (PSSA development tools)

---

**Version Format**: MAJOR.MINOR.PATCH
- MAJOR: Breaking changes or architectural shifts
- MINOR: New auto-fixes or significant features
- PATCH: Bug fixes or minor improvements

**Release Assets**:
- `poshguard-3.0.0.zip` - Complete distribution package
- `poshguard-3.0.0.spdx.json` - Software Bill of Materials (SBOM)
- Build provenance attestation via GitHub Actions
