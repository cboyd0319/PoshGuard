#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Interactive Tutorial for PoshGuard - ZERO Technical Knowledge Required

.DESCRIPTION
    Step-by-step guided tutorial that teaches beginners how to use PoshGuard.
    Assumes NO prior PowerShell or programming knowledge.
    
.NOTES
    Write-Host is used intentionally throughout this script for interactive CLI output
    and colored user feedback, which is appropriate for tutorial/interactive tools.
    
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
    Version: 4.3.0
    Audience: Complete beginners
    Duration: ~30 minutes
    Prerequisites: NONE - We'll teach you everything!
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', 
  Justification = 'Write-Host is used intentionally for colored CLI output in this interactive tutorial tool')]
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
  Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "🎓 PoshGuard Interactive Tutorial" -ForegroundColor White -NoNewline
  Write-Host "                                 ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "Zero Technical Knowledge Required" -ForegroundColor Gray -NoNewline
  Write-Host "                                 ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ╠════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    
  # Truncate title if too long and pad to exact width
  $maxTitleLength = 64
  $displayTitle = if ($Title.Length -gt $maxTitleLength) { 
    $Title.Substring(0, $maxTitleLength - 3) + "..." 
  } else { 
    $Title.PadRight($maxTitleLength) 
  }
  Write-Host $displayTitle -ForegroundColor Yellow -NoNewline
  Write-Host "  ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""
}

function Write-TutorialStep {
  param(
    [string]$Step,
    [string]$Description
  )
    
  Write-Host ""
  Write-Host "  ┌─────────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
  Write-Host "  │ " -ForegroundColor Green -NoNewline
  Write-Host "📍 $Step" -ForegroundColor White -NoNewline
  $padding = 67 - $Step.Length
  if ($padding -lt 0) { $padding = 0 }
  Write-Host (" " * $padding) -NoNewline
  Write-Host "│" -ForegroundColor Green
  Write-Host "  │ " -ForegroundColor Green -NoNewline
  Write-Host "   $Description" -ForegroundColor Gray -NoNewline
  $padding2 = 64 - $Description.Length
  if ($padding2 -lt 0) { $padding2 = 0 }
  Write-Host (" " * $padding2) -NoNewline
  Write-Host "│" -ForegroundColor Green
  Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
  Write-Host ""
}

function Wait-ForUser {
  param([string]$Message = "Press any key to continue...")
    
  Write-Host ""
  Write-Host "  ╭" -ForegroundColor DarkGray -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkGray -NoNewline
  Write-Host "╮" -ForegroundColor DarkGray
  Write-Host "  │  " -ForegroundColor DarkGray -NoNewline
  Write-Host "⏎  $Message" -ForegroundColor Yellow -NoNewline
  $padding = 65 - $Message.Length
  if ($padding -lt 0) { $padding = 0 }
  Write-Host (" " * $padding) -NoNewline
  Write-Host "│" -ForegroundColor DarkGray
  Write-Host "  ╰" -ForegroundColor DarkGray -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkGray -NoNewline
  Write-Host "╯" -ForegroundColor DarkGray
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  Write-Host ""
}

function Show-CodeExample {
  param(
    [string]$Code,
    [string]$Description
  )
    
  Write-Host ""
  Write-Host "  ╭─ 💻 Code Example " -ForegroundColor Cyan -NoNewline
  Write-Host ("─" * 53) -ForegroundColor DarkCyan -NoNewline
  Write-Host "╮" -ForegroundColor Cyan
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host $Description -ForegroundColor Gray
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  ├" -ForegroundColor DarkCyan -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkCyan -NoNewline
  Write-Host "┤" -ForegroundColor DarkCyan
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host $Code -ForegroundColor Green
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  ╰" -ForegroundColor Cyan -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkCyan -NoNewline
  Write-Host "╯" -ForegroundColor Cyan
  Write-Host ""
}

function Test-UserKnowledge {
  param(
    [string]$Question,
    [array]$Options,
    [int]$CorrectAnswer
  )
    
  Write-Host ""
  Write-Host "  ╭─ ❓ Quick Check " -ForegroundColor Yellow -NoNewline
  Write-Host ("─" * 55) -ForegroundColor DarkYellow -NoNewline
  Write-Host "╮" -ForegroundColor Yellow
  Write-Host "  │" -ForegroundColor Yellow
  Write-Host "  │  " -ForegroundColor Yellow -NoNewline
  Write-Host $Question -ForegroundColor White
  Write-Host "  │" -ForegroundColor Yellow
  Write-Host "  ├" -ForegroundColor DarkYellow -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkYellow -NoNewline
  Write-Host "┤" -ForegroundColor DarkYellow
    
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "  │" -ForegroundColor Yellow
    Write-Host "  │  " -ForegroundColor Yellow -NoNewline
    $optionNumber = "[" + ($i + 1) + "]"
    Write-Host $optionNumber -ForegroundColor Cyan -NoNewline
    Write-Host " $($Options[$i])" -ForegroundColor White
  }
    
  Write-Host "  │" -ForegroundColor Yellow
  Write-Host "  ╰" -ForegroundColor Yellow -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkYellow -NoNewline
  Write-Host "╯" -ForegroundColor Yellow
  Write-Host ""
    
  do {
    Write-Host "  Your answer (1-$($Options.Count)): " -ForegroundColor Cyan -NoNewline
    $answer = Read-Host
  } while ($answer -notmatch '^\d+$' -or [int]$answer -lt 1 -or [int]$answer -gt $Options.Count)
    
  if ([int]$answer -eq $CorrectAnswer) {
    Write-Host ""
    Write-Host "  ╭" -ForegroundColor Green -NoNewline
    Write-Host ("─" * 71) -ForegroundColor DarkGreen -NoNewline
    Write-Host "╮" -ForegroundColor Green
    Write-Host "  │  " -ForegroundColor Green -NoNewline
    Write-Host "✅ Correct! Great job! You're learning fast!" -ForegroundColor White -NoNewline
    Write-Host "                      │" -ForegroundColor Green
    Write-Host "  ╰" -ForegroundColor Green -NoNewline
    Write-Host ("─" * 71) -ForegroundColor DarkGreen -NoNewline
    Write-Host "╯" -ForegroundColor Green
    return $true
  }
  else {
    Write-Host ""
    Write-Host "  ╭" -ForegroundColor Red -NoNewline
    Write-Host ("─" * 71) -ForegroundColor DarkRed -NoNewline
    Write-Host "╮" -ForegroundColor Red
    Write-Host "  │  " -ForegroundColor Red -NoNewline
    Write-Host "❌ Not quite. The correct answer is: " -ForegroundColor White -NoNewline
    Write-Host $Options[$CorrectAnswer - 1] -ForegroundColor Yellow
    Write-Host "  │  " -ForegroundColor Red -NoNewline
    Write-Host "   Don't worry, learning takes time! Keep going!" -ForegroundColor Gray -NoNewline
    Write-Host "                │" -ForegroundColor Red
    Write-Host "  ╰" -ForegroundColor Red -NoNewline
    Write-Host ("─" * 71) -ForegroundColor DarkRed -NoNewline
    Write-Host "╯" -ForegroundColor Red
    return $false
  }
}

function Show-Progress {
  param([int]$CurrentLesson, [int]$TotalLessons)
    
  $percentage = [math]::Round(($CurrentLesson / $TotalLessons) * 100)
  $completed = [math]::Floor(($CurrentLesson / $TotalLessons) * 40)
  $remaining = 40 - $completed
    
  Write-Host ""
  Write-Host "  ╭─ 📊 Progress " -ForegroundColor Magenta -NoNewline
  Write-Host ("─" * 58) -ForegroundColor DarkMagenta -NoNewline
  Write-Host "╮" -ForegroundColor Magenta
  Write-Host "  │" -ForegroundColor Magenta
  Write-Host "  │  Lesson $CurrentLesson of $TotalLessons  " -ForegroundColor White -NoNewline
  Write-Host "[" -NoNewline -ForegroundColor DarkGray
  Write-Host ("█" * $completed) -NoNewline -ForegroundColor Green
  Write-Host ("░" * $remaining) -NoNewline -ForegroundColor DarkGray
  Write-Host "] " -NoNewline -ForegroundColor DarkGray
  Write-Host "$percentage% Complete" -ForegroundColor Cyan
  Write-Host "  │" -ForegroundColor Magenta
  Write-Host "  ╰" -ForegroundColor Magenta -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkMagenta -NoNewline
  Write-Host "╯" -ForegroundColor Magenta
  Write-Host ""
}

function Show-InfoBox {
  param(
    [string]$Title,
    [string[]]$Content,
    [string]$Icon = "ℹ️",
    [string]$Color = "Cyan"
  )
    
  Write-Host ""
  Write-Host "  ╭─ $Icon $Title " -ForegroundColor $Color -NoNewline
  $titleLen = $Title.Length + 3
  $dashCount = 70 - $titleLen
  if ($dashCount -lt 0) { $dashCount = 0 }
  Write-Host ("─" * $dashCount) -ForegroundColor "Dark$Color" -NoNewline
  Write-Host "╮" -ForegroundColor $Color
  Write-Host "  │" -ForegroundColor $Color
    
  foreach ($line in $Content) {
    Write-Host "  │  " -ForegroundColor $Color -NoNewline
    Write-Host $line -ForegroundColor White
  }
    
  Write-Host "  │" -ForegroundColor $Color
  Write-Host "  ╰" -ForegroundColor $Color -NoNewline
  Write-Host ("─" * 71) -ForegroundColor "Dark$Color" -NoNewline
  Write-Host "╯" -ForegroundColor $Color
  Write-Host ""
}

function Show-TipBox {
  param([string]$Tip)
    
  Write-Host ""
  Write-Host "  ╭─ 💡 Pro Tip " -ForegroundColor Yellow -NoNewline
  Write-Host ("─" * 58) -ForegroundColor DarkYellow -NoNewline
  Write-Host "╮" -ForegroundColor Yellow
  Write-Host "  │" -ForegroundColor Yellow
  Write-Host "  │  " -ForegroundColor Yellow -NoNewline
  Write-Host $Tip -ForegroundColor White
  Write-Host "  │" -ForegroundColor Yellow
  Write-Host "  ╰" -ForegroundColor Yellow -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkYellow -NoNewline
  Write-Host "╯" -ForegroundColor Yellow
  Write-Host ""
}

function Show-WarningBox {
  param([string]$Warning)
    
  Write-Host ""
  Write-Host "  ╭─ ⚠️  Important " -ForegroundColor Red -NoNewline
  Write-Host ("─" * 56) -ForegroundColor DarkRed -NoNewline
  Write-Host "╮" -ForegroundColor Red
  Write-Host "  │" -ForegroundColor Red
  Write-Host "  │  " -ForegroundColor Red -NoNewline
  Write-Host $Warning -ForegroundColor Yellow
  Write-Host "  │" -ForegroundColor Red
  Write-Host "  ╰" -ForegroundColor Red -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkRed -NoNewline
  Write-Host "╯" -ForegroundColor Red
  Write-Host ""
}

function Show-SuccessBox {
  param([string]$Message)
    
  Write-Host ""
  Write-Host "  ╭─ ✅ Success " -ForegroundColor Green -NoNewline
  Write-Host ("─" * 58) -ForegroundColor DarkGreen -NoNewline
  Write-Host "╮" -ForegroundColor Green
  Write-Host "  │" -ForegroundColor Green
  Write-Host "  │  " -ForegroundColor Green -NoNewline
  Write-Host $Message -ForegroundColor White
  Write-Host "  │" -ForegroundColor Green
  Write-Host "  ╰" -ForegroundColor Green -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkGreen -NoNewline
  Write-Host "╯" -ForegroundColor Green
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
    
  Show-TipBox "Always start with '-DryRun' to preview changes before applying them!"
    
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
    
  Show-InfoBox -Title "Color Coding Guide" -Icon "🎨" -Color "Cyan" -Content @(
    "🔴 RED = Critical security issue - Fix immediately!",
    "🟡 YELLOW = Warning - Should fix soon",
    "🟢 GREEN = Success - Fixed successfully",
    "⚪ GRAY = Information - Just for your reference"
  )
    
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
    
  Show-InfoBox -Title "What Happens When You Apply Fixes" -Icon "✅" -Color "Green" -Content @(
    "1. PoshGuard creates a backup in the .psqa-backup folder",
    "2. PoshGuard applies all safe fixes to your file",
    "3. PoshGuard saves the improved file",
    "4. You can rollback if needed (we'll learn this later)"
  )
    
  Show-InfoBox -Title "Safety Features Built-In" -Icon "🔒" -Color "Yellow" -Content @(
    "• Automatic backups before any changes",
    "• Rollback capability to undo changes",
    "• Validation after fixes are applied",
    "• Confidence scoring for every fix"
  )
    
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
    
  Write-Host ""
  Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "📖 Quick Reference Card" -ForegroundColor White -NoNewline
  Write-Host "                                                ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "👁️  Preview fixes:                                                      " -ForegroundColor Yellow -NoNewline
  Write-Host "║" -ForegroundColor Cyan
  Write-Host "  ║     " -ForegroundColor Cyan -NoNewline
  Write-Host "Invoke-PoshGuard -Path .\file.ps1 -DryRun" -ForegroundColor White -NoNewline
  Write-Host "                     ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "🔧 Apply fixes:                                                         " -ForegroundColor Green -NoNewline
  Write-Host "║" -ForegroundColor Cyan
  Write-Host "  ║     " -ForegroundColor Cyan -NoNewline
  Write-Host "Invoke-PoshGuard -Path .\file.ps1" -ForegroundColor White -NoNewline
  Write-Host "                              ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "📂 Fix entire folder:                                                   " -ForegroundColor Green -NoNewline
  Write-Host "║" -ForegroundColor Cyan
  Write-Host "  ║     " -ForegroundColor Cyan -NoNewline
  Write-Host "Invoke-PoshGuard -Path .\src" -ForegroundColor White -NoNewline
  Write-Host "                                     ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "🔍 See changes (diff):                                                  " -ForegroundColor Magenta -NoNewline
  Write-Host "║" -ForegroundColor Cyan
  Write-Host "  ║     " -ForegroundColor Cyan -NoNewline
  Write-Host "Invoke-PoshGuard -Path .\file.ps1 -ShowDiff" -ForegroundColor White -NoNewline
  Write-Host "                     ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
  Write-Host "↩️  Restore backup:                                                      " -ForegroundColor Yellow -NoNewline
  Write-Host "║" -ForegroundColor Cyan
  Write-Host "  ║     " -ForegroundColor Cyan -NoNewline
  Write-Host ".\tools\Restore-Backup.ps1 -Path .\file.ps1" -ForegroundColor White -NoNewline
  Write-Host "                    ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                      ║" -ForegroundColor Cyan
  Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""
    
  Show-InfoBox -Title "Need Help?" -Icon "💬" -Color "Yellow" -Content @(
    "📝 GitHub Issues: https://github.com/cboyd0319/PoshGuard/issues",
    "📚 Documentation: ./docs/ folder in the repository",
    "👥 Community: Join discussions on GitHub",
    "🎓 Re-run this tutorial anytime: .\tools\Start-InteractiveTutorial.ps1"
  )
    
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
    Clear-Host
    Write-Host ""
    Write-Host ""
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ║           " -ForegroundColor Cyan -NoNewline
    Write-Host "🎓  Welcome to the PoshGuard Tutorial!" -ForegroundColor White -NoNewline
    Write-Host "               ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ╠════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "✨ This tutorial assumes you have ZERO technical knowledge" -ForegroundColor White -NoNewline
    Write-Host "         ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "   We'll teach you everything you need, step by step!" -ForegroundColor Gray -NoNewline
    Write-Host "          ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ╠════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "⏱️  Duration:      " -ForegroundColor White -NoNewline
    Write-Host "~30 minutes (at your own pace)" -ForegroundColor Cyan -NoNewline
    Write-Host "                   ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "📚 Lessons:       " -ForegroundColor White -NoNewline
    Write-Host "10 interactive lessons with examples" -ForegroundColor Cyan -NoNewline
    Write-Host "                ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "🎯 Your Goal:     " -ForegroundColor White -NoNewline
    Write-Host "Use PoshGuard confidently and safely" -ForegroundColor Cyan -NoNewline
    Write-Host "                ║" -ForegroundColor Cyan
    Write-Host "  ║  " -ForegroundColor Cyan -NoNewline
    Write-Host "✅ What You'll Get: " -ForegroundColor White -NoNewline
    Write-Host "Skills to improve PowerShell code quality" -ForegroundColor Cyan -NoNewline
    Write-Host "         ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ""
    Write-Host "  ╭" -ForegroundColor Green -NoNewline
    Write-Host ("─" * 71) -ForegroundColor DarkGreen -NoNewline
    Write-Host "╮" -ForegroundColor Green
    Write-Host "  │  " -ForegroundColor Green -NoNewline
    Write-Host "🚀 Ready to start your journey? Press any key to begin!" -ForegroundColor Yellow -NoNewline
    Write-Host "              │" -ForegroundColor Green
    Write-Host "  ╰" -ForegroundColor Green -NoNewline
    Write-Host ("─" * 71) -ForegroundColor DarkGreen -NoNewline
    Write-Host "╯" -ForegroundColor Green
    Write-Host ""
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
    
  Clear-Host
  Write-Host ""
  Write-Host ""
  Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ║                 " -ForegroundColor Green -NoNewline
  Write-Host "🎉 CONGRATULATIONS! 🎉" -ForegroundColor White -NoNewline
  Write-Host "                           ║" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ║           " -ForegroundColor Green -NoNewline
  Write-Host "You've completed the PoshGuard tutorial!" -ForegroundColor Cyan -NoNewline
  Write-Host "               ║" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ╠════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ║  " -ForegroundColor Green -NoNewline
  Write-Host "🏆 You now know how to:" -ForegroundColor Yellow -NoNewline
  Write-Host "                                           ║" -ForegroundColor Green
  Write-Host "  ║     " -ForegroundColor Green -NoNewline
  Write-Host "✓ Run PoshGuard safely with dry-run mode" -ForegroundColor White -NoNewline
  Write-Host "                       ║" -ForegroundColor Green
  Write-Host "  ║     " -ForegroundColor Green -NoNewline
  Write-Host "✓ Understand and interpret the output" -ForegroundColor White -NoNewline
  Write-Host "                           ║" -ForegroundColor Green
  Write-Host "  ║     " -ForegroundColor Green -NoNewline
  Write-Host "✓ Apply fixes to improve your code" -ForegroundColor White -NoNewline
  Write-Host "                             ║" -ForegroundColor Green
  Write-Host "  ║     " -ForegroundColor Green -NoNewline
  Write-Host "✓ Use backups and rollback if needed" -ForegroundColor White -NoNewline
  Write-Host "                           ║" -ForegroundColor Green
  Write-Host "  ║     " -ForegroundColor Green -NoNewline
  Write-Host "✓ Identify and fix security issues" -ForegroundColor White -NoNewline
  Write-Host "                              ║" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ║  " -ForegroundColor Green -NoNewline
  Write-Host "🚀 You're ready to write better PowerShell code!" -ForegroundColor White -NoNewline
  Write-Host "                  ║" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
  Write-Host ""
  Write-Host ""
}

Start-Tutorial

#endregion
