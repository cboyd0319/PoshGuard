Configuration
=============

Defaults are sensible; you rarely need to tweak anything. When you do, start here.

Files
-----

- PSScriptAnalyzer rules: `config/PSScriptAnalyzerSettings.psd1`
- Quality gates & formatting: `config/QASettings.psd1`
- Security rules: `config/SecurityRules.psd1`
- App settings (MCP, observability): `config/poshguard.json`

How settings apply
------------------

- Tools (`./tools/Apply-AutoFix.ps1`) load `PSScriptAnalyzerSettings.psd1` and `QASettings.psd1` by default.
- Module (`Invoke-PoshGuard`) uses the same defaults. Override via parameters or environment variables when provided.

Key settings (quick scan)
-------------------------

- SecurityRules.psd1: credential handling, secrets detection, API token patterns, risk levels.
- QASettings.psd1: formatting rules (indent, casing), naming, scoping, string handling, output conventions.
- PSScriptAnalyzerSettings.psd1: upstream rules inclusion/exclusions, severity.
- poshguard.json: optional MCP, logging, metrics; all disabled by default for privacy.

poshguard.json (example)
------------------------

```json
{
  "mcp": {
    "servers": [
      { "name": "context7", "type": "http", "enabled": false },
      { "name": "openai-websearch", "type": "local", "enabled": false }
    ]
  },
  "observability": { "enabled": true, "structuredLogging": true, "metrics": true },
  "slo": { "availabilityTarget": 99.5, "latencyP95Target": 5000 },
  "security": { "scanForSecrets": true, "enforceSecureStrings": true },
  "performance": { "parallelProcessing": false, "cacheAST": true }
}
```

Override patterns
-----------------

- Per-run: prefer command parameters (e.g., `-Skip @('RuleA','RuleB')`).
- Per-repo: commit adjusted PSD1 files under `config/` with rationale in PR.
- Per-file: use comment-based suppression only when necessary; document in the PR.

Tips
----

- Keep changes minimal; prefer upstream rule updates over local overrides.
- Never disable security-critical rules without a clear, documented reason.
- Validate with `-DryRun` and include before/after diffs in reviews.

