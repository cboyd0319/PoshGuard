# PoshGuard Operational Runbooks

Runbooks for common operational scenarios, incident response, and troubleshooting.

## Quick Reference

### Alert → Runbook Mapping

| Alert Name | Severity | Response |
|------------|----------|---------|
| SyntaxErrorIntroduced | SEV-1 | Immediate rollback, investigate root cause |
| AvailabilitySLOBreach | SEV-1 | Investigate + mitigate, check error logs |
| ErrorBudgetExhausted | SEV-2 | Feature freeze, reliability work only |
| LatencySLOWarning | SEV-3 | Profile + optimize bottlenecks |
| FixRateRegression | SEV-3 | Analyze failing rules, update tests |

### Common Commands

```powershell
# Check current version
pwsh -Command "Import-Module ./PoshGuard/PoshGuard.psd1; (Get-Module PoshGuard).Version"

# Run benchmark (validate changes)
pwsh ./tools/Run-Benchmark.ps1

# View recent structured logs
Get-Content ./logs/poshguard.jsonl -Tail 20 | ForEach-Object { $_ | ConvertFrom-Json }

# Emergency rollback
git checkout <previous-commit-sha>
pwsh ./tools/Run-Benchmark.ps1  # Validate
```

## Incident Response Workflow

```
1. DETECT → 2. ACKNOWLEDGE → 3. TRIAGE → 4. MITIGATE → 5. RESOLVE → 6. POSTMORTEM → 7. PREVENT
```

---

**Document Owner**: SRE Team  
**Last Updated**: 2025-10-12
