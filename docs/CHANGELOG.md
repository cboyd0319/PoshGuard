# Changelog

All notable changes to PoshGuard are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/).

## [3.0.0] - 2025-10-11

### Achievement
**100% PSSA General Rules Coverage** - First PowerShell auto-fix tool to achieve complete coverage of all 60 general-purpose PSScriptAnalyzer rules.

### Added
- PSAvoidUsingDeprecatedManifestFields auto-fix using Test-ModuleManifest integration
- Comprehensive coverage documentation
- Strategic roadmap for "Beyond PSSA" features

### Changed
- Consolidated documentation from 16 files (5,468 lines) to 5 essential files
- Updated README following production tone guidelines
- Marked v3.0.0 as production milestone

### Excluded
- 6 DSC-specific rules (not applicable to general scripts)
- 3 complex compatibility rules (require 200+ MB profile data; simplified version implemented)
- 2 internal utility rules (PSSA development tools)

---

**Version Format**: MAJOR.MINOR.PATCH
- MAJOR: Breaking changes or architectural shifts
- MINOR: New auto-fixes or significant features
- PATCH: Bug fixes or minor improvements
