# Version Management Guide

This document defines the semantic versioning strategy and version synchronization process for PoshGuard.

## Current Version: 4.3.0

**Note**: As of 2025-10-13, no git tags exist yet. The first tag (v4.3.0) should be created using `tools/Create-Release.ps1`.

## Version Schema

PoshGuard follows [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

### Version Components

- **MAJOR**: Breaking changes or architectural shifts
  - Example: v3.0.0 → v4.0.0 (AI/ML capabilities added)
- **MINOR**: New features, significant enhancements, or new auto-fixes
  - Example: v4.2.0 → v4.3.0 (full AI/ML pipeline integration)
- **PATCH**: Bug fixes, minor improvements, documentation updates
  - Example: v4.3.0 → v4.3.1 (bug fix)

## Files That Must Be Synchronized

When releasing a new version, the following files **MUST** be updated to maintain consistency:

### 1. Core Version Files (REQUIRED)

| File | Location | Format | Example |
|------|----------|--------|---------|
| **VERSION.txt** | `PoshGuard/VERSION.txt` | `X.Y.Z` | `4.3.0` |
| **Module Manifest** | `PoshGuard/PoshGuard.psd1` | `ModuleVersion = 'X.Y.Z'` | `ModuleVersion = '4.3.0'` |
| **CHANGELOG.md** | `docs/CHANGELOG.md` | `## [X.Y.Z] - YYYY-MM-DD` | `## [4.3.0] - 2025-10-12` |

### 2. Documentation Files (REQUIRED)

| File | Location | Update Type |
|------|----------|-------------|
| **README.md** | `README.md` | Version badge (if applicable) |
| **ROADMAP.md** | `docs/ROADMAP.md` | Status line with current version |

### 3. Tool Scripts (RECOMMENDED)

| File | Location | Field | Example |
|------|----------|-------|---------|
| **Apply-AutoFix.ps1** | `tools/Apply-AutoFix.ps1` | `.NOTES Version:` | `Version: 4.3.0` |
| **Restore-Backup.ps1** | `tools/Restore-Backup.ps1` | `.NOTES Version:` | `Version: 4.3.0` |
| **Start-InteractiveTutorial.ps1** | `tools/Start-InteractiveTutorial.ps1` | `.NOTES Version:` | `Version: 4.3.0` |

### 4. Configuration & Asset Files (REQUIRED)

| File | Location | Field | Example |
|------|----------|-------|---------|
| **poshguard.json** | `config/poshguard.json` | `"version"` | `"version": "4.3.0"` |
| **latest.json** | `benchmarks/latest.json` | `"PoshGuardVersion"` | `"PoshGuardVersion": "4.3.0"` |
| **package.json** | `vscode-extension/package.json` | `"version"` | `"version": "4.3.0"` |
| **README.md examples** | `README.md` | Release filename in examples | `poshguard-4.3.0.zip` |

### 5. Library Modules (OPTIONAL)

Library modules (`tools/lib/*.psm1`) maintain their own independent version numbers based on when they were last updated. These do NOT need to match the main PoshGuard version.

## Version Update Process

### Step 1: Determine Version Number

Use semantic versioning rules:

```powershell
# Current: 4.3.0
# Breaking change → 5.0.0
# New feature → 4.4.0
# Bug fix → 4.3.1
```

### Step 2: Update Core Files

```powershell
$newVersion = "4.4.0"

# 1. Update VERSION.txt
Set-Content -Path "PoshGuard/VERSION.txt" -Value $newVersion -NoNewline

# 2. Update module manifest
$manifestPath = "PoshGuard/PoshGuard.psd1"
$content = Get-Content $manifestPath -Raw
$content = $content -replace "ModuleVersion\s*=\s*'[\d.]+?'", "ModuleVersion = '$newVersion'"
Set-Content -Path $manifestPath -Value $content

# 3. Test manifest
Test-ModuleManifest -Path $manifestPath
```

### Step 3: Update CHANGELOG.md

Add new version entry at the top (after "Unreleased"):

```markdown
## [Unreleased]

## [4.4.0] - 2025-10-15 - 🎯 FEATURE NAME

### Added
- New feature X
- Enhancement Y

### Changed
- Improved Z

### Fixed
- Bug fix A

### Breaking Changes
None / List any breaking changes

---

## [4.3.0] - 2025-10-12 - 🚀 FULL AI/ML INTEGRATION
...
```

### Step 4: Update Documentation

Update relevant docs with the new version where applicable:

- `docs/CHANGELOG.md` (see Step 3)
- `docs/ROADMAP.md` (status line with current version, if used)
- `README.md` (badges or examples referencing versioned artifacts, if any)

### Step 5: Update Tool Scripts

Update `.NOTES Version:` field in:

- `tools/Apply-AutoFix.ps1`
- `tools/Restore-Backup.ps1`
- `tools/Start-InteractiveTutorial.ps1`

### Step 6: Update Configuration & Asset Files

Update version fields in:

- `config/poshguard.json`: `"version": "4.4.0"`
- `benchmarks/latest.json`: `"PoshGuardVersion": "4.4.0"`
- `vscode-extension/package.json`: `"version": "4.4.0"`
- `README.md`: Update release filename in examples (e.g., `poshguard-4.4.0.zip`)

### Step 7: Create Release

```powershell
# Use the Create-Release.ps1 script
./tools/Create-Release.ps1 -Version 4.4.0

# The script will:
# ✓ Validate VERSION.txt matches
# ✓ Validate module manifest matches
# ✓ Extract changelog snippet
# ✓ Create annotated git tag
# ✓ Generate release package
```

### Step 8: Push Release (Optional)

```powershell
# Push tag to trigger release workflow
./tools/Create-Release.ps1 -Version 4.4.0 -Push

# Or manually:
git push origin v4.4.0
```

## Validation Checklist

Before creating a release, verify:

- [ ] VERSION.txt contains correct version
- [ ] PoshGuard.psd1 ModuleVersion matches VERSION.txt
- [ ] CHANGELOG.md has entry for new version
- [ ] ROADMAP.md status line updated
- [ ] Tool scripts updated (Apply-AutoFix.ps1, Restore-Backup.ps1, Start-InteractiveTutorial.ps1)
- [ ] Configuration files updated (config/poshguard.json, benchmarks/latest.json)
- [ ] VS Code extension updated (vscode-extension/package.json)
- [ ] README.md examples updated with correct version
- [ ] Module manifest validates: `Test-ModuleManifest PoshGuard/PoshGuard.psd1`
- [ ] Git status is clean (or changes are committed)
- [ ] No existing tag with same version: `git tag -l v4.4.0`

## Automated Validation

The `Create-Release.ps1` script automatically validates:

1. **VERSION.txt match**: Compares file content with `-Version` parameter
2. **Module manifest match**: Uses `Test-ModuleManifest` to verify
3. **Tag uniqueness**: Checks if tag already exists
4. **Changelog snippet**: Extracts notes for git tag annotation

If any validation fails, the script will:

- Offer to update VERSION.txt automatically
- Offer to update module manifest automatically
- Abort if tag already exists (requires manual deletion)

## Common Issues and Solutions

### Issue: Version Mismatch

**Symptom**: VERSION.txt shows 4.3.0 but PoshGuard.psd1 shows 4.2.0

**Solution**: Run version sync check:

```powershell
$versionFile = Get-Content PoshGuard/VERSION.txt
$manifest = Test-ModuleManifest PoshGuard/PoshGuard.psd1
if ($versionFile.Trim() -ne $manifest.Version) {
    Write-Warning "Version mismatch detected!"
    Write-Host "VERSION.txt: $versionFile"
    Write-Host "Manifest: $($manifest.Version)"
}
```

### Issue: Missing CHANGELOG Entry

**Symptom**: CHANGELOG.md doesn't have entry for current version

**Solution**: Add entry manually following the format in Step 3

### Issue: Tag Already Exists

**Symptom**: `git tag -a v4.4.0` fails with "already exists"

**Solution**: Delete old tag (if appropriate):

```powershell
# Delete local tag
git tag -d v4.4.0

# Delete remote tag (if pushed)
git push origin :refs/tags/v4.4.0
```

## Version History

| Version | Date | Type | Description |
|---------|------|------|-------------|
| 4.3.0 | 2025-10-12 | Minor | Full AI/ML pipeline integration |
| 4.2.0 | 2025-10-12 | Minor | Reinforcement learning, entropy detection, SBOM, NIST compliance |
| 4.1.0 | 2025-10-12 | Minor | Enhanced AI/ML capabilities |
| 4.0.0 | 2025-10-12 | Major | AI/ML integration, 25+ standards compliance |
| 3.3.0 | 2025-10-12 | Minor | Enhanced detection and metrics |
| 3.2.0 | 2025-10-12 | Minor | Advanced features |
| 3.1.0 | 2025-10-12 | Minor | World-class engineering standards |
| 3.0.0 | 2025-10-11 | Major | Production release, 60/60 PSSA rules |

## Best Practices

1. **Never skip versions**: Always increment sequentially (4.3.0 → 4.4.0, not 4.3.0 → 4.5.0)
2. **Update CHANGELOG first**: Write changelog entry before updating version numbers
3. **Test manifest**: Always run `Test-ModuleManifest` after updating PoshGuard.psd1
4. **Use Create-Release.ps1**: Automates validation and reduces human error
5. **Document breaking changes**: Clearly mark any breaking changes in CHANGELOG
6. **Tag releases**: Always create git tags for releases (enables GitHub releases)
7. **Keep history**: Don't delete old CHANGELOG entries or version references

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)
- PoshGuard `tools/Create-Release.ps1` script
- PoshGuard `docs/CHANGELOG.md`

---

**Created**: 2025-10-13  
**Last Updated**: 2025-10-13  
**Maintainer**: PoshGuard Team
