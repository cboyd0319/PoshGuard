Checks & Fixes
==============

Overview
--------
PoshGuard detects and fixes common PowerShell issues across four categories:
- Security — secrets, credential handling, dangerous patterns
- Best Practices — naming, parameters, scoping, usage patterns
- Formatting — whitespace, aliases, casing, output
- Advanced — manifests, encoding, platform compatibility

Examples
--------
```powershell
# Replace aliases with approved cmdlet names
gci -Path .      # before
Get-ChildItem .  # after

# Replace Write-Host with Write-Information
Write-Host "Hello"                         # before
Write-Information "Hello" -InformationAction Continue  # after

# Enforce SecureString for credentials
param([string]$Password)   # before
param([SecureString]$Password)  # after
```

How it works
------------
1) Detect with PSScriptAnalyzer → 2) Parse AST → 3) Transform → 4) Validate → 5) Report/apply

Notes
-----
- See `samples/` to review before/after diffs.
- Use `-DryRun -ShowDiff` to preview changes.
- Security rules prefer hardening over suppression; use `-Skip` sparingly with justification.

