#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Display a beautiful getting started guide for PoshGuard

.DESCRIPTION
    Shows a comprehensive, visually appealing getting started guide for new users.
    Assumes ZERO technical knowledge and provides clear, step-by-step instructions.
    
.EXAMPLE
    .\Show-GettingStarted.ps1
    Display the getting started guide

.NOTES
    Version: 1.0.0
    Audience: Complete beginners
    Prerequisites: NONE
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest

function Show-GettingStarted {
  Clear-Host
  Write-Host ""
  Write-Host ""
  Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ║           " -ForegroundColor Cyan -NoNewline
  Write-Host "🚀  Welcome to PoshGuard!" -ForegroundColor White -NoNewline
  Write-Host "                                 ║" -ForegroundColor Cyan
  Write-Host "  ║           " -ForegroundColor Cyan -NoNewline
  Write-Host "The World's Best PowerShell QA Tool" -ForegroundColor Gray -NoNewline
  Write-Host "                   ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ║                                                                    ║" -ForegroundColor Cyan
  Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""
  Write-Host ""
    
  Write-Host "  ╭─ 🎯 What is PoshGuard? " -ForegroundColor Green -NoNewline
  Write-Host ("─" * 46) -ForegroundColor DarkGreen -NoNewline
  Write-Host "╮" -ForegroundColor Green
  Write-Host "  │" -ForegroundColor Green
  Write-Host "  │  PoshGuard automatically fixes issues in your PowerShell scripts:" -ForegroundColor White
  Write-Host "  │" -ForegroundColor Green
  Write-Host "  │    " -ForegroundColor Green -NoNewline
  Write-Host "✅  Improves code quality and readability" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Green -NoNewline
  Write-Host "🔒  Finds and fixes security vulnerabilities" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Green -NoNewline
  Write-Host "🎓  Teaches best practices" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Green -NoNewline
  Write-Host "⚡  Saves you time with automation" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Green -NoNewline
  Write-Host "🤖  Uses AI/ML for smart, self-improving fixes" -ForegroundColor White
  Write-Host "  │" -ForegroundColor Green
  Write-Host "  ╰" -ForegroundColor Green -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkGreen -NoNewline
  Write-Host "╯" -ForegroundColor Green
  Write-Host ""
    
  Write-Host "  ╭─ 📚 Quick Start Guide " -ForegroundColor Cyan -NoNewline
  Write-Host ("─" * 49) -ForegroundColor DarkCyan -NoNewline
  Write-Host "╮" -ForegroundColor Cyan
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host "Step 1: Preview fixes (safe - no changes)" -ForegroundColor Yellow
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host "────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
  Write-Host "  │    " -ForegroundColor Cyan -NoNewline
  Write-Host "Invoke-PoshGuard -Path .\MyScript.ps1 -DryRun" -ForegroundColor White
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │    " -ForegroundColor Cyan -NoNewline
  Write-Host "💡 This shows what PoshGuard would fix WITHOUT making changes" -ForegroundColor Gray
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host "Step 2: Apply fixes" -ForegroundColor Yellow
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host "────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
  Write-Host "  │    " -ForegroundColor Cyan -NoNewline
  Write-Host "Invoke-PoshGuard -Path .\MyScript.ps1" -ForegroundColor White
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │    " -ForegroundColor Cyan -NoNewline
  Write-Host "💡 PoshGuard creates backups automatically before making changes" -ForegroundColor Gray
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host "Step 3: Fix entire folders" -ForegroundColor Yellow
  Write-Host "  │  " -ForegroundColor Cyan -NoNewline
  Write-Host "────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
  Write-Host "  │    " -ForegroundColor Cyan -NoNewline
  Write-Host "Invoke-PoshGuard -Path .\MyScriptsFolder" -ForegroundColor White
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  │    " -ForegroundColor Cyan -NoNewline
  Write-Host "💡 Processes all .ps1, .psm1, and .psd1 files in the folder" -ForegroundColor Gray
  Write-Host "  │" -ForegroundColor Cyan
  Write-Host "  ╰" -ForegroundColor Cyan -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkCyan -NoNewline
  Write-Host "╯" -ForegroundColor Cyan
  Write-Host ""
    
  Write-Host "  ╭─ 🎓 Learning Resources " -ForegroundColor Magenta -NoNewline
  Write-Host ("─" * 48) -ForegroundColor DarkMagenta -NoNewline
  Write-Host "╮" -ForegroundColor Magenta
  Write-Host "  │" -ForegroundColor Magenta
  Write-Host "  │    " -ForegroundColor Magenta -NoNewline
  Write-Host "🎮  Interactive Tutorial:  " -ForegroundColor White -NoNewline
  Write-Host ".\tools\Start-InteractiveTutorial.ps1" -ForegroundColor Cyan
  Write-Host "  │       " -ForegroundColor Magenta -NoNewline
  Write-Host "30-minute hands-on guide (perfect for beginners!)" -ForegroundColor Gray
  Write-Host "  │" -ForegroundColor Magenta
  Write-Host "  │    " -ForegroundColor Magenta -NoNewline
  Write-Host "📖  Beginner's Guide:     " -ForegroundColor White -NoNewline
  Write-Host "docs/BEGINNERS-GUIDE.md" -ForegroundColor Cyan
  Write-Host "  │       " -ForegroundColor Magenta -NoNewline
  Write-Host "Complete written guide with examples" -ForegroundColor Gray
  Write-Host "  │" -ForegroundColor Magenta
  Write-Host "  │    " -ForegroundColor Magenta -NoNewline
  Write-Host "📚  Full Documentation:   " -ForegroundColor White -NoNewline
  Write-Host "README.md" -ForegroundColor Cyan
  Write-Host "  │       " -ForegroundColor Magenta -NoNewline
  Write-Host "All features, options, and advanced usage" -ForegroundColor Gray
  Write-Host "  │" -ForegroundColor Magenta
  Write-Host "  ╰" -ForegroundColor Magenta -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkMagenta -NoNewline
  Write-Host "╯" -ForegroundColor Magenta
  Write-Host ""
    
  Write-Host "  ╭─ 💡 Pro Tips " -ForegroundColor Yellow -NoNewline
  Write-Host ("─" * 58) -ForegroundColor DarkYellow -NoNewline
  Write-Host "╮" -ForegroundColor Yellow
  Write-Host "  │" -ForegroundColor Yellow
  Write-Host "  │    " -ForegroundColor Yellow -NoNewline
  Write-Host "1. Always use -DryRun first to preview changes" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Yellow -NoNewline
  Write-Host "2. PoshGuard creates automatic backups - but test on copies first!" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Yellow -NoNewline
  Write-Host "3. Run the interactive tutorial if you're new to PowerShell" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Yellow -NoNewline
  Write-Host "4. Check the confidence score - 0.9+ means high quality fix" -ForegroundColor White
  Write-Host "  │    " -ForegroundColor Yellow -NoNewline
  Write-Host "5. Use -Verbose for detailed information about what's happening" -ForegroundColor White
  Write-Host "  │" -ForegroundColor Yellow
  Write-Host "  ╰" -ForegroundColor Yellow -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkYellow -NoNewline
  Write-Host "╯" -ForegroundColor Yellow
  Write-Host ""
    
  Write-Host "  ╭─ 🆘 Need Help? " -ForegroundColor Red -NoNewline
  Write-Host ("─" * 56) -ForegroundColor DarkRed -NoNewline
  Write-Host "╮" -ForegroundColor Red
  Write-Host "  │" -ForegroundColor Red
  Write-Host "  │    " -ForegroundColor Red -NoNewline
  Write-Host "📝  Report Issues:  " -ForegroundColor White -NoNewline
  Write-Host "https://github.com/cboyd0319/PoshGuard/issues" -ForegroundColor Cyan
  Write-Host "  │    " -ForegroundColor Red -NoNewline
  Write-Host "💬  Ask Questions:  " -ForegroundColor White -NoNewline
  Write-Host "GitHub Discussions" -ForegroundColor Cyan
  Write-Host "  │    " -ForegroundColor Red -NoNewline
  Write-Host "📧  Email Support:  " -ForegroundColor White -NoNewline
  Write-Host "Available through GitHub" -ForegroundColor Cyan
  Write-Host "  │" -ForegroundColor Red
  Write-Host "  ╰" -ForegroundColor Red -NoNewline
  Write-Host ("─" * 71) -ForegroundColor DarkRed -NoNewline
  Write-Host "╯" -ForegroundColor Red
  Write-Host ""
  Write-Host ""
    
  Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ║     " -ForegroundColor Green -NoNewline
  Write-Host "✨  Ready to improve your PowerShell code? Let's go!  ✨" -ForegroundColor White -NoNewline
  Write-Host "          ║" -ForegroundColor Green
  Write-Host "  ║                                                                    ║" -ForegroundColor Green
  Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
  Write-Host ""
  Write-Host ""
}

Show-GettingStarted
