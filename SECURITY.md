# Security Policy

## Supported Versions

We support the latest minor release and security patches.

| Version | Supported |
|---------|-----------|
| 4.x     | Yes       |
| < 4.0   | No        |

## Reporting Vulnerabilities

Do not use public GitHub issues for security reports.

Report via:
- GitHub Security Advisories (preferred, private): https://github.com/cboyd0319/PoshGuard/security/advisories/new
- Direct contact: https://github.com/cboyd0319

We aim to respond within 3 business days.

Include:
- Issue type (injection, unsafe eval, hardcoded secret, etc.)
- Affected script/module paths (tag/branch/commit)
- Steps to reproduce or PoC
- Impact assessment

## Handling of Secrets

- Never commit secrets. Use environment variables or a secret manager.
- Required runtime secrets are documented in README (Security section).
- PoshGuard detects hardcoded secrets — review and remediate findings.

## Supply Chain

- Releases are signed (Sigstore/cosign).
- SBOM (SPDX 2.3) is attached to every release.
- Build provenance is attached when available.

## Security Features in PoshGuard

PoshGuard helps you find and fix:
- Hardcoded secrets (API keys, passwords, tokens)
- Dangerous invocation patterns (e.g., Invoke-Expression)
- Insecure configuration (unencrypted auth, weak crypto)
- Injection-prone constructs
- Path traversal and unsafe file operations

## Best Practices When Using PoshGuard

1. Review DryRun output before applying fixes
2. Keep PoshGuard updated (`Install-Module PoshGuard -Force`)
3. Backups are created automatically in `.psqa-backup/` before changes
4. Sandbox untrusted code; PoshGuard analyzes without executing scripts
5. Review CI logs and SARIF reports when enabled
