# PoshGuard Advanced Module Architecture

## Overview

The Advanced module category contains complex AST-based PowerShell code analysis and transformation functions. This directory contains focused submodules organized by functional cohesion.

## Module Structure

```
Advanced/
├── ASTTransformations.psm1      (484 lines) - AST code transformations
├── AttributeManagement.psm1     (413 lines) - Function attribute management
├── ParameterManagement.psm1     (478 lines) - Parameter validation & cleanup
├── CodeAnalysis.psm1            (255 lines) - Code safety & analysis
└── Documentation.psm1           (219 lines) - Help & documentation generation
```

**Total:** 1,849 lines across 5 focused modules (down from 1,739 lines in monolithic module)

## Submodules

### 1. ASTTransformations.psm1
**Purpose:** Complex AST-based code transformations requiring deep parsing

**Functions:**
- `Invoke-WmiToCimFix` - Converts deprecated WMI cmdlets to CIM cmdlets
- `Invoke-BrokenHashAlgorithmFix` - Replaces MD5/SHA1 with SHA256
- `Invoke-LongLinesFix` - Wraps long lines intelligently

**Use Cases:**
- Modernizing legacy PowerShell code
- Security compliance (replacing weak cryptography)
- Code readability improvements

---

### 2. AttributeManagement.psm1
**Purpose:** Manages PowerShell function attributes and decorators

**Functions:**
- `Invoke-SupportsShouldProcessFix` - Adds SupportsShouldProcess to CmdletBinding
- `Invoke-ShouldProcessForStateChangingFix` - Detects state-changing functions
- `Invoke-CmdletCorrectlyFix` - Adds [CmdletBinding()] where needed
- `Invoke-ProcessBlockForPipelineFix` - Adds process{} for pipeline functions

**Use Cases:**
- PowerShell advanced function compliance
- WhatIf/Confirm support
- Pipeline processing correctness

---

### 3. ParameterManagement.psm1
**Purpose:** Parameter validation, typing, and cleanup

**Functions:**
- `Invoke-ReservedParamsFix` - Renames reserved parameter names
- `Invoke-SwitchParameterDefaultFix` - Removes switch parameter defaults
- `Invoke-UnusedParameterFix` - Comments out unused parameters
- `Invoke-NullHelpMessageFix` - Fixes empty HelpMessage attributes

**Use Cases:**
- Parameter naming conflicts
- Dead code removal
- Parameter validation

---

### 4. CodeAnalysis.psm1
**Purpose:** Code safety analysis and improvements

**Functions:**
- `Invoke-SafetyFix` - Adds -ErrorAction Stop to I/O cmdlets
- `Invoke-DuplicateLineFix` - Removes duplicate consecutive lines
- `Invoke-CmdletParameterFix` - Fixes Write-Output → Write-Host for colors

**Use Cases:**
- Error handling improvements
- Code deduplication
- Runtime error prevention

---

### 5. Documentation.psm1
**Purpose:** Generate and improve PowerShell documentation

**Functions:**
- `Invoke-CommentHelpFix` - Adds comment-based help templates
- `Invoke-OutputTypeCorrectlyFix` - Suggests [OutputType()] attributes

**Use Cases:**
- Get-Help compliance
- IntelliSense improvements
- Type inference support

---

## Usage

### Direct Submodule Import
```powershell
# Import specific submodule
Import-Module ./tools/lib/Advanced/ASTTransformations.psm1

# Use functions
$code = 'Get-WmiObject -Class Win32_Process'
$fixed = Invoke-WmiToCimFix -Content $code
```

### Facade Module Import (Recommended)
```powershell
# Import all Advanced modules via facade
Import-Module ./tools/lib/Advanced.psm1

# All 16 functions are available
Get-Command -Module Advanced
```

## Design Principles

1. **Single Responsibility** - Each module has one clear purpose
2. **Functional Cohesion** - Related functions are grouped together
3. **Selective Loading** - Import only what you need for performance
4. **Backward Compatibility** - Facade module maintains existing API
5. **Discoverability** - Clear naming and logical organization

## Performance

- **Monolithic (old):** 1,739 lines loaded every import
- **Modular (new):** Average ~350 lines per submodule
- **Selective loading:** 75-80% reduction when using specific submodules
- **Facade loading:** Same as monolithic (backward compatible)

## Migration Guide

### Before (Monolithic)
```powershell
Import-Module ./tools/lib/Advanced.psm1
Invoke-WmiToCimFix -Content $code
```

### After (Same - Backward Compatible)
```powershell
Import-Module ./tools/lib/Advanced.psm1
Invoke-WmiToCimFix -Content $code
```

### After (Optimized - Selective Loading)
```powershell
Import-Module ./tools/lib/Advanced/ASTTransformations.psm1
Invoke-WmiToCimFix -Content $code
```

## Testing

All modules have been validated:
- ✅ Module loading (no errors)
- ✅ Function exports (all 16 functions)
- ✅ Function execution (WmiToCim, Safety, DuplicateLine)
- ✅ Backward compatibility (facade pattern)

## Future Enhancements

- Add Pester tests for each submodule
- Create module manifests (.psd1) for version control
- Add performance benchmarks
- Consider further splitting if modules exceed 500 lines

## Contributing

When adding new Advanced functions:
1. Determine which submodule fits best (functional cohesion)
2. If no fit, consider creating new submodule
3. Update facade module's `$FunctionsToExport` array
4. Add function to appropriate section in this README
5. Ensure module is imported in facade's `$SubModules` array

## Version History

- **v2.3.0** - Split Advanced.psm1 into 5 focused submodules
- **v2.2.x** - Monolithic Advanced.psm1 (1,739 lines)
