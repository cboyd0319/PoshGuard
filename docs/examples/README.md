# PoshGuard Sample Scripts

This directory contains intentionally broken PowerShell scripts demonstrating common PSSA violations and their fixes.

## Files

### Security Issues

- **before-security-issues.ps1** - Script with 12 security and best practice violations
- **after-security-issues.ps1** - Expected output after PoshGuard auto-fix

Demonstrates fixes for:

- PSAvoidUsingPlainTextForPassword
- PSAvoidUsingConvertToSecureStringWithPlainText
- PSAvoidUsingComputerNameHardcoded
- PSAvoidUsingCmdletAliases
- PSAvoidUsingWriteHost
- PSAvoidUsingInvokeExpression
- PSAvoidGlobalVars
- PSAvoidUsingPositionalParameters
- PSAvoidUsingDoubleQuotesForConstantString
- PSAvoidSemicolonsAsLineTerminators
- PSAvoidTrailingWhitespace
- PSAvoidUsingEmptyCatchBlock

### Formatting Issues

- **before-formatting.ps1** - Script with formatting violations

Demonstrates fixes for:

- PSPlaceOpenBrace
- PSPlaceCloseBrace
- PSUseConsistentIndentation
- PSAlignAssignmentStatement
- PSUseCorrectCasing
- PSUseConsistentWhitespace
- PSProvideCommentHelp

## Usage

```powershell
# Run PoshGuard on samples (dry run)
../tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -DryRun

# Show unified diff
../tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -ShowDiff

# Apply fixes (creates .backup file)
../tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1
```

## Testing

The Pester tests reference these samples to ensure consistent fix behavior:

```powershell
# Run tests that validate sample fixes
Invoke-Pester -Path ../tests/
```

## Expected Diff Output

Run with `-ShowDiff` to see unified diff format showing exact changes made by PoshGuard.
