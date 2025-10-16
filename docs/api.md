Module API
==========

Exports
-------

- `Invoke-PoshGuard` — main entry point to analyze and auto-fix PowerShell code

Signature
---------

```powershell
Invoke-PoshGuard `
  -Path <string> `
  [-DryRun] `
  [-ShowDiff] `
  [-Recurse] `
  [-Skip <string[]>] `
  [-ExportSarif] `
  [-SarifOutputPath <string>]
```

Examples
--------

```powershell
# Preview changes
Invoke-PoshGuard -Path ./script.ps1 -DryRun -ShowDiff

# Apply fixes recursively
Invoke-PoshGuard -Path ./src -Recurse

# Export SARIF
Invoke-PoshGuard -Path . -DryRun -ExportSarif -SarifOutputPath ./poshguard-results.sarif
```

Notes
-----

- For repo usage without installing the module, call `./tools/Apply-AutoFix.ps1` directly.
- PSScriptAnalyzer settings and quality gates load from `config/` by default.

