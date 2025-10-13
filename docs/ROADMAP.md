# Roadmap

PoshGuard development priorities and future features.

## v3.1.0 - Beyond PSSA (Q4 2025)

### Goal
Implement auto-fixes for community-requested rules that don't exist in PSScriptAnalyzer yet.

### Features
- TODO/FIXME comment detection and tracking
- Unused namespace detection (optimize `using namespace`)
- ASCII character warnings (prevent encoding issues)
- Get-Content | ConvertFrom-Json optimization (add `-Raw`)
- SecureString disclosure detection

### Benefits
- First-mover advantage on emerging best practices
- Solve problems users are asking for today
- Innovation leadership in PowerShell tooling

## v3.2.0 - IDE Integration (Q1 2026)

### Goal
Seamless integration with development environments.

### Features
- VS Code extension for inline fix suggestions
- Language server protocol (LSP) support
- Real-time linting and auto-fix on save
- Quick fix actions in editor

## v3.3.0 - CI/CD Templates (Q1 2026)

### Goal
Make PoshGuard easy to integrate into build pipelines.

### Features
- GitHub Actions template
- Azure DevOps pipeline template
- Jenkins pipeline example
- Pre-commit hook script
- Configuration profiles (security-focused, compatibility-focused, performance-focused)

## v3.4.0 - Performance (Q2 2026)

### Goal
Handle large codebases efficiently.

### Features
- Parallel file processing
- Incremental analysis (only changed files)
- Caching of AST parses
- Performance benchmarking suite

## v4.0.0 - Custom Rules Framework (Q3 2026)

### Goal
Allow users to define their own project-specific rules.

### Features
- Custom rule DSL
- Rule template generator
- Rule testing framework
- Community rule marketplace

## Wishlist (Future)

- **AI-Powered Fixes**: Suggest context-aware fixes using LLM
- **Code Quality Dashboard**: Web UI for team-wide metrics
- **Migration Tools**: Automate PowerShell 5.1 → 7.x migrations
- **Compliance Profiles**: Industry-specific rule sets (PCI-DSS, HIPAA, etc.)
- **Jupyter Notebook Support**: Fix PowerShell notebooks
- **Team Analytics**: Code quality trends over time

## Community Requests

Track open issues at: [GitHub Issues](https://github.com/cboyd0319/PoshGuard/issues)

Vote on features by commenting with 👍 on issue threads.

---

**Status**: Actively maintained | v4.3.0 production-ready
