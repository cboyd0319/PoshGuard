# Recommended VS Code Settings

This directory contains recommended VS Code workspace settings for PoshGuard development.

## Setup

To use these settings:

```bash
# Copy the entire directory to .vscode
cp -r .vscode.recommended .vscode
```

Or manually copy the files you want:

```bash
# Copy settings only
cp .vscode.recommended/settings.json .vscode/settings.json

# Copy extensions recommendations
cp .vscode.recommended/extensions.json .vscode/extensions.json
```

## Included Files

### `settings.json`

Workspace settings that configure:
- PowerShell formatting with OTBS (One True Brace Style)
- PSScriptAnalyzer integration
- GitHub Copilot enablement
- File associations and exclusions
- EditorConfig support

### `extensions.json`

Recommended VS Code extensions:
- **PowerShell**: Official PowerShell extension for VS Code
- **GitHub Copilot**: AI pair programmer
- **GitHub Copilot Chat**: Chat interface for Copilot
- **Markdown Lint**: Markdown linting
- **EditorConfig**: EditorConfig support
- **Code Spell Checker**: Spelling checker
- **Test Explorer**: Test runner integration

## GitHub Copilot Configuration

The workspace is configured to work with GitHub Copilot via:

1. **Copilot Instructions**: `.github/copilot-instructions.md` provides Copilot with comprehensive context about the project
2. **MCP Servers**: `.github/copilot-mcp.json` configures Model Context Protocol servers for enhanced capabilities
3. **Workspace Settings**: These recommended settings enable Copilot for PowerShell files

## Note

The `.vscode` directory is in `.gitignore` to keep personal settings local. These recommended settings serve as a starting point that contributors can customize.
