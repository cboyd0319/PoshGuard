# PoshGuard Comprehensive Test Plan

## Executive Summary

This document outlines the comprehensive testing strategy for all PowerShell modules in the PoshGuard repository, following Pester v5+ best practices with AAA (Arrange-Act-Assert) pattern, deterministic execution, and hermetic isolation.

**Target Coverage**: 90%+ lines, 85%+ critical branches  
**Test Framework**: Pester 5.5.0+  
**Platforms**: Windows, macOS, Linux (PowerShell 7.4+)

## Module Inventory

### Tested Modules (9/20 core + 11/27 submodules)

**Core Modules with Tests:**
1. ✅ Core.psm1 - 32 tests (Clean-Backups, Write-Log, Get-PowerShellFiles, New-FileBackup, New-UnifiedDiff)
2. ✅ Security.psm1 - Tests cover 7 security fix functions
3. ✅ Advanced.psm1 - Facade module tests
4. ✅ Formatting.psm1 - Facade module tests
5. ✅ ConfigurationManager.psm1 - Configuration handling tests
6. ✅ EntropySecretDetection.psm1 - Entropy-based secret detection
7. ✅ Observability.psm1 - Logging and monitoring tests
8. ✅ PerformanceOptimization.psm1 - Performance enhancement tests
9. ✅ PoshGuard.psm1 - Main module entry point

**Submodules with Tests:**
- ✅ Advanced/ASTTransformations.Tests.ps1
- ✅ BestPractices/CodeQuality.Tests.ps1
- ✅ BestPractices/Naming.Tests.ps1
- ✅ BestPractices/Scoping.Tests.ps1
- ✅ BestPractices/StringHandling.Tests.ps1
- ✅ BestPractices/Syntax.Tests.ps1
- ✅ BestPractices/TypeSafety.Tests.ps1
- ✅ Formatting/Aliases.Tests.ps1
- ✅ Formatting/Casing.Tests.ps1
- ✅ Formatting/Output.Tests.ps1
- ✅ Formatting/Whitespace.Tests.ps1

### Modules Requiring Tests (12 core modules)

#### Priority 1 - Critical Security & AI (High Impact)

**1. AIIntegration.psm1** (14 functions, 699 lines)
- **Public Functions:**
  - `Get-FixConfidenceScore` - ML-based confidence scoring (0.0-1.0)
  - `Get-FixRecommendation` - AI-powered fix suggestions
  - `Update-PatternDatabase` - Pattern learning and storage
  - `Get-AIConfig` - Configuration retrieval
  - `Set-AIConfig` - Configuration updates
  - `Enable-MCPIntegration` - MCP protocol enablement
  - `Invoke-MCPQuery` - MCP server queries
  - `Get-SemanticSimilarity` - Code similarity analysis
  - `Invoke-PredictiveAnalysis` - Issue prediction
  - `Get-PatternInsights` - Pattern statistics
  - `Export-MLModel` - Model export
  - `Import-MLModel` - Model import
  - `Test-AIHealth` - Health diagnostics
  - `Clear-AICache` - Cache management

- **Test Coverage Required:**
  - ✅ Confidence scoring algorithm validation
  - ✅ Edge cases: empty content, identical content, invalid syntax
  - ✅ Weight configuration validation
  - ✅ AST preservation scoring
  - ✅ Pattern database operations (CRUD)
  - ✅ MCP integration mocking
  - ✅ Semantic similarity calculations
  - ✅ Predictive analysis output validation
  - ✅ Model import/export functionality
  - ✅ Health check diagnostics
  - ✅ Cache management

**2. EnhancedSecurityDetection.psm1** (10 functions, 716 lines)
- **Public Functions:**
  - `Invoke-EnhancedSecurityScan` - Comprehensive security scanning
  - `Get-SecurityPattern` - Pattern-based detection
  - `Test-SecretExposure` - Secret leakage detection
  - `Test-InjectionVulnerability` - SQL/Command injection detection
  - `Test-InsecureDeserialization` - Deserialization vulnerability detection
  - `Test-XXEVulnerability` - XML External Entity detection
  - `Test-PathTraversal` - Path traversal detection
  - `Get-SecurityScore` - Overall security scoring
  - `Export-SecurityReport` - SARIF/JSON report generation
  - `Get-MITREMapping` - MITRE ATT&CK framework mapping

- **Test Coverage Required:**
  - ✅ All OWASP Top 10 vulnerability patterns
  - ✅ CWE mapping validation
  - ✅ MITRE ATT&CK technique correlation
  - ✅ False positive prevention
  - ✅ Security score calculation
  - ✅ SARIF export compliance
  - ✅ Pattern matching accuracy
  - ✅ Edge cases: obfuscated code, encoding variations

**3. SecurityDetectionEnhanced.psm1** (10 functions, 751 lines)
- **Public Functions:**
  - Advanced security detection patterns
  - Credential scanning
  - Crypto weakness detection
  - Authentication bypass detection

- **Test Coverage Required:**
  - ✅ Credential pattern detection
  - ✅ Weak cryptography identification
  - ✅ Authentication mechanism analysis
  - ✅ Authorization bypass detection

#### Priority 2 - Compliance & Standards (Regulatory)

**4. NISTSP80053Compliance.psm1** (28 functions, 822 lines)
- **Public Functions:**
  - `Test-NISTCompliance` - Overall compliance testing
  - 27 individual control tests (AC-*, SI-*, SC-*, etc.)
  
- **Test Coverage Required:**
  - ✅ All NIST SP 800-53 Rev 5 controls
  - ✅ FedRAMP baseline validation
  - ✅ Compliance report generation
  - ✅ Control mapping accuracy
  - ✅ Risk assessment calculations
  - ✅ Remediation recommendations

**5. SupplyChainSecurity.psm1** (8 functions, 744 lines)
- **Public Functions:**
  - `Get-PowerShellDependencies` - Dependency discovery
  - `New-SBOM` - SBOM generation (CycloneDX/SPDX)
  - `Test-DependencyVulnerabilities` - Vulnerability scanning
  - `Test-LicenseCompliance` - License validation
  - `Get-ComponentIntegrity` - Integrity verification
  - `Export-SBOMReport` - Report generation
  - `Get-TransitiveDependencies` - Transitive dep analysis
  - `Test-SupplyChainRisk` - Risk assessment

- **Test Coverage Required:**
  - ✅ SBOM generation (CycloneDX 1.5, SPDX 2.3)
  - ✅ Dependency tree construction
  - ✅ Vulnerability database queries (mocked)
  - ✅ License compatibility checks
  - ✅ Component integrity validation
  - ✅ Transitive dependency resolution
  - ✅ CISA minimum elements compliance

#### Priority 3 - Observability & Performance

**6. OpenTelemetryTracing.psm1** (15 functions, 665 lines)
- **Public Functions:**
  - `Initialize-Tracing` - Setup tracing
  - `New-Span` - Create spans
  - `Complete-Span` - Close spans
  - `Add-SpanAttribute` - Add metadata
  - `Record-Exception` - Exception tracking
  - `New-Event` - Event creation
  - `Export-Traces` - Export functionality
  - And 8 more...

- **Test Coverage Required:**
  - ✅ Span lifecycle management
  - ✅ Context propagation
  - ✅ Attribute validation
  - ✅ Exception recording
  - ✅ Export format compliance (OTLP)
  - ✅ Performance overhead validation

**7. ReinforcementLearning.psm1** (12 functions, 690 lines)
- **Public Functions:**
  - `Initialize-RLAgent` - Agent initialization
  - `Get-RLAction` - Action selection
  - `Update-RLModel` - Model updates
  - `Get-RLReward` - Reward calculation
  - And 8 more...

- **Test Coverage Required:**
  - ✅ Q-learning algorithm validation
  - ✅ State/action/reward mechanics
  - ✅ Model persistence
  - ✅ Exploration vs exploitation
  - ✅ Convergence behavior

**8. EnhancedMetrics.psm1** (7 functions, 533 lines)
- **Public Functions:**
  - Metric collection and aggregation
  - Dashboard generation
  - Trend analysis

- **Test Coverage Required:**
  - ✅ Metric calculation accuracy
  - ✅ Aggregation logic
  - ✅ Visualization output
  - ✅ Time-series handling

#### Priority 4 - Integration & Analysis

**9. MCPIntegration.psm1** (13 functions, 590 lines)
- **Public Functions:**
  - MCP server communication
  - Tool registration
  - Context management

- **Test Coverage Required:**
  - ✅ MCP protocol compliance
  - ✅ Server communication (mocked)
  - ✅ Tool invocation
  - ✅ Context lifecycle

**10. AdvancedCodeAnalysis.psm1** (12 functions, 620 lines)
- **Public Functions:**
  - AST analysis utilities
  - Complexity metrics
  - Code smell detection

- **Test Coverage Required:**
  - ✅ AST traversal accuracy
  - ✅ Cyclomatic complexity
  - ✅ Code smell patterns
  - ✅ Maintainability index

**11. AdvancedDetection.psm1** (6 functions, 755 lines)
- **Public Functions:**
  - Advanced pattern detection
  - Multi-pass analysis

- **Test Coverage Required:**
  - ✅ Pattern matching engines
  - ✅ Multi-pass coordination
  - ✅ Detection accuracy

**12. BestPractices.psm1** (facade module)
- **Test Coverage Required:**
  - ✅ Submodule loading
  - ✅ Function export verification
  - ✅ Error handling for missing submodules

### Submodules Requiring Tests (16 remaining)

#### Advanced Submodules (12)
- [ ] AttributeManagement.psm1
- [ ] CmdletBindingFix.psm1
- [ ] CodeAnalysis.psm1
- [ ] CompatibleCmdletsWarning.psm1
- [ ] DefaultValueForMandatoryParameter.psm1
- [ ] DeprecatedManifestFields.psm1
- [ ] Documentation.psm1
- [ ] InvokingEmptyMembers.psm1
- [ ] ManifestManagement.psm1
- [ ] OverwritingBuiltInCmdlets.psm1
- [ ] ParameterManagement.psm1
- [ ] ShouldProcessTransformation.psm1
- [ ] UTF8EncodingForHelpFile.psm1

#### BestPractices Submodules (1)
- [ ] UsagePatterns.psm1

#### Formatting Submodules (4)
- [ ] Alignment.psm1
- [ ] Runspaces.psm1
- [ ] WriteHostEnhanced.psm1
- (Note: Some may have partial coverage in parent module tests)

## Test Architecture

### Directory Structure
```
tests/
├── Unit/                           # Unit tests (one per module)
│   ├── Advanced/                   # Advanced submodule tests
│   ├── BestPractices/             # BestPractices submodule tests
│   ├── Formatting/                # Formatting submodule tests
│   ├── AIIntegration.Tests.ps1
│   ├── AdvancedCodeAnalysis.Tests.ps1
│   ├── AdvancedDetection.Tests.ps1
│   ├── EnhancedMetrics.Tests.ps1
│   ├── EnhancedSecurityDetection.Tests.ps1
│   ├── MCPIntegration.Tests.ps1
│   ├── NISTSP80053Compliance.Tests.ps1
│   ├── OpenTelemetryTracing.Tests.ps1
│   ├── ReinforcementLearning.Tests.ps1
│   ├── SecurityDetectionEnhanced.Tests.ps1
│   └── SupplyChainSecurity.Tests.ps1
├── Integration/                    # Integration tests (optional)
├── Helpers/                       # Shared test utilities
│   ├── TestHelpers.psm1          # General utilities
│   ├── MockBuilders.psm1         # Mock object builders
│   ├── TestData.psm1             # Test data generators
│   └── TestHelper.psm1           # Legacy (consolidate)
└── COMPREHENSIVE_TEST_PLAN_FINAL.md
```

### Test Pattern Template

```powershell
#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for [ModuleName]

.DESCRIPTION
    Comprehensive unit tests for [ModuleName].psm1 covering:
    - [Function 1]
    - [Function 2]
    - ...

    Tests follow AAA pattern with deterministic execution.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Coverage Target: 90%+ lines, 85%+ branches
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  Import-Module -Name $helpersPath -Force -ErrorAction Stop

  # Import module under test
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/[ModuleName].psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe '[FunctionName]' -Tag 'Unit', '[ModuleName]' {
  
  Context 'When [scenario]' {
    It 'Should [expected behavior]' {
      # Arrange
      InModuleScope [ModuleName] {
        # Setup
      }
      
      # Act
      $result = [FunctionName] -Param $value
      
      # Assert
      $result | Should -Be $expected
    }
  }

  Context 'When error conditions occur' {
    It 'Should throw on invalid input' {
      InModuleScope [ModuleName] {
        { [FunctionName] -Param $null } | Should -Throw -ErrorId 'InvalidParameter'
      }
    }
  }
}
```

## Mocking Strategy

### External Dependencies to Mock

1. **Network/HTTP**: All `Invoke-RestMethod`, `Invoke-WebRequest`
2. **Filesystem**: Use `TestDrive:` for all file operations
3. **Time**: Mock `Get-Date` for deterministic timestamps
4. **Random**: Mock any RNG sources
5. **Processes**: Mock `Start-Process`, `Start-Job`
6. **Registry**: Use `TestRegistry:` or mocks
7. **Environment**: Scoped `$env:` variables
8. **AI/ML APIs**: Mock all external LLM/MCP calls
9. **Telemetry**: Mock OpenTelemetry exporters
10. **Databases**: Mock vulnerability/pattern databases

### Mock Builder Functions

```powershell
function New-MockAIResponse {
  param([string]$Confidence = '0.95')
  return @{
    Confidence = [double]$Confidence
    Recommendation = 'Use SecureString'
    Reasoning = 'Security best practice'
  }
}

function New-MockSBOM {
  param([string]$Format = 'CycloneDX')
  return [PSCustomObject]@{
    BOMFormat = $Format
    SpecVersion = '1.5'
    Components = @()
    Dependencies = @()
  }
}

function New-MockVulnerability {
  param([string]$Severity = 'High')
  return [PSCustomObject]@{
    ID = 'CVE-2024-0001'
    Severity = $Severity
    Description = 'Test vulnerability'
    Remediation = 'Update to v2.0'
  }
}
```

## Quality Gates

### Coverage Requirements
- **Minimum Line Coverage**: 90% per module
- **Minimum Branch Coverage**: 85% for critical paths
- **Test Execution Time**: <100ms per test (target), <500ms (max)
- **Test Determinism**: 100% (no flakes)

### Static Analysis
- **PSScriptAnalyzer**: Zero errors/warnings on test files
- **Formatting**: Consistent with `.psscriptanalyzer.psd1`
- **Naming**: `*.Tests.ps1` convention
- **Structure**: AAA pattern, `Describe/Context/It`

### CI Integration
- **Platforms**: ubuntu-latest, windows-latest, macos-latest
- **PowerShell Versions**: 7.4+
- **Parallel Execution**: Tests must be independent
- **Artifact Generation**: JaCoCo coverage reports

## Implementation Timeline

### Phase 1: Priority 1 Modules (Week 1)
- [ ] AIIntegration.Tests.ps1
- [ ] EnhancedSecurityDetection.Tests.ps1
- [ ] SecurityDetectionEnhanced.Tests.ps1

### Phase 2: Priority 2 Modules (Week 2)
- [ ] NISTSP80053Compliance.Tests.ps1
- [ ] SupplyChainSecurity.Tests.ps1

### Phase 3: Priority 3 Modules (Week 3)
- [ ] OpenTelemetryTracing.Tests.ps1
- [ ] ReinforcementLearning.Tests.ps1
- [ ] EnhancedMetrics.Tests.ps1

### Phase 4: Priority 4 & Submodules (Week 4)
- [ ] MCPIntegration.Tests.ps1
- [ ] AdvancedCodeAnalysis.Tests.ps1
- [ ] AdvancedDetection.Tests.ps1
- [ ] BestPractices.Tests.ps1
- [ ] All remaining submodules

## Success Criteria

✅ All 20 core modules have comprehensive tests  
✅ All 27+ submodules have tests  
✅ 90%+ line coverage achieved  
✅ 85%+ branch coverage achieved  
✅ Zero flaky tests  
✅ All tests pass on Windows/macOS/Linux  
✅ CI pipeline updated and passing  
✅ Documentation updated  

## References

- **Pester Documentation**: https://pester.dev/docs/quick-start
- **PSScriptAnalyzer**: https://github.com/PowerShell/PSScriptAnalyzer
- **OpenTelemetry**: https://opentelemetry.io/docs/
- **NIST SP 800-53**: https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- **CycloneDX**: https://cyclonedx.org/
- **SPDX**: https://spdx.dev/

---

*Document Version: 1.0*  
*Last Updated: 2025-10-16*  
*Maintained by: PoshGuard QA Team*
