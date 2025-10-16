# Engineering Standards & Performance Budgets

**Date**: 2025-10-12  
**Framework**: SWEBOK v4.0 + Industry Best Practices  
**Repository**: cboyd0319/PoshGuard  
**Enforcement**: Automated + Code Review

## Executive Summary

This document defines engineering standards for PoshGuard development, aligned with **Software Engineering Body of Knowledge (SWEBOK) v4.0** principles. All contributions must meet these standards for quality, security, performance, and maintainability.

**Source**: SWEBOK v4.0 | <https://www.computer.org/education/bodies-of-knowledge/software-engineering> | High | Canonical software engineering knowledge areas and lifecycle guidance.

## Code Quality Standards

### 1. Types & Contracts

**Requirement**: Strong typing at module boundaries  
**SWEBOK Reference**: Software Design (KA 2.1 - Interface Design)

**PowerShell Implementation**:

```powershell
# ✅ GOOD: Strongly typed parameters with validation
function Invoke-SecurityFix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Content,
        
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$MaxIterations = 5
    )
    
    # Implementation
}

# ❌ BAD: No types, no validation
function Invoke-SecurityFix {
    param($Content, $MaxIterations)
}
```

**Validation Rules**:

- All parameters must have type constraints
- Use `[ValidateNotNullOrEmpty()]`, `[ValidateRange()]`, `[ValidateSet()]`
- Output types declared with `[OutputType()]`
- Null checks at function entry points

### 2. Error Handling

**Requirement**: Typed errors with actionable messages  
**SWEBOK Reference**: Software Testing (KA 4.2 - Exception Handling)

**PowerShell Implementation**:

```powershell
# ✅ GOOD: Structured error handling with context
try {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $FilePath, [ref]$null, [ref]$errors
    )
    
    if ($errors.Count -gt 0) {
        throw [System.InvalidOperationException]::new(
            "Failed to parse '$FilePath': $($errors[0].Message)"
        )
    }
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $FilePath" -Category ObjectNotFound
    return $null
}
catch {
    Write-Error "Unexpected error processing $FilePath`: $_" -Category NotSpecified
    return $null
}

# ❌ BAD: Silent failure, no context
try {
    # operation
}
catch {
    # ignore
}
```

**Error Standards**:

- Use specific exception types
- Include file path/context in error messages
- Never leak credentials or secrets in errors
- Log errors with trace IDs for debugging
- Use `-ErrorAction Stop` for critical operations

### 3. Security by Design

**Requirement**: OWASP ASVS Level 1 compliance  
**SWEBOK Reference**: Software Security (KA 10)

**Security Checklist** (mandatory for all PRs):

- [ ] No credentials in code, logs, or error messages
- [ ] Input validation at all trust boundaries
- [ ] No `Invoke-Expression` or dynamic code execution
- [ ] Path traversal prevention (`Test-Path`, full paths)
- [ ] File operations use atomic writes (.tmp → move)
- [ ] Secrets use `[SecureString]` or `Get-Secret`
- [ ] Error messages don't leak sensitive data

**Security Controls Mapping**: See [SECURITY-FRAMEWORK.md](SECURITY-FRAMEWORK.md)

### 4. Performance Budgets

**Requirement**: Operations within defined latency targets  
**SWEBOK Reference**: Software Quality (KA 10.2 - Performance Efficiency)

**Performance Targets**:

| File Size | Target (p95) | Max (p99) | Budget Exceeded Action |
|-----------|--------------|-----------|------------------------|
| < 1KB     | 500ms        | 1s        | Profile + optimize     |
| 1-10KB    | 2s           | 5s        | Investigate bottleneck |
| 10-100KB  | 5s           | 15s       | Algorithm review       |
| 100KB-10MB| 30s          | 60s       | Warn user, consider split |
| > 10MB    | Reject       | N/A       | Return error           |

**Measurement**:

```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Operation

$stopwatch.Stop()
Write-Metric -Name "operation.duration" -Value $stopwatch.ElapsedMilliseconds

if ($stopwatch.ElapsedMilliseconds > $budget) {
    Write-Warning "Performance budget exceeded: $($stopwatch.ElapsedMilliseconds)ms > $budget ms"
}
```

**Optimization Techniques**:

- Use AST `FindAll()` with specific predicates (not entire tree walk)
- Cache cmdlet lists (don't re-query on every call)
- Avoid regex on multi-line content (use AST where possible)
- Dispose large objects: `$ast = $null; [GC]::Collect()`
- Stream large files instead of loading entirely

### 5. Observability

**Requirement**: Emit metrics, logs, traces with correlation  
**SWEBOK Reference**: Software Maintenance (KA 5.1 - Maintenance Logs)

**Structured Logging**:

```powershell
function Write-StructuredLog {
    param(
        [string]$Level,
        [string]$Message,
        [hashtable]$Properties = @{}
    )
    
    $logEntry = @{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        level = $Level
        message = $Message
        trace_id = $script:TraceId
    } + $Properties
    
    $logEntry | ConvertTo-Json -Compress | Add-Content -Path $LogFile
}

# Usage
Write-StructuredLog -Level INFO -Message "Processing file" -Properties @{
    file = "script.ps1"
    size_bytes = 1024
}
```

**Trace Correlation**:

- Generate trace ID at operation start: `$script:TraceId = (New-Guid).ToString()`
- Propagate trace ID through all function calls
- Include trace ID in all log entries and errors
- Use for end-to-end debugging

**Metrics to Emit**:

- Operation success/failure counts
- Duration (latency) for each operation
- Violations detected/fixed counts
- File sizes processed
- Memory usage (via `[GC]::GetTotalMemory()`)

### 6. Testing Standards

**Requirement**: >85% code coverage with unit + integration tests  
**SWEBOK Reference**: Software Testing (KA 4)

**Test Pyramid**:

```
        E2E Tests (10%)
       ↗ Benchmark runs
       ↗ Full pipeline tests
    
    Integration Tests (30%)
   ↗ Multi-module interactions
   ↗ File I/O operations
   ↗ Real PSScriptAnalyzer integration

  Unit Tests (60%)
 ↗ Individual functions
 ↗ AST transformations
 ↗ Edge cases & error paths
```

**Test Requirements**:

```powershell
Describe "Invoke-EmptyCatchBlockFix" {
    Context "When catch block is empty" {
        It "Should add error logging" {
            # Arrange
            $input = @'
try { Get-Item "test" }
catch { }
'@
            $expected = "Write-Verbose"
            
            # Act
            $result = Invoke-EmptyCatchBlockFix -Content $input
            
            # Assert
            $result | Should -Match $expected
        }
    }
    
    Context "When catch block has statements" {
        It "Should not modify existing handlers" {
            # Arrange
            $input = @'
try { Get-Item "test" }
catch { Write-Error "Failed" }
'@
            
            # Act
            $result = Invoke-EmptyCatchBlockFix -Content $input
            
            # Assert
            $result | Should -BeExactly $input
        }
    }
}
```

**Test Categories**:

- **Valid Input**: Typical use cases, expected transformations
- **Edge Cases**: Empty files, massive files, nested structures
- **Idempotency**: Running fix twice produces same result
- **Error Handling**: Invalid syntax, missing files, permission errors
- **Performance**: Benchmark tests against performance budgets

**Coverage Requirements**:

- Functions: >85% line coverage
- Branches: >75% coverage
- Security modules: 95% coverage (critical paths)

### 7. API Design (Module Interfaces)

**Requirement**: Consistent, discoverable module exports  
**SWEBOK Reference**: Software Design (KA 2.3 - Module Design)

**Module Structure**:

```powershell
<#
.SYNOPSIS
    Brief description (one sentence)

.DESCRIPTION
    Detailed explanation of module purpose, scope, and constraints.
    List all exported functions and their use cases.

.NOTES
    Version: x.y.z
    Author: PoshGuard Contributors
    Requires: PowerShell 5.1 or higher
#>

Set-StrictMode -Version Latest

# Internal helper (not exported)
function Get-InternalHelper {
    [CmdletBinding()]
    param()
    # Implementation
}

# Public API (exported)
function Invoke-PublicFix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )
    # Implementation
}

Export-ModuleMember -Function @(
    'Invoke-PublicFix'
)
```

**Function Naming Conventions**:

- Use approved verbs: `Get-`, `Set-`, `Invoke-`, `New-`, `Remove-`
- Pattern: `Invoke-{RuleName}Fix` for fix functions
- Pattern: `Get-{Resource}` for queries
- Pattern: `Test-{Condition}` for validations
- No aliases in module exports (internal use only)

**Parameter Design**:

- Consistent parameter names across modules (`-Content`, `-FilePath`)
- Position 0 for most common parameter
- Use `[Parameter(Mandatory)]` explicitly
- Provide `[ValidateScript()]` for complex validation
- Document parameters with `.PARAMETER` in comment-based help

## Architecture Standards

### 8. Module Organization

**Requirement**: Cohesive, loosely coupled modules  
**SWEBOK Reference**: Software Construction (KA 3.3 - Modularity)

**Current Architecture** (modular, extensible):

```
PoshGuard/
├── Core.psm1              # Foundation (logging, backups, file ops)
├── Security.psm1          # Security fixes (8 rules, OWASP ASVS aligned)
├── BestPractices.psm1     # Coding standards (28 rules)
│   ├── Syntax.psm1
│   ├── Naming.psm1
│   ├── Scoping.psm1
│   ├── StringHandling.psm1
│   ├── TypeSafety.psm1
│   └── UsagePatterns.psm1
├── Formatting.psm1        # Code formatting (11 rules)
│   ├── Whitespace.psm1
│   ├── Aliases.psm1
│   ├── Casing.psm1
│   ├── Output.psm1
│   ├── Alignment.psm1
│   └── Runspaces.psm1
└── Advanced.psm1          # Complex transformations (24 rules)
    ├── ASTTransformations.psm1
    ├── ParameterManagement.psm1
    ├── Documentation.psm1
    └── ...
```

**Module Cohesion Rules**:

- Each module focuses on single responsibility (Security, Formatting, etc.)
- Submodules group related rules (Syntax, Naming, Scoping)
- No circular dependencies between modules
- Core.psm1 is foundation; never depends on other modules
- Fix modules only depend on Core.psm1

**Coupling Constraints**:

- Modules communicate via explicit function calls (no global state)
- Shared configuration via `$script:Config` in Apply-AutoFix.ps1
- No direct file I/O in fix functions (handled by Core.psm1)
- Testable in isolation without loading entire module tree

### 9. Change Management

**Requirement**: Semantic versioning with backward compatibility  
**SWEBOK Reference**: Software Configuration Management (KA 6)

**Version Format**: MAJOR.MINOR.PATCH (e.g., 3.1.2)

**Versioning Rules**:

- **MAJOR**: Breaking changes (API changes, removed functions)
- **MINOR**: New features, new rules (backward compatible)
- **PATCH**: Bug fixes, performance improvements (no new features)

**Breaking Change Policy**:

- Announce in release notes 2 versions in advance
- Provide migration guide with code examples
- Deprecation warnings in logs for 1 version
- Mark deprecated functions with `[Obsolete()]` attribute

**Backward Compatibility Requirements**:

- All exported functions maintain signature for MINOR releases
- Configuration file format versioned (`Version = "3.0"`)
- Auto-migration for config files when possible
- Documented migration steps in CHANGELOG.md

**Deprecation Process**:

1. **Announce** (v3.0): Function marked deprecated, warning in logs
2. **Maintain** (v3.1-v3.x): Function still works, migration guide available
3. **Remove** (v4.0): Function removed, major version bump

## Development Workflow

### 10. Code Review Requirements

**Requirement**: Peer review for all changes  
**SWEBOK Reference**: Software Quality (KA 10.5 - Reviews)

**PR Checklist** (mandatory):

- [ ] Unit tests added/updated (>85% coverage)
- [ ] Integration tests pass locally
- [ ] PSScriptAnalyzer reports zero violations
- [ ] Performance benchmarks run (no regression)
- [ ] Security checklist completed
- [ ] Documentation updated (README, module help)
- [ ] CHANGELOG.md entry added
- [ ] Breaking changes documented (if any)

**Review Criteria**:

- **Correctness**: Logic is sound, edge cases handled
- **Security**: No vulnerabilities introduced (OWASP ASVS checks)
- **Performance**: Meets performance budgets
- **Maintainability**: Code is readable, well-documented
- **Testing**: Adequate test coverage, tests are meaningful

**Review Timeline**:

- Initial review within 48 hours (business days)
- Address feedback within 5 business days
- Re-review within 24 hours
- Squash-merge after approval

### 11. CI/CD Pipeline

**Requirement**: Automated quality gates  
**SWEBOK Reference**: Software Engineering Process (KA 8)

**Pipeline Stages**:

```yaml
1. Lint (PSScriptAnalyzer)
   ↓ Pass required
   
2. Unit Tests (Pester)
   ↓ >85% coverage required
   
3. Integration Tests (Benchmark)
   ↓ >70% fix rate required
   
4. Security Scan (SARIF upload)
   ↓ Zero critical issues
   
5. Package (Artifact creation)
   ↓ Versioned zip
   
6. Release (PowerShell Gallery)
   ↓ Manual approval
```

**Quality Gates**:

- **Lint**: Zero PSScriptAnalyzer errors (warnings allowed with justification)
- **Test**: All tests pass, no skipped tests without reason
- **Coverage**: >85% line coverage on new code
- **Security**: Zero critical or high vulnerabilities
- **Performance**: Benchmark success rate ≥70%

**Gate Overrides**:

- Security fixes: Can bypass feature freeze
- Hotfixes: Expedited review + approval
- Documentation: No tests required

### 12. Documentation Standards

**Requirement**: Self-documenting code + comprehensive guides  
**SWEBOK Reference**: Software Maintenance (KA 5.4 - Documentation)

**Comment-Based Help** (all functions):

```powershell
<#
.SYNOPSIS
    Fixes empty catch blocks by adding minimal error logging

.DESCRIPTION
    Detects catch blocks with no statements and adds Write-Verbose
    logging to ensure errors are not silently suppressed.
    
    Aligns with PSAvoidUsingEmptyCatchBlock rule from PSScriptAnalyzer.

.PARAMETER Content
    The PowerShell script content to analyze and fix

.EXAMPLE
    Invoke-EmptyCatchBlockFix -Content $scriptText
    
    Adds error logging to empty catch blocks

.OUTPUTS
    System.String
    Returns the fixed script content

.NOTES
    Version: 3.0.0
    Part of PoshGuard Security Module
#>
```

**Documentation Types**:

- **README.md**: Quick start, installation, examples
- **ARCHITECTURE.md**: System design, module structure
- **CONTRIBUTING.md**: Dev setup, PR guidelines
- **SECURITY.md**: Vulnerability disclosure, security policies
- **CHANGELOG.md**: Version history, breaking changes
- **API Docs**: Auto-generated from comment-based help

**Documentation Review**:

- Accuracy: Examples work as written
- Completeness: All parameters documented
- Clarity: Non-expert can understand
- Maintenance: Update with code changes

## Performance Engineering

### 13. Profiling & Optimization

**Requirement**: Data-driven performance improvements  
**SWEBOK Reference**: Software Quality (KA 10.2.3 - Performance Analysis)

**Profiling Tools**:

```powershell
# Method 1: Measure-Command (simple)
Measure-Command { Invoke-MyFix -Content $large }

# Method 2: Stopwatch (detailed)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
Invoke-MyFix -Content $large
$sw.Stop()
Write-Host "Elapsed: $($sw.ElapsedMilliseconds)ms"

# Method 3: Trace-Command (advanced)
Trace-Command -Name TypeConversion,ETS -Expression {
    Invoke-MyFix -Content $large
} -PSHost
```

**Optimization Priority**:

1. **Correctness** > Performance (never sacrifice correctness)
2. **Algorithm** > Micro-optimizations (O(n²) → O(n log n))
3. **Memory** > CPU (avoid large object allocations)
4. **Readability** > Clever tricks (maintainability matters)

**Common Bottlenecks**:

- AST full tree walks (use predicates to filter early)
- String concatenation in loops (use `StringBuilder` or `-join`)
- Repeated file I/O (cache content in memory)
- Regex on multi-line strings (AST parsing is faster)

### 14. Memory Management

**Requirement**: Bounded memory usage  
**SWEBOK Reference**: Software Construction (KA 3.7 - Resource Management)

**Memory Budgets**:

- Max file size: 10MB (reject larger files)
- Max concurrent files: 1 (process sequentially)
- Peak memory: <500MB for typical workload (100 files)

**Memory Discipline**:

```powershell
# ✅ GOOD: Dispose large objects
$ast = [Parser]::ParseFile($path)
# ... use AST
$ast = $null
[GC]::Collect()

# ❌ BAD: Hold references unnecessarily
$global:AllAsts += $ast  # Memory leak!
```

**Garbage Collection**:

- Let GC run automatically (don't force unless necessary)
- Nullify large objects after use
- Avoid holding file content in memory longer than needed

## References

1. **SWEBOK v4.0** | <https://www.computer.org/education/bodies-of-knowledge/software-engineering> | High | Software engineering best practices
2. **PowerShell Best Practices** | <https://poshcode.gitbooks.io/powershell-practice-and-style/> | High | Community style guide
3. **Clean Code (Martin)** | <https://www.oreilly.com/library/view/clean-code/9780136083238/> | Medium | Code quality principles
4. **Refactoring (Fowler)** | <https://refactoring.com/> | Medium | Code improvement techniques
5. **Design Patterns (GoF)** | <https://en.wikipedia.org/wiki/Design_Patterns> | Medium | Reusable design solutions

---

**Document Owner**: Engineering Team  
**Last Updated**: 2025-10-12  
**Next Review**: 2025-11-12  
**Version**: 1.0.0
