# GitHub Configuration Scripts

This directory contains validation and testing scripts for GitHub configurations.

## Available Scripts

### Test-MCPConfiguration.ps1

Validates MCP (Model Context Protocol) server configurations in `.github/copilot-mcp.json`.

**Usage:**

```powershell
# Basic validation
pwsh -File .github/scripts/Test-MCPConfiguration.ps1

# With verbose output
pwsh -File .github/scripts/Test-MCPConfiguration.ps1 -Verbose

# Skip connectivity tests (faster, checks config only)
pwsh -File .github/scripts/Test-MCPConfiguration.ps1 -SkipConnectivityTests
```

**What it checks:**

1. **File Existence:** Verifies `.github/copilot-mcp.json` exists
2. **JSON Validity:** Validates JSON syntax
3. **Server Configuration:** Checks each MCP server for:
   - Required fields (type, url/command)
   - Valid server types (http, local, stdio)
   - Proper authentication setup
   - Environment variable references
   - Tool configurations
4. **Known Good Configurations:** Validates against recommended server configurations
5. **Connectivity:** Tests HTTP endpoints and command availability (optional)
6. **Deprecated Patterns:** Detects use of deprecated authentication methods

**Exit Codes:**

- `0` - All validations passed
- `1` - Validation failures detected

**Example Output:**

```
═══════════════════════════════════════════════════════
  MCP Configuration Validation
═══════════════════════════════════════════════════════

[1/6] Checking configuration file...
  ✓ Configuration file exists

[2/6] Validating JSON structure...
  ✓ Valid JSON

[3/6] Checking MCP servers section...
  ✓ Has mcpServers section
  Found 4 MCP server(s) configured

[4/6] Validating individual server configurations...
  
  Validating: context7
  ✓ Has required field 'type'
  ✓ Valid server type
  ✓ HTTP server has URL
  ...

═══════════════════════════════════════════════════════
  Validation Summary
═══════════════════════════════════════════════════════

  Total Servers: 4
  Passed: 4
  Failed: 0

  ✓ All servers configured correctly!
```

**Troubleshooting:**

If validation fails, see:
- [docs/development/workflows/MCP-TROUBLESHOOTING.md](../../docs/development/workflows/MCP-TROUBLESHOOTING.md)
- [docs/MCP-GUIDE.md](../../docs/MCP-GUIDE.md)

## Future Scripts

This directory may contain additional validation scripts for:
- Workflow file validation
- Dependabot configuration checks
- GitHub Actions security scanning
- PR and issue template validation

## Contributing

When adding new scripts to this directory:

1. **Use descriptive names:** Follow the pattern `Test-<Component>.ps1` or `Validate-<Component>.ps1`
2. **Add documentation:** Include comment-based help in the script
3. **Update this README:** Document the new script here
4. **Follow conventions:**
   - Use `[CmdletBinding()]` for advanced functions
   - Support `-Verbose` for detailed output
   - Return meaningful exit codes (0 = success, 1 = failure)
   - Use colored output for readability

## Related Documentation

- [MCP Configuration Guide](../../docs/MCP-GUIDE.md)
- [MCP Troubleshooting](../../docs/development/workflows/MCP-TROUBLESHOOTING.md)
- [GitHub Copilot Setup](../../docs/development/workflows/copilot-instructions.md)
- [Contributing Guidelines](../../CONTRIBUTING.md)
