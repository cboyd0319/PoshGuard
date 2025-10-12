# PoshGuard Library Modules

This directory contains the modular PowerShell libraries that power PoshGuard's auto-fix engine.

## Architecture Overview

PoshGuard uses a **facade pattern** with specialized modules:

```
lib/
├── Core.psm1                    # Foundation utilities (logging, backups, diffs)
├── Security.psm1                # Security vulnerability fixes (8 rules)
├── BestPractices.psm1           # Coding standards (28 rules across 6 submodules)
├── Formatting.psm1              # Code formatting (11 rules across 6 submodules)
├── Advanced.psm1                # Complex AST transformations (24 rules across 9 submodules)
├── BestPractices/               # Best practices submodules
│   ├── Syntax.psm1
│   ├── Naming.psm1
│   ├── Scoping.psm1
│   ├── StringHandling.psm1
│   ├── TypeSafety.psm1
│   └── UsagePatterns.psm1
├── Formatting/                  # Formatting submodules
│   ├── Whitespace.psm1
│   ├── Aliases.psm1
│   ├── Casing.psm1
│   ├── Output.psm1
│   ├── Alignment.psm1
│   └── Runspaces.psm1
└── Advanced/                    # Advanced submodules
    ├── ASTTransformations.psm1
    ├── ParameterManagement.psm1
    ├── CodeAnalysis.psm1
    ├── Documentation.psm1
    ├── AttributeManagement.psm1
    ├── ManifestManagement.psm1
    ├── CompatibleCmdletsWarning.psm1
    ├── DefaultValueForMandatoryParameter.psm1
    └── UTF8EncodingForHelpFile.psm1
```

## Module Descriptions

### Core.psm1
**Foundation utilities used across all modules**

Functions:
- `Clean-Backups` - Cleanup old backup files
- `Write-Log` - Structured logging with color-coded output
- `Get-PowerShellFiles` - Discover PowerShell files recursively
- `New-FileBackup` - Create timestamped backups
- `New-UnifiedDiff` - Generate unified diff format

### Security.psm1
**Security vulnerability fixes (100% PSSA security coverage)**

Functions:
- `Invoke-PlainTextPasswordFix` - Fix plaintext password parameters
- `Invoke-ConvertToSecureStringFix` - Fix insecure ConvertTo-SecureString usage
- `Invoke-UsernamePasswordParamsFix` - Replace Username/Password with PSCredential
- `Invoke-AllowUnencryptedAuthFix` - Fix unencrypted authentication
- `Invoke-HardcodedComputerNameFix` - Parameterize hardcoded computer names
- `Invoke-InvokeExpressionFix` - Replace Invoke-Expression with safer alternatives
- `Invoke-EmptyCatchBlockFix` - Add error handling to empty catch blocks
- `Invoke-BrokenHashAlgorithmFix` - Replace MD5/SHA1 with SHA256

### BestPractices.psm1
**PowerShell coding standards (facade for 6 submodules)**

Submodules:
- **Syntax.psm1** - Language-level fixes (semicolons, null comparisons, operators)
- **Naming.psm1** - Identifier conventions (verbs, singular nouns, characters)
- **Scoping.psm1** - Namespace management (global vars, function scoping)
- **StringHandling.psm1** - Literal syntax (quotes, hashtables, backticks)
- **TypeSafety.psm1** - Type system usage (attributes, null checks, PSCredential)
- **UsagePatterns.psm1** - Code smell detection (positional params, unused vars)

Total: 28 functions across 6 focused modules

### Formatting.psm1
**Code formatting and style (facade for 6 submodules)**

Submodules:
- **Whitespace.psm1** - Indentation, consistency, trailing spaces
- **Aliases.psm1** - Cmdlet aliases, global aliases
- **Casing.psm1** - Cmdlet/parameter casing
- **Output.psm1** - Write-Host to Write-Information conversion
- **Alignment.psm1** - Assignment statement alignment
- **Runspaces.psm1** - Runspace pool management

Total: 11 functions across 6 focused modules

### Advanced.psm1
**Complex AST-based transformations (facade for 9 submodules)**

Submodules:
- **ASTTransformations.psm1** - Pipeline processing, long line wrapping, WMI to CIM
- **ParameterManagement.psm1** - Mandatory params, switch defaults, unused params
- **CodeAnalysis.psm1** - Empty members, built-in cmdlets
- **Documentation.psm1** - Comment help, BOM encoding
- **AttributeManagement.psm1** - Output types, DSC functions
- **ManifestManagement.psm1** - Exports, missing fields, deprecated fields
- **CompatibleCmdletsWarning.psm1** - Platform compatibility warnings
- **DefaultValueForMandatoryParameter.psm1** - Parameter validation
- **UTF8EncodingForHelpFile.psm1** - Help file encoding fixes
- **ShouldProcessTransformation.psm1** - Full ShouldProcess implementation (hardest fix!)
- **InvokingEmptyMembers.psm1** - Detect empty member invocations
- **OverwritingBuiltInCmdlets.psm1** - Prevent shadowing built-in cmdlets
- **DeprecatedManifestFields.psm1** - Remove deprecated manifest fields
- **CmdletBindingFix.psm1** - Add/fix CmdletBinding attributes

Total: 24 functions across 9 focused modules

## Design Principles

### 1. Single Responsibility
Each module/submodule focuses on one specific category of fixes.

### 2. Facade Pattern
Top-level modules (BestPractices, Formatting, Advanced) act as facades that import and re-export submodules.

### 3. Load-on-Demand
Import specific submodules for faster load times when you only need certain fixes.

### 4. Zero Dependencies
All modules work independently with only PowerShell 5.1+ built-ins (except PSScriptAnalyzer requirement).

### 5. Idempotent Fixes
All fix functions can be run multiple times safely - they won't introduce errors on subsequent runs.

## Usage Examples

### Import All Modules
```powershell
Import-Module ./Core.psm1
Import-Module ./Security.psm1
Import-Module ./BestPractices.psm1
Import-Module ./Formatting.psm1
Import-Module ./Advanced.psm1
```

### Import Specific Submodule
```powershell
# Just need syntax fixes
Import-Module ./BestPractices/Syntax.psm1

# Just need security fixes
Import-Module ./Security.psm1
```

### Use in Script
```powershell
# Import Core for logging
Import-Module ./Core.psm1

$scriptContent = Get-Content ./MyScript.ps1 -Raw

# Apply security fixes
Import-Module ./Security.psm1
$fixed = Invoke-PlainTextPasswordFix -Content $scriptContent
$fixed = Invoke-InvokeExpressionFix -Content $fixed

# Apply formatting fixes
Import-Module ./Formatting/Whitespace.psm1
$fixed = Invoke-WhitespaceFix -Content $fixed

# Save result
Set-Content ./MyScript.ps1 -Value $fixed
```

## Testing

Each module is tested via:
1. **Unit tests** - In `/tests/Phase2-AutoFix.Tests.ps1`
2. **Integration tests** - Via `Apply-AutoFix.ps1` on sample files
3. **Benchmarks** - See `/docs/benchmarks.md`

Run tests:
```powershell
Invoke-Pester -Path ../tests/
```

## Performance

- **Facade modules**: 75-80% faster than monolithic approach
- **Submodules**: Load only what you need, minimal memory footprint
- **AST caching**: Parse once, transform multiple times

## Coverage

**Total: 71 PSScriptAnalyzer rules covered**
- Security: 8 rules (100% coverage)
- Best Practices: 28 rules
- Formatting: 11 rules
- Advanced: 24 rules

See `/docs/ARCHITECTURE.md` for detailed rule mappings.

## Contributing

When adding new fixes:

1. Choose the appropriate category (Security, BestPractices, Formatting, Advanced)
2. Create a new submodule if needed: `./Category/RuleName.psm1`
3. Implement `Invoke-{RuleName}Fix` function
4. Export from facade module
5. Add to `Apply-AutoFix.ps1` pipeline
6. Write tests in `/tests/`

See `/docs/CONTRIBUTING.md` for detailed guidelines.

## Version History

- **v3.0.0** - Modular architecture with 71 rule coverage
- **v2.16.0** - Split into 5 main modules
- **v2.4.0** - Submodule organization
- **v1.0.0** - Monolithic implementation

---

**Maintained by**: PoshGuard Contributors
**License**: See `/LICENSE`
**Documentation**: See `/docs/`
