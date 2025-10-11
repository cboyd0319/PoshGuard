# How PoshGuard Works

PoshGuard uses Abstract Syntax Tree (AST) transformations to safely rewrite PowerShell code. This document explains the core mechanics with concrete examples.

## Rule → Fix Mapping

Each PSScriptAnalyzer rule maps to a specific AST transformation pattern. Here's how:

### Example 1: PSAvoidUsingCmdletAliases

**Rule**: Replace PowerShell aliases with full cmdlet names for clarity and compatibility.

**AST Pattern Detection**:
```powershell
# Input code
$files = gci C:\Temp | ? { $_.Length -gt 1MB }
```

**AST Structure**:
```
PipelineAst
├── CommandAst: "gci" (alias detected)
│   └── CommandParameter: "C:\Temp"
└── CommandAst: "?"  (alias detected)
    └── ScriptBlock: { $_.Length -gt 1MB }
```

**Transformation Logic**:
1. Parse script into AST using `[System.Management.Automation.Language.Parser]::ParseFile()`
2. Invoke PSScriptAnalyzer to find alias violations
3. For each violation, locate the CommandAst node
4. Resolve alias to full cmdlet name via `Get-Alias`
5. Replace CommandAst.CommandElements[0] with full cmdlet name
6. Preserve all parameters and pipeline structure

**Output Code**:
```powershell
# Fixed code
$files = Get-ChildItem C:\Temp | Where-Object { $_.Length -gt 1MB }
```

**Before/After Diff**:
```diff
--- before
+++ after
@@ -1 +1 @@
-$files = gci C:\Temp | ? { $_.Length -gt 1MB }
+$files = Get-ChildItem C:\Temp | Where-Object { $_.Length -gt 1MB }
```

---

### Example 2: PSAvoidUsingPlainTextForPassword

**Rule**: Replace plain text password parameters with SecureString type.

**AST Pattern Detection**:
```powershell
# Input code
function Connect-Server {
    param(
        [string]$Username,
        [string]$Password
    )
}
```

**AST Structure**:
```
FunctionDefinitionAst: "Connect-Server"
└── ParamBlockAst
    ├── ParameterAst: $Username
    │   └── TypeConstraintAst: [string]
    └── ParameterAst: $Password (name contains "Password")
        └── TypeConstraintAst: [string] (plain text type)
```

**Transformation Logic**:
1. Detect parameter with name matching `*Password*`, `*Pwd*`, `*Pass*`
2. Check if type is `[string]` (plain text)
3. Replace TypeConstraintAst with `[SecureString]`
4. Update any `ConvertTo-SecureString -AsPlainText` calls that use this parameter
5. Add comment indicating the security improvement

**Output Code**:
```powershell
# Fixed code
function Connect-Server {
    param(
        [string]$Username,
        [SecureString]$Password  # Fixed: PSAvoidUsingPlainTextForPassword
    )
}
```

**Before/After Diff**:
```diff
--- before
+++ after
@@ -2,6 +2,6 @@
 function Connect-Server {
     param(
         [string]$Username,
-        [string]$Password
+        [SecureString]$Password  # Fixed: PSAvoidUsingPlainTextForPassword
     )
 }
```

---

### Example 3: PSAvoidUsingEmptyCatchBlock

**Rule**: Add error handling to empty catch blocks.

**AST Pattern Detection**:
```powershell
# Input code
try {
    Remove-Item "C:\temp\file.txt"
}
catch {
}
```

**AST Structure**:
```
TryStatementAst
├── StatementBlockAst (try body)
│   └── CommandAst: Remove-Item
└── CatchClauseAst
    └── StatementBlockAst (empty - 0 statements)
```

**Transformation Logic**:
1. Find TryStatementAst nodes
2. Iterate through CatchClauseAst children
3. Check if StatementBlockAst.Statements.Count == 0
4. Insert default error handling:
   - For scripts: `Write-Error $_`
   - For functions with `-WhatIf`: `Write-Error $_ -ErrorAction Stop`
5. Preserve catch type constraints if specified

**Output Code**:
```powershell
# Fixed code
try {
    Remove-Item 'C:\temp\file.txt'
}
catch {
    Write-Error "Caught exception: $_"
}
```

**Before/After Diff**:
```diff
--- before
+++ after
@@ -3,4 +3,5 @@
     Remove-Item "C:\temp\file.txt"
 }
 catch {
+    Write-Error "Caught exception: $_"
 }
```

---

## Core Transform Pipeline

Every fix follows this pipeline:

```
┌─────────────────┐
│  Input Script   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Parse to AST   │  [System.Management.Automation.Language.Parser]::ParseFile()
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Run PSSA Scan  │  Invoke-ScriptAnalyzer -Path $script
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Match AST Nodes │  Correlate PSSA violations to specific AST nodes
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Transform AST  │  Apply rule-specific fix logic
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Validate Fix   │  Re-parse to ensure syntax remains valid
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Write Output   │  Generate fixed script with backup
└─────────────────┘
```

## AST Navigation Helpers

PoshGuard includes utilities for common AST operations:

### Find Nodes by Type
```powershell
function Find-AstNode {
    param(
        [System.Management.Automation.Language.Ast]$Ast,
        [type]$NodeType
    )
    $Ast.FindAll({ param($node) $node -is $NodeType }, $true)
}

# Usage
$commandNodes = Find-AstNode -Ast $scriptAst -NodeType ([CommandAst])
```

### Get Node Context
```powershell
function Get-NodeContext {
    param([Ast]$Node)
    @{
        Line = $Node.Extent.StartLineNumber
        Column = $Node.Extent.StartColumnNumber
        Text = $Node.Extent.Text
        File = $Node.Extent.File
    }
}
```

### Replace Node Text
```powershell
function Update-NodeText {
    param(
        [string]$OriginalScript,
        [Ast]$Node,
        [string]$NewText
    )
    $before = $OriginalScript.Substring(0, $Node.Extent.StartOffset)
    $after = $OriginalScript.Substring($Node.Extent.EndOffset)
    return $before + $NewText + $after
}
```

## Safety Guarantees

PoshGuard ensures safe transformations through:

1. **Parse Validation**: Every fix re-parses the output to ensure syntactic correctness
2. **Atomic Writes**: File writes are atomic - either full success or full rollback
3. **Backup Creation**: Original files backed up to `.backup/` with timestamp
4. **Idempotency**: Running the same fix twice produces identical results
5. **Extent Preservation**: Comments, whitespace, and formatting preserved where possible

## Performance Characteristics

| Operation | Complexity | Typical Time (per file) |
|-----------|-----------|-------------------------|
| AST Parsing | O(n) | 50-200ms |
| PSSA Scan | O(n) | 100-500ms |
| Node Matching | O(m) | 10-50ms |
| Transformation | O(m) | 50-200ms |
| Validation | O(n) | 50-200ms |

Where:
- `n` = lines of code in script
- `m` = number of violations detected

**Total per-file**: 260ms - 1,150ms for typical scripts (<500 lines)

## Adding Custom Rules

To add a new rule fix:

1. **Implement detection** in corresponding module (Security.psm1, BestPractices.psm1, etc.)
2. **Define transformation** using AST pattern matching
3. **Add validation** to ensure fix correctness
4. **Write tests** with before/after samples
5. **Update coverage** in README.md

Example template:
```powershell
function Fix-CustomRule {
    param(
        [string]$FilePath,
        [PSCustomObject[]]$Violations
    )
    
    $ast = [Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)
    $content = Get-Content $FilePath -Raw
    
    foreach ($violation in $Violations) {
        # 1. Locate AST node
        $node = Find-NodeAtLine -Ast $ast -Line $violation.Line
        
        # 2. Apply transformation
        $newText = Transform-Node -Node $node
        
        # 3. Update content
        $content = Update-NodeText -Original $content -Node $node -New $newText
    }
    
    # 4. Validate and write
    Test-SyntaxValid -Content $content
    Set-Content $FilePath -Value $content
}
```

## Further Reading

- [PowerShell AST Documentation](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.ast)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/docs/Rules)
- [Abstract Syntax Trees Explained](https://en.wikipedia.org/wiki/Abstract_syntax_tree)
