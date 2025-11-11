# Contributing to PoshGuard

Thanks for helping make PoshGuard better! We welcome contributions of all kinds: bug fixes, new features, documentation improvements, and test additions.

## Development Setup

### Prerequisites
- PowerShell 7.0+ (cross-platform)
- Pester 5.0+ for testing: `Install-Module Pester -Force -SkipPublisherCheck`
- PSScriptAnalyzer: `Install-Module PSScriptAnalyzer -Force`
- Git for version control

### Clone and Setup

```powershell
# Clone repository
git clone https://github.com/cboyd0319/PoshGuard.git
cd PoshGuard

# Run tests to verify setup
Invoke-Pester -Path ./tests/Unit -Output Detailed

# Run PoshGuard on itself (dogfooding)
./tools/Apply-AutoFix.ps1 -Path ./tools -ShowDiff -DryRun
```

### Documentation Tooling (Optional)

```bash
# Markdown linting
npm i -g markdownlint-cli
markdownlint "**/*.md"

# Vale style checking
pip install vale
vale .

# Link validation
npx linkinator README.md docs/**/*.md
```

## Code Structure

### Module Organization
```
tools/lib/
├── Core.psm1                    # Core helper functions
├── Security.psm1                # Security-focused fixes
├── ASTHelper.psm1              # ✨ NEW: Reusable AST operations
├── Constants.psm1              # ✨ NEW: Centralized configuration
├── ASTCache.psm1               # ✨ NEW: Performance caching
├── Advanced/                    # Advanced fix modules
├── BestPractices/              # Best practice fixes
└── Formatting/                  # Code formatting fixes
```

### Infrastructure Modules

#### ASTHelper.psm1 (Refactoring Pattern)
All new AST-based fix functions should use ASTHelper for consistency:

```powershell
function Invoke-MyFix {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter()]
    [string]$FilePath = ''
  )

  # Use ASTHelper instead of direct Parser::ParseInput
  Invoke-ASTBasedFix `
    -Content $Content `
    -FixName 'MyFix' `
    -FilePath $FilePath `
    -ASTNodeFinder {
      param($ast)
      # Find nodes to transform
      $ast.FindAll({ param($node) ... }, $true)
    } `
    -NodeTransformer {
      param($node, $content)
      # Return replacement info or $null
      return @{
        Start = $node.Extent.StartOffset
        End = $node.Extent.EndOffset
        NewText = 'replacement'
      }
    }
}
```

**Benefits**: Consistent error handling, automatic validation, observability hooks, 60% less code

#### Constants.psm1 (No Magic Numbers)
Use constants instead of hardcoded values:

```powershell
# ❌ Bad: Magic numbers
$maxSize = 50
$threshold = 4.5

# ✅ Good: Named constants
$maxSize = Get-PoshGuardConstant -Name 'MaxFunctionLength'
$threshold = Get-PoshGuardConstant -Name 'HighEntropyThreshold'
```

## Testing

### Running Tests

```powershell
# Run all tests
Invoke-Pester

# Run specific test suite
Invoke-Pester -Path ./tests/Unit/ASTHelper.Tests.ps1 -Output Detailed

# Run with code coverage
Invoke-Pester -CodeCoverage ./tools/lib/*.psm1 -Output Detailed
```

### Writing Tests

Follow the AAA pattern (Arrange-Act-Assert):

```powershell
Describe 'My Feature' -Tag 'Unit', 'MyFeature' {
  Context 'Specific Scenario' {
    It 'Should do something' {
      # Arrange
      $input = 'test input'

      # Act
      $result = Invoke-MyFunction -Input $input

      # Assert
      $result | Should -Be 'expected output'
    }
  }
}
```

**Coverage Target**: 90%+ for new code

## Linting & Quality

### PowerShell Script Analyzer

```powershell
# Run PSScriptAnalyzer on your changes
Invoke-ScriptAnalyzer -Path ./tools/lib/MyModule.psm1 -Recurse

# Use PoshGuard on itself
./tools/Apply-AutoFix.ps1 -Path ./tools/lib/MyModule.psm1 -ShowDiff
```

### Code Style
- Use approved PowerShell verbs: `Get-Verb`
- Follow PascalCase for functions: `Invoke-MyFix`
- Use full cmdlet names (no aliases)
- Add comprehensive comment-based help
- Include [CmdletBinding()] and [OutputType()]

### Documentation
- Update README.md for user-facing features
- Update DOCUMENTATION_INDEX.md for new docs
- Add inline comments for complex logic
- Include .EXAMPLE in function help

## Commit style

- Conventional commits preferred: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`
- Keep PRs narrowly scoped. Include before/after evidence (logs, screenshots).

## PR checklist

- [ ] Quickstart works on a clean machine
- [ ] Updated README/config tables as needed
- [ ] Added/updated tests
- [ ] Security implications noted (secrets/permissions)
- [ ] Links valid, badges green
- [ ] Docs lint-clean (markdownlint, vale)

## Releasing

- Tag with SemVer (`vX.Y.Z`)
- Publish artifacts + SBOM (SPDX)
- Sign release (Sigstore/cosign); attach provenance/SLSA if available
