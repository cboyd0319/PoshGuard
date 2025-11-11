# PoshGuard Documentation Index

**Complete guide to all PoshGuard documentation - Updated 2025-11-11**

Use this page to navigate the docs. Prefer short, runnable examples and link deep-dives under `docs/reference/`.

---

## 🚀 Getting Started (5-10 minutes)

Start here if you're new to PoshGuard:

- **[Quick Start](quick-start.md)** - Get running in 5 minutes
- **[Install Guide](install.md)** - Installation instructions for all platforms
- **[Usage Guide](usage.md)** - Basic usage and common scenarios
- **[Beginners Guide](BEGINNERS-GUIDE.md)** - Comprehensive introduction

---

## 📖 Core Documentation

### Architecture & Design
- **[Architecture Overview](ARCHITECTURE.md)** - System design and module structure
- **[How It Works](how-it-works.md)** - Technical deep dive into fix engine
- **[Roadmap](ROADMAP.md)** - Future plans and feature requests

### Integration Guides
- **[RipGrep Integration](RIPGREP_INTEGRATION.md)** - 5-10x faster scanning
- **[RipGrep Usage Guide](RIPGREP_USAGE_GUIDE.md)** - Practical RipGrep examples
- **[GitHub SARIF Integration](reference/GITHUB-SARIF-INTEGRATION.md)** - Code Scanning setup
- **[MCP Integration Guide](MCP-GUIDE.md)** - Claude/LLM integration

### Security
- **[Security Framework](reference/SECURITY-FRAMEWORK.md)** - NIST/OWASP/CIS compliance
- **[Advanced Detection](reference/ADVANCED-DETECTION.md)** - ML-powered detection
- **[SARIF Implementation](reference/SARIF-IMPLEMENTATION-SUMMARY.md)** - SARIF export details

---

## 📚 Reference Documentation

### API & Configuration
- **[API Reference](api.md)** - Function signatures and parameters
- **[Configuration Guide](config.md)** - Settings and customization
- **[Checks Catalog](checks.md)** - Complete list of rules and fixes

### Testing
- **[Testing Guide](../tests/TESTING_GUIDE.md)** - How to run and write tests
- **[Test Plan](../tests/PESTER_ARCHITECT_TEST_PLAN.md)** - Comprehensive test strategy
- **[Test Rationale](../tests/TEST_RATIONALE.md)** - Testing decisions and architecture
- **[Quick Reference](../tests/QUICK_REFERENCE.md)** - Developer cheat sheet
- **[Implementation Status](../tests/IMPLEMENTATION_SUMMARY_PESTER_ARCHITECT.md)** - Current test coverage

### Performance
- **[Test Optimization Guide](TEST_OPTIMIZATION_GUIDE.md)** - Making tests faster
- **[Test Performance Best Practices](TEST_PERFORMANCE_BEST_PRACTICES.md)** - Performance tips
- **[Test Performance Guide](TEST_PERFORMANCE_GUIDE.md)** - Benchmarking and profiling
- **[Test Performance Issues](TEST_PERFORMANCE_ISSUES.md)** - Common problems and solutions

### Analysis & Reports
- **[Pester Architect Analysis](PESTER_ARCHITECT_ANALYSIS.md)** - Test framework analysis
- **[Testing Implementation](TESTING_IMPLEMENTATION.md)** - Implementation details

---

## 👨‍💻 Development

### Contributing
- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute
- **[Code of Conduct](../CODE_OF_CONDUCT.md)** - Community guidelines
- **[Engineering Standards](development/ENGINEERING-STANDARDS.md)** - Code quality standards
- **[Version Management](development/VERSION-MANAGEMENT.md)** - Release process

### CI/CD
- **[CI Integration](development/ci-integration.md)** - GitHub Actions, Azure DevOps, GitLab
- **[Dependabot](development/DEPENDABOT.md)** - Dependency management

### Workflows
- **[Best Practices Compliance](development/workflows/BEST-PRACTICES-COMPLIANCE.md)**
- **[Pull Request Template](development/workflows/PULL_REQUEST_TEMPLATE.md)**
- **[Copilot Instructions](development/workflows/copilot-instructions.md)**
- **[MCP Troubleshooting](development/workflows/MCP-TROUBLESHOOTING.md)**

### Tools Documentation
- **[Tools Overview](development/tools/README.md)**
- **[Advanced Tools](development/tools/Advanced/README.md)**
- **[BestPractices Tools](development/tools/BestPractices/README.md)**
- **[Formatting Tools](development/tools/Formatting/README.md)**

---

## 🎯 Runbooks & Examples

- **[Runbooks Directory](runbooks/)** - Operational procedures
- **[Examples Directory](examples/)** - Code samples and demos
- **[Demo Instructions](demo-instructions.md)** - How to demo PoshGuard

---

## 📊 Audit Reports & Change History

### Recent Audits (2025-11-11)
- **[Audit Report](../AUDIT_REPORT.md)** - Deep audit: 5 critical bugs fixed
- **[Enhancements Report](../ENHANCEMENTS_REPORT.md)** - 8 major UX improvements

### Historical Reports (tests/ directory)
- **[Comprehensive Test Audit 2025](../tests/COMPREHENSIVE_TEST_AUDIT_2025.md)** - Test suite audit
- **[Pester Architect Implementation](../tests/PESTER_ARCHITECT_IMPLEMENTATION_COMPLETE.md)** - Test implementation report

### Changelog
- **[Changelog](CHANGELOG.md)** - Version history and release notes

---

## 📂 Directory Structure

```
PoshGuard/
├── README.md                 # Project overview
├── CONTRIBUTING.md           # How to contribute
├── CODE_OF_CONDUCT.md       # Community standards
├── SECURITY.md               # Security policy
├── AUDIT_REPORT.md          # Latest audit (2025-11-11)
├── ENHANCEMENTS_REPORT.md   # Latest enhancements (2025-11-11)
│
├── docs/                     # 📚 Main documentation
│   ├── DOCUMENTATION_INDEX.md (this file)
│   ├── quick-start.md       # 5-min quickstart
│   ├── install.md           # Installation
│   ├── usage.md             # Basic usage
│   ├── ARCHITECTURE.md      # System design
│   ├── BEGINNERS-GUIDE.md   # Comprehensive intro
│   ├── MCP-GUIDE.md         # Claude integration
│   ├── RIPGREP_*.md         # RipGrep guides
│   ├── PESTER_*.md          # Testing analysis
│   ├── TEST_*.md            # Testing guides
│   │
│   ├── reference/           # 📖 Reference docs
│   │   ├── SECURITY-FRAMEWORK.md
│   │   ├── ADVANCED-DETECTION.md
│   │   ├── GITHUB-SARIF-INTEGRATION.md
│   │   └── SARIF-IMPLEMENTATION-SUMMARY.md
│   │
│   ├── development/         # 👨‍💻 Developer docs
│   │   ├── README.md
│   │   ├── ENGINEERING-STANDARDS.md
│   │   ├── VERSION-MANAGEMENT.md
│   │   ├── DEPENDABOT.md
│   │   ├── ci-integration.md
│   │   ├── workflows/      # Workflow docs
│   │   └── tools/          # Tool-specific docs
│   │
│   ├── examples/            # 💡 Code examples
│   └── runbooks/            # 📋 Operations
│
└── tests/                   # 🧪 Testing documentation
    ├── README.md            # Test suite overview
    ├── TESTING_GUIDE.md     # How to run tests
    ├── PESTER_ARCHITECT_TEST_PLAN.md  # Test strategy
    ├── QUICK_REFERENCE.md   # Developer cheat sheet
    └── IMPLEMENTATION_SUMMARY_PESTER_ARCHITECT.md
```

---

## 🔍 Finding What You Need

### By Task
- **I want to install PoshGuard** → [install.md](install.md)
- **I want to fix my scripts** → [quick-start.md](quick-start.md)
- **I want to skip specific rules** → [usage.md](usage.md) (see -Skip parameter)
- **I want faster scanning** → [RIPGREP_INTEGRATION.md](RIPGREP_INTEGRATION.md)
- **I want GitHub integration** → [reference/GITHUB-SARIF-INTEGRATION.md](reference/GITHUB-SARIF-INTEGRATION.md)
- **I want to contribute** → [../CONTRIBUTING.md](../CONTRIBUTING.md)
- **I want to run tests** → [../tests/TESTING_GUIDE.md](../tests/TESTING_GUIDE.md)
- **I want to understand architecture** → [ARCHITECTURE.md](ARCHITECTURE.md)

### By Role
- **End User** → Start with [quick-start.md](quick-start.md)
- **DevOps Engineer** → See [development/ci-integration.md](development/ci-integration.md)
- **Security Analyst** → See [reference/SECURITY-FRAMEWORK.md](reference/SECURITY-FRAMEWORK.md)
- **Developer/Contributor** → See [../CONTRIBUTING.md](../CONTRIBUTING.md) and [development/](development/)
- **QA/Tester** → See [../tests/TESTING_GUIDE.md](../tests/TESTING_GUIDE.md)

---

## 📝 Documentation Standards

All PoshGuard documentation follows these standards:

1. **Markdown format** - GitHub-flavored markdown
2. **Clear structure** - Logical sections with headers
3. **Code examples** - Runnable examples for all features
4. **Cross-references** - Links to related docs
5. **Date stamps** - Last updated dates on major docs
6. **Concise** - Focus on practical information

---

## 🆘 Getting Help

- **GitHub Issues**: https://github.com/cboyd0319/PoshGuard/issues
- **Discussions**: https://github.com/cboyd0319/PoshGuard/discussions
- **Security Issues**: See [SECURITY.md](../SECURITY.md)

---

**Last Updated:** 2025-11-11
**Documentation Status:** ✅ Current and Complete
**Total Documents:** 60+ files across docs/, tests/, and root
