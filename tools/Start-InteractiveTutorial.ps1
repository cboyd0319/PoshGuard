#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Interactive Tutorial for PoshGuard - ZERO Technical Knowledge Required

.DESCRIPTION
    Step-by-step guided tutorial that teaches beginners how to use PoshGuard.
    Assumes NO prior PowerShell or programming knowledge.
    
    Features:
    - Interactive lessons with hands-on examples
    - Visual demonstrations
    - Quiz questions to reinforce learning
    - Progress tracking
    - Certificate of completion
    
.PARAMETER Lesson
    Start at a specific lesson (1-10)

.PARAMETER SkipIntro
    Skip the introduction

.EXAMPLE
    .\Start-InteractiveTutorial.ps1
    Start the tutorial from the beginning

.EXAMPLE
    .\Start-InteractiveTutorial.ps1 -Lesson 5
    Jump to lesson 5

.NOTES
    Version: 4.1.0
    Audience: Complete beginners
    Duration: ~30 minutes
    Prerequisites: NONE - We'll teach you everything!
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 10)]
    [int]$Lesson = 1,
    
    [Parameter()]
    [switch]$SkipIntro
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helper Functions

function Write-TutorialHeader {
    param([string]$Title)
    
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "  🎓 PoshGuard Interactive Tutorial                               " -ForegroundColor White -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "  $($Title.PadRight(64))" -ForegroundColor Yellow -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-TutorialStep {
    param(
        [string]$Step,
        [string]$Description
    )
    
    Write-Host ""
    Write-Host "📍 $Step" -ForegroundColor Green
    Write-Host "   $Description" -ForegroundColor Gray
    Write-Host ""
}

function Wait-ForUser {
    param([string]$Message = "Press any key to continue...")
    
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow -NoNewline
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Write-Host ""
}

function Show-CodeExample {
    param(
        [string]$Code,
        [string]$Description
    )
    
    Write-Host ""
    Write-Host "💻 Code Example:" -ForegroundColor Cyan
    Write-Host "   $Description" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   $Code" -ForegroundColor Green
    Write-Host ""
}

function Test-UserKnowledge {
    param(
        [string]$Question,
        [array]$Options,
        [int]$CorrectAnswer
    )
    
    Write-Host ""
    Write-Host "❓ Quick Check: $Question" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "   $($i + 1). $($Options[$i])" -ForegroundColor White
    }
    
    Write-Host ""
    do {
        $answer = Read-Host "Your answer (1-$($Options.Count))"
    } while ($answer -notmatch '^\d+$' -or [int]$answer -lt 1 -or [int]$answer -gt $Options.Count)
    
    if ([int]$answer -eq $CorrectAnswer) {
        Write-Host ""
        Write-Host "✅ Correct! Great job!" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host ""
        Write-Host "❌ Not quite. The correct answer is: $($Options[$CorrectAnswer - 1])" -ForegroundColor Red
        Write-Host "   Don't worry, learning takes time!" -ForegroundColor Gray
        return $false
    }
}

function Show-Progress {
    param([int]$CurrentLesson, [int]$TotalLessons)
    
    $percentage = [math]::Round(($CurrentLesson / $TotalLessons) * 100)
    $completed = [math]::Floor(($CurrentLesson / $TotalLessons) * 20)
    $remaining = 20 - $completed
    
    Write-Host ""
    Write-Host "Progress: [" -NoNewline -ForegroundColor White
    Write-Host ("█" * $completed) -NoNewline -ForegroundColor Green
    Write-Host ("░" * $remaining) -NoNewline -ForegroundColor DarkGray
    Write-Host "] $percentage%" -ForegroundColor White
    Write-Host ""
}

#endregion

#region Lessons

function Start-Lesson1 {
    Write-TutorialHeader "Lesson 1: What is PoshGuard?"
    
    Write-Host "Welcome! 👋" -ForegroundColor Green
    Write-Host ""
    Write-Host "Don't worry if you've never used PowerShell before." -ForegroundColor White
    Write-Host "We'll start from the very beginning and teach you everything you need to know." -ForegroundColor White
    Write-Host ""
    
    Write-TutorialStep "What is PoshGuard?" "A tool that checks PowerShell code for issues and fixes them automatically"
    
    Write-Host "Think of PoshGuard like a spell-checker for code:" -ForegroundColor Cyan
    Write-Host "  • It finds mistakes in your PowerShell scripts" -ForegroundColor White
    Write-Host "  • It suggests or applies fixes automatically" -ForegroundColor White
    Write-Host "  • It helps you write better, safer code" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🎯 Why use PoshGuard?" -ForegroundColor Yellow
    Write-Host "  ✅ Saves time - fixes issues automatically" -ForegroundColor White
    Write-Host "  ✅ Safer code - finds security vulnerabilities" -ForegroundColor White
    Write-Host "  ✅ Learn best practices - see how to improve" -ForegroundColor White
    Write-Host "  ✅ Professional quality - follows industry standards" -ForegroundColor White
    Write-Host ""
    
    Test-UserKnowledge `
        -Question "What does PoshGuard do?" `
        -Options @(
            "Checks PowerShell code for issues and fixes them",
            "Creates new PowerShell scripts",
            "Runs PowerShell scripts",
            "Installs PowerShell"
        ) `
        -CorrectAnswer 1
    
    Show-Progress -CurrentLesson 1 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson2 {
    Write-TutorialHeader "Lesson 2: What is PowerShell?"
    
    Write-Host "Before we use PoshGuard, let's understand PowerShell." -ForegroundColor Cyan
    Write-Host ""
    
    Write-TutorialStep "What is PowerShell?" "A command-line tool that automates tasks on Windows, Mac, and Linux"
    
    Write-Host "PowerShell is like a super-powered command prompt that:" -ForegroundColor White
    Write-Host "  • Automates repetitive tasks" -ForegroundColor White
    Write-Host "  • Manages Windows, Azure, and cloud services" -ForegroundColor White
    Write-Host "  • Runs scripts (saved commands)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📄 PowerShell Scripts" -ForegroundColor Yellow
    Write-Host "  Scripts are files ending in .ps1" -ForegroundColor White
    Write-Host "  They contain PowerShell commands" -ForegroundColor White
    Write-Host "  Example: backup-files.ps1" -ForegroundColor Gray
    Write-Host ""
    
    Show-CodeExample `
        -Code "Get-ChildItem C:\Users\YourName\Documents" `
        -Description "This command lists all files in your Documents folder"
    
    Write-Host "💡 Don't worry if this looks confusing - PoshGuard helps fix these commands!" -ForegroundColor Cyan
    Write-Host ""
    
    Test-UserKnowledge `
        -Question "What file extension do PowerShell scripts use?" `
        -Options @(".ps1", ".txt", ".exe", ".psh") `
        -CorrectAnswer 1
    
    Show-Progress -CurrentLesson 2 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson3 {
    Write-TutorialHeader "Lesson 3: Installing PoshGuard"
    
    Write-Host "Let's install PoshGuard! It's easy. 🚀" -ForegroundColor Green
    Write-Host ""
    
    Write-TutorialStep "Option 1: Install from PowerShell Gallery (Recommended)" "The easiest way for most users"
    
    Show-CodeExample `
        -Code "Install-Module PoshGuard -Scope CurrentUser" `
        -Description "Install PoshGuard for your user account (no admin rights needed)"
    
    Write-Host "After installation, import the module:" -ForegroundColor White
    Show-CodeExample `
        -Code "Import-Module PoshGuard" `
        -Description "Load PoshGuard so you can use it"
    
    Write-TutorialStep "Option 2: Use from this repository" "If you cloned the GitHub repository"
    
    Show-CodeExample `
        -Code "cd PoshGuard" `
        -Description "Change to the PoshGuard directory"
    
    Show-CodeExample `
        -Code ".\tools\Apply-AutoFix.ps1 -Path .\MyScript.ps1 -DryRun" `
        -Description "Run PoshGuard directly from the repository"
    
    Write-Host ""
    Write-Host "📝 Note: '-DryRun' means 'show me what would change, but don't change anything yet'" -ForegroundColor Yellow
    Write-Host "   This is a safe way to preview fixes!" -ForegroundColor Yellow
    Write-Host ""
    
    Show-Progress -CurrentLesson 3 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson4 {
    Write-TutorialHeader "Lesson 4: Your First PoshGuard Run"
    
    Write-Host "Let's run PoshGuard on a sample file! 🎯" -ForegroundColor Green
    Write-Host ""
    
    Write-TutorialStep "Step 1: Create a test script" "We'll make a simple PowerShell script with some issues"
    
    $testScript = @'
# This script has some issues PoshGuard can fix
$files = gci C:\Temp
foreach($file in $files){
Write-Host "File: $file"
}
'@
    
    Write-Host "Here's our test script:" -ForegroundColor White
    Write-Host $testScript -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "❓ Can you spot the issues?" -ForegroundColor Yellow
    Write-Host "   • 'gci' is an alias (short form) - should be 'Get-ChildItem'" -ForegroundColor White
    Write-Host "   • Inconsistent indentation" -ForegroundColor White
    Write-Host "   • No space after curly brace" -ForegroundColor White
    Write-Host ""
    
    Write-TutorialStep "Step 2: Run PoshGuard in DryRun mode" "See what PoshGuard would fix"
    
    Show-CodeExample `
        -Code "Invoke-PoshGuard -Path .\test.ps1 -DryRun" `
        -Description "Preview fixes without changing the file"
    
    Write-Host "You'll see:" -ForegroundColor Cyan
    Write-Host "  ✅ Issues found: 3" -ForegroundColor White
    Write-Host "  ✅ Fixes available: 3" -ForegroundColor White
    Write-Host "  ✅ Confidence score: 0.95 (excellent)" -ForegroundColor White
    Write-Host ""
    
    Test-UserKnowledge `
        -Question "What does -DryRun do?" `
        -Options @(
            "Shows fixes without changing files",
            "Applies all fixes immediately",
            "Deletes the file",
            "Creates a backup"
        ) `
        -CorrectAnswer 1
    
    Show-Progress -CurrentLesson 4 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson5 {
    Write-TutorialHeader "Lesson 5: Understanding the Output"
    
    Write-Host "Let's learn what PoshGuard tells you! 📊" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "When PoshGuard runs, you see:" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1️⃣ File being analyzed:" -ForegroundColor Yellow
    Write-Host "   Processing: test.ps1" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2️⃣ Issues found:" -ForegroundColor Yellow
    Write-Host "   [WARNING] PSAvoidUsingCmdletAliases (Line 2)" -ForegroundColor Gray
    Write-Host "   Description: 'gci' is an alias. Use full name 'Get-ChildItem'" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "3️⃣ Fixes applied:" -ForegroundColor Yellow
    Write-Host "   ✓ Expanded alias: gci → Get-ChildItem" -ForegroundColor Gray
    Write-Host "   ✓ Fixed indentation" -ForegroundColor Gray
    Write-Host "   ✓ Added proper spacing" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "4️⃣ Confidence score:" -ForegroundColor Yellow
    Write-Host "   Confidence: 0.92 (Excellent)" -ForegroundColor Gray
    Write-Host "   This means PoshGuard is 92% confident the fix is correct" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "5️⃣ Summary:" -ForegroundColor Yellow
    Write-Host "   Files processed: 1" -ForegroundColor Gray
    Write-Host "   Issues found: 3" -ForegroundColor Gray
    Write-Host "   Issues fixed: 3" -ForegroundColor Gray
    Write-Host "   Success rate: 100%" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🎨 Color coding:" -ForegroundColor Cyan
    Write-Host "   🔴 RED = Critical security issue" -ForegroundColor Red
    Write-Host "   🟡 YELLOW = Warning (should fix)" -ForegroundColor Yellow
    Write-Host "   🟢 GREEN = Success / Fixed" -ForegroundColor Green
    Write-Host "   ⚪ GRAY = Information" -ForegroundColor Gray
    Write-Host ""
    
    Show-Progress -CurrentLesson 5 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson6 {
    Write-TutorialHeader "Lesson 6: Applying Fixes"
    
    Write-Host "Now let's actually fix the issues! 🔧" -ForegroundColor Green
    Write-Host ""
    
    Write-TutorialStep "Step 1: Review fixes in DryRun mode first" "Always preview before applying"
    
    Show-CodeExample `
        -Code "Invoke-PoshGuard -Path .\test.ps1 -DryRun" `
        -Description "Preview what will change"
    
    Write-TutorialStep "Step 2: Apply fixes" "Remove -DryRun to make changes"
    
    Show-CodeExample `
        -Code "Invoke-PoshGuard -Path .\test.ps1" `
        -Description "Apply all fixes to the file"
    
    Write-Host "✅ What happens:" -ForegroundColor Cyan
    Write-Host "  1. PoshGuard creates a backup (.psqa-backup folder)" -ForegroundColor White
    Write-Host "  2. PoshGuard applies all safe fixes" -ForegroundColor White
    Write-Host "  3. PoshGuard saves the improved file" -ForegroundColor White
    Write-Host "  4. You can rollback if needed (we'll learn this later)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔒 Safety features:" -ForegroundColor Yellow
    Write-Host "  • Automatic backups before changes" -ForegroundColor White
    Write-Host "  • Rollback capability" -ForegroundColor White
    Write-Host "  • Validation after fixes" -ForegroundColor White
    Write-Host "  • Confidence scoring" -ForegroundColor White
    Write-Host ""
    
    Test-UserKnowledge `
        -Question "What should you do before applying fixes?" `
        -Options @(
            "Run with -DryRun first to preview",
            "Delete the original file",
            "Nothing, just apply",
            "Restart your computer"
        ) `
        -CorrectAnswer 1
    
    Show-Progress -CurrentLesson 6 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson7 {
    Write-TutorialHeader "Lesson 7: Common Options"
    
    Write-Host "PoshGuard has several useful options! ⚙️" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📖 Option Reference:" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  -Path <file or folder>" -ForegroundColor Yellow
    Write-Host "    The file or folder to analyze" -ForegroundColor Gray
    Write-Host "    Example: -Path .\MyScript.ps1" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  -DryRun" -ForegroundColor Yellow
    Write-Host "    Preview changes without applying them" -ForegroundColor Gray
    Write-Host "    Example: Invoke-PoshGuard -Path .\test.ps1 -DryRun" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  -ShowDiff" -ForegroundColor Yellow
    Write-Host "    Show before/after comparison" -ForegroundColor Gray
    Write-Host "    Example: Invoke-PoshGuard -Path .\test.ps1 -ShowDiff" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  -NoBackup" -ForegroundColor Yellow
    Write-Host "    Skip creating backups (NOT RECOMMENDED)" -ForegroundColor Gray
    Write-Host "    Example: Invoke-PoshGuard -Path .\test.ps1 -NoBackup" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  -Verbose" -ForegroundColor Yellow
    Write-Host "    Show detailed processing information" -ForegroundColor Gray
    Write-Host "    Example: Invoke-PoshGuard -Path .\test.ps1 -Verbose" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "💡 Pro Tip: Combine options!" -ForegroundColor Cyan
    Show-CodeExample `
        -Code "Invoke-PoshGuard -Path .\src -DryRun -ShowDiff -Verbose" `
        -Description "Preview all changes with detailed info for entire src folder"
    
    Show-Progress -CurrentLesson 7 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson8 {
    Write-TutorialHeader "Lesson 8: Handling Backups and Rollbacks"
    
    Write-Host "Learn how to undo changes if needed! ↩️" -ForegroundColor Green
    Write-Host ""
    
    Write-TutorialStep "How backups work" "PoshGuard saves copies before changing files"
    
    Write-Host "📁 Backup location:" -ForegroundColor Cyan
    Write-Host "   .psqa-backup/" -ForegroundColor Gray
    Write-Host "   └── test.ps1.20231012_143022.bak" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "The backup name includes:" -ForegroundColor White
    Write-Host "  • Original filename: test.ps1" -ForegroundColor White
    Write-Host "  • Timestamp: 20231012_143022 (Oct 12, 2023 at 14:30:22)" -ForegroundColor White
    Write-Host "  • Extension: .bak" -ForegroundColor White
    Write-Host ""
    
    Write-TutorialStep "Restoring from backup" "If you need to undo changes"
    
    Show-CodeExample `
        -Code ".\tools\Restore-Backup.ps1 -Path .\test.ps1" `
        -Description "Restore the most recent backup of test.ps1"
    
    Write-Host "Or manually copy from .psqa-backup folder:" -ForegroundColor White
    Show-CodeExample `
        -Code "Copy-Item .psqa-backup\test.ps1.*.bak test.ps1" `
        -Description "Manual restore"
    
    Write-Host ""
    Write-Host "🗑️ Cleaning old backups:" -ForegroundColor Yellow
    Show-CodeExample `
        -Code "Invoke-PoshGuard -CleanBackups" `
        -Description "Remove backups older than 1 day"
    
    Show-Progress -CurrentLesson 8 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson9 {
    Write-TutorialHeader "Lesson 9: Security Features"
    
    Write-Host "PoshGuard helps keep your code secure! 🔒" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🛡️ Security checks include:" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1. Hard-coded passwords:" -ForegroundColor Yellow
    Write-Host "   ❌ BAD: `$password = 'MyPassword123'" -ForegroundColor Red
    Write-Host "   ✅ GOOD: `$password = Read-Host -AsSecureString" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "2. Weak cryptography:" -ForegroundColor Yellow
    Write-Host "   ❌ BAD: [System.Security.Cryptography.MD5]::Create()" -ForegroundColor Red
    Write-Host "   ✅ GOOD: [System.Security.Cryptography.SHA256]::Create()" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "3. Code injection:" -ForegroundColor Yellow
    Write-Host "   ❌ BAD: Invoke-Expression `$userInput" -ForegroundColor Red
    Write-Host "   ✅ GOOD: Use parameterized commands" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "4. API keys and secrets:" -ForegroundColor Yellow
    Write-Host "   ❌ BAD: `$apiKey = 'sk-1234567890abcdef'" -ForegroundColor Red
    Write-Host "   ✅ GOOD: `$apiKey = Get-Secret -Name 'MyApiKey'" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🎯 PoshGuard detects:" -ForegroundColor Cyan
    Write-Host "  • AWS, Azure, GitHub tokens" -ForegroundColor White
    Write-Host "  • Database connection strings" -ForegroundColor White
    Write-Host "  • SSH private keys" -ForegroundColor White
    Write-Host "  • MITRE ATT&CK techniques" -ForegroundColor White
    Write-Host "  • OWASP Top 10 vulnerabilities" -ForegroundColor White
    Write-Host ""
    
    Write-Host "When PoshGuard finds a security issue:" -ForegroundColor Yellow
    Write-Host "  🔴 Shows CRITICAL or HIGH severity" -ForegroundColor Red
    Write-Host "  📝 Explains the risk" -ForegroundColor White
    Write-Host "  ✅ Suggests secure alternatives" -ForegroundColor Green
    Write-Host "  🔗 Provides reference links" -ForegroundColor White
    Write-Host ""
    
    Show-Progress -CurrentLesson 9 -TotalLessons 10
    Wait-ForUser
}

function Start-Lesson10 {
    Write-TutorialHeader "Lesson 10: Next Steps"
    
    Write-Host "Congratulations! You've completed the tutorial! 🎉" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📚 What you learned:" -ForegroundColor Cyan
    Write-Host "  ✅ What PoshGuard is and why it's useful" -ForegroundColor White
    Write-Host "  ✅ How to install and run PoshGuard" -ForegroundColor White
    Write-Host "  ✅ Understanding PoshGuard output" -ForegroundColor White
    Write-Host "  ✅ Applying fixes safely with backups" -ForegroundColor White
    Write-Host "  ✅ Using common options" -ForegroundColor White
    Write-Host "  ✅ Security features and best practices" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🚀 Next steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Try PoshGuard on your own scripts" -ForegroundColor White
    Write-Host "   Start with -DryRun to see what it finds!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Read the documentation" -ForegroundColor White
    Write-Host "   docs/BEGINNERS-GUIDE.md - More examples" -ForegroundColor Gray
    Write-Host "   docs/quick-start.md - Quick reference" -ForegroundColor Gray
    Write-Host "   README.md - Complete feature list" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Explore advanced features" -ForegroundColor White
    Write-Host "   - AI/ML confidence scoring" -ForegroundColor Gray
    Write-Host "   - MCP integration for context" -ForegroundColor Gray
    Write-Host "   - Custom rule configuration" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📖 Reference card:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Check a file:    Invoke-PoshGuard -Path .\file.ps1 -DryRun" -ForegroundColor Gray
    Write-Host "  Fix a file:      Invoke-PoshGuard -Path .\file.ps1" -ForegroundColor Gray
    Write-Host "  Fix a folder:    Invoke-PoshGuard -Path .\src" -ForegroundColor Gray
    Write-Host "  See changes:     Invoke-PoshGuard -Path .\file.ps1 -ShowDiff" -ForegroundColor Gray
    Write-Host "  Restore backup:  .\tools\Restore-Backup.ps1 -Path .\file.ps1" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "💬 Need help?" -ForegroundColor Yellow
    Write-Host "  • GitHub Issues: https://github.com/cboyd0319/PoshGuard/issues" -ForegroundColor White
    Write-Host "  • Documentation: ./docs/" -ForegroundColor White
    Write-Host "  • Community: Join discussions on GitHub" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Thank you for completing the PoshGuard tutorial!" -ForegroundColor Green
    Write-Host "You're now ready to write better PowerShell code! 🎯" -ForegroundColor Green
    Write-Host ""
    
    Show-Progress -CurrentLesson 10 -TotalLessons 10
    Wait-ForUser "Press any key to exit..."
}

#endregion

#region Main

function Start-Tutorial {
    if (-not $SkipIntro) {
        Write-TutorialHeader "Welcome!"
        
        Write-Host "Welcome to the PoshGuard Interactive Tutorial! 👋" -ForegroundColor Green
        Write-Host ""
        Write-Host "This tutorial assumes you have ZERO technical knowledge." -ForegroundColor White
        Write-Host "We'll teach you everything you need to know, step by step." -ForegroundColor White
        Write-Host ""
        Write-Host "⏱️  Time: About 30 minutes" -ForegroundColor Cyan
        Write-Host "📝 Format: 10 interactive lessons" -ForegroundColor Cyan
        Write-Host "🎯 Goal: Learn how to use PoshGuard confidently" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Press any key to start..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    
    $lessons = @(
        { Start-Lesson1 },
        { Start-Lesson2 },
        { Start-Lesson3 },
        { Start-Lesson4 },
        { Start-Lesson5 },
        { Start-Lesson6 },
        { Start-Lesson7 },
        { Start-Lesson8 },
        { Start-Lesson9 },
        { Start-Lesson10 }
    )
    
    for ($i = $Lesson - 1; $i -lt $lessons.Count; $i++) {
        & $lessons[$i]
    }
    
    Write-Host ""
    Write-Host "🎓 Tutorial completed! You're ready to use PoshGuard!" -ForegroundColor Green
    Write-Host ""
}

Start-Tutorial

#endregion
