# MCP Server Configuration

This repository is configured to use Model Context Protocol (MCP) servers with GitHub Copilot to enhance code suggestions and development capabilities.

## Overview

MCP (Model Context Protocol) allows GitHub Copilot to access additional tools and context sources to provide better suggestions. This repository includes four MCP servers:

### 1. Context7
- **Type**: HTTP Server
- **Purpose**: Provides access to up-to-date library documentation and code examples
- **Configuration**: Requires `COPILOT_MCP_CONTEXT7_API_KEY` environment variable

### 2. OpenAI Web Search
- **Type**: Local Server
- **Purpose**: Enables web search capabilities through OpenAI
- **Configuration**: Requires `COPILOT_MCP_OPENAI_API_KEY` environment variable
- **Command**: `uvx openai-websearch-mcp`

### 3. Fetch
- **Type**: Local Server
- **Purpose**: Fetches web content for analysis
- **Command**: `npx -y mcp-fetch-server@latest`

### 4. Playwright
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
# For Context7
export COPILOT_MCP_CONTEXT7_API_KEY="your-api-key-here"

# For OpenAI Web Search
export COPILOT_MCP_OPENAI_API_KEY="your-api-key-here"
```

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

### MCP servers not working in PoshGuard
1. Verify MCP is enabled: `Get-MCPStatus`
2. Check user consent is granted
3. Review logs for error messages
4. Ensure network connectivity for HTTP servers

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [GitHub Copilot MCP Documentation](https://docs.github.com/copilot)
- [PoshGuard AI/ML Integration](../docs/AI-ML-INTEGRATION.md)
