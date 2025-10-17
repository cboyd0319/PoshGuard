# Security Policy

## Reporting Vulnerabilities

Please use GitHub's Private Security Advisories to report sensitive issues:
https://github.com/cboyd0319/JobSentinel/security/advisories/new

Alternatively, open an issue (omit sensitive details):
https://github.com/cboyd0319/JobSentinel/issues

Include:
- Steps to reproduce
- Impact assessment
- Affected versions/commits
- Suggested mitigations (if any)

Target response time: 3 business days.

## Supported Versions

- Main branch and latest tagged release receive security fixes.

## Security Posture

- Local-first: no telemetry; data stays on your machine
- Least privilege: scrapers are read-only (no job board writes)
- Supply chain: pinned dependencies; releases tracked via CHANGELOG
- Secrets: store in environment variables or `.env`; never commit

