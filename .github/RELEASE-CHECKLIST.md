# Release Checklist for PoshGuard

Use this checklist when preparing and publishing a new release.

## Pre-Release (1-2 days before)

### Code & Tests
- [ ] All tests pass locally (`Invoke-Pester -CI`)
- [ ] All CI checks pass on main branch
- [ ] No open critical bugs
- [ ] Code coverage maintained or improved
- [ ] Sample scripts tested with latest changes

### Documentation
- [ ] README.md updated with new features
- [ ] CHANGELOG.md updated with release notes
- [ ] VERSION.txt updated to new version
- [ ] PoshGuard.psd1 manifest version updated
- [ ] Breaking changes documented (if any)
- [ ] Migration guide provided (if breaking changes)

### Version Validation
- [ ] Semantic versioning followed (MAJOR.MINOR.PATCH)
- [ ] Version consistent across all files:
  - VERSION.txt
  - PoshGuard.psd1 (ModuleVersion)
  - CHANGELOG.md (heading)

## Release Day

### 1. Final Commit
```powershell
git add -A
git commit -m "chore: prepare v{VERSION} release"
git push origin main
```

### 2. Create Release Tag
```powershell
./tools/Create-Release.ps1 -Version {VERSION} -Push
```

### 3. Monitor Release Workflow
- [ ] Go to https://github.com/cboyd0319/PoshGuard/actions
- [ ] Verify release workflow completes successfully
- [ ] Check all jobs (lint, test, package, release) pass
- [ ] Verify artifacts uploaded (zip, SBOM)

### 4. Verify GitHub Release
- [ ] Go to https://github.com/cboyd0319/PoshGuard/releases
- [ ] Confirm new release appears
- [ ] Download and test release artifacts
- [ ] Verify changelog is included
- [ ] Check SBOM file is attached
- [ ] Ensure release is not marked as draft

### 5. PowerShell Gallery Publication
```powershell
# Test manifest
Test-ModuleManifest ./PoshGuard.psd1

# Publish to gallery
Publish-Module -Path . -NuGetApiKey $env:PSGALLERY_API_KEY -Verbose

# Verify published
Find-Module PoshGuard
```

### 6. Update Repository Settings (first release only)
- [ ] Upload social preview image (Settings → Social preview)
- [ ] Add repository topics
- [ ] Enable branch protection on main
- [ ] Enable code scanning
- [ ] Enable Dependabot

## Post-Release (same day)

### Verification
- [ ] Install from PowerShell Gallery works
  ```powershell
  Install-Module PoshGuard -Force
  Get-Command -Module PoshGuard
  ```
- [ ] Test basic functionality
  ```powershell
  Invoke-PoshGuard -Path ./samples/before-security-issues.ps1 -DryRun
  ```
- [ ] Badges in README show correct status
- [ ] Release appears in GitHub Releases tab
- [ ] Documentation links work

### Announcements
- [ ] Tweet/post on X with #PowerShell #DevOps
  ```
  🚀 PoshGuard v{VERSION} is live!
  
  ✅ {Key feature 1}
  ✅ {Key feature 2}
  ✅ {Key feature 3}
  
  Install: Install-Module PoshGuard
  
  https://github.com/cboyd0319/PoshGuard
  #PowerShell #DevOps #CodeQuality
  ```

- [ ] Post on Reddit r/PowerShell
  ```
  Title: PoshGuard v{VERSION} - {Brief description}
  
  Body:
  - What's new
  - Key improvements
  - Link to release notes
  - Installation instructions
  ```

- [ ] Post on LinkedIn (PowerShell groups)
- [ ] Update Dev.to blog (if applicable)
- [ ] Email notification to watchers (if list exists)

### Project Management
- [ ] Close milestone for this version
- [ ] Create milestone for next version
- [ ] Move completed issues to Done
- [ ] Review and prioritize backlog

## Post-Release (next few days)

### Monitor
- [ ] Check for new issues related to release
- [ ] Monitor PowerShell Gallery download stats
- [ ] Review community feedback
- [ ] Check for installation problems

### Documentation
- [ ] Update any external documentation
- [ ] Record demo video (if not done yet)
- [ ] Create blog post with examples
- [ ] Update comparison tables (vs other tools)

### Planning
- [ ] Review roadmap
- [ ] Plan next release features
- [ ] Update project board
- [ ] Schedule next release date

## Rollback Plan (if critical issues found)

If critical bugs are discovered:

1. **Immediate Action**
   ```powershell
   # Unlist from gallery (doesn't delete)
   Unlist-PSGalleryPackage -Name PoshGuard -Version {VERSION}
   ```

2. **Create Hotfix**
   - Branch from release tag: `git checkout -b hotfix/{VERSION}.1 v{VERSION}`
   - Fix critical issue
   - Test thoroughly
   - Release as {VERSION}.1

3. **Communication**
   - Post issue on GitHub
   - Tweet about known issue
   - Update release notes with known issues
   - Provide workaround if available

## Version Numbering Guide

Follow Semantic Versioning (semver.org):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
  - API changes that break existing code
  - Removed features
  - Fundamentally different behavior

- **MINOR** (1.0.0 → 1.1.0): New features, backwards compatible
  - New auto-fix rules
  - New command-line options
  - Performance improvements
  - New module functions

- **PATCH** (1.0.0 → 1.0.1): Bug fixes, backwards compatible
  - Fix existing auto-fix logic
  - Documentation corrections
  - Security patches
  - Dependency updates

## Release Cadence

Recommended schedule:

- **Major releases**: 6-12 months (breaking changes)
- **Minor releases**: 1-2 months (new features)
- **Patch releases**: As needed (bug fixes)
- **Security releases**: Immediately (security issues)

## Support Policy

- **Current version**: Full support
- **Previous minor**: Security fixes only
- **Older versions**: Community support only

## Quality Gates

Before any release:

- ✅ All tests passing
- ✅ No critical/high security alerts
- ✅ Code scanning passing
- ✅ Documentation complete
- ✅ CHANGELOG updated
- ✅ Manual testing completed
- ✅ Sample scripts validated

## Emergency Release Process

For critical security issues:

1. Create private security advisory
2. Develop fix in private fork
3. Test fix thoroughly
4. Coordinate disclosure timeline
5. Release patch immediately
6. Publish security advisory
7. Notify users via all channels

## Post-Mortem (after major releases)

Within 1 week:

- [ ] What went well?
- [ ] What could be improved?
- [ ] Were timelines realistic?
- [ ] Did we catch issues early enough?
- [ ] Update this checklist with lessons learned

---

**Last Updated**: 2025-10-11  
**Template Version**: 1.0
