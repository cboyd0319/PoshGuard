# Security Framework - OWASP ASVS Mappings

**Date**: 2025-10-12  
**Framework Version**: OWASP ASVS 5.0  
**Repository**: cboyd0319/PoshGuard  
**Security Posture**: Defense-in-Depth with Secure Defaults

## Executive Summary

PoshGuard implements security controls aligned with **OWASP Application Security Verification Standard (ASVS) v5.0** Level 1 requirements. This document maps PoshGuard's auto-fix rules to specific ASVS controls and establishes our security baseline.

**Source**: OWASP ASVS 5.0 | https://owasp.org/www-project-application-security-verification-standard/ | High | Concrete app-sec verification requirements by security level and category.

## Security Architecture

### Trust Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│ External (Untrusted)                                         │
├─────────────────────────────────────────────────────────────┤
│ Input: PowerShell Files (.ps1, .psm1, .psd1)               │
│ Validation: AST parsing, syntax validation                  │
└─────────────────────────────────────────────────────────────┘
                        ↓ Validated
┌─────────────────────────────────────────────────────────────┐
│ Processing (Semi-Trusted)                                    │
├─────────────────────────────────────────────────────────────┤
│ Core Engine: AST transformations, fix applications          │
│ Security Controls: Read-only by default, backups            │
└─────────────────────────────────────────────────────────────┘
                        ↓ Fixed
┌─────────────────────────────────────────────────────────────┐
│ Output (Trusted)                                             │
├─────────────────────────────────────────────────────────────┤
│ Modified Files: Write only after validation                 │
│ Logs: JSONL format with correlation IDs, no secrets         │
│ Backups: Timestamped, retention policy enforced             │
└─────────────────────────────────────────────────────────────┘
```

### Threat Model

| Threat | Impact | Likelihood | Mitigation | ASVS Ref |
|--------|--------|------------|------------|----------|
| Malicious PowerShell injection via crafted AST | HIGH | LOW | AST parsing validation, no Invoke-Expression | V5.2.1 |
| Secrets leaked in logs or output | HIGH | MEDIUM | No credential logging, error message sanitization | V2.7.4 |
| Path traversal in file operations | MEDIUM | LOW | Path validation, working directory restrictions | V12.2.1 |
| Backup file exposure | MEDIUM | LOW | Restricted permissions, automatic cleanup | V8.3.1 |
| DoS via large file processing | MEDIUM | MEDIUM | File size limits (10MB default), timeout enforcement | V11.1.5 |

**Methodology**: OWASP Threat Modeling | https://owasp.org/www-community/Threat_Modeling | High | Structured approach to identifying security risks.

## OWASP ASVS Control Mappings

### V2: Authentication (N/A for PoshGuard)
PoshGuard operates as a local file processing tool with no authentication requirements.

### V5: Validation, Sanitization and Encoding

#### V5.1 Input Validation

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V5.1.1 | Application validates input on server side | ✅ AST parsing validates PowerShell syntax | 100% |
| V5.1.2 | Application uses strongly typed parsing | ✅ .NET PowerShell AST parser (strongly typed) | 100% |
| V5.1.3 | Application validates data schemas | ✅ PSScriptAnalyzer settings validation | 100% |
| V5.1.4 | Application validates file extensions | ✅ Whitelist: .ps1, .psm1, .psd1 only | 100% |
| V5.1.5 | Application validates file size limits | ✅ 10MB default max, configurable | 100% |

#### V5.2 Sanitization and Sandboxing

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V5.2.1 | Untrusted data is sanitized | ✅ AST-based transformations (no eval) | 100% |
| V5.2.2 | Untrusted data not used in command execution | ✅ No Invoke-Expression, subprocess calls | 100% |
| V5.2.4 | Application validates and sanitizes file paths | ✅ Test-Path validation, no path traversal | 100% |

#### V5.3 Output Encoding

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V5.3.1 | Output encoding relevant for interpreter | ✅ UTF-8 with BOM for PowerShell compatibility | 100% |
| V5.3.6 | Error messages don't leak sensitive data | ✅ Generic error messages, verbose flag for details | 100% |

### V7: Error Handling and Logging

#### V7.1 Log Content

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V7.1.1 | Application logs security events | ✅ All file modifications logged with trace IDs | 100% |
| V7.1.2 | Application logs with sufficient detail | ✅ Timestamp, file, operation, result, trace ID | 100% |
| V7.1.3 | Application classifies logs | ✅ Levels: INFO, WARN, ERROR, SUCCESS | 100% |
| V7.1.4 | Application doesn't log sensitive data | ✅ No credentials, secrets, or PII in logs | 100% |

#### V7.2 Log Processing

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V7.2.1 | Logs stored securely | ✅ Local filesystem, user permissions applied | 100% |
| V7.2.2 | Logs have integrity protection | ⚠️ JSONL append-only format (partial) | 60% |

### V8: Data Protection

#### V8.1 General Data Protection

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V8.1.1 | Application protects sensitive data at rest | ✅ Backup files inherit source permissions | 100% |
| V8.1.6 | Sensitive data minimization | ✅ No sensitive data collected or stored | 100% |

#### V8.3 Sensitive Private Data

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V8.3.1 | Sensitive data not in logs or error messages | ✅ Sanitized error messages | 100% |
| V8.3.4 | Sensitive data in memory for minimum time | ✅ Content processed once, not cached | 100% |
| V8.3.6 | Cached/temporary sensitive data protected | ✅ Backups cleaned after retention period | 100% |

### V12: File and Resources

#### V12.1 File Upload

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V12.1.1 | Application validates file content type | ✅ PowerShell AST syntax validation | 100% |
| V12.1.2 | Application validates file size | ✅ 10MB limit enforced | 100% |
| V12.1.3 | Application prevents path traversal | ✅ Test-Path with full path resolution | 100% |

#### V12.2 File Integrity

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V12.2.1 | Files from untrusted sources validated | ✅ AST parsing before any operations | 100% |

#### V12.3 File Execution

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V12.3.1 | Application doesn't execute untrusted code | ✅ No Invoke-Expression or dynamic execution | 100% |

### V11: Business Logic

#### V11.1 Business Logic Security

| ASVS ID | Requirement | PoshGuard Implementation | Coverage |
|---------|-------------|--------------------------|----------|
| V11.1.5 | Application has anti-automation controls | ✅ File size limits, timeout enforcement | 100% |
| V11.1.8 | Application detects replay attacks | N/A | - |

## Security Controls Implementation

### 1. Credential Management
**Rule**: PSAvoidUsingPlainTextForPassword  
**ASVS**: V2.1.1, V2.1.3  
**Implementation**: Converts [string] password parameters to [SecureString]  
**Severity**: CRITICAL

### 2. Secure String Handling
**Rule**: PSAvoidUsingConvertToSecureStringWithPlainText  
**ASVS**: V2.1.11, V8.3.1  
**Implementation**: Comments out dangerous plaintext→SecureString conversions  
**Severity**: CRITICAL

### 3. Parameter Validation
**Rule**: PSAvoidUsingUsernameAndPasswordParams  
**ASVS**: V2.1.1  
**Implementation**: Flags functions with both Username and Password parameters  
**Severity**: HIGH

### 4. Code Injection Prevention
**Rule**: PSAvoidUsingInvokeExpression  
**ASVS**: V5.2.1, V5.2.2  
**Implementation**: Adds warnings and suggests safer alternatives (& operator, splatting)  
**Severity**: HIGH

### 5. Error Handling
**Rule**: PSAvoidUsingEmptyCatchBlock  
**ASVS**: V7.1.1, V7.1.2  
**Implementation**: Adds logging to empty catch blocks  
**Severity**: MEDIUM

### 6. Global Namespace Pollution
**Rule**: PSAvoidGlobalVars, PSAvoidGlobalFunctions, PSAvoidGlobalAliases  
**ASVS**: V11.1.4 (Business Logic)  
**Implementation**: Converts global scope to script scope  
**Severity**: MEDIUM

### 7. Hash Algorithm Security
**Rule**: PSAvoidUsingBrokenHashAlgorithms  
**ASVS**: V6.2.1 (Cryptography)  
**Implementation**: Flags MD5, SHA1 usage, suggests SHA256+  
**Severity**: MEDIUM

### 8. Computer Name Hardcoding
**Rule**: PSAvoidUsingComputerNameHardcoded  
**ASVS**: V11.1.1 (Business Logic)  
**Implementation**: Suggests parameterization for hardcoded computer names  
**Severity**: LOW

## Defense-in-Depth Layers

### Layer 1: Input Validation
- File extension whitelist (.ps1, .psm1, .psd1)
- AST syntax validation
- File size enforcement (10MB default)
- Path traversal prevention

### Layer 2: Secure Processing
- Read-only by default (`-DryRun` mode)
- Automatic backups before modifications
- AST-based transformations (no string manipulation)
- No external API calls or network access

### Layer 3: Output Protection
- Atomic file operations (write to .tmp, then move)
- Backup retention policy (default: 1 day)
- Error message sanitization
- JSONL structured logging with correlation IDs

### Layer 4: Observability
- Trace ID for request correlation
- Structured logging (JSONL format)
- No PII or credentials in logs
- Retention and rotation policies

## Security Best Practices

### Secure Defaults
- ✅ Dry-run mode available for preview
- ✅ Automatic backups enabled by default
- ✅ Verbose logging disabled by default
- ✅ No network access
- ✅ No credential storage

### Least Privilege
- ✅ Reads files with current user permissions
- ✅ Writes only when explicitly authorized
- ✅ No elevation required
- ✅ Scoped to working directory

### Auditability
- ✅ Every operation logged with trace ID
- ✅ Before/after state captured in backups
- ✅ JSONL format for machine parsing
- ✅ Timestamp precision (ISO 8601)

## Compliance Considerations

### Data Protection Regulations
**GDPR**: No personal data collected or processed  
**CCPA**: No consumer data handling  
**HIPAA**: No PHI processing  
**PCI-DSS**: No payment card data

### Security Frameworks
**NIST CSF**: Aligns with Protect (PR) and Detect (DE) functions  
**ISO 27001**: Follows secure development lifecycle principles  
**CIS Controls**: Implements secure configuration management (Control 5)

**Reference**: NIST Cybersecurity Framework | https://www.nist.gov/cyberframework | High | Risk-based approach to managing cybersecurity risk.

## Security Testing

### Static Analysis
- ✅ PSScriptAnalyzer with strict rules
- ✅ Zero tolerance for security violations
- ✅ CI/CD integration with SARIF output
- ✅ Code scanning with GitHub Advanced Security

### Manual Testing
- ✅ Path traversal attempts
- ✅ Malformed AST injection tests
- ✅ Large file DoS scenarios
- ✅ Permission boundary validation

### Continuous Monitoring
- ✅ Automated security scanning in CI
- ✅ Dependency vulnerability checks (Dependabot)
- ✅ SBOM generation for supply chain security
- ✅ Regular ASVS compliance audits

## Incident Response

### Security Issue Disclosure
**Process**: See [SECURITY.md](SECURITY.md) for responsible disclosure  
**Response SLA**: Critical issues < 48 hours, High < 7 days  
**Communication**: Security advisories via GitHub Security Advisories

### Vulnerability Remediation
1. **Assess**: CVSS scoring, exploitability analysis
2. **Patch**: Develop and test fix
3. **Release**: Emergency release if critical
4. **Notify**: Security advisory + release notes
5. **Verify**: Confirm fix effectiveness

## Future Enhancements

### Planned Security Features (v3.1+)
- [ ] Digital signatures for release artifacts
- [ ] SLSA Build Level 3 compliance
- [ ] Supply chain security with Sigstore
- [ ] Runtime sandboxing with AppContainer
- [ ] Memory-safe parameter handling
- [ ] SIEM integration (Splunk, ELK)

### Security Roadmap Alignment
**Target**: OWASP ASVS Level 2 compliance by v4.0.0  
**Timeline**: Q3 2026  
**Investment**: Enhanced cryptographic controls, secure key management

## References

1. **OWASP ASVS 5.0** | https://owasp.org/www-project-application-security-verification-standard/ | High | Application security verification requirements
2. **SWEBOK v4.0** | https://www.computer.org/education/bodies-of-knowledge/software-engineering | High | Software engineering best practices and knowledge areas
3. **NIST SP 800-53** | https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final | High | Security and privacy controls for information systems
4. **CWE Top 25** | https://cwe.mitre.org/top25/ | High | Most dangerous software weaknesses
5. **PowerShell Security Best Practices** | https://docs.microsoft.com/en-us/powershell/scripting/security | Medium | Microsoft official security guidance

---

**Document Owner**: Security Engineering Team  
**Last Updated**: 2025-10-12  
**Next Review**: 2025-11-12  
**Version**: 1.0.0
