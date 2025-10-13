# MCP Server Configuration

This repository is configured to use Model Context Protocol (MCP) servers with GitHub Copilot to enhance code suggestions and development capabilities.

## Overview

MCP (Model Context Protocol) allows GitHub Copilot to access additional tools and context sources to provide better suggestions. This repository includes five MCP servers:

### 1. GitHub
- **Type**: HTTP Server
- **Purpose**: Access GitHub API for repository data, issues, pull requests, and more
- **Configuration**: Requires `COPILOT_MCP_GITHUB_PERSONAL_ACCESS_TOKEN` environment variable
- **Note**: Some GitHub API endpoints may not support Personal Access Tokens (PATs) and require OAuth authentication. If you encounter "Personal Access Tokens are not supported for this endpoint" errors, consider using OAuth authentication instead or using a GitHub App token.

### 2. Context7
- **Type**: HTTP Server
- **Purpose**: Pulls up-to-date, version-specific documentation and code examples directly from the source. Context7 solves the problem of LLMs relying on outdated or generic information about libraries by providing accurate, relevant documentation that eliminates hallucinations and helps AI tools better understand your stack.
- **Configuration**: Requires `COPILOT_MCP_CONTEXT7_API_KEY` environment variable

### 3. OpenAI Web Search
- **Type**: Local Server
- **Purpose**: Enables web search capabilities through OpenAI
- **Configuration**: Requires `COPILOT_MCP_OPENAI_API_KEY` environment variable
- **Command**: `uvx openai-websearch-mcp`

### 4. Fetch
- **Type**: Local Server
- **Purpose**: Fetches web content for analysis
- **Command**: `npx -y mcp-fetch-server@latest`

### 5. Playwright
- **Type**: Local Server
- **Purpose**: Browser automation capabilities
- **Command**: `npx -y @playwright/mcp@latest`

## Configuration Files

### GitHub Copilot Configuration
Location: `.github/copilot-mcp.json`

This file configures MCP servers for GitHub Copilot IDE integration. GitHub Copilot will automatically detect and use these servers when working in this repository.

### PoshGuard Application Configuration
Location: `config/poshguard.json`

The MCP section in the application configuration file allows PoshGuard to integrate with MCP servers. By default, MCP integration is disabled and requires explicit user consent.

## Usage

### For GitHub Copilot Users

GitHub Copilot will automatically use the configured MCP servers when you open this repository in a supported IDE (VS Code, Visual Studio, etc.). No additional setup is required if you have:

1. GitHub Copilot installed and active
2. The required environment variables set (if using HTTP servers)
3. Node.js installed (for local MCP servers)

### For PoshGuard Users

To enable MCP integration in PoshGuard:

```powershell
# Import the MCP integration module
Import-Module ./tools/lib/MCPIntegration.psm1

# Enable MCP with user consent
Enable-MCPIntegration -ServerType All -ConsentGiven

# Check MCP status
Get-MCPStatus

# Query MCP servers for context
$context = Invoke-MCPQuery -Query "PowerShell best practices for SecureString"
```

## Privacy and Security

- **Opt-in**: MCP integration is disabled by default and requires explicit user consent
- **Privacy-first**: No data is transmitted to external servers without user consent
- **Local-first**: Most MCP servers run locally on your machine
- **Transparency**: All MCP queries are logged and can be reviewed

## Environment Variables

If using HTTP-based MCP servers, you may need to set environment variables:

```bash
# For GitHub MCP Server
export COPILOT_MCP_GITHUB_PERSONAL_ACCESS_TOKEN="your-github-pat-here"

# For Context7
export COPILOT_MCP_CONTEXT7_API_KEY="your-api-key-here"

# For OpenAI Web Search
export COPILOT_MCP_OPENAI_API_KEY="your-api-key-here"
```

**Important Note about GitHub Personal Access Tokens:**
Some GitHub API endpoints no longer support Personal Access Tokens (PATs) and require OAuth authentication or GitHub App tokens. If you encounter errors like "Personal Access Tokens are not supported for this endpoint", you have the following options:

1. **Use OAuth authentication**: Configure the GitHub MCP server to use OAuth instead of a PAT
2. **Use a GitHub App token**: Create a GitHub App and use installation tokens instead
3. **Use a fine-grained PAT**: Some endpoints accept fine-grained PATs but not classic PATs
4. **Contact your admin**: If you're on an Enterprise plan, your organization may have PAT restrictions

For most use cases, OAuth authentication is recommended for the GitHub MCP server.

## Disabling MCP

### In GitHub Copilot
Remove or rename the `.github/copilot-mcp.json` file.

### In PoshGuard
```powershell
Disable-MCPIntegration
```

Or edit `config/poshguard.json` and set:
```json
"mcp": {
  "enabled": false
}
```

## Requirements

- **Node.js**: Required for local MCP servers (fetch, playwright, openai-websearch)
- **Python/uvx**: Required for Python-based MCP servers (openai-websearch uses `uvx`)
- **GitHub Copilot**: For IDE integration
- **PowerShell 5.1+**: For PoshGuard MCP integration

## Troubleshooting

### MCP servers not working in GitHub Copilot
1. Check that GitHub Copilot is enabled and active
2. Verify environment variables are set correctly
3. Ensure Node.js is installed and in PATH
4. Restart your IDE

### GitHub MCP Server: "Personal Access Tokens are not supported for this endpoint"
This error occurs when the GitHub API endpoint being accessed no longer supports Personal Access Token (PAT) authentication. 

**Solutions:**
1. **Use OAuth authentication (Recommended)**:
   - Remove the `headers` section from the GitHub MCP server configuration
   - Let GitHub Copilot use OAuth authentication automatically
   - Update `.github/copilot-mcp.json`:
     ```json
     "github": {
       "type": "http",
       "url": "https://api.githubcopilot.com/mcp/",
       "tools": ["*"]
     }
     ```

2. **Use a fine-grained Personal Access Token**:
   - Create a fine-grained PAT instead of a classic PAT
   - Fine-grained PATs have better support for newer API endpoints
   - Set appropriate scopes: `repo`, `read:packages`, etc.

3. **Use a GitHub App token**:
   - Create a GitHub App and generate installation tokens
   - GitHub App tokens have broader API support than PATs

4. **Check Enterprise restrictions**:
   - If you're on GitHub Enterprise, your organization may restrict PATs
   - Contact your administrator to enable PATs or OAuth apps

5. **Use local MCP server**:
   - Run the GitHub MCP server locally using Docker
   - Local servers may have different authentication requirements

### MCP servers not working in PoshGuard
1. Verify MCP is enabled: `Get-MCPStatus`
2. Check user consent is granted
3. Review logs for error messages
4. Ensure network connectivity for HTTP servers

## Complete Setup Guide

For a comprehensive guide on using GitHub Copilot with PoshGuard, including MCP integration, see:
- **[GitHub Copilot Setup Guide](COPILOT-SETUP-GUIDE.md)** — Complete guide with examples, workflows, and troubleshooting

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [GitHub Copilot MCP Documentation](https://docs.github.com/copilot)
- [PoshGuard AI/ML Integration](../docs/AI-ML-INTEGRATION.md)
- [GitHub Copilot Instructions](copilot-instructions.md) — Project-specific context for Copilot
