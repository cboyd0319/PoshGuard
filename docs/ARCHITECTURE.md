# Architecture

PoshGuard uses modular AST-based transformations to fix PowerShell code issues.

## Prerequisites

| Item | Version | Why | Optional |
|------|---------|-----|----------|
| PowerShell | 7+ | runtime | No |
| PSScriptAnalyzer | 1.24.0+ | code analysis | No |
| RipGrep | 14+ | fast pre-filtering | Yes (degrades to slower scan) |

**RipGrep Installation:**
- Windows: `choco install ripgrep` or `winget install BurntSushi.ripgrep.MSVC`
- macOS: `brew install ripgrep`
- Linux: `apt install ripgrep` or download from [GitHub releases](https://github.com/BurntSushi/ripgrep/releases)

RipGrep enables 10-100x faster file filtering and secret scanning. Without it, PoshGuard automatically falls back to slower PowerShell-native file scanning.

## System Flow

```
Input Script → PSScriptAnalyzer Detection → AST Parsing → Rule Matching → Transformation → Validation → Output
```

## Components

### Apply-AutoFix.ps1

Main entry point. Orchestrates analysis, fix selection, and application.

### Core.psm1

Foundation utilities: backup, logging, file operations, diff generation.

### Security.psm1

8 security fixes: password handling, credential management, injection prevention.

### BestPractices.psm1

28 best practice fixes organized in 6 submodules:

- Syntax: positional params, verbs, reserved chars
- Naming: singular nouns, approved verbs
- Scoping: global vars, declared vars
- StringHandling: quotes, backticks, semicolons
- TypeSafety: type attributes, null checks
- UsagePatterns: empty catches, help messages

### Formatting.psm1

11 formatting fixes organized in 6 submodules:

- Whitespace: indentation, consistency, trailing spaces
- Aliases: cmdlet aliases, global aliases
- Casing: cmdlet/parameter casing
- Output: Write-Host to Write-Information
- Alignment: assignment statements
- Runspaces: runspace pool management

### Advanced.psm1

24 advanced fixes organized in 9 submodules:

- ASTTransformations: pipeline processing, ShouldProcess
- ParameterManagement: mandatory params, switch defaults
- CodeAnalysis: empty members, built-in cmdlets
- Documentation: comment help, BOM encoding
- AttributeManagement: output types, DSC functions
- ManifestManagement: exports, missing fields, deprecated fields
- CompatibleCmdletsWarning: platform compatibility
- DefaultValueForMandatoryParameter: param validation
- UTF8EncodingForHelpFile: help file encoding

## Data Flow

1. **Detection**: PSScriptAnalyzer scans script
2. **Parsing**: AST extracted via `[System.Management.Automation.Language.Parser]::ParseFile()`
3. **Transformation**: Rule-specific fix functions modify AST
4. **Validation**: Ensure no syntax errors introduced
5. **Output**: Write modified script or show diff

## Trust Boundaries

- Read-only mode: `-DryRun` flag (no file writes)
- Write mode: Creates `.backup/` with timestamped copies
- No external API calls or network access
- No credential storage or logging of sensitive data

## Extension Points

Add new fix by:

1. Create submodule in appropriate category (`./tools/lib/{Category}/{RuleName}.psm1`)
2. Implement `Invoke-{RuleName}Fix` function with AST parsing
3. Import in category facade module
4. Add fix call in `Apply-AutoFix.ps1`

## Performance Considerations

- AST parsing: O(n) where n = file size
- Transformation: O(m) where m = matches found
- Typical file (500 lines): 1-3 seconds
- Large file (5K+ lines): May see slower parsing
- Memory: <100 MB for typical projects
