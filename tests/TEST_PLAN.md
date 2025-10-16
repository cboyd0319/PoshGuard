# PoshGuard Comprehensive Test Plan

## Overview
This test plan outlines comprehensive unit test coverage for all PowerShell modules in the PoshGuard repository following Pester v5+ best practices and the Pester Architect Agent playbook.

## Test Infrastructure
- **Framework**: Pester 5.7.1
- **Static Analysis**: PSScriptAnalyzer 1.24.0
- **Coverage Target**: ≥90% lines, ≥85% branches (critical paths)
- **Platform**: Cross-platform (Windows, macOS, Linux) PowerShell 7+

## Testing Principles
1. **Hermetic Tests**: Use TestDrive:, mocks, no real filesystem/network/registry
2. **AAA Pattern**: Arrange-Act-Assert structure
3. **Determinism**: Mock Get-Date, Start-Sleep, randomness
4. **Isolation**: InModuleScope, BeforeAll/BeforeEach, no state leakage
5. **Table-Driven**: Use -TestCases for input matrices
6. **Focus**: Public API contracts, error paths, edge cases, branching

## Module Test Coverage Analysis

### ✅ Already Tested (4 modules)
1. **Core.psm1** - 93 tests passing
   - Clean-Backups, Write-Log, Get-PowerShellFiles, New-FileBackup, New-UnifiedDiff
2. **ConfigurationManager.psm1** - Covered
3. **Security.psm1** - Covered
4. **Formatting/Aliases.psm1** - Covered

### 🔴 Needs Testing (16 modules + submodules)

#### High Priority: Core Functionality

**1. BestPractices.psm1** (21 functions across 7 submodules)
- **Submodules to test**:
  - Syntax.psm1: Invoke-SemicolonFix, Invoke-NullComparisonFix, Invoke-ExclaimOperatorFix
  - Naming.psm1: Invoke-SingularNounFix, Invoke-ApprovedVerbFix, Invoke-ReservedCmdletCharFix
  - Scoping.psm1: Invoke-GlobalVarFix, Invoke-GlobalFunctionsFix
  - StringHandling.psm1: Invoke-DoubleQuoteFix, Invoke-LiteralHashtableFix
  - TypeSafety.psm1: Invoke-AutomaticVariableFix, Invoke-MultipleTypeAttributesFix, Invoke-PSCredentialTypeFix
  - UsagePatterns.psm1: Invoke-PositionalParametersFix, Invoke-DeclaredVarsMoreThanAssignmentsFix, Invoke-IncorrectAssignmentOperatorFix
  - CodeQuality.psm1: Invoke-TodoCommentDetectionFix, Invoke-UnusedNamespaceDetectionFix, etc.

**2. Formatting.psm1** (12 functions across 7 submodules)
- **Submodules to test**:
  - Whitespace.psm1: Invoke-WhitespaceFix, Invoke-FormatterFix, Invoke-AlignAssignmentFix
  - Casing.psm1: Invoke-CasingFix
  - Output.psm1: Invoke-WriteHostFix, Invoke-WriteHostEnhancedFix
  - Runspaces.psm1: Invoke-MisleadingBacktickFix, Invoke-RedirectionOperatorFix
  - WriteHostEnhanced.psm1: Advanced Write-Host detection
  - Alignment.psm1: Assignment alignment logic

**3. Advanced.psm1** (27 functions across 9 submodules)
- **Submodules to test**:
  - CmdletBindingFix.psm1: Invoke-CmdletBindingFix, Invoke-CmdletCorrectlyFix
  - ParameterManagement.psm1: Invoke-CmdletParameterFix, Invoke-UnusedParameterFix, etc.
  - ShouldProcessTransformation.psm1: Invoke-PSShouldProcessFix, Invoke-SupportsShouldProcessFix
  - Documentation.psm1: Invoke-CommentHelpFix, Invoke-UTF8EncodingForHelpFileFix
  - ManifestManagement.psm1: Invoke-MissingModuleManifestFieldFix, Invoke-UseToExportFieldsInManifestFix
  - CodeAnalysis.psm1: Invoke-DuplicateLineFix, Invoke-LongLinesFix
  - ASTTransformations.psm1: AST-based transformations
  - AttributeManagement.psm1: Attribute handling
  - Others: Safety, compatibility, deprecation fixes

#### Medium Priority: Enhanced Features

**4. AIIntegration.psm1** (9 functions)
- Add-FixPattern, Get-AIConfiguration, Get-FixConfidenceScore
- Get-MCPContext, Initialize-AIFeatures, Test-AIFeatures
- Test-MCPAvailable, Clear-MCPCache, Invoke-ModelRetraining
- **Test Focus**: Mock ML operations, validate confidence scoring, MCP availability checks

**5. EnhancedMetrics.psm1**
- Code metrics calculation and reporting
- **Test Focus**: Metric accuracy, aggregation logic

**6. AdvancedDetection.psm1**
- Advanced pattern detection logic
- **Test Focus**: Pattern matching, rule evaluation

**7. AdvancedCodeAnalysis.psm1**
- Complex code analysis algorithms
- **Test Focus**: AST parsing, analysis accuracy

#### Medium Priority: Security Features

**8. EnhancedSecurityDetection.psm1**
- Enhanced security pattern detection
- **Test Focus**: Security vulnerability detection accuracy

**9. EntropySecretDetection.psm1**
- Shannon entropy-based secret detection
- **Test Focus**: Entropy calculation, threshold logic, false positive rate

**10. SecurityDetectionEnhanced.psm1**
- Additional security detection rules
- **Test Focus**: Security rule coverage, detection accuracy

**11. SupplyChainSecurity.psm1**
- SBOM generation, supply chain validation
- **Test Focus**: SBOM format compliance, dependency tracking

#### Medium Priority: Observability & Compliance

**12. Observability.psm1**
- Observability infrastructure
- **Test Focus**: Metric collection, logging behavior

**13. OpenTelemetryTracing.psm1**
- OpenTelemetry tracing integration
- **Test Focus**: Trace generation, span management (mocked)

**14. NISTSP80053Compliance.psm1**
- NIST SP 800-53 / FedRAMP compliance checking
- **Test Focus**: Compliance rule validation, report generation

**15. ReinforcementLearning.psm1**
- Q-learning for fix optimization
- **Test Focus**: Model state management, reward calculation (mocked)

#### Lower Priority: Specialized Features

**16. PerformanceOptimization.psm1**
- Performance analysis and optimization
- **Test Focus**: Optimization logic, performance metrics (deterministic)

**17. MCPIntegration.psm1**
- Model Context Protocol integration
- **Test Focus**: MCP communication (mocked), error handling

## Test Structure Per Module

### File Organization
```
tests/
  Unit/
    BestPractices/
      Syntax.Tests.ps1
      Naming.Tests.ps1
      Scoping.Tests.ps1
      StringHandling.Tests.ps1
      TypeSafety.Tests.ps1
      UsagePatterns.Tests.ps1
      CodeQuality.Tests.ps1
    Formatting/
      Whitespace.Tests.ps1
      Casing.Tests.ps1
      Output.Tests.ps1
      Runspaces.Tests.ps1
      Alignment.Tests.ps1
    Advanced/
      CmdletBindingFix.Tests.ps1
      ParameterManagement.Tests.ps1
      ShouldProcessTransformation.Tests.ps1
      Documentation.Tests.ps1
      ManifestManagement.Tests.ps1
      CodeAnalysis.Tests.ps1
      ASTTransformations.Tests.ps1
      [etc...]
    AIIntegration.Tests.ps1
    AdvancedDetection.Tests.ps1
    AdvancedCodeAnalysis.Tests.ps1
    EnhancedMetrics.Tests.ps1
    EnhancedSecurityDetection.Tests.ps1
    EntropySecretDetection.Tests.ps1
    MCPIntegration.Tests.ps1
    NISTSP80053Compliance.Tests.ps1
    Observability.Tests.ps1
    OpenTelemetryTracing.Tests.ps1
    PerformanceOptimization.Tests.ps1
    ReinforcementLearning.Tests.ps1
    SecurityDetectionEnhanced.Tests.ps1
    SupplyChainSecurity.Tests.ps1
  Helpers/
    TestHelpers.psm1 (existing)
    MockBuilders.psm1 (new - AST/diagnostic mocks)
    TestData.psm1 (new - test script samples)
```

### Standard Test Template
```powershell
BeforeAll {
  # Import helpers
  $helpersPath = Join-Path $PSScriptRoot '../Helpers/TestHelpers.psm1'
  Import-Module $helpersPath -Force
  
  # Import module under test
  $modulePath = Join-Path $PSScriptRoot '../../tools/lib/ModuleName.psm1'
  Import-Module $modulePath -Force
}

Describe 'Function-Name' -Tag 'Unit', 'ModuleName' {
  Context 'Happy path scenarios' {
    It 'Should <behavior> when <condition>' -TestCases @(...) {
      # Arrange
      # Act
      # Assert
    }
  }
  
  Context 'Error handling' {
    It 'Should throw when <invalid_condition>' {
      { Function-Name ... } | Should -Throw -ErrorId '...'
    }
  }
  
  Context 'Edge cases' {
    It 'Should handle <edge_case>' -TestCases @(...) {
      # Test boundary conditions
    }
  }
  
  Context 'Side effects (mocked)' {
    It 'Should call <external_dependency> correctly' {
      InModuleScope ModuleName {
        Mock External-Command -MockWith {...}
        # Test and verify mock calls
        Assert-MockCalled External-Command -Exactly -Times 1
      }
    }
  }
}
```

## Test Scenarios by Category

### 1. AST-Based Fix Functions
**Pattern**: Parse AST, identify issues, apply transformations
- ✅ Valid input produces expected AST modifications
- ✅ Invalid/malformed PowerShell throws appropriate errors
- ✅ Edge cases: empty scripts, comments-only, large files
- ✅ Idempotency: Running fix twice produces same result
- ✅ Mock PSScriptAnalyzer integration

### 2. Security Detection Functions
**Pattern**: Analyze code for vulnerabilities, report findings
- ✅ Known vulnerable patterns are detected
- ✅ Safe patterns are not flagged (no false positives)
- ✅ Edge cases: obfuscated code, string manipulation
- ✅ Entropy calculations are accurate (for secret detection)
- ✅ Mock file system access

### 3. AI/ML Integration Functions
**Pattern**: Model inference, confidence scoring, learning
- ✅ Configuration loading and validation
- ✅ Mock model inference (no real ML operations)
- ✅ Confidence score calculation logic
- ✅ Error handling for missing/invalid models
- ✅ Cache operations (mocked file I/O)

### 4. Observability Functions
**Pattern**: Tracing, metrics, logging
- ✅ Trace/span creation (mocked OTel)
- ✅ Metric collection and aggregation
- ✅ Log formatting and output
- ✅ No real network calls
- ✅ Deterministic timestamps (mock Get-Date)

### 5. Compliance Functions
**Pattern**: Rule evaluation, report generation
- ✅ Compliance rule evaluation accuracy
- ✅ Report format validation (JSON/SARIF/etc.)
- ✅ Coverage of all rule categories
- ✅ Edge cases: partially compliant code
- ✅ Mock report file output

## Mocking Strategy

### External Dependencies to Mock
1. **PSScriptAnalyzer**: `Invoke-ScriptAnalyzer`, `Invoke-Formatter`
2. **File System**: All file I/O via TestDrive: or mocks
3. **Network**: Any HTTP/REST calls (MCP, API, telemetry)
4. **Time**: `Get-Date`, `Start-Sleep`
5. **Processes**: `Start-Process`, `Start-Job`
6. **Registry**: Use TestRegistry: or mocks
7. **ML/AI**: Model loading, inference, training
8. **Cryptographic**: Hash calculations, entropy (deterministic test data)

### Mock Builders (New Helper Module)
```powershell
# MockBuilders.psm1
function New-MockDiagnosticRecord { ... }
function New-MockAST { ... }
function New-MockPSScriptAnalyzerResult { ... }
function New-MockSecurityFinding { ... }
function New-MockOTelSpan { ... }
```

## Coverage Targets

### Per-Module Targets
- **Critical modules** (Core, Security, BestPractices, Formatting, Advanced): ≥95% line coverage
- **Enhanced features** (AI, Observability, Compliance): ≥90% line coverage
- **Specialized modules** (Performance, MCP): ≥85% line coverage
- **Branch coverage**: ≥85% for critical decision points

### Quality Gates
1. All tests pass on Windows, macOS, Linux
2. No flaky tests (deterministic execution)
3. Test execution < 60 seconds total
4. PSScriptAnalyzer: 0 errors/warnings in test code
5. Code coverage reports generated

## CI Integration

### GitHub Actions Updates
```yaml
- name: Run comprehensive tests with coverage
  shell: pwsh
  run: |
    $config = [PesterConfiguration]::Default
    $config.Run.PassThru = $true
    $config.Run.Exit = $true
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = 'coverage.xml'
    $config.CodeCoverage.Path = './tools/lib/**/*.psm1'
    
    Invoke-Pester -Configuration $config

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: ./coverage.xml
    fail_ci_if_error: true
```

## Implementation Priority

### Phase 1: High Priority (Week 1)
1. ✅ Create enhanced test helpers (MockBuilders, TestData)
2. ✅ BestPractices submodules (7 files)
3. ✅ Formatting submodules (5 files)
4. ✅ Advanced submodules (9 files)

### Phase 2: Medium Priority (Week 2)
5. ✅ AIIntegration, EnhancedMetrics, AdvancedDetection
6. ✅ Security modules (Enhanced, Entropy, DetectionEnhanced)
7. ✅ SupplyChainSecurity, NISTSP80053Compliance

### Phase 3: Specialized (Week 3)
8. ✅ Observability, OpenTelemetryTracing
9. ✅ ReinforcementLearning, PerformanceOptimization
10. ✅ MCPIntegration
11. ✅ CI integration and coverage reporting

## Success Criteria
- [ ] All 16+ modules have comprehensive unit tests
- [ ] ≥90% line coverage across codebase
- [ ] ≥85% branch coverage for critical paths
- [ ] All tests pass on Windows/macOS/Linux
- [ ] 0 PSScriptAnalyzer violations in test code
- [ ] Test suite executes in < 60 seconds
- [ ] Coverage reports integrated in CI
- [ ] Test documentation complete

## Risk Mitigation
- **Complex AST logic**: Use simplified AST mock objects, focus on behavior
- **ML/AI features**: Mock all model operations, test logic only
- **External services**: Mock all network/API calls
- **Platform differences**: Use cross-platform abstractions (TestDrive:)
- **Flaky tests**: Ban real time/network/randomness, enforce mocks

## References
- Pester Architect Agent Playbook (problem statement)
- Existing test patterns: tests/Unit/Core.Tests.ps1
- PSScriptAnalyzer config: .psscriptanalyzer.psd1
- Module manifest: PoshGuard/PoshGuard.psd1
