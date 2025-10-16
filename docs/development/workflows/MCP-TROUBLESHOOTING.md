# MCP Troubleshooting Guide

This guide helps you diagnose and resolve issues with Model Context Protocol (MCP) server configurations in PoshGuard.

## Quick Diagnostics

Run the validation script to check your MCP configuration:

```powershell
# PowerShell
pwsh -File .github/scripts/Test-MCPConfiguration.ps1

# With verbose output
pwsh -File .github/scripts/Test-MCPConfiguration.ps1 -Verbose

# Skip connectivity tests
pwsh -File .github/scripts/Test-MCPConfiguration.ps1 -SkipConnectivityTests
```

## Common Issues

### 1. "Personal Access Tokens are not supported for this endpoint"

**Symptom:** Error when GitHub Copilot tries to use the GitHub MCP server.

**Cause:** The GitHub MCP server configuration is using deprecated Personal Access Token (PAT) authentication.

**Solution:**

Remove the GitHub MCP server entry from `.github/copilot-mcp.json`. GitHub Copilot has built-in GitHub integration that doesn't require explicit configuration:

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

**Note:** Do NOT add a `github` server entry with PAT authentication. If you need GitHub access, use GitHub Copilot's native integration or OAuth-based authentication.

### 2. Environment Variables Not Set

**Symptom:** MCP servers fail with authentication errors or missing API keys.

**Cause:** Required environment variables are not set in your environment.

**Solution:**

Set the required environment variables:

```powershell
# PowerShell
$env:COPILOT_MCP_CONTEXT7_API_KEY = "your-context7-api-key"
$env:COPILOT_MCP_OPENAI_API_KEY = "your-openai-api-key"

# Bash/Zsh
export COPILOT_MCP_CONTEXT7_API_KEY="your-context7-api-key"
export COPILOT_MCP_OPENAI_API_KEY="your-openai-api-key"
```

**Persistence:**

For permanent setup, add to your shell profile:

- **PowerShell:** Add to `$PROFILE` (usually `~/.config/powershell/Microsoft.PowerShell_profile.ps1`)
- **Bash:** Add to `~/.bashrc` or `~/.bash_profile`
- **Zsh:** Add to `~/.zshrc`

**GitHub Actions/CI:**

Set as repository secrets in GitHub Settings → Secrets and variables → Actions:

- `COPILOT_MCP_CONTEXT7_API_KEY`
- `COPILOT_MCP_OPENAI_API_KEY`

### 3. Command Not Found (npx, uvx)

**Symptom:** Local MCP servers fail with "command not found" errors.

**Cause:** Required package managers are not installed.

**Solution:**

**For npx (Node.js):**

```powershell
# Windows
winget install OpenJS.NodeJS.LTS

# macOS
brew install node

# Ubuntu/Debian
sudo apt-get install nodejs npm

# Fedora/RHEL
sudo dnf install nodejs npm
```

**For uvx (Python):**

```powershell
# All platforms (requires Python 3.8+)
pip install uv
# or
pip3 install uv

# Verify installation
uvx --version
```

### 4. MCP Server Connectivity Issues

**Symptom:** HTTP 404, connection timeout, or SSL errors.

**Cause:** Server URL is incorrect, server is down, or network issues.

**Solution:**

1. **Verify URLs:** Check that server URLs in `.github/copilot-mcp.json` are correct
2. **Test connectivity manually:**

```powershell
# Test Context7
Invoke-WebRequest -Uri "https://mcp.context7.com/health" -Method Get

# Test OpenAI (requires API key)
Invoke-WebRequest -Uri "https://api.openai.com/v1/models" -Method Get -Headers @{
    "Authorization" = "Bearer $env:COPILOT_MCP_OPENAI_API_KEY"
}
```

3. **Check firewall/proxy:** Ensure your network allows connections to MCP servers
4. **Check server status:** Some servers may have maintenance windows or outages

### 5. JSON Syntax Errors

**Symptom:** Configuration validation fails with JSON parsing errors.

**Cause:** Invalid JSON syntax in `.github/copilot-mcp.json`.

**Solution:**

1. Use a JSON validator (e.g., [jsonlint.com](https://jsonlint.com/))
2. Check for:
   - Missing or extra commas
   - Unmatched brackets/braces
   - Unescaped quotes
   - Trailing commas (not allowed in JSON)

**Valid example:**

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "$COPILOT_MCP_CONTEXT7_API_KEY"
      },
      "tools": ["*"]
    }
  }
}
```

### 6. VS Code Not Detecting MCP Configuration

**Symptom:** GitHub Copilot in VS Code doesn't seem to use MCP servers.

**Cause:** VS Code needs to be restarted to pick up configuration changes.

**Solution:**

1. **Fully restart VS Code:** Use File → Exit (Windows/Linux) or Code → Quit (macOS)
2. **Do more than reload the window:** A window reload is not sufficient
3. **Verify GitHub Copilot is enabled:** Check status bar for Copilot icon
4. **Check Copilot logs:**
   - Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
   - Run "GitHub Copilot: View Logs"
   - Look for MCP server initialization messages

### 7. Permission Denied Errors

**Symptom:** MCP servers fail with permission or access denied errors.

**Cause:** File permissions or execution policies are blocking the servers.

**Solution:**

**Windows PowerShell execution policy:**

```powershell
# Check current policy
Get-ExecutionPolicy

# Set to allow local scripts (may require admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Linux/macOS file permissions:**

```bash
# Make script executable
chmod +x .github/scripts/Test-MCPConfiguration.ps1

# Fix npm/node permissions
sudo chown -R $(whoami) ~/.npm
```

### 8. API Rate Limiting

**Symptom:** MCP servers work initially but then fail with rate limit errors.

**Cause:** Too many requests to external APIs.

**Solution:**

1. **Use caching:** MCP queries are cached for 24 hours by default
2. **Reduce query frequency:** Limit how often you ask Copilot to query external servers
3. **Upgrade API plans:** If using free tier, consider paid plans with higher limits
4. **Check API quotas:**

```powershell
# Check OpenAI usage
Invoke-RestMethod -Uri "https://api.openai.com/v1/usage" -Headers @{
    "Authorization" = "Bearer $env:COPILOT_MCP_OPENAI_API_KEY"
}
```

## Server-Specific Issues

### Context7

**Issue:** API key invalid or expired

**Solution:**

1. Get a new API key from [context7.com](https://context7.com)
2. Update environment variable: `$env:COPILOT_MCP_CONTEXT7_API_KEY = "new-key"`
3. Restart VS Code

### OpenAI Web Search

**Issue:** uvx command hangs or fails

**Solution:**

1. Update uv: `pip install --upgrade uv`
2. Clear uv cache: `uv cache clean`
3. Test manually: `uvx openai-websearch-mcp --version`

**Issue:** OpenAI API errors

**Solution:**

1. Verify API key: Check it's a valid OpenAI API key starting with `sk-`
2. Check billing: Ensure your OpenAI account has credits
3. Test API directly:

```powershell
Invoke-RestMethod -Uri "https://api.openai.com/v1/models" -Headers @{
    "Authorization" = "Bearer $env:COPILOT_MCP_OPENAI_API_KEY"
}
```

### Fetch

**Issue:** npx fails to install or run mcp-fetch-server

**Solution:**

1. Clear npm cache: `npm cache clean --force`
2. Update npm: `npm install -g npm@latest`
3. Test manually: `npx -y mcp-fetch-server@latest --version`

### Playwright

**Issue:** Browser automation fails

**Solution:**

1. Install browser binaries: `npx playwright install`
2. Install system dependencies: `npx playwright install-deps`
3. Test manually:

```powershell
npx -y @playwright/mcp@latest
```

## Debugging Techniques

### 1. Enable Verbose Logging

```powershell
# Run validation with verbose output
pwsh -File .github/scripts/Test-MCPConfiguration.ps1 -Verbose

# Enable PowerShell debug mode
$DebugPreference = 'Continue'
```

### 2. Test Each Server Individually

```powershell
# Test Context7
$response = Invoke-WebRequest -Uri "https://mcp.context7.com/mcp" -Method Options
Write-Host "Context7 status: $($response.StatusCode)"

# Test OpenAI
uvx openai-websearch-mcp --help

# Test Fetch
npx -y mcp-fetch-server@latest --help

# Test Playwright
npx -y @playwright/mcp@latest --help
```

### 3. Check GitHub Copilot Extension Logs

1. Open VS Code Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Run "GitHub Copilot: View Logs"
3. Look for error messages or warnings
4. Search for "MCP" to find relevant log entries

### 4. Verify Environment Variables

```powershell
# PowerShell
Get-ChildItem Env: | Where-Object Name -like "COPILOT_MCP_*"

# Bash/Zsh
env | grep COPILOT_MCP
```

## Getting Help

If you're still experiencing issues:

1. **Run the diagnostic script:**

   ```powershell
   pwsh -File .github/scripts/Test-MCPConfiguration.ps1 -Verbose > mcp-diagnostics.txt
   ```

2. **Open an issue:** [PoshGuard Issues](https://github.com/cboyd0319/PoshGuard/issues)
   - Include the diagnostic output
   - Describe what you were trying to do
   - Include relevant error messages
   - Mention your OS and PowerShell version

3. **Check existing issues:** Someone may have already solved your problem

## Reference

- **Main MCP Guide:** [docs/MCP-GUIDE.md](../../MCP-GUIDE.md)
- **Validation Script:** [.github/scripts/Test-MCPConfiguration.ps1](../../../.github/scripts/Test-MCPConfiguration.ps1)
- **Configuration File:** [.github/copilot-mcp.json](../../../.github/copilot-mcp.json)
- **MCP Specification:** [modelcontextprotocol.io](https://modelcontextprotocol.io/)

## Security Notes

- **Never commit API keys to git:** Use environment variables only
- **Use secrets in CI/CD:** Store keys in GitHub Secrets or similar
- **Rotate keys regularly:** Generate new API keys periodically
- **Limit key permissions:** Use fine-grained tokens when possible
- **Monitor usage:** Check API usage to detect unauthorized access

---

**Last Updated:** 2025-10-13  
**Version:** 1.0.0
