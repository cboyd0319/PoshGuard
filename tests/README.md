# PoshGuard Test Suite - Pester Architect Implementation

[![Tests](https://github.com/cboyd0319/PoshGuard/workflows/Comprehensive%20Test%20Suite/badge.svg)](https://github.com/cboyd0319/PoshGuard/actions)
[![Coverage](https://codecov.io/gh/cboyd0319/PoshGuard/branch/main/graph/badge.svg)](https://codecov.io/gh/cboyd0319/PoshGuard)

Comprehensive, maintainable, deterministic test suite following Pester Architect principles.

## 📊 Quick Stats

- **1066+ tests** across 49 test files
- **48 modules** fully covered
- **Pester v5.7.1** (modern AAA pattern)
- **CI/CD** on Windows, macOS, Linux
- **~75% coverage** (target: 90% line, 85% branch)

## 🚀 Quick Start

```powershell
# Quick test (core modules only, ~2 seconds)
./tests/run-local-tests.ps1 -Quick

# Full suite (~10 minutes)
./tests/run-local-tests.ps1

# With code coverage
./tests/run-local-tests.ps1 -Coverage

# Specific module
./tests/run-local-tests.ps1 -Module Security
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [**QUICK_REFERENCE.md**](QUICK_REFERENCE.md) | Developer cheat sheet |
| [**PESTER_ARCHITECT_TEST_PLAN.md**](PESTER_ARCHITECT_TEST_PLAN.md) | Test strategy |
| [**TEST_RATIONALE.md**](TEST_RATIONALE.md) | Design decisions |
| [**IMPLEMENTATION_SUMMARY_PESTER_ARCHITECT.md**](IMPLEMENTATION_SUMMARY_PESTER_ARCHITECT.md) | Status |
| [**EXEMPLAR_PESTER_ARCHITECT_TEST.ps1**](EXEMPLAR_PESTER_ARCHITECT_TEST.ps1) | Reference tests |

## ✅ Test Quality Standards

- **Deterministic**: No flaky tests, all dependencies mocked
- **Hermetic**: TestDrive only, no real filesystem/network
- **Fast**: Core tests ~2s, full suite ~10min
- **Maintainable**: AAA pattern, table-driven, shared helpers

For complete information, see [QUICK_REFERENCE.md](QUICK_REFERENCE.md) and [IMPLEMENTATION_SUMMARY_PESTER_ARCHITECT.md](IMPLEMENTATION_SUMMARY_PESTER_ARCHITECT.md).
