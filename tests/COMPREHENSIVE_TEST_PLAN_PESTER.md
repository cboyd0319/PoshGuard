# PoshGuard Comprehensive Test Plan - Pester v5+

## Executive Summary

This test plan covers comprehensive unit testing for **9 untested PowerShell modules** in the PoshGuard repository, following Pester v5+ best practices, deterministic execution patterns, and the principles outlined in the Pester Architect Agent persona.

**Testing Philosophy**: High-signal tests that exploit Pester's strengths (Gherkin-ish readability, strict mocks, isolated temp drives) with focus on meaningful coverage (logic + error paths) rather than cargo-cult tests.

---

## Modules Requiring Tests

### 1. AdvancedCodeAnalysis.psm1
**Purpose**: Advanced static analysis beyond PSScriptAnalyzer (dead code, code smells, cognitive complexity)

**Exported Functions**:
- `Find-CodeSmells`
- `Find-DeadCode`
- `Get-CognitiveComplexity`

**Test Coverage Strategy**:
- **Happy Paths**: Valid code analysis with expected results
- **Edge Cases**: Empty content, malformed code, extremely complex functions
- **Error Handling**: Invalid AST parsing, null parameters
- **Branching**: Different code smell types, various dead code patterns
- **Mocking**: AST parser calls, file system access

**Test Cases**:
```
Find-CodeSmells
  ├─ Detects long functions (>50 lines)
  ├─ Detects excessive parameters (>5)
  ├─ Detects deeply nested code (>4 levels)
  ├─ Handles valid code with no smells
  ├─ Handles empty/null content
  └─ Throws on invalid syntax

Find-DeadCode
  ├─ Detects unreachable code after return
  ├─ Detects unused functions
  ├─ Detects unused variables
  ├─ Detects commented-out code
  ├─ Handles code with no dead sections
  └─ Validates parameter constraints

Get-CognitiveComplexity
  ├─ Calculates complexity for simple functions
  ├─ Calculates complexity for nested control flow
  ├─ Returns appropriate thresholds
  ├─ Handles edge cases (empty functions)
  └─ Error handling for invalid input
```

---

### 2. AdvancedDetection.psm1
**Purpose**: Code quality detection (complexity, performance, security, maintainability)

**Exported Functions**:
- `Invoke-AdvancedDetection`
- `Test-CodeComplexity`
- `Test-MaintainabilityIssues`
- `Test-PerformanceAntiPatterns`
- `Test-SecurityVulnerabilities`

**Test Coverage Strategy**:
- **Complexity Metrics**: Cyclomatic complexity, nesting depth, line count
- **Performance Patterns**: Inefficient loops, pipeline misuse, unnecessary iterations
- **Security Issues**: OWASP alignment, injection risks, hardcoded credentials
- **Maintainability**: Long functions, unclear naming, missing documentation

**Test Cases**:
```
Test-CodeComplexity
  ├─ Detects high cyclomatic complexity (>10)
  ├─ Detects excessive nesting (>4 levels)
  ├─ Flags long functions (>50 lines)
  ├─ Returns empty for simple functions
  └─ Parameter validation

Test-MaintainabilityIssues
  ├─ Detects unclear variable names
  ├─ Detects missing function documentation
  ├─ Detects magic numbers
  └─ Edge cases (empty content)

Test-PerformanceAntiPatterns
  ├─ Detects += operator in loops
  ├─ Detects inefficient pipeline usage
  ├─ Detects unnecessary nested loops
  └─ Returns clean for optimized code

Test-SecurityVulnerabilities
  ├─ Detects Invoke-Expression usage
  ├─ Detects hardcoded credentials
  ├─ Detects insecure cryptography
  └─ Validates against OWASP patterns
```

---

### 3. EnhancedMetrics.psm1
**Purpose**: Metrics tracking, confidence scoring, detailed diagnostics

**Exported Functions**:
- `Initialize-MetricsTracking`
- `Add-RuleMetric`
- `Add-FileMetric`
- `Get-MetricsSummary`
- `Show-MetricsSummary`
- `Export-MetricsReport`
- `Get-FixConfidenceScore`

**Test Coverage Strategy**:
- **State Management**: Initialize, accumulate, reset
- **Data Integrity**: Metric calculations, aggregations
- **Output Formats**: JSON, console display
- **Confidence Scoring**: Algorithm validation

**Test Cases**:
```
Initialize-MetricsTracking
  ├─ Resets metrics store
  ├─ Sets session start time
  └─ Initializes empty collections

Add-RuleMetric
  ├─ Records successful fix
  ├─ Records failed fix with error
  ├─ Tracks duration and confidence
  ├─ Validates confidence range (0.0-1.0)
  └─ Parameter validation

Get-MetricsSummary
  ├─ Aggregates multiple metrics
  ├─ Calculates success rates
  ├─ Computes average confidence
  └─ Handles empty metrics

Export-MetricsReport
  ├─ Exports valid JSON format
  ├─ Includes all required fields
  ├─ Uses TestDrive for file output
  └─ Error handling for invalid paths
```

---

### 4. EnhancedSecurityDetection.psm1
**Purpose**: Security vulnerability detection (OWASP, MITRE ATT&CK, secrets)

**Exported Functions**:
- `Test-EnhancedSecurityIssues`
- `Find-SecretsInCode`
- `Find-CodeInjectionVulnerabilities`
- `Find-PathTraversalVulnerabilities`
- `Find-CryptographicWeaknesses`
- `Find-MITREATTCKPatterns`
- `Get-SecurityReport`

**Test Coverage Strategy**:
- **Secret Detection**: API keys, passwords, tokens, certificates
- **Injection Patterns**: Command injection, code injection
- **Crypto Issues**: Weak algorithms, hardcoded keys
- **MITRE Mapping**: ATT&CK technique identification

**Test Cases**:
```
Find-SecretsInCode
  ├─ Detects AWS access keys
  ├─ Detects Azure connection strings
  ├─ Detects private keys
  ├─ Detects passwords in variables
  ├─ Handles code with no secrets
  └─ High-entropy string detection

Find-CodeInjectionVulnerabilities
  ├─ Detects Invoke-Expression
  ├─ Detects dangerous Start-Process
  ├─ Detects unsafe eval patterns
  └─ Returns clean for safe code

Find-PathTraversalVulnerabilities
  ├─ Detects ../ patterns
  ├─ Detects unsafe path joins
  └─ Edge cases

Find-CryptographicWeaknesses
  ├─ Detects MD5/SHA1 usage
  ├─ Detects DES encryption
  ├─ Detects weak key sizes
  └─ Validates modern algorithms
```

---

### 5. MCPIntegration.psm1
**Purpose**: Model Context Protocol integration for AI-assisted analysis

**Exported Functions**:
- `Initialize-MCPConfiguration`
- `Enable-MCPIntegration`
- `Disable-MCPIntegration`
- `Get-MCPStatus`
- `Add-MCPServer`
- `Invoke-MCPQuery`
- `Clear-MCPCache`

**Test Coverage Strategy**:
- **Configuration Management**: Init, enable/disable state
- **Server Registration**: Add, validate, remove
- **Query Execution**: Mock external calls
- **Cache Management**: Store, retrieve, clear

**Test Cases**:
```
Initialize-MCPConfiguration
  ├─ Creates config file in TestDrive
  ├─ Sets default values
  ├─ Validates JSON structure
  └─ Error handling for existing config

Enable-MCPIntegration
  ├─ Updates config state to enabled
  ├─ Validates prerequisites
  └─ Returns confirmation

Get-MCPStatus
  ├─ Returns enabled status
  ├─ Returns server count
  ├─ Returns cache statistics
  └─ Handles no config file

Add-MCPServer
  ├─ Adds server to config
  ├─ Validates URL format
  ├─ Prevents duplicates
  └─ Parameter validation

Invoke-MCPQuery
  ├─ Mocks HTTP call
  ├─ Returns parsed response
  ├─ Handles network errors
  └─ Respects cache settings
```

---

### 6. NISTSP80053Compliance.psm1
**Purpose**: NIST SP 800-53 compliance validation

**Exported Functions**:
- `Test-NIST80053Compliance`

**Test Coverage Strategy**:
- **Control Mapping**: SI-10 (Input Validation), AC-6 (Least Privilege), SC-8 (Transmission Confidentiality)
- **Compliance Reporting**: Detailed findings per control
- **Edge Cases**: Empty code, compliant code

**Test Cases**:
```
Test-NIST80053Compliance
  ├─ Detects input validation violations (SI-10)
  ├─ Detects privilege escalation risks (AC-6)
  ├─ Detects unencrypted transmission (SC-8)
  ├─ Returns compliant for secure code
  ├─ Generates structured report
  └─ Parameter validation
```

---

### 7. OpenTelemetryTracing.psm1
**Purpose**: Distributed tracing and observability

**Exported Functions**:
- `Initialize-TraceContext`
- `Start-Span`
- `Stop-Span`
- `Add-SpanEvent`
- `Export-Spans`
- `Invoke-WithTracing`
- `Get-W3CTraceParent`

**Test Coverage Strategy**:
- **Context Management**: Init, parent/child relationships
- **Span Lifecycle**: Start, stop, duration calculation
- **W3C Format**: TraceParent header generation
- **Export**: Mock file/OTLP export

**Test Cases**:
```
Initialize-TraceContext
  ├─ Generates valid trace ID
  ├─ Initializes empty span stack
  └─ Sets trace flags

Start-Span
  ├─ Creates span with attributes
  ├─ Records start time
  ├─ Assigns span ID
  └─ Validates parent context

Stop-Span
  ├─ Records end time
  ├─ Calculates duration
  ├─ Throws if no active span
  └─ Handles nested spans

Get-W3CTraceParent
  ├─ Generates valid W3C format
  ├─ Includes trace ID, span ID, flags
  └─ Validates format regex

Invoke-WithTracing
  ├─ Wraps scriptblock execution
  ├─ Captures errors in span
  ├─ Ensures span cleanup
  └─ Returns scriptblock result
```

---

### 8. ReinforcementLearning.psm1
**Purpose**: RL-based fix selection and quality improvement

**Exported Functions**:
- `Get-CodeState`
- `Select-FixAction`
- `Get-FixReward`
- `Update-QLearning`
- `Start-ExperienceReplay`
- `Export-RLModel`
- `Import-RLModel`

**Test Coverage Strategy**:
- **State Representation**: Code -> feature vector
- **Action Selection**: Epsilon-greedy, Q-values
- **Reward Calculation**: Success/failure, confidence
- **Model Persistence**: Save/load Q-table

**Test Cases**:
```
Get-CodeState
  ├─ Extracts features from code
  ├─ Returns consistent hash
  ├─ Handles invalid syntax
  └─ Edge cases (empty code)

Select-FixAction
  ├─ Selects best action (exploit)
  ├─ Selects random action (explore)
  ├─ Respects epsilon parameter
  └─ Validates Q-table

Get-FixReward
  ├─ Returns positive for success
  ├─ Returns negative for failure
  ├─ Weights by confidence score
  └─ Validates input ranges

Update-QLearning
  ├─ Updates Q-value correctly
  ├─ Applies learning rate
  ├─ Applies discount factor
  └─ Validates parameters (0-1)

Export-RLModel / Import-RLModel
  ├─ Serializes Q-table to JSON
  ├─ Deserializes from JSON
  ├─ Uses TestDrive
  └─ Error handling
```

---

### 9. SecurityDetectionEnhanced.psm1
**Purpose**: Enhanced security testing (OWASP Top 10, MITRE ATT&CK)

**Exported Functions**:
- `Test-OWASPTop10`
- `Test-MITREAttack`
- `Test-InjectionVulnerabilities`
- `Test-BrokenAccessControl`
- `Test-CryptographicFailures`
- `Test-IntegrityFailures`
- `Test-LoggingFailures`
- `Test-SSRFVulnerabilities`
- `Test-AdvancedSecrets`
- `Test-AuthenticationFailures`

**Test Coverage Strategy**:
- **OWASP Top 10 Coverage**: All categories
- **MITRE ATT&CK**: Common techniques
- **Pattern Matching**: Regex, AST analysis
- **False Positives**: Validate accuracy

**Test Cases**:
```
Test-OWASPTop10
  ├─ Aggregates all OWASP checks
  ├─ Returns structured report
  ├─ Includes severity ratings
  └─ Handles clean code

Test-InjectionVulnerabilities
  ├─ Detects command injection
  ├─ Detects SQL injection
  ├─ Detects LDAP injection
  └─ Returns empty for safe code

Test-BrokenAccessControl
  ├─ Detects missing authorization
  ├─ Detects privilege escalation
  └─ Edge cases

Test-CryptographicFailures
  ├─ Detects weak algorithms
  ├─ Detects insecure storage
  └─ Validates best practices

Test-AdvancedSecrets
  ├─ High-entropy detection
  ├─ Pattern-based detection
  ├─ Base64 encoded secrets
  └─ False positive mitigation
```

---

## Test Infrastructure Requirements

### Test Helpers (tests/Helpers/)
- **MockBuilders.psm1**: Pre-built mocks for common scenarios
- **TestData.psm1**: Sample code snippets with known issues
- **TestHelpers.psm1**: Utilities for file creation, AST generation

### Fixtures
- Sample scripts with security issues
- Sample scripts with complexity issues
- Sample scripts with no issues (negative tests)
- Golden outputs for comparison

### Mocking Strategy
- **File System**: Use `TestDrive:` exclusively
- **Time**: Mock `Get-Date` for determinism
- **Network**: Mock `Invoke-RestMethod`, `Invoke-WebRequest`
- **AST Parsing**: Validate input, don't mock parser
- **Logging**: Capture streams with `-PassThru`

---

## Quality Gates

### Coverage Targets
- **Lines**: ≥ 90% per module
- **Branches**: ≥ 85% for critical paths
- **Functions**: 100% of exported functions

### Performance
- Individual `It` blocks: < 100ms typical, < 500ms max
- Full suite: < 5 minutes on CI

### Determinism
- Zero flakes: No real time, network, or randomness
- Repeatable: Same input → same output every time

---

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: PoshGuard Tests
on: [push, pull_request]
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        pwsh: ["7.4.4"]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup PowerShell
        uses: PowerShell/PowerShell-For-GitHub-Actions@v1
        with:
          version: ${{ matrix.pwsh }}
      - name: Install dependencies
        shell: pwsh
        run: |
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module Pester -Scope CurrentUser -Force -MinimumVersion 5.5.0
          Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
      - name: Run static analysis
        shell: pwsh
        run: |
          Invoke-ScriptAnalyzer -Path ./tools/lib -Settings ./.psscriptanalyzer.psd1 -Recurse -Severity Error,Warning
      - name: Run tests with coverage
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './tests/Unit'
          $config.Run.PassThru = $true
          $config.CodeCoverage.Enabled = $true
          $config.CodeCoverage.Path = './tools/lib/*.psm1'
          $config.CodeCoverage.OutputFormat = 'JaCoCo'
          $config.CodeCoverage.OutputPath = 'coverage.xml'
          $config.Output.Verbosity = 'Detailed'
          Invoke-Pester -Configuration $config
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
```

---

## Test Execution Plan

1. **Phase 1**: Create test files for all 9 modules
2. **Phase 2**: Implement core test cases (happy paths)
3. **Phase 3**: Add edge cases and error handling
4. **Phase 4**: Validate coverage metrics
5. **Phase 5**: Run on CI (Windows, macOS, Linux)
6. **Phase 6**: Refine based on failures/flakes

---

## Rationale & Trade-offs

### What We Test
- Public API contracts (all exported functions)
- Error handling and parameter validation
- Complex logic branches (complexity, security detection)
- Side-effects (file I/O via TestDrive)

### What We Don't Test
- Private helper functions directly (test via public API)
- PSScriptAnalyzer internals (assume it works)
- GUI/user interaction (out of scope)
- Real network calls (mocked)

### Intentional Coverage Gaps
- Some defensive error handling may be hard to trigger artificially
- Rare OS-specific behaviors (document in test comments)
- Performance edge cases (use profiling tools instead)

---

## Success Criteria

✅ All 9 modules have comprehensive unit tests
✅ Test suite passes on Windows, macOS, Linux
✅ Code coverage ≥ 90% lines, ≥ 85% branches
✅ Zero flakes (100 consecutive runs)
✅ Test execution < 5 minutes
✅ PSScriptAnalyzer passes (no warnings)
✅ Clear, maintainable test code following AAA pattern
