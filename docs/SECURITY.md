# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 4.x     | ✅ |
| 3.x     | ✅ |
| < 3.0   | ❌ |

## Reporting

**Don't open public issues for security vulnerabilities.**

Contact: security@poshguard via [GitHub Security Advisories](https://github.com/cboyd0319/PoshGuard/security/advisories)

Include: description, repro steps, impact, suggested fix

Response:
- Ack: 48 hours
- Assessment: 5 business days
- Fix: 7 days (critical), 14 days (high), 30 days (medium), next release (low)

Disclosure: 90 days after patch or sooner if exploited

## Best Practices

**Users**:
- Run `-DryRun` first
- Don't use elevated privileges unless needed
- Never commit credentials
- Use env vars or secure vaults
- Pin PSScriptAnalyzer versions in CI

**Contributors**:
- Validate all inputs
- Use `-WhatIf` for destructive ops
- No `Invoke-Expression`
- Validate file paths (prevent traversal)
- No sensitive data in errors
- Fail securely (deny by default)

## Known Considerations

**AST parsing**: Malicious scripts could trigger parser bugs. Mitigation: isolated environment, `-DryRun`

**File access**: Requires read/write. Mitigation: explicit `-Path`, `.backup/` rollback

**Network**: None. All operations local.

**Dependencies**: PSScriptAnalyzer required. Update regularly for patches.

## Disclosure History

No security vulnerabilities disclosed to date.

---

**Last Updated**: 2025-10-11  
**Policy Version**: 1.0
