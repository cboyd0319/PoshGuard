# Creating the Demo GIF

To create an engaging demo GIF for the README, follow these steps:

## Recommended Tool

Use **asciinema** + **agg** for high-quality terminal recordings:

```bash
# Install asciinema (terminal recorder)
brew install asciinema  # macOS
apt install asciinema   # Linux

# Install agg (converts to GIF)
cargo install agg
```

## Recording Steps

1. **Prepare demo script**:
```powershell
# Use the sample file
cd samples/
cp before-security-issues.ps1 demo-script.ps1
```

2. **Start recording**:
```bash
asciinema rec demo.cast
```

3. **Run commands** (what viewers will see):
```powershell
# Show the problematic file
cat demo-script.ps1

# Run PoshGuard with diff output
../tools/Apply-AutoFix.ps1 -Path ./demo-script.ps1 -ShowDiff -DryRun

# Show summary
echo "✓ Fixed 12 issues: 5 security, 4 formatting, 3 best practices"
```

4. **Stop recording**: Press `Ctrl+D`

5. **Convert to GIF**:
```bash
agg demo.cast demo.gif --speed 1.5 --cols 100 --rows 30
```

6. **Optimize GIF size**:
```bash
gifsicle -O3 --colors 256 demo.gif -o demo-optimized.gif
```

7. **Move to docs folder**:
```bash
mv demo-optimized.gif ../docs/demo.gif
```

## Alternative: Use TerminalGIF

If you prefer a simpler tool:

1. Visit https://terminalizer.com/
2. Install: `npm install -g terminalizer`
3. Record: `terminalizer record demo`
4. Render: `terminalizer render demo`

## What to Show

**Ideal demo flow (30-45 seconds)**:
1. Show messy script with violations (5 sec)
2. Run `Apply-AutoFix.ps1 -ShowDiff` (10 sec)
3. Display unified diff with color highlighting (15 sec)
4. Show before/after comparison (10 sec)
5. Display success message with stats (5 sec)

## Styling Tips

- Use a clean terminal theme (e.g., "Solarized Dark" or "Dracula")
- Set font size to 14-16pt for readability
- Keep terminal width to ~100 columns
- Use syntax highlighting for PowerShell
- Show cursor movement naturally (don't rush)
- Add 2-3 second pause at key moments

## Example Script

```powershell
# demo-recording-script.ps1
# Run this for consistent demo

Clear-Host
Write-Host "PoshGuard Demo - Auto-fixing security issues" -ForegroundColor Cyan
Write-Host ""

# Show problematic file
Write-Host "→ Analyzing script with violations..." -ForegroundColor Yellow
Get-Content ./samples/before-security-issues.ps1 -Head 15
Write-Host "..." -ForegroundColor DarkGray
Write-Host ""

# Run PoshGuard
Write-Host "→ Running PoshGuard..." -ForegroundColor Yellow
./tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -ShowDiff -DryRun

# Show summary
Write-Host ""
Write-Host "✓ Analysis complete!" -ForegroundColor Green
Write-Host "  • 5 security issues fixed" -ForegroundColor Green
Write-Host "  • 4 formatting improvements" -ForegroundColor Green
Write-Host "  • 3 best practices applied" -ForegroundColor Green
```

## Current Status

**TODO**: Record and generate demo.gif following the steps above.

For now, the README references `docs/demo.gif` which should be created before the next release.

## Quick Alternative

If pressed for time, use a static screenshot instead:

```powershell
# Take screenshot of diff output
./tools/Apply-AutoFix.ps1 -Path ./samples/before-security-issues.ps1 -ShowDiff | Out-File demo-output.txt
# Then screenshot the terminal and save as demo.png
```

Update README.md to use `.png` instead of `.gif` if using screenshot approach.
