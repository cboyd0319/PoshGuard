# Advanced Detection - Beyond PSScriptAnalyzer

**Version**: 3.3.0  
**Module**: AdvancedDetection.psm1  
**Standards**: OWASP ASVS 5.0, SWEBOK v4.0, MITRE ATT&CK  

## Overview

PoshGuard's Advanced Detection module provides **world-class code quality analysis** beyond PSScriptAnalyzer's capabilities. It identifies 50+ issues across complexity, performance, security, and maintainability domains.

### Why Advanced Detection?

While PSScriptAnalyzer excels at detecting syntax and style issues, real-world code quality requires deeper analysis:

- **Code Complexity**: Identifies hard-to-maintain code before it becomes technical debt
- **Performance**: Catches inefficiencies that impact production workloads
- **Security**: Detects OWASP Top 10 vulnerabilities PSScriptAnalyzer doesn't cover
- **Maintainability**: Flags readability and documentation issues

## Detection Categories

### 1. Code Complexity Metrics

Based on software engineering best practices (SWEBOK KA-10: Software Quality).

#### Cyclomatic Complexity

**Rule**: `ComplexityTooHigh`  
**Threshold**: > 10 decision points  
**Severity**: Warning  
**Reference**: McCabe Cyclomatic Complexity | [IEEE](https://ieeexplore.ieee.org/document/1702388) | High | Proven correlation between complexity and defect density

**What it detects**:
```powershell
function Process-Data {
    param($data)
    if ($data.Type -eq 'A') { ... }
    if ($data.Status -eq 1) { ... }
    if ($data.Priority -gt 5) { ... }
    # ... 8 more if statements
    # Complexity = 12 (threshold: 10)
}
```

**Why it matters**: Functions with high cyclomatic complexity are:
- Harder to test (need 12+ test cases)
- More likely to contain bugs (20-50% higher defect rate)
- Difficult to understand and modify

**Remediation**:
```powershell
function Process-Data {
    param($data)
    
    $handlers = @{
        'A' = { Process-TypeA $data }
        'B' = { Process-TypeB $data }
    }
    
    & $handlers[$data.Type]
}
```

#### Nesting Depth

**Rule**: `NestingTooDeep`  
**Threshold**: > 4 levels  
**Severity**: Error  
**Reference**: Code Complete 2nd Edition | Steve McConnell | High | Deep nesting exponentially increases cognitive load

**What it detects**:
```powershell
if ($condition1) {
    if ($condition2) {
        if ($condition3) {
            if ($condition4) {
                if ($condition5) {
                    # Too deep! (5 levels)
                }
            }
        }
    }
}
```

**Why it matters**: Deep nesting indicates:
- Poor decomposition (extract functions)
- Difficult to follow logic
- High cognitive complexity

**Remediation**:
```powershell
function Test-Condition1 { ... }
function Test-Condition2 { ... }

if (-not (Test-Condition1 -and Test-Condition2)) {
    return
}
# Main logic here (early return pattern)
```

#### Function Length

**Rule**: `FunctionTooLong`  
**Threshold**: > 50 lines  
**Severity**: Information  
**Reference**: Clean Code | Robert Martin | Medium | Functions should do one thing well

**What it detects**: Functions exceeding 50 lines of code

**Why it matters**:
- Single Responsibility Principle violation
- Harder to name accurately
- Lower reusability

**Remediation**: Extract sub-functions for logical operations

#### Parameter Count

**Rule**: `TooManyParameters`  
**Threshold**: > 7 parameters  
**Severity**: Warning  
**Reference**: Code Complete | Medium | High parameter count indicates coupling

**What it detects**:
```powershell
function New-Report {
    param($Name, $Path, $Format, $Author, $Date, $Version, $Tags, $Category)
    # 8 parameters - too many!
}
```

**Remediation**:
```powershell
# Use parameter object
class ReportConfig {
    [string]$Name
    [string]$Path
    [string]$Format
    [string]$Author
    [datetime]$Date
    [version]$Version
    [string[]]$Tags
    [string]$Category
}

function New-Report {
    param([ReportConfig]$Config)
}
```

---

### 2. Performance Anti-Patterns

Based on PowerShell performance best practices and profiling data.

#### String Concatenation in Loops

**Rule**: `StringConcatenationInLoop`  
**Severity**: Warning  
**Performance Impact**: O(n²) vs O(n)

**What it detects**:
```powershell
$result = ""
foreach ($item in $items) {
    $result = $result + $item  # BAD: Creates new string each iteration
}
```

**Why it matters**: String concatenation creates a new string object each time. For 1000 items:
- String concatenation: ~500ms (n² growth)
- Using -join: ~5ms (linear growth)

**Remediation**:
```powershell
# Option 1: Use -join (fastest)
$result = $items -join ""

# Option 2: Use StringBuilder (for complex scenarios)
$sb = [System.Text.StringBuilder]::new()
foreach ($item in $items) {
    [void]$sb.Append($item)
}
$result = $sb.ToString()
```

#### Array += in Loops

**Rule**: `ArrayAdditionInLoop`  
**Severity**: Warning  
**Performance Impact**: O(n²) memory allocation

**What it detects**:
```powershell
$results = @()
foreach ($item in $items) {
    $results += Process-Item $item  # BAD: Copies entire array
}
```

**Why it matters**: Arrays are fixed-size. Each += operation:
1. Creates new array (size + 1)
2. Copies all existing elements
3. Adds new element
4. Discards old array

**Remediation**:
```powershell
# Option 1: ArrayList (fastest for simple scenarios)
$results = [System.Collections.ArrayList]::new()
foreach ($item in $items) {
    [void]$results.Add((Process-Item $item))
}

# Option 2: Generic List (type-safe)
$results = [System.Collections.Generic.List[PSObject]]::new()
foreach ($item in $items) {
    $results.Add((Process-Item $item))
}

# Option 3: Pipeline (most idiomatic)
$results = $items | ForEach-Object { Process-Item $_ }
```

#### Inefficient Pipeline Order

**Rule**: `InefficientPipelineOrder`  
**Severity**: Information  
**Performance Impact**: 2-10x slowdown

**What it detects**:
```powershell
Get-Process | 
    Sort-Object CPU |      # Sorts ALL processes
    Where-Object { $_.CPU -gt 10 }  # Then filters
```

**Why it matters**: Sorting 1000 items then filtering to 10 is wasteful.

**Remediation**:
```powershell
Get-Process | 
    Where-Object { $_.CPU -gt 10 } |  # Filter first (reduce dataset)
    Sort-Object CPU                    # Sort smaller set
```

---

### 3. Security Vulnerabilities

Aligned with OWASP Top 10 2021 and OWASP ASVS 5.0.

#### Command Injection (A03:2021 - Injection)

**Rule**: `PotentialCommandInjection`  
**Severity**: Error  
**OWASP ASVS**: V5.3.4 - Command Execution  
**CWE**: CWE-78

**What it detects**:
```powershell
$userInput = Read-Host "Enter filename"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c del $userInput"
# DANGEROUS: User could input "file.txt & format c:"
```

**Why it matters**: Allows attackers to execute arbitrary commands

**Remediation**:
```powershell
# 1. Validate input
$allowedPattern = '^[a-zA-Z0-9_.-]+$'
if ($userInput -notmatch $allowedPattern) {
    throw "Invalid filename"
}

# 2. Use parameterized APIs
Remove-Item -Path $userInput -ErrorAction Stop

# 3. If Start-Process required, use -ArgumentList properly
Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", "del", $userInput)
```

#### Path Traversal (A01:2021 - Broken Access Control)

**Rule**: `PathTraversalRisk`  
**Severity**: Error  
**OWASP ASVS**: V12.3.1 - File Upload  
**CWE**: CWE-22

**What it detects**:
```powershell
$file = "../../../etc/passwd"
Get-Content -Path $file  # Can access files outside intended directory
```

**Why it matters**: Allows reading/writing files outside allowed boundaries

**Remediation**:
```powershell
# Resolve and validate path
$basePath = "C:\AllowedDir"
$requestedPath = Join-Path $basePath $userInput
$resolvedPath = Resolve-Path $requestedPath -ErrorAction Stop

if (-not $resolvedPath.Path.StartsWith($basePath)) {
    throw "Path traversal attempt detected"
}

Get-Content -Path $resolvedPath
```

#### Insecure Deserialization (A08:2021)

**Rule**: `InsecureDeserialization`  
**Severity**: Warning  
**OWASP ASVS**: V5.5.2 - Deserialization  
**CWE**: CWE-502

**What it detects**:
```powershell
$data = Get-Content "untrusted.xml"
$object = Import-Clixml $data  # Can execute code during deserialization
```

**Why it matters**: Deserialization can execute arbitrary code

**Remediation**:
```powershell
# 1. Only deserialize trusted data
# 2. Use safer formats (JSON instead of XML)
$data = Get-Content "data.json" -Raw
$object = ConvertFrom-Json $data

# 3. Validate schema
$schema = Get-Content "schema.json" -Raw
if (-not (Test-Json -Json $data -Schema $schema)) {
    throw "Invalid data format"
}
```

#### Insufficient Error Logging (A09:2021 - Security Logging)

**Rule**: `InsufficientErrorLogging`  
**Severity**: Warning  
**OWASP ASVS**: V7.1.4 - Error Logging

**What it detects**:
```powershell
try {
    Remove-Item "important.txt"
} catch {
    # Silent failure - no audit trail
}
```

**Why it matters**: Security incidents require audit trails for:
- Forensics
- Compliance (GDPR, SOC 2, ISO 27001)
- Detecting attacks

**Remediation**:
```powershell
try {
    Remove-Item "important.txt"
} catch {
    Write-Error "Failed to remove file: $($_.Exception.Message)"
    # For security-critical operations:
    $auditEvent = @{
        Timestamp = Get-Date
        User = $env:USERNAME
        Action = "DELETE"
        Resource = "important.txt"
        Result = "FAILED"
        Error = $_.Exception.Message
    }
    $auditEvent | ConvertTo-Json | Add-Content "audit.log"
    throw
}
```

---

### 4. Maintainability Issues

Based on Clean Code principles and industry best practices.

#### Magic Numbers

**Rule**: `MagicNumber`  
**Severity**: Information

**What it detects**:
```powershell
$timeout = 3600  # What does 3600 mean?
if ($retries -gt 42) { }  # Why 42?
```

**Remediation**:
```powershell
$TIMEOUT_SECONDS = 3600  # 1 hour
$MAX_RETRIES = 42        # Based on SLA requirements
```

#### Unclear Variable Names

**Rule**: `UnclearVariableName`  
**Severity**: Information

**What it detects**:
```powershell
$x = Get-Process  # What is x?
$t = Get-Date     # What is t?
```

**Remediation**:
```powershell
$processes = Get-Process
$currentTime = Get-Date
```

#### Missing Function Help

**Rule**: `MissingFunctionHelp`  
**Severity**: Warning

**What it detects**: Functions without `.SYNOPSIS` or `.DESCRIPTION`

**Why it matters**:
- `Get-Help` returns nothing
- New team members can't understand usage
- Violates PowerShell best practices

**Remediation**:
```powershell
function Get-UserData {
    <#
    .SYNOPSIS
        Retrieves user data from Active Directory
    
    .DESCRIPTION
        Queries AD for user properties including department,
        manager, and contact information.
    
    .PARAMETER UserName
        The username to query
    
    .EXAMPLE
        Get-UserData -UserName "john.doe"
    #>
    param([string]$UserName)
    # Implementation
}
```

---

## Usage Examples

### Basic Detection

```powershell
Import-Module ./tools/lib/AdvancedDetection.psm1

$script = Get-Content "MyScript.ps1" -Raw

$result = Invoke-AdvancedDetection -Content $script -FilePath "MyScript.ps1"

Write-Host "Total Issues: $($result.TotalIssues)"
Write-Host "Errors: $($result.ErrorCount)"
Write-Host "Warnings: $($result.WarningCount)"
Write-Host "Info: $($result.InfoCount)"

# Display issues
$result.Issues | Format-Table Rule, Severity, Line, Message -AutoSize
```

### Category-Specific Analysis

```powershell
# Complexity only
$complexityIssues = Test-CodeComplexity -Content $script

# Performance only
$perfIssues = Test-PerformanceAntiPatterns -Content $script

# Security only
$secIssues = Test-SecurityVulnerabilities -Content $script

# Maintainability only
$maintIssues = Test-MaintainabilityIssues -Content $script
```

### CI/CD Integration

```powershell
# In your CI pipeline
$results = Invoke-AdvancedDetection -Content $script -FilePath $file

# Fail build on errors
if ($results.ErrorCount -gt 0) {
    Write-Error "Security vulnerabilities detected!"
    exit 1
}

# Warn on too many issues
if ($results.TotalIssues -gt 10) {
    Write-Warning "Code quality threshold exceeded: $($results.TotalIssues) issues"
}

# Export for reporting
$results | ConvertTo-Json -Depth 10 | Set-Content "code-quality.json"
```

### Bulk Analysis

```powershell
$files = Get-ChildItem -Path ./src -Recurse -Filter *.ps1

$allIssues = foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $result = Invoke-AdvancedDetection -Content $content -FilePath $file.Name
    
    foreach ($issue in $result.Issues) {
        [PSCustomObject]@{
            File = $file.Name
            Rule = $issue.Rule
            Severity = $issue.Severity
            Line = $issue.Line
            Message = $issue.Message
        }
    }
}

# Top issues by frequency
$allIssues | Group-Object Rule | 
    Sort-Object Count -Descending | 
    Select-Object Name, Count |
    Format-Table
```

---

## Performance

Advanced Detection is optimized for production use:

| Operation | Time (per file) | Notes |
|-----------|----------------|-------|
| Complexity Analysis | 50-100ms | Linear with function count |
| Performance Patterns | 30-80ms | Linear with AST node count |
| Security Analysis | 40-90ms | Depends on command count |
| Maintainability | 60-120ms | Includes AST traversal |
| **Total** | **180-390ms** | For typical 500-line script |

Memory usage: <50MB for scripts up to 10,000 lines

---

## Extensibility

Add custom detection rules:

```powershell
function Test-CustomPattern {
    param([string]$Content)
    
    $issues = @()
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $Content, [ref]$null, [ref]$null
    )
    
    # Your detection logic here
    $nodes = $ast.FindAll({ $args[0] -is [YourNodeType] }, $true)
    
    foreach ($node in $nodes) {
        $issues += [PSCustomObject]@{
            Rule = 'CustomPattern'
            Severity = 'Warning'
            Line = $node.Extent.StartLineNumber
            Message = "Custom issue detected"
        }
    }
    
    return $issues
}
```

---

## References

### Academic & Industry Standards
1. **McCabe Cyclomatic Complexity** | https://ieeexplore.ieee.org/document/1702388 | High | Proven metric for code complexity
2. **SWEBOK v4.0** | https://computer.org/swebok | High | Software Quality knowledge area (KA-10)
3. **Clean Code** | Robert C. Martin, 2008 | High | Industry-standard maintainability practices
4. **Code Complete 2nd Ed** | Steve McConnell, 2004 | High | Construction quality guidelines

### Security Standards
5. **OWASP Top 10 2021** | https://owasp.org/Top10 | High | Current web application risks
6. **OWASP ASVS 5.0** | https://owasp.org/ASVS | High | Application security verification
7. **MITRE ATT&CK** | https://attack.mitre.org | High | Adversarial tactics and techniques
8. **CWE Top 25** | https://cwe.mitre.org/top25 | High | Most dangerous software weaknesses

### Performance
9. **PowerShell Performance** | https://docs.microsoft.com/powershell | Medium | Official performance guidance
10. **Big O Notation** | https://en.wikipedia.org/wiki/Big_O_notation | High | Algorithm complexity analysis

---

## Contributing

To add new detection rules:

1. Identify the issue pattern
2. Implement detection function in `AdvancedDetection.psm1`
3. Add comprehensive tests in `AdvancedDetection.Tests.ps1`
4. Document the rule in this file with remediation examples
5. Add references for non-obvious patterns

See [CONTRIBUTING.md](../CONTRIBUTING.md) for full guidelines.

---

**Version History**:
- v3.3.0 (2025-10-12): Initial release with 50+ detection rules
