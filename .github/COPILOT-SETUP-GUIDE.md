# GitHub Copilot Setup Guide for PoshGuard

This guide explains how to get the most out of GitHub Copilot when working on the PoshGuard project.

## Overview

PoshGuard is configured with comprehensive GitHub Copilot support to enhance your development experience. The configuration includes:

1. **Workspace Instructions** - Provides Copilot with detailed context about the project
2. **MCP Server Integration** - Enables advanced capabilities through Model Context Protocol
3. **Editor Configuration** - Recommended settings for optimal development

## Quick Start

### Prerequisites

- GitHub Copilot subscription (Individual, Business, or Enterprise)
- VS Code with GitHub Copilot extensions installed
- Node.js (for MCP servers)
- Python/uvx (for Python-based MCP servers)

### Basic Setup

1. **Open the repository in VS Code**
   ```bash
   code /path/to/PoshGuard
   ```

2. **Install recommended extensions**
   
   VS Code will prompt you to install recommended extensions. Accept to install:
   - PowerShell
   - GitHub Copilot
   - GitHub Copilot Chat
   - And other helpful extensions

3. **Copy recommended settings (optional)**
   ```bash
   cp -r .vscode.recommended .vscode
   ```

4. **Start coding**
   
   Copilot will automatically use the workspace instructions and MCP servers.

## Configuration Files

### 1. Copilot Instructions (`.github/copilot-instructions.md`)

This file provides Copilot with comprehensive context about PoshGuard:

- **Project Overview**: What PoshGuard is and how it works
- **Project Structure**: Directory layout and organization
- **Coding Standards**: PowerShell style guide and conventions
- **Key Features**: AST transformations, ML/AI integration, standards compliance
- **Development Workflow**: How to add features and test changes
- **Common Patterns**: Reusable code patterns and best practices
- **Security Considerations**: Security best practices
- **Performance Tips**: Optimization guidelines

**How it helps**: Copilot uses this context to provide better suggestions that align with PoshGuard's architecture, coding standards, and patterns.

### 2. MCP Configuration (`.github/copilot-mcp.json`)

Configures Model Context Protocol servers that extend Copilot's capabilities:

#### Context7
- **Purpose**: Provides up-to-date, version-specific documentation
- **Setup**: Requires `COPILOT_MCP_CONTEXT7_API_KEY` environment variable
- **Benefit**: Eliminates hallucinations about libraries and provides accurate documentation

#### OpenAI Web Search
- **Purpose**: Enables web search capabilities
- **Setup**: Requires `COPILOT_MCP_OPENAI_API_KEY` environment variable
- **Benefit**: Access to current information and recent developments

#### Fetch
- **Purpose**: Fetches web content for analysis
- **Setup**: No additional configuration needed (uses npx)
- **Benefit**: Can retrieve and analyze web resources

#### Playwright
- **Purpose**: Browser automation capabilities
- **Setup**: No additional configuration needed (uses npx)
- **Benefit**: Can automate browser interactions for testing

### 3. Editor Configuration

#### `.editorconfig`
Ensures consistent formatting across different editors:
- UTF-8 encoding
- LF line endings
- 4-space indentation for PowerShell
- 2-space indentation for JSON/YAML/Markdown

#### `.vscode.recommended/`
Recommended VS Code workspace settings:
- PowerShell formatting with OTBS (One True Brace Style)
- PSScriptAnalyzer integration
- Copilot enablement for PowerShell files
- File associations and exclusions

## Setting Up MCP Servers

### Environment Variables

If you want to use HTTP-based MCP servers, set these environment variables:

**Windows (PowerShell)**:
```powershell
# Add to your PowerShell profile ($PROFILE)
$env:COPILOT_MCP_CONTEXT7_API_KEY = "your-api-key-here"
$env:COPILOT_MCP_OPENAI_API_KEY = "your-api-key-here"
```

**Linux/macOS (Bash)**:
```bash
# Add to ~/.bashrc or ~/.zshrc
export COPILOT_MCP_CONTEXT7_API_KEY="your-api-key-here"
export COPILOT_MCP_OPENAI_API_KEY="your-api-key-here"
```

### Installing MCP Dependencies

The local MCP servers require Node.js and Python:

```bash
# Verify Node.js is installed
node --version

# Verify Python/uvx is installed
uvx --version

# Test MCP servers
npx -y mcp-fetch-server@latest --version
npx -y @playwright/mcp@latest --version
uvx openai-websearch-mcp --version
```

## Using Copilot with PoshGuard

### Getting Started

1. **Open a PowerShell file**
   - Copilot will automatically use the workspace context
   - Start typing and Copilot will suggest completions

2. **Ask questions in Copilot Chat**
   ```
   @workspace How do I add a new auto-fix rule?
   @workspace What's the pattern for AST-based transformations?
   @workspace How do I write tests for a new rule?
   ```

3. **Generate code with context**
   ```
   # Type a comment describing what you want:
   # Create a function that fixes PSAvoidUsingCmdletAliases violations
   
   # Copilot will suggest implementation following PoshGuard patterns
   ```

### Best Practices

1. **Use @workspace in Chat**
   - Always use `@workspace` to ensure Copilot uses project context
   - Example: `@workspace How does PoshGuard handle backups?`

2. **Reference existing patterns**
   - Look at existing auto-fix modules for patterns
   - Copilot will suggest similar implementations

3. **Ask for explanations**
   - `@workspace Explain how AST parsing works in this file`
   - `@workspace What does this function do?`

4. **Request code generation**
   - `@workspace Generate a Pester test for this function`
   - `@workspace Create a new auto-fix rule for {RuleName}`

5. **Get documentation help**
   - `@workspace Create comment-based help for this function`
   - `@workspace Update the README with this new feature`

### Example Workflows

#### Adding a New Auto-Fix Rule

1. **Ask Copilot for guidance**
   ```
   @workspace I want to add a new auto-fix rule for PSAvoidUsingPositionalParameters. 
   What's the process?
   ```

2. **Generate the module structure**
   ```
   @workspace Generate the module structure for PSAvoidUsingPositionalParameters 
   following PoshGuard patterns
   ```

3. **Create tests**
   ```
   @workspace Generate Pester tests for the PSAvoidUsingPositionalParameters fix
   ```

4. **Add documentation**
   ```
   @workspace Update the documentation for the new rule
   ```

#### Debugging an Issue

1. **Explain the code**
   ```
   @workspace Explain what this AST transformation is doing
   ```

2. **Suggest fixes**
   ```
   @workspace This function isn't handling edge cases correctly. What's wrong?
   ```

3. **Improve performance**
   ```
   @workspace How can I optimize this code for better performance?
   ```

## Troubleshooting

### Copilot not using workspace context

**Solution**: Make sure you have:
1. Opened the repository root in VS Code (not a subdirectory)
2. GitHub Copilot extension is active (check status bar)
3. Used `@workspace` prefix in chat queries

### MCP servers not working

**Solution**: Check that:
1. Environment variables are set correctly
2. Node.js and Python are installed and in PATH
3. Restart VS Code after setting environment variables
4. Check Copilot logs: View → Output → GitHub Copilot

### Suggestions not following PoshGuard patterns

**Solution**:
1. Reference the copilot-instructions.md file
2. Use `@workspace` to ensure context is loaded
3. Provide more specific prompts mentioning PoshGuard patterns
4. Look at existing code and mention similar patterns

### Performance issues

**Solution**:
1. Disable MCP servers you don't need
2. Close unnecessary files in the editor
3. Restart VS Code periodically
4. Check VS Code performance settings

## Advanced Usage

### Custom Queries

You can query MCP servers directly:

```
@workspace Use Context7 to get the latest PowerShell AST documentation
@workspace Search the web for recent PowerShell security best practices
@workspace Fetch the content from [URL] and analyze it
```

### Combining Tools

Copilot can use multiple tools together:

```
@workspace Use Context7 to get PSScriptAnalyzer documentation, 
then generate a new rule implementation following that pattern
```

### Privacy and Security

- MCP integration is **opt-in** and requires explicit setup
- Local MCP servers (fetch, playwright) run on your machine
- HTTP servers (Context7, OpenAI) require API keys you control
- No code is sent to external services without your explicit action
- Review MCP logs to see what queries are made

## Getting Help

- **Project Documentation**: See `docs/` directory
- **MCP Setup**: See `.github/MCP_SETUP.md`
- **Contributing Guide**: See `docs/CONTRIBUTING.md`
- **GitHub Issues**: https://github.com/cboyd0319/PoshGuard/issues

## Resources

- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [PowerShell AST Documentation](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation)

## Tips for Maximum Productivity

1. **Learn keyboard shortcuts**
   - `Ctrl+I` (Windows/Linux) or `Cmd+I` (macOS): Open inline chat
   - `Ctrl+Shift+I`: Open chat pane
   - `Tab`: Accept suggestion

2. **Use descriptive comments**
   - Write clear comments describing what you want
   - Copilot uses comments as prompts

3. **Review suggestions carefully**
   - Always review and test Copilot's suggestions
   - Ensure they follow PoshGuard patterns
   - Check for security implications

4. **Iterate with Copilot**
   - If first suggestion isn't right, provide more context
   - Ask for alternatives: "Show me another way to do this"

5. **Leverage context**
   - Open related files to give Copilot more context
   - Reference existing patterns in your prompts

## Feedback and Improvements

We're continuously improving the Copilot configuration. If you have suggestions:

1. Open an issue describing your idea
2. Submit a PR with improvements to configuration files
3. Share your experience with the team

---

**Happy coding with Copilot! 🚀**
