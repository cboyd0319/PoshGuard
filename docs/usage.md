Usage
=====

Run PoshGuard in two ways: module or tools.

Module (Invoke-PoshGuard)
-------------------------

```powershell
Import-Module PoshGuard

# Preview (safe)
Invoke-PoshGuard -Path ./MyScript.ps1 -DryRun -ShowDiff

# Apply fixes
Invoke-PoshGuard -Path ./src -Recurse

# Skip rules
Invoke-PoshGuard -Path ./script.ps1 -Skip @('PSAvoidUsingWriteHost','PSUseApprovedVerbs')

# Export SARIF for GitHub Code Scanning
Invoke-PoshGuard -Path . -DryRun -ExportSarif -SarifOutputPath ./poshguard-results.sarif
```

Tools (no install required)
---------------------------

```powershell
# Preview (safe)
./tools/Apply-AutoFix.ps1 -Path ./MyScript.ps1 -DryRun -ShowDiff

# Apply fixes recursively
./tools/Apply-AutoFix.ps1 -Path ./src -Recurse

# Restore backup
./tools/Restore-Backup.ps1 -BackupPath ./.backup/MyScript.ps1.20251011_140523.bak
```

Common scenarios
----------------

- Pre-commit: `./tools/Apply-AutoFix.ps1 -Path . -DryRun -Recurse`
- CI/CD: `./tools/Apply-AutoFix.ps1 -Path . -NonInteractive -OutputFormat jsonl`
- Sample run: `cd samples; ../tools/Apply-AutoFix.ps1 -Path ./before-security-issues.ps1 -ShowDiff`

Exit codes
----------

- 0 = Success
- 1 = Issues found (DryRun)
- 2 = Error

Help
----

```powershell
Get-Help Invoke-PoshGuard -Full
Get-Help ./tools/Apply-AutoFix.ps1 -Full
```

