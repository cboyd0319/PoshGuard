# PoshGuard v2.7.0 Release Notes

**Date:** October 11, 2025
**Coverage:** 54/70 rules (77%) - +3 rules from v2.6.0

## What's New

### Phase 6: Module Manifest & Alias Scoping

**3 New Auto-Fixes:**

1. **PSMissingModuleManifestField** - Adds `ModuleVersion = '1.0.0'` if missing
2. **PSUseToExportFieldsInManifest** - Replaces `*` → `@()` (performance)
3. **PSAvoidGlobalAliases** - Changes `Global` → `Script` scope

### New Module

- `tools/lib/Advanced/ManifestManagement.psm1` (3 functions, 250+ lines)

## Testing

- ✅ 5/5 tests passing
- ✅ 100% syntax validation
- ✅ Idempotent behavior confirmed

## Files Modified

- Apply-AutoFix.ps1 (v2.7.0, +3 fix calls)
- Advanced.psm1 (+ManifestManagement import)
- README.md (77% coverage)
- PSSA-RULES-AUTOFIX-ROADMAP.md (Phase 6 section)

## Upgrade Notes

- Zero breaking changes
- 100% backward compatible
- Drop-in replacement for v2.6.0

---

**Full Changelog:** v2.6.0...v2.7.0
