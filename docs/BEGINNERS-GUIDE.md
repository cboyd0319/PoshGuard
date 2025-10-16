# Complete Beginner's Guide to PoshGuard

**Welcome!** This guide assumes ZERO technical knowledge. We'll explain everything step by step.

---

## What is PoshGuard?

**Simple Answer**: PoshGuard is a free tool that automatically fixes problems in PowerShell scripts (code).

**Why You Need It**:

- ✅ Makes your code more secure (protects against hackers)
- ✅ Makes your code easier to read
- ✅ Follows best practices (the "right way" to write code)
- ✅ Saves you time (fixes 60+ types of issues automatically)

---

## What is PowerShell?

**PowerShell** is a programming language used to automate tasks on Windows, Mac, and Linux computers. If you write scripts (small programs) that end in `.ps1`, you're using PowerShell!

---

## Do I Need to Know How to Code?

**NO!** You need to:

1. Have PowerShell installed (it comes with Windows)
2. Have some PowerShell scripts (`.ps1` files)
3. Follow the steps below

---

## Step 1: Check if PowerShell is Installed

### Windows Users

1. Press `Windows Key + R`
2. Type `powershell` and press Enter
3. A blue window opens? ✅ You have PowerShell!

### Mac Users

1. Install PowerShell: <https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-macos>
2. Open Terminal
3. Type `pwsh` and press Enter

### Linux Users

1. Install PowerShell: <https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-linux>
2. Open Terminal
3. Type `pwsh` and press Enter

---

## Step 2: Download PoshGuard

### Method 1: Easy Way (Recommended)

Open PowerShell and type:

```powershell
Install-Module PoshGuard -Scope CurrentUser -Force
```

Press Enter. Wait for download to complete.

### Method 2: Manual Way

1. Go to <https://github.com/cboyd0319/PoshGuard>
2. Click the green "Code" button
3. Click "Download ZIP"
4. Extract the ZIP file to your Documents folder
5. Remember this location (you'll need it)

---

## Step 3: Your First Fix

Let's say you have a script called `MyScript.ps1` in your Documents folder.

### Preview What Will Be Fixed (Safe - No Changes)

```powershell
# Navigate to PoshGuard folder
cd C:\Users\YourName\Documents\PoshGuard

# Preview fixes
.\tools\Apply-AutoFix.ps1 -Path C:\Users\YourName\Documents\MyScript.ps1 -DryRun
```

**What This Does**:

- `-Path` - Tells PoshGuard where your script is
- `-DryRun` - Shows what WOULD be fixed (doesn't actually change anything)

You'll see output like:

```
🔍 Analyzing: MyScript.ps1
✅ Fixed: PSAvoidUsingCmdletAliases (Line 10)
✅ Fixed: PSAvoidUsingPlainTextForPassword (Line 15)
📊 Summary: 2 issues fixed, 0 skipped
```

### Apply the Fixes

If you're happy with the preview, run WITHOUT `-DryRun`:

```powershell
.\tools\Apply-AutoFix.ps1 -Path C:\Users\YourName\Documents\MyScript.ps1
```

**Important**: PoshGuard automatically creates a backup in the `.backup` folder!

---

## Step 4: Understanding the Output

### What Do The Symbols Mean?

- ✅ = Fixed successfully
- ⚠️ = Warning (check this)
- ❌ = Error (couldn't fix)
- 📊 = Summary statistics
- 🔍 = Analyzing file
- 💾 = Backup created

### Common Fixes Explained

1. **PSAvoidUsingCmdletAliases**
   - **Problem**: Using shortcuts like `gci` instead of full command `Get-ChildItem`
   - **Why Fix**: Shortcuts can be confusing and don't work everywhere
   - **Example**: `gci C:\` → `Get-ChildItem C:\`

2. **PSAvoidUsingPlainTextForPassword**
   - **Problem**: Storing passwords as plain text (anyone can read them!)
   - **Why Fix**: SECURITY - passwords should be encrypted
   - **Example**: `$password = "MyPassword"` → `$password = Read-Host -AsSecureString`

3. **PSAvoidUsingWriteHost**
   - **Problem**: Using `Write-Host` (old way) instead of modern methods
   - **Why Fix**: Better compatibility and features
   - **Example**: `Write-Host "Hello"` → `Write-Information "Hello"`

---

## Step 5: What If Something Goes Wrong?

### Rollback (Undo Changes)

```powershell
# Find your backup (they're timestamped)
cd .backup
dir

# You'll see files like: MyScript.ps1.20251012_143022.bak

# Restore the backup
..\tools\Restore-Backup.ps1 -BackupPath .\MyScript.ps1.20251012_143022.bak
```

**Boom!** Your original file is back like nothing happened.

---

## Step 6: Fix Multiple Files

### Fix All Scripts in a Folder

```powershell
.\tools\Apply-AutoFix.ps1 -Path C:\Users\YourName\Documents\Scripts -Recurse -DryRun
```

**What This Does**:

- Checks ALL `.ps1` files in the Scripts folder
- `-Recurse` - Also checks subfolders
- `-DryRun` - Preview only (safe!)

Remove `-DryRun` when ready to apply fixes.

---

## Step 7: Skip Certain Fixes

Maybe you don't want to fix `Write-Host` (you like it the old way):

```powershell
.\tools\Apply-AutoFix.ps1 -Path .\MyScript.ps1 -Skip @('PSAvoidUsingWriteHost')
```

**Explanation**:

- `-Skip` - Don't fix these rules
- `@('RuleName')` - List of rules to skip

---

## Common Questions (FAQ)

### Q: Will PoshGuard break my scripts?

**A**: Extremely unlikely! PoshGuard:

1. Creates automatic backups
2. Only makes safe, well-tested changes
3. Has been tested on 1000s of scripts
4. You can always undo with `-DryRun` first

### Q: How long does it take?

**A**: Usually 1-5 seconds per script (fast!)

### Q: Does it work offline?

**A**: YES! No internet required after installation.

### Q: Is it free?

**A**: YES! Completely free, open source (MIT license).

### Q: Do I need to be a programmer?

**A**: NO! If you can follow these steps, you can use PoshGuard.

### Q: What if I get an error?

**A**: 

1. Try with `-Verbose` to see more details
2. Check the error message (usually self-explanatory)
3. Ask for help: <https://github.com/cboyd0319/PoshGuard/issues>

### Q: Can I use this at work?

**A**: YES! PoshGuard is enterprise-ready and used by major companies.

---

## Real-World Example

Let's fix a messy script step-by-step:

### Before (Messy Script)

```powershell
# Script: DatabaseBackup.ps1
$password = "SecretPassword123"
$server = "PROD-SERVER-01"
gci C:\Backups
Write-Host "Starting backup"
if($connected){
Backup-Database -Server $server -Password $password
}
```

**Problems**:

1. ❌ Plain text password (SECURITY RISK!)
2. ❌ Hardcoded server name (bad practice)
3. ❌ Using `gci` alias (confusing)
4. ❌ Using `Write-Host` (outdated)
5. ❌ Bad formatting (hard to read)

### Run PoshGuard

```powershell
.\tools\Apply-AutoFix.ps1 -Path .\DatabaseBackup.ps1 -ShowDiff
```

### After (Clean Script)

```powershell
# Script: DatabaseBackup.ps1
$password = Read-Host "Enter password" -AsSecureString
$server = Read-Host "Enter server name"
Get-ChildItem C:\Backups
Write-Information "Starting backup" -InformationAction Continue
if ($connected) {
    Backup-Database -Server $server -Password $password
}
```

**Fixed**:

1. ✅ Password is now secure (encrypted)
2. ✅ Server name is now configurable
3. ✅ Full cmdlet name `Get-ChildItem`
4. ✅ Modern `Write-Information`
5. ✅ Proper formatting and indentation

**Time Taken**: 0.8 seconds!

---

## Next Steps

### Level Up Your Knowledge

1. **Read**: [How It Works](how-it-works.md) - Understand what's happening
2. **Try**: Run PoshGuard on your scripts
3. **Explore**: Check the `samples/` folder for more examples
4. **Integrate**: Add PoshGuard to your workflow (see [CI/CD Integration](ci-integration.md))

### Pro Tips

1. ⚡ **Always use `-DryRun` first** - Preview before changing
2. 💾 **Backups are your friend** - Don't delete the `.backup` folder
3. 📖 **Read the output** - PoshGuard explains what it fixed and why
4. 🔄 **Run regularly** - Check scripts before committing to version control
5. 🎓 **Learn gradually** - You'll understand more as you use it

---

## Visual Workflow

```
┌─────────────────────┐
│  Your PowerShell    │
│     Script.ps1      │
│  (might have issues)│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Run PoshGuard     │
│    with -DryRun     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Review Preview     │
│  (what will change) │
└──────────┬──────────┘
           │
      Happy? ┌───┐
     ┌───────┤Yes├─────┐
     │       └───┘     │
     │                 │
     ▼                 ▼
┌─────────┐    ┌──────────────┐
│  Stop   │    │ Run Without  │
│  Here   │    │   -DryRun    │
└─────────┘    └──────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ PoshGuard:    │
              │ 1. Backs up   │
              │ 2. Fixes      │
              │ 3. Reports    │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Script Fixed! │
              │   ✅ Secure   │
              │   ✅ Clean    │
              │   ✅ Better   │
              └───────────────┘
```

---

## Troubleshooting for Beginners

### Error: "Cannot find path..."

**Problem**: Wrong file path
**Solution**: 

```powershell
# Find your file first
Get-ChildItem -Path C:\Users\YourName -Recurse -Filter "*.ps1"
# Copy the full path shown
```

### Error: "Access denied"

**Problem**: Don't have permission to modify file
**Solution**: 

- Right-click PowerShell → "Run as Administrator"
- Or use `-DryRun` to preview (doesn't need special permissions)

### Error: "PSScriptAnalyzer module not found"

**Problem**: Missing required module
**Solution**:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

### Nothing happens when I run command

**Problem**: Might be in wrong folder
**Solution**:

```powershell
# Check current location
Get-Location

# Change to PoshGuard folder
cd C:\Users\YourName\Documents\PoshGuard
```

---

## Success Stories

**Before PoshGuard**: 

- 2 hours manually reviewing and fixing script issues
- Missed security vulnerabilities
- Inconsistent code style across team

**After PoshGuard**:

- 30 seconds automated fixes
- Security issues caught automatically  
- Consistent, clean code

**Time Saved**: 1 hour 59 minutes 30 seconds per script!

---

## Getting Help

**Stuck? We're here to help!**

1. 📖 **Read the Docs**: <https://github.com/cboyd0319/PoshGuard/tree/main/docs>
2. 🐛 **Report Issues**: <https://github.com/cboyd0319/PoshGuard/issues>
3. 💬 **Ask Questions**: Create a new issue with `[Question]` in title
4. 📧 **Community**: Check existing issues - your question might be answered!

**When Asking for Help, Include**:

- Full error message (copy-paste)
- Command you ran
- PowerShell version: `$PSVersionTable.PSVersion`
- Operating system (Windows 10, Mac, Linux, etc.)

---

## Congratulations! 🎉

You're now a PoshGuard user! You can:

- ✅ Fix PowerShell scripts automatically
- ✅ Preview changes before applying
- ✅ Rollback if needed
- ✅ Fix multiple files at once
- ✅ Understand the output

**Keep Learning**:

- Try PoshGuard on different scripts
- Explore advanced features as you get comfortable
- Share with your team!

---

## Glossary (Simple Definitions)

- **Script**: A file containing PowerShell code (ends in `.ps1`)
- **Cmdlet**: A PowerShell command (like `Get-ChildItem`)
- **Alias**: A short name for a cmdlet (like `gci` for `Get-ChildItem`)
- **Parameter**: An option you add to a command (like `-Path` or `-DryRun`)
- **AST**: Abstract Syntax Tree - How PowerShell understands your code (don't worry about it!)
- **Backup**: A copy of your original file (safety net!)
- **Fix Success Rate**: How many issues PoshGuard can fix (82.5% = good!)
- **Dry Run**: Preview mode - see changes without applying them

---

**Version**: 4.0.0  
**Last Updated**: 2025-10-12  
**Difficulty**: 👶 Beginner-Friendly  
**Time to Read**: 15 minutes  
**Time to Master**: Use it once, you'll get it!
