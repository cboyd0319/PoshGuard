# PowerShell QA & Auto‑Fix System — Architecture and Operations

Version: 2025-10-09

Scope: Documents the design, components, data flow, contracts, and known gaps for the `qa` folder. Use this to quickly regain context and continue work.

## Mission & Guardrails
- Correctness: Explicit contracts, validated inputs, strict behavior; zero analyzer errors.
- Safety & Security: Idempotent fixes, backups, rollback, no secrets in logs, least privilege.
- Clarity & UX: Clean CLI, readable output, sensible defaults; `--dry-run` previews; unified diffs.
- Testability: Pester v5 tests per module (happy/edge/failure), mocks for IO.
- Maintainability: Modular design, analyzer settings, consistent style, docs and examples.

## Directory Map (qa/)
- `config/`
  - `QASettings.psd1`: Engine/analysis/fix/reporting/logging settings.
  - `PSScriptAnalyzerSettings.psd1`: PSSA configuration (strict; zero-tolerance style/security).
  - `SecurityRules.psd1`: Pattern-based security scanning rules.
- `modules/`
  - `Core/Core.psm1`: Data model classes (`PSQAResult`, `PSQAAnalysisResult`, `PSQAFixResult`).
  - `Configuration/Configuration.psm1`: Loads config files; sets `$global:PSQAConfig`.
  - `FileSystem/FileSystem.psm1`: Discovers files to process (respects include/exclude).
  - `Analysis/Analysis.psm1`: Invokes PSScriptAnalyzer; security scan; metrics; aggregates `PSQAResult`.
  - `Analyzers/PSQAASTAnalyzer.psm1`: Deep AST analysis rules (unbound vars, shadowing, etc.).
  - `Fixing/Fixing.psm1`: Applies rule-specific fixes for `PSQAResult` issues.
  - `Fixers/PSQAAutoFixer.psm1`: Standalone auto-fix engine with unified diffs + formatter.
  - `Reporting/Reporting.psm1`: Console/JSON/HTML reports.
  - `Loggers/PSQALogger.psm1`: Structured JSONL logging with redaction & rotation.
- `tools/`
  - `Invoke-PSQAEngine.ps1`: Orchestrates analyze/fix/report; imports modules.
  - `Apply-AutoFix.ps1`: Idempotent, standalone, safe auto-fix (format/aliases/whitespace/security).
  - `Restore-Backup.ps1`: Safe rollback from `.psqa-backup`.
  - `Import-Modules.ps1`: Helper script to import all modules.
  - `alias-map.json`: Alias→cmdlet map (used by tooling).
- `tests/`
  - `PSQAASTAnalyzer.Tests.ps1`, `PSQALogger.Tests.ps1`, `PSQAAutoFixer.Tests.ps1`.
  - `test_script.ps1`: A simple PowerShell script with known issues, used for testing the linter.
- `Makefile`: Automation entrypoints (analyze/fix/test/report/etc.).
- `README.md`, `QUICKSTART.md`, `SYSTEM_CAPABILITIES.md`: Orientation docs.

## Data Model (Core)
- `PSQAResult`
  - `FilePath`, `TraceId`, `Timestamp`, `AnalysisResults: PSQAAnalysisResult[]`, `FixResults: PSQAFixResult[]`, `Metrics: hashtable`, `Errors: string[]`.
- `PSQAAnalysisResult`
  - `RuleName`, `Severity`, `Message`, `Line`, `Column`, `Source`.
- `PSQAFixResult`
  - `FixType`, `Description`, `Applied`, `OriginalContent`, `FixedContent`.
- `AutoFixResult` (Fixers)
  - `FilePath`, `FixType`, `Description`, `Applied`, `OriginalContent`, `FixedContent`, `UnifiedDiff`, `Timestamp`, `TraceId`.
- `ASTAnalysisIssue` (AST Analyzer)
  - `RuleName`, `Severity`, `Message`, `Line`, `Column`, `Extent`, `Suggestion`, `Metadata`.

## Module Responsibilities & Public API

1) Configuration (`qa/modules/Configuration/Configuration.psm1`)
- `Initialize-Configuration -ConfigPath <dir>`: Loads `QASettings.psd1`, optional PSSA settings path and security rules. Sets `$global:PSQAConfig`.
- `Get-PSQAConfig`: Returns the global configuration object.

2) File Discovery (`qa/modules/FileSystem/FileSystem.psm1`)
- `Get-PSFile -Path <file|dir>`: Returns `FileInfo[]`; filters by `SupportedExtensions`, honors `ExcludePatterns`.
  - Uses `Get-PSQAConfig` to retrieve configuration.

3) Analysis (`qa/modules/Analysis/Analysis.psm1`)
- `Invoke-FileAnalysis -File <FileInfo> -TraceId <guid>`
  - Invokes PSScriptAnalyzer with settings; runs `Invoke-SecurityAnalysis`; collects metrics via `Get-FileMetric` into `PSQAResult`.
  - Uses `Get-PSQAConfig` to retrieve configuration.
- `Invoke-SecurityAnalysis -File <FileInfo>`
  - Applies regex patterns from `SecurityRules.psd1` to file content; returns `PSQAAnalysisResult[]`.
- `Get-FileMetric -File <FileInfo>`
  - Computes size/lines/comments; attempts AST to count functions/vars.

4) AST Analyzer (`qa/modules/Analyzers/PSQAASTAnalyzer.psm1`)
- `Invoke-PSQAASTAnalysis -FilePath <path> -TraceId <guid>`
  - Rules: unbound vars, shadowing, unsafe pipeline binding, high cognitive complexity, dead code, `Invoke-Expression`, global vars, missing parameter validation, empty catch blocks.

5) Fixing (rules → content) (`qa/modules/Fixing/Fixing.psm1`)
- `Invoke-AutoFix -AnalysisResult <PSQAResult> [-DryRun]`
  - Iterates `AnalysisResult.AnalysisResults`, applies `Set-SingleFix` transforms, writes back with backup.
- `Set-SingleFix -Content <string> -Issue <PSQAAnalysisResult>`
  - Rule-based transforms: trailing whitespace, indentation, alias expansion, `Write-Host`→`Write-Output`, positional params→named, comment-help scaffolding, approved-verbs, OutputType, ShouldProcess scaffolding, unused parameter commenting, singular nouns, brace placement, adding `-ErrorAction Stop` to IO.
  - Returns updated content string.

6) Auto-Fixer (standalone) (`qa/modules/Fixers/PSQAAutoFixer.psm1`)
- `Invoke-PSQAAutoFix -FilePath <path> [-DryRun] [-CreateBackup] [-FixTypes] [-TraceId]`
  - Phases: Formatter, whitespace, alias expansion, security, best-practices. Produces unified diffs via `New-UnifiedDiff`. Writes only when not `-DryRun`.
- `New-UnifiedDiff -Original <string> -Modified <string> -FilePath <path> [-ContextLines]`
- `New-FileBackup -FilePath <path>`: Creates `.psqa-backup/<file>.<timestamp>.bak`.

7) Reporting (`qa/modules/Reporting/Reporting.psm1`)
- `New-QAReport -Results <PSQAResult[]> -OutputFormat <Console|JSON|HTML|All> -StartTime <datetime> -TraceId <string> -EngineVersion <string>`
- `Write-ConsoleReport`, `Write-JsonReport`, `Write-HtmlReport`.
  - JSON/HTML written to `qa-report-<timestamp>.*` in CWD.

8) Logging (`qa/modules/Loggers/PSQALogger.psm1`)
- `Initialize-PSQALogger [-Config <hashtable>] [-NoAnsi]`
- `Write-PSQALog -Level <Trace|Debug|Info|Warn|Error|Fatal> -Message <string> [-TraceId] [-Category] [-Code] [-Hint] [-Action] [-Properties]`
- `Write-PSQAInfo/Warning/Error`
  - Redacts secrets; writes console/file/JSONL with rotation; color output controllable via config.

## Tooling Entry Points

- Engine (`qa/tools/Invoke-PSQAEngine.ps1`)
  - Params: `-Path <file|dir> [-Mode Analyze|Fix|Test|Report|CI|All] [-DryRun] [-ConfigPath ./config] [-OutputFormat Console|JSON|HTML|All]`.
  - Flow: Initialize-Configuration → Get-PSFile → per file: Invoke-FileAnalysis → optional Invoke-AutoFix → accumulate → optional New-QAReport.
  - Test Mode: Invokes Pester on the `tests` directory.
  - Imports: Uses `Import-Modules.ps1`.

- Standalone Auto-Fix (`qa/tools/Apply-AutoFix.ps1`)
  - Params: `-Path <file|dir> [-DryRun] [-NoBackup] [-ShowDiff] [-CleanBackups] [-Encoding <Default|UTF8|UTF8BOM>]`.
  - Phases: Structure injection (CmdletBinding/param), formatter, whitespace, alias-expansion (AST-based), safety fixes (`$null` comparison order, `-ErrorAction Stop`), encoding normalization, atomic write (temp→move), optional diff display.

- Rollback (`qa/tools/Restore-Backup.ps1`)
  - Params: `-Path <dir|file> [-ListOnly] [-BackupTimestamp yyyyMMddHHmmss] [-Latest] [-Force]`.
  - Lists backups; restores selected set; creates “before-restore” safety backups.

- Module Importer (`qa/tools/Import-Modules.ps1`)
    - Imports all modules in the `modules` directory.

## Configuration Surfaces

- PSSA settings: `qa/config/PSScriptAnalyzerSettings.psd1`
  - Strict: indentation, whitespace, braces, approved verbs, alias avoidance, secure practices, help required.
- Engine settings: `qa/config/QASettings.psd1`
  - File processing limits, analysis/security/perf toggles, reporting formats, logging targets, quality gates.
- Security rules: `qa/config/SecurityRules.psd1`
  - Categories: credentials, injection, dangerous commands, error-handling, validation, module security, system modification.

## Execution & Data Flow

1) Discovery: `Get-PSFile` enumerates `.ps1/.psm1/.psd1`, respecting excludes.
2) Per-file Analysis: `Invoke-FileAnalysis` → PSSA → `Invoke-SecurityAnalysis` → `Get-FileMetric` → `PSQAResult`.
3) Auto-Fix (optional): `Invoke-AutoFix` (rule-driven) or `Invoke-PSQAAutoFix` (standalone pass). Always backup unless dry-run.
4) Reporting: `New-QAReport` writes console/JSON/HTML; includes counts and issue lists.
5) Rollback: Restore `.psqa-backup/<file>.<timestamp>.bak` safely.

## Error Handling & Logging
- Default strictness: Set-StrictMode + `$ErrorActionPreference = 'Stop'` across modules (where set).
- Logging via Logger module: JSONL + human-readable; secret redaction; rotation at 50MB.
- Error taxonomy suggested in docs: UserError / TransientError / SystemError (partial implementation; enrich in future).

## Cross-Runtime Compatibility
- Declared support: Windows PowerShell 5.1 and PowerShell 7.x (`#requires -Version 5.1`).
- Uses .NET AST APIs available in both. Avoids OS-specific cmdlets in core logic.

## Tests (Pester v5)
- `PSQALogger.Tests.ps1`: Exports, init, log writing, log dir creation.
- `PSQAASTAnalyzer.Tests.ps1`: Unbound vars; complexity; unsafe patterns; parse-error surfaced.
- `PSQAAutoFixer.Tests.ps1`: Whitespace, alias expansion (including string literal protection), diffs, backups, dry-run, simple security fix.
- `test_script.ps1`: A simple PowerShell script with known issues, used for testing the linter.

Coverage Gaps (observed):
- No tests for `Fixing/Fixing.psm1` pipeline (rule-to-fix mapping correctness).
- No integration tests for `Invoke-PSQAEngine.ps1` end-to-end.
- Logger file/JSONL content validation minimal; redaction patterns not unit-tested.

## Noted Issues & Risks (to triage)

1) **[FIXED]** Configuration scope leakage across modules
- Symptom: `FileSystem` and `Analysis` modules reference `$script:Config`, but `Initialize-Configuration` sets `$script:Config` in its own module scope, not globally.
- Risk: Null references; PSSA settings path and excludes not applied.
- Direction: Introduce a shared accessor (`Get-PSQAConfig`), or promote to `$global:PSQAConfig` in Configuration module; ref modules to consume via imported function or `$script:PSQAConfig` set at import time.

2) **[FIXED]** Reporting depends on undeclared module variables
- `qa/modules/Reporting/Reporting.psm1:42` uses `$script:StartTime`; not initialized in module; may be `$null`.
- JSON metadata references `$TraceId` and `$script:EngineVersion` that are not set in this module.
- Direction: Pass `-StartTime`, `-TraceId`, `-EngineVersion` as parameters to `New-QAReport` or set once via an Initialize function.

3) **[FIXED]** Engine `-Mode Test` not implemented
- `qa/tools/Invoke-PSQAEngine.ps1` accepts `Test` but does not run Pester or any test harness.
- Direction: Either implement a Test mode (Invoke-Pester with config) or remove option.

4) **[FIXED]** `Analysis.psm1` references `$script:Results` (errors bucket)
- `qa/modules/Analysis/Analysis.psm1:69` pushes to `$script:Results.Errors` which is never declared in that module.
- Direction: Return errors as part of `PSQAResult` or log via Logger; remove cross-module script vars.

5) **[FIXED]** `PSQALogger` color/console usage
- Uses `Write-Host` for console; no `--no-ansi` fallback toggle exposed via public API beyond `ColorOutput`.
- Direction: Respect a `NoAnsi` flag and avoid color sequences entirely when set; add tests.

6) **[FIXED]** Standalone `Apply-AutoFix.ps1` alias expansion pattern
- Regex quoting is brittle; risk of false positives/negatives.
- Direction: Prefer AST-based alias detection or token scanning to ensure literals/keys/strings are not altered; add comprehensive tests.

7) **[FIXED]** Make BOM policy configurable and default to UTF-8 (no BOM) unless required.

8) **[FIXED]** Expand security fixes for trivial unsafe patterns (param validation scaffolding; `-ErrorAction Stop` additions) guarded by config.

) **[FIXED]** Tests minor defect
- `qa/tests/PSQAAutoFixer.Tests.ps1:~70` uses `$alias_results` (underscore) vs `$aliasResults` causing a potential test failure.

## Quality & Safety Characteristics
- Idempotence: Fixers avoid repeated changes; backups use timestamped copies; atomic writes via temp→move in `Apply-AutoFix.ps1`.
- Rollback: `Restore-Backup.ps1` supports listing, selective restore, and before-restore safety backups.
- Logging: Human vs structured logs; secret redaction via patterns; rotation at 50MB.
- Diffs: Unified diffs in auto-fixer modules; readable hunks with headers and context.

## Operational Recipes

- Quick analyze:
  - `pwsh qa/tools/Invoke-PSQAEngine.ps1 -Path .. -Mode Analyze -OutputFormat Console`
- Auto-fix preview:
  - `pwsh qa/tools/Apply-AutoFix.ps1 -Path .. -DryRun -ShowDiff`
- Apply fixes safely:
  - `pwsh qa/tools/Apply-AutoFix.ps1 -Path ..`
- Generate reports:
  - `pwsh qa/tools/Invoke-PSQAEngine.ps1 -Path .. -Mode Report -OutputFormat All`
- Run tests:
  - `pwsh -NoProfile -Command "Invoke-Pester -Path qa/tests -CI -Output Detailed"`

## Design Principles Recap
- Advanced functions everywhere; prefer `SupportsShouldProcess` for state changes.
- Strict parameter validation (`ValidateNotNullOrEmpty`, `ValidateSet`, etc.).
- Avoid `Invoke-Expression`; avoid globals; propagate `TraceId` where relevant.
- Crash-safe writes; backups and rollbacks by default; dry-run available.
- Keep rules safe-by-default; promote manual review for risky transforms.

## Backlog (Prioritized)
1) Add module-level integration tests for `Invoke-PSQAEngine.ps1` (dry-run) against `qa/temp_script.ps1`.


## File Pointers (for quick nav)
- Core types: qa/modules/Core/Core.psm1:1
- Config init: qa/modules/Configuration/Configuration.psm1:1
- File discovery: qa/modules/FileSystem/FileSystem.psm1:1
- PSSA/security/metrics: qa/modules/Analysis/Analysis.psm1:1
- AST rules: qa/modules/Analyzers/PSQAASTAnalyzer.psm1:1
- Rule-driven fixer: qa/modules/Fixing/Fixing.psm1:1
- Standalone auto-fixer: qa/modules/Fixers/PSQAAutoFixer.psm1:1
- Reports: qa/modules/Reporting/Reporting.psm1:1
- Logger: qa/modules/Loggers/PSQALogger.psm1:1
- Engine entry: qa/tools/Invoke-PSQAEngine.ps1:1
- Auto-fix tool: qa/tools/Apply-AutoFix.ps1:1
- Rollback tool: qa/tools/Restore-Backup.ps1:1
- PSSA settings: qa/config/PSScriptAnalyzerSettings.psd1:1
- Engine settings: qa/config/QASettings.psd1:1
- Security rules: qa/config/SecurityRules.psd1:1

---

This document is the authoritative map of the QA system’s current state. Update it when you move interfaces, add modules, change flows, or close items in the backlog.