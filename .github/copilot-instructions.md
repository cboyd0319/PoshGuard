# Copilot Instructions — PoshGuard

Purpose: Provide clear, enforceable guidance so changes remain aligned with PoshGuard's mission, security posture, testing rigor, and documentation standards.

## Mission & Non-Negotiables

- World-class PowerShell security and quality auto-fixing: AST-based transformations, zero telemetry, privacy-first.
- NIST SP 800-53, OWASP ASVS, CIS PowerShell Benchmarks, ISO 27001, FedRAMP compliance built-in.
- Safe AST-based fixes: No regex hacks. Preserve code intent. All transformations must be reversible with backups.
- Multi-platform support: Windows, macOS, Linux (PowerShell 7+). Cross-platform testing required.
- SARIF 2.1.0 export for GitHub Code Scanning integration.
- RipGrep integration for 5-10x faster scanning on large codebases (optional but recommended).

CRITICAL Repo Rules (must follow)
- Zero unsafe transformations. All code fixes must preserve functionality and be validated by tests.
- Avoid doc sprawl. Do not create a new doc for every small task. Prefer updating canonical docs under `docs/`. Create new documents only when a clear gap exists, and then link them from `docs/DOCUMENTATION_INDEX.md`.
- All PowerShell code must pass PSScriptAnalyzer with zero errors/warnings using `.psscriptanalyzer.psd1` rules.
- All markdown must pass markdownlint using `.markdownlint.json` rules.

Primary audience: DevOps engineers, Security teams, IT administrators; secondary: Compliance officers; tertiary: PowerShell developers.
Target OS: Windows → macOS → Linux.

## Architecture Snapshot

- **Core Module** (`tools/lib/Core.psm1`): Logging, file operations, backups, unified diff generation.
- **Security Module** (`tools/lib/Security.psm1`): Hardcoded credentials, weak crypto, command injection, Invoke-Expression detection and fixes.
- **BestPractices Module** (`tools/lib/BestPractices.psm1`): Error handling, parameter validation, naming conventions.
- **Formatting Module** (`tools/lib/Formatting.psm1`): Indentation, whitespace, casing, alignment, alias expansion.
- **Advanced Module** (`tools/lib/Advanced.psm1`): AST transformations, ShouldProcess, documentation generation, manifest management.
- **RipGrep Module** (`tools/lib/RipGrep.psm1`): Fast pre-filtering for large codebases; optional integration.
- **AI Integration** (`tools/lib/AIIntegration.psm1`): ML confidence scoring, reinforcement learning for fix quality.
- **MCP Integration** (`tools/lib/MCPIntegration.psm1`): Model Context Protocol for AI-assisted analysis.
- **Observability** (`tools/lib/Observability.psm1`): OpenTelemetry tracing, metrics, distributed tracing.
- **Supply Chain** (`tools/lib/SupplyChainSecurity.psm1`): SBOM generation (CycloneDX/SPDX), provenance, attestation.

Main entry points:
- Module: `Invoke-PoshGuard` (imported from `PoshGuard/PoshGuard.psm1`)
- Direct script: `tools/Apply-AutoFix.ps1`

## Documentation Policy (must follow)

- All canonical docs live under `docs/` only.
- Allowed root stubs (minimal link-only): `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`.
- This file (`.github/copilot-instructions.md`) is an operational exception.
- Documentation index: `docs/DOCUMENTATION_INDEX.md` (single source of truth for all docs).
- Standards: Enforce markdownlint + Vale; active voice; consistent terminology; relative links.
- Configuration guides in `docs/reference/`; examples in `samples/`; architecture in `docs/ARCHITECTURE.md`.

## Testing & Coverage Requirements

- Module coverage ≥ 85%; critical security modules should be ~95%.
- All tests under `tests/Unit/` using Pester v5.5.0+.
- Test runner: `tests/run-local-tests.ps1` for local validation.
- CI enforces coverage thresholds via `.github/workflows/coverage.yml`.
- Golden file tests for AST transformations; edge case coverage (empty, null, Unicode, special characters).
- Performance benchmarks for RipGrep integration and large codebase scanning.

## CI Rules & Required Checks

- **PSScriptAnalyzer**: Zero errors/warnings across all `.ps1`, `.psm1`, `.psd1` files using `.psscriptanalyzer.psd1` settings.
- **Pester Tests**: All unit tests must pass; coverage ≥85% enforced.
- **Markdown Linting**: markdownlint + Vale with zero errors.
- **Security**: CodeQL, dependency review, Scorecard compliance.
- **SARIF Validation**: All exports must validate against SARIF 2.1.0 schema.

## Single Source of Truth

- **Documentation Index**: `docs/DOCUMENTATION_INDEX.md` (complete catalog of all documentation).
- **Root README**: Overview, quickstart, and links into `docs/` (don't duplicate).
- **Checks & Fixes Reference**: `docs/checks.md` (complete list of security rules and transformations).
- **API Reference**: `docs/api.md` (cmdlet usage and parameters).
- **Architecture**: `docs/ARCHITECTURE.md` (system design, data flow, module interactions).
- All user/developer docs: under `docs/` (reference, guides, tutorials, troubleshooting).

## When Adding or Changing Features

1) Update reference and guides:
   - `docs/checks.md` for new security rules or fixes
   - `docs/api.md` for new cmdlets or parameters
   - `docs/ARCHITECTURE.md` for architectural changes
   - `docs/config.md` for configuration options
   - `docs/TROUBLESHOOTING.md` for known issues
2) Update root `README.md` where applicable (Features, Quickstart, Performance benchmarks).
3) If SARIF output changes: validate against SARIF 2.1.0 schema; update golden tests.
4) If RipGrep patterns change: update pattern documentation in `docs/RIPGREP_INTEGRATION.md`.
5) Run validation:
   ```powershell
   # PSScriptAnalyzer
   Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse
   
   # Pester tests
   ./tests/run-local-tests.ps1 -Coverage
   
   # Markdown linting
   markdownlint --config .markdownlint.json '**/*.md'
   ```

## Build Systems & Examples Checklist

- Cover both module installation methods:
  - **PowerShell Gallery**: `Install-Module PoshGuard` → `Invoke-PoshGuard`
  - **Source/Development**: `tools/Apply-AutoFix.ps1` for direct usage
- Include examples for:
  - Single file analysis
  - Directory recursion
  - Fast scan mode with RipGrep
  - Dry-run with diff preview
  - SARIF export for GitHub Code Scanning
  - CI/CD integration (GitHub Actions, Azure DevOps)

## Security & Supply Chain Requirements

- **Zero telemetry**: No data collection, no network calls except for optional RipGrep installation checks.
- **Backup-first**: All fixes create timestamped backups before modifying files.
- **SARIF 2.1.0**: All exports must validate; include rule metadata, locations, fixes.
- **Compliance mappings**: Every security rule maps to NIST SP 800-53, OWASP ASVS, CIS, ISO 27001, FedRAMP.
- **Supply chain**: SBOM generation via CycloneDX/SPDX; provenance tracking; attestation support.

## PowerShell Module Standards

- **Module structure**:
  - `PoshGuard/PoshGuard.psd1` - manifest (PowerShell Gallery metadata)
  - `PoshGuard/PoshGuard.psm1` - root module (exports `Invoke-PoshGuard`)
  - `tools/lib/*.psm1` - submodules (Core, Security, BestPractices, etc.)
  - `tools/Apply-AutoFix.ps1` - direct script usage
- **Coding standards**:
  - PowerShell 5.1 minimum (for compatibility)
  - PowerShell 7+ recommended (for cross-platform)
  - Strict mode: `Set-StrictMode -Version Latest`
  - Error handling: Use `-ErrorAction Stop` and try/catch
  - Parameter validation: Use `[Parameter(Mandatory)]`, `[ValidateSet()]`, etc.
  - Output types: Declare with `[OutputType()]`
  - ShouldProcess: Add for state-changing functions
- **Naming conventions**:
  - Functions: Approved PowerShell verbs only (Get-, Set-, New-, Remove-, etc.)
  - Singular nouns for function names (Get-PowerShellFile, not Get-PowerShellFiles)
  - Parameters: PascalCase
  - Variables: camelCase

## Write-Host Usage Policy

- Write-Host is acceptable for CLI tools with colored user-facing output.
- Suppress PSScriptAnalyzer warnings with:
  ```powershell
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', 
    Justification = 'Write-Host is used intentionally for colored CLI output')]
  ```
- Use Write-Verbose for diagnostic output instead of Write-Host where possible.
- Use Write-Information for structured output.

## Test Helpers & Mocking

- Test helpers in `tests/Helpers/TestHelpers.psm1`
- Write-Host is mocked in tests via `Initialize-PerformanceMocks` to prevent slow console I/O.
- When testing functions that use Write-Host for output, either:
  1. Remove the mock temporarily in that test scope, or
  2. Test the function's side effects rather than console output

## RipGrep Integration

- RipGrep (`rg`) is optional but provides 5-10x speedup for large codebases.
- Graceful fallback: If RipGrep is not installed, fall back to standard PowerShell file discovery.
- Check availability: `Test-RipGrepAvailable` function in RipGrep.psm1.
- Pattern-based pre-filtering: Identify candidate files before expensive AST parsing.
- Document installation in `README.md` and `docs/RIPGREP_INTEGRATION.md`.

## Dependency Management

- **Required**: `PSScriptAnalyzer` v1.24.0+ (declarative in manifest)
- **Optional**: RipGrep v14.0+ (user-installed, checked at runtime)
- **Development**: Pester v5.5.0+ (for testing)
- No other external dependencies for runtime operation.

## Release & Distribution

- PowerShell Gallery: `Publish-Module` from `PoshGuard/` directory.
- GitHub Releases: Include module package, examples, documentation PDF.
- Versioning: Semantic versioning (MAJOR.MINOR.PATCH) in `PoshGuard/PoshGuard.psd1` and `PoshGuard/VERSION.txt`.
- Changelog: Update `docs/CHANGELOG.md` for each release.

## Common Pitfalls to Avoid

- ❌ Don't use regex for code transformations (use AST instead).
- ❌ Don't modify files without creating backups first.
- ❌ Don't add dependencies without justification and fallback handling.
- ❌ Don't create new documentation files without updating `docs/DOCUMENTATION_INDEX.md`.
- ❌ Don't use plural nouns in function names (PSUseSingularNouns).
- ❌ Don't use unapproved PowerShell verbs (PSUseApprovedVerbs).
- ❌ Don't assume Write-Host output is testable (it's mocked in tests).

## Quality Gates (must pass before PR merge)

1. ✅ PSScriptAnalyzer: Zero errors/warnings
2. ✅ Pester tests: 100% pass rate, ≥85% coverage
3. ✅ Markdown linting: Zero errors
4. ✅ SARIF validation: Valid against schema 2.1.0
5. ✅ Manual testing: Verify fixes on sample scripts
6. ✅ Documentation: Updated for all changes
7. ✅ Changelog: Entry added for user-facing changes

## Getting Started for Contributors

1. Clone the repository
2. Install prerequisites:
   ```powershell
   # Required
   Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
   Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force
   
   # Optional (recommended)
   # Install RipGrep via package manager (choco, brew, apt, etc.)
   
   # Linting
   npm install -g markdownlint-cli
   ```
3. Run tests: `./tests/run-local-tests.ps1`
4. Run analyzer: `Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse`
5. Make changes following this guide
6. Verify all quality gates pass
7. Submit PR with description of changes and test results

## Resources

- PowerShell Best Practices: https://poshcode.gitbook.io/powershell-practice-and-style/
- PSScriptAnalyzer Rules: https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation
- Pester Documentation: https://pester.dev/docs/quick-start
- SARIF 2.1.0 Schema: https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html
