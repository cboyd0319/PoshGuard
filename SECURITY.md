# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 3.x     | :white_check_mark: |
| 2.16.x  | :white_check_mark: |
| 2.15.x  | :x:                |
| < 2.15  | :x:                |

## Reporting a Vulnerability

**Do NOT open public issues for security vulnerabilities.**

### Contact
Email: https://github.com/cboyd0319

Include:
- Description of vulnerability
- Steps to reproduce
- Impact assessment
- Suggested fix (if any)

### Response Timeline
- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Fix Timeline**: Depends on severity
  - Critical: 7 days
  - High: 14 days
  - Medium: 30 days
  - Low: Next minor release

### Disclosure Policy
We follow responsible disclosure:
1. Vulnerability confirmed and fix developed
2. Patch released to supported versions
3. Security advisory published (90 days after patch or sooner if actively exploited)
4. Credit given to reporter (if desired)

## Security Best Practices

### For Users

**Least Privilege**
- Run with `-DryRun` first to preview changes
- Don't run with elevated privileges unless necessary
- Review diffs before applying fixes

**Secrets Management**
- Never commit credentials to repos
- Use environment variables or secure vaults
- Don't log sensitive data

**Supply Chain**
- Verify module signatures (when available)
- Pin PSScriptAnalyzer versions in CI
- Review third-party dependencies

### For Contributors

**Input Validation**
- Validate all external inputs (file paths, parameters)
- Use `-WhatIf` for destructive operations
- Don't trust user-supplied AST without validation

**Code Execution**
- Avoid `Invoke-Expression` (blocked by our own security rules)
- Don't evaluate arbitrary expressions
- Use AST parsing instead of string manipulation

**File Operations**
- Validate file paths (prevent traversal attacks)
- Check permissions before writing
- Create backups before modifying files

**Error Handling**
- Don't expose sensitive data in error messages
- Log errors without credentials/secrets
- Fail securely (deny by default)

## Known Security Considerations

### AST Parsing
- Malicious scripts could trigger parser bugs
- Mitigation: Run in isolated environment, use `-DryRun`

### File System Access
- Tool requires read/write access to target files
- Mitigation: Explicit `-Path` parameter, `.backup/` rollback available

### No Network Access
- PoshGuard doesn't make external network calls
- All operations are local file system only

### Dependencies
- PSScriptAnalyzer is required dependency
- Regularly update to latest version for security patches

## Disclosure History

No security vulnerabilities disclosed to date.

---

**Last Updated**: 2025-10-11  
**Policy Version**: 1.0
