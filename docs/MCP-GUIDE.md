# Model Context Protocol (MCP) Integration Guide

## TL;DR

PoshGuard integrates with MCP servers to enhance GitHub Copilot and AI-assisted development. MCP is opt-in, privacy-first, and runs mostly on your machine. Set up environment variables, restart VS Code, and Copilot gets superpowers: current docs, web search, browser automation.

## Quick Setup

```powershell
# Set API keys (PowerShell)
$env:COPILOT_MCP_CONTEXT7_API_KEY = "your-key-here"
$env:COPILOT_MCP_OPENAI_API_KEY = "your-key-here"

# Or in Bash/Zsh
export COPILOT_MCP_CONTEXT7_API_KEY="your-key-here"
export COPILOT_MCP_OPENAI_API_KEY="your-key-here"

# Verify dependencies
node --version  # Required for local servers
uvx --version   # Required for Python servers
```

Restart VS Code. Done.

## What You Get

| Server | Purpose | Setup | Runs Where |
|--------|---------|-------|------------|
| **Context7** | Up-to-date library documentation | API key required | Cloud (HTTP) |
| **OpenAI Web Search** | Current web information | API key required | Local (Python) |
| **Fetch** | Web content retrieval | None | Local (Node.js) |
| **Playwright** | Browser automation | None | Local (Node.js) |

## Why MCP Matters

GitHub Copilot's training data gets stale. MCP fixes this by letting Copilot:

1. **Query live documentation** - No more hallucinated API calls or outdated syntax
2. **Search the web** - Find recent best practices, security updates, breaking changes
3. **Fetch real content** - Analyze actual web pages, not guesses
4. **Automate browsers** - Test your code against real browsers

Result: Better suggestions, fewer errors, less fact-checking.

## Configuration Files

### `.github/copilot-mcp.json`

This file configures MCP servers for GitHub Copilot. GitHub Copilot automatically detects it when you open this repo.

**Example queries you can make:**

```
@workspace Use Context7 to get PowerShell AST documentation for token replacement

@workspace Search the web for recent PowerShell security best practices

@workspace Fetch content from https://example.com and analyze the code patterns

@workspace Use Playwright to test this PowerShell script's output in a browser
```

### `config/poshguard.json`

The MCP section in this file lets PoshGuard integrate with MCP servers directly (not Copilot). By default, disabled—requires user consent.

```json
{
  "mcp": {
    "enabled": false,
    "consent_given": false,
    "servers": ["context7", "openai-websearch", "fetch", "playwright"]
  }
}
```

## Using MCP in PoshGuard Code

You can query MCP servers directly from PowerShell:

```powershell
# Import the MCP integration module
Import-Module ./tools/lib/MCPIntegration.psm1

# Enable MCP (requires user consent)
Enable-MCPIntegration -ServerType All -ConsentGiven

# Check status
Get-MCPStatus

# Query for context
$context = Invoke-MCPQuery -Query "PowerShell best practices for SecureString"
Write-Host "MCP Response: $context"

# Disable when done
Disable-MCPIntegration
```

## Privacy & Security

**Opt-in by default.** No data leaves your machine without explicit consent.

- **Local servers** (Fetch, Playwright): Run on your machine, no external calls
- **HTTP servers** (Context7, OpenAI): Require API keys YOU control
- **GitHub Copilot**: Uses your GitHub account, follows Copilot privacy policy
- **Logging**: All queries logged for transparency (check logs if paranoid)
- **No telemetry**: PoshGuard doesn't send usage data to external servers

**You control the keys, you control the data.**

## Detailed Server Setup

### Context7 (Documentation)

**What it does:** Pulls version-specific, accurate documentation from library sources. No more "that method doesn't exist" surprises.

**Setup:**

```powershell
# Get API key from https://context7.com
$env:COPILOT_MCP_CONTEXT7_API_KEY = "your-key"
```

**Use case:**

```
@workspace Use Context7 to get the latest PSScriptAnalyzer rule documentation
```

### OpenAI Web Search (Current Info)

**What it does:** Searches the web using OpenAI's search capabilities. Gets you current information, not training data from 2023.

**Setup:**

```powershell
# Requires OpenAI API key
$env:COPILOT_MCP_OPENAI_API_KEY = "sk-..."

# Verify uvx is installed (Python package runner)
uvx --version
```

**Use case:**

```
@workspace Search for recent PowerShell 7.4 breaking changes
```

### Fetch (Web Content)

**What it does:** Retrieves web content and makes it available to Copilot. Useful for analyzing real-world examples.

**Setup:**

```bash
# No setup needed - uses npx to run on demand
npx -y mcp-fetch-server@latest
```

**Use case:**

```
@workspace Fetch https://github.com/PowerShell/PSScriptAnalyzer and summarize their coding patterns
```

### Playwright (Browser Automation)

**What it does:** Automates browser interactions. Great for testing web-based tools or scraping structured data.

**Setup:**

```bash
# No setup needed - uses npx to run on demand
npx -y @playwright/mcp@latest
```

**Use case:**

```
@workspace Use Playwright to test if our HTML report renders correctly in Chrome
```

## Troubleshooting

For comprehensive troubleshooting, see **[MCP Troubleshooting](development/workflows/MCP-TROUBLESHOOTING.md)**

### Quick Diagnostics

Run the validation script to test your MCP configuration:

```powershell
pwsh -File .github/scripts/Test-MCPConfiguration.ps1
```

### MCP not working in Copilot

**Check:**

1. GitHub Copilot extension enabled? (Look at VS Code status bar)
2. Environment variables set? (Restart VS Code after setting)
3. Node.js installed? (`node --version`)
4. Python/uvx installed? (`uvx --version`)

**Fix:**

```powershell
# Verify environment variables are set
Get-ChildItem Env: | Where-Object Name -like "COPILOT_MCP_*"

# Restart VS Code completely (do more than reload the window)
# File → Exit (Windows/Linux) or Code → Quit (macOS)
```

### GitHub PAT errors

**Error:** "Personal Access Tokens are not supported for this endpoint"

**Why:** GitHub Copilot MCP endpoint does not support Personal Access Token authentication.

**Fix:**

**Recommended: Remove GitHub MCP server configuration**

The GitHub MCP server is not needed in `.github/copilot-mcp.json`. GitHub Copilot has built-in GitHub integration that works automatically. Simply remove the `github` server entry from your configuration.

**Correct configuration:**

```json
{
  "mcpServers": {
    "context7": { ... },
    "openai-websearch": { ... },
    "fetch": { ... },
    "playwright": { ... }
  }
}
```

**Do not include:**

```json
{
  "github": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/",
    "headers": {
      "Authorization": "Bearer $COPILOT_MCP_GITHUB_PERSONAL_ACCESS_TOKEN"
    }
  }
}
```

For more details, see [MCP Troubleshooting](development/workflows/MCP-TROUBLESHOOTING.md).

### MCP servers not working in PoshGuard

**Check:**

```powershell
# Verify MCP is enabled
Get-MCPStatus

# Check logs for errors
Get-Content ./logs/mcp.log -Tail 50

# Verify consent was granted
Get-Content ./config/poshguard.json | Select-String "consent_given"
```

**Fix:**

```powershell
# Re-enable with consent
Enable-MCPIntegration -ServerType All -ConsentGiven -Force

# Test connectivity (for HTTP servers)
Invoke-WebRequest -Uri "https://api.context7.com/health" -Method GET
```

### Node.js or Python missing

**Fix:**

**Windows:**

```powershell
# Install Node.js
winget install OpenJS.NodeJS.LTS

# Install Python
winget install Python.Python.3.12

# Install uvx (Python package runner)
pip install uvx
```

**macOS:**

```bash
# Install Node.js
brew install node

# Install Python
brew install python@3.12

# Install uvx
pip3 install uvx
```

**Linux:**

```bash
# Ubuntu/Debian
sudo apt-get install nodejs npm python3 python3-pip
pip3 install uvx

# Fedora/RHEL
sudo dnf install nodejs npm python3 python3-pip
pip3 install uvx
```

## Using Copilot with MCP

### Basic Usage

1. **Open a PowerShell file in VS Code**
2. **Use `@workspace` prefix in Copilot Chat:**

```
@workspace How do I parse AST tokens in PowerShell?

@workspace Generate a Pester test for this function

@workspace Use Context7 to get PSScriptAnalyzer best practices
```

3. **Get inline suggestions:**

Type a comment describing what you want, and Copilot suggests code:

```powershell
# Create a function that replaces aliases with full cmdlet names using AST
```

### Advanced Workflows

**Workflow 1: Add a new auto-fix rule**

```
@workspace I want to add an auto-fix rule for PSAvoidUsingPositionalParameters.
Use Context7 to get the rule documentation, then generate the module structure
following PoshGuard patterns.
```

**Workflow 2: Debug an AST transformation**

```powershell
# Open the file with the issue
code ./PoshGuard/AutoFix/PSAvoidUsingCmdletAliases.psm1

# Ask Copilot to explain
@workspace Explain what this AST transformation is doing and why it might fail
on nested script blocks
```

**Workflow 3: Research best practices**

```
@workspace Search for recent PowerShell security best practices for handling
user input. Then review our current input validation and suggest improvements.
```

**Workflow 4: Analyze external code**

```
@workspace Fetch https://github.com/PowerShell/PSScriptAnalyzer/blob/main/Rules/AvoidUsingCmdletAliases.psm1
and compare their approach to ours. What can we learn?
```

## Example Queries That Work Well

| Goal | Query |
|------|-------|
| **Get docs** | `@workspace Use Context7 to get PowerShell AST documentation for [System.Management.Automation.Language.Ast]` |
| **Research** | `@workspace Search for recent discussions about PowerShell AST performance optimization` |
| **Analyze** | `@workspace Fetch [URL] and summarize the code patterns they use` |
| **Generate** | `@workspace Generate a Pester test for this function following our test patterns` |
| **Explain** | `@workspace Explain how this AST visitor works and what edge cases it handles` |
| **Compare** | `@workspace Compare our approach to [URL] and suggest improvements` |

## Best Practices

1. **Always use `@workspace`** - Ensures Copilot loads project context
2. **Be specific** - "Generate tests for X" beats "write some tests"
3. **Reference patterns** - "Following PoshGuard patterns" helps consistency
4. **Ask for explanations** - Understand before accepting suggestions
5. **Iterate** - If first suggestion misses, add more context and try again
6. **Review everything** - Copilot is smart but not infallible

## Disabling MCP

### In GitHub Copilot

Remove or rename `.github/copilot-mcp.json`:

```powershell
cd /Users/chadboyd/Documents/GitHub/PoshGuard
Rename-Item .github/copilot-mcp.json .github/copilot-mcp.json.disabled
```

Restart VS Code.

### In PoshGuard

```powershell
Disable-MCPIntegration
```

Or edit `config/poshguard.json`:

```json
{
  "mcp": {
    "enabled": false
  }
}
```

## Requirements

| Requirement | Purpose | Version |
|-------------|---------|---------|
| **Node.js** | Local MCP servers (fetch, playwright) | 16.x+ |
| **Python/uvx** | OpenAI Web Search server | Python 3.8+, uvx latest |
| **GitHub Copilot** | IDE integration | Latest |
| **PowerShell** | PoshGuard MCP integration | 5.1+ |

## Resources

- **[GitHub Copilot Setup Guide](development/workflows/copilot-instructions.md)** - Complete Copilot configuration walkthrough
- **[Model Context Protocol](https://modelcontextprotocol.io/)** - Official MCP specification
- **[GitHub Copilot Docs](https://docs.github.com/copilot)** - GitHub's official documentation
- **[PowerShell AST Documentation](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language)** - .NET AST reference

## Next Steps

1. **Set up environment variables** (see Quick Setup)
2. **Restart VS Code**
3. **Try a simple query:** `@workspace How do I add a new auto-fix rule?`
4. **Read the Copilot Setup Guide** for advanced workflows
5. **Experiment!** The best way to learn is by using it

---

**Questions?** Open an issue or ask Copilot: `@workspace How does MCP integration work in PoshGuard?`
