# ManifestManagement.psm1
# Module manifest validation and auto-fix functions

function Invoke-MissingModuleManifestFieldFix {
  <#
    .SYNOPSIS
        Adds missing ModuleVersion field to module manifests

    .DESCRIPTION
        PSScriptAnalyzer rule: PSMissingModuleManifestField
        Adds ModuleVersion = '1.0' if missing from .psd1 files.

        Module manifests require at minimum:
        - ModuleVersion (this fix)
        - RootModule or ModuleToProcess or NestedModules

    .PARAMETER Content
        The manifest content to process

    .EXAMPLE
        Invoke-MissingModuleManifestFieldFix -Content $manifestContent

    .NOTES
        Only processes .psd1 files.
        Adds version field after @{ opening if missing.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,

    [Parameter(Mandatory)]
    [string]$FilePath
  )

  # Only process .psd1 files
  if ($FilePath -notmatch '\.psd1$') {
    return $Content
  }

  # Check if ModuleVersion already exists (case-insensitive, multiline)
  if ($Content -match '(?im)^\s*ModuleVersion\s*=') {
    return $Content
  }

  # Check if this looks like a module manifest (starts with @{)
  if ($Content -notmatch '^\s*@\{') {
    return $Content
  }

  # Add ModuleVersion after the opening @{
  $lines = $Content -split "`r?`n"
  $newLines = @()
  $addedVersion = $false

  foreach ($line in $lines) {
    $newLines += $line

    # Add version after the @{ line
    if (-not $addedVersion -and $line -match '^\s*@\{') {
      $newLines += "    ModuleVersion = '1.0.0'"
      $addedVersion = $true
    }
  }

  if ($addedVersion) {
    Write-Verbose "Added ModuleVersion field to manifest"
  }

  return ($newLines -join "`n")
}

function Invoke-UseToExportFieldsInManifestFix {
  <#
    .SYNOPSIS
        Replaces wildcard exports with explicit empty arrays in module manifests

    .DESCRIPTION
        PSScriptAnalyzer rule: PSUseToExportFieldsInManifest
        Replaces '*' and $null with @() for:
        - FunctionsToExport
        - CmdletsToExport
        - VariablesToExport
        - AliasesToExport

        Using wildcards causes performance issues during module auto-discovery.
        Using explicit exports (even empty arrays) is much faster.

    .PARAMETER Content
        The manifest content to process

    .PARAMETER FilePath
        The file path for context

    .EXAMPLE
        Invoke-UseToExportFieldsInManifestFix -Content $manifestContent -FilePath "MyModule.psd1"

    .NOTES
        Only processes .psd1 files.
        Preserves explicit function lists.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content,

    [Parameter(Mandatory)]
    [string]$FilePath
  )

  # Only process .psd1 files
  if ($FilePath -notmatch '\.psd1$') {
    return $Content
  }

  $modified = $false
  $result = $Content

  # Replace FunctionsToExport = '*' with @()
  if ($result -match "FunctionsToExport\s*=\s*['\`"]?\*['\`"]?") {
    $result = $result -replace "(FunctionsToExport\s*=\s*)['\`"]?\*['\`"]?", '$1@()'
    $modified = $true
    Write-Verbose "Replaced FunctionsToExport wildcard with @()"
  }

  # Replace CmdletsToExport = '*' with @()
  if ($result -match "CmdletsToExport\s*=\s*['\`"]?\*['\`"]?") {
    $result = $result -replace "(CmdletsToExport\s*=\s*)['\`"]?\*['\`"]?", '$1@()'
    $modified = $true
    Write-Verbose "Replaced CmdletsToExport wildcard with @()"
  }

  # Replace VariablesToExport = '*' with @()
  if ($result -match "VariablesToExport\s*=\s*['\`"]?\*['\`"]?") {
    $result = $result -replace "(VariablesToExport\s*=\s*)['\`"]?\*['\`"]?", '$1@()'
    $modified = $true
    Write-Verbose "Replaced VariablesToExport wildcard with @()"
  }

  # Replace AliasesToExport = '*' with @()
  if ($result -match "AliasesToExport\s*=\s*['\`"]?\*['\`"]?") {
    $result = $result -replace "(AliasesToExport\s*=\s*)['\`"]?\*['\`"]?", '$1@()'
    $modified = $true
    Write-Verbose "Replaced AliasesToExport wildcard with @()"
  }

  # Replace $null assignments with @()
  if ($result -match "(FunctionsToExport|CmdletsToExport|VariablesToExport|AliasesToExport)\s*=\s*\`$null") {
    $result = $result -replace "((FunctionsToExport|CmdletsToExport|VariablesToExport|AliasesToExport)\s*=\s*)\`$null", '$1@()'
    $modified = $true
    Write-Verbose "Replaced export field null with @()"
  }

  if ($modified) {
    Write-Verbose "Updated manifest export fields for better performance"
  }

  return $result
}

function Invoke-AvoidGlobalAliasesFix {
  <#
    .SYNOPSIS
        Changes Set-Alias -Scope Global to -Scope Script

    .DESCRIPTION
        PSScriptAnalyzer rule: PSAvoidGlobalAliases
        Replaces Global scope with Script scope in Set-Alias calls.

        Global aliases can override existing aliases across the entire session,
        causing conflicts. Script scope is safer and more predictable.

    .PARAMETER Content
        The script content to process

    .EXAMPLE
        Invoke-AvoidGlobalAliasesFix -Content $scriptContent

    .NOTES
        Handles both quoted and unquoted scope values.
        Preserves other Set-Alias parameters.
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Content
  )

  $modified = $false
  $result = $Content

  # Pattern 1: -Scope Global (unquoted)
  if ($result -match '-Scope\s+Global\b') {
    $result = $result -replace '-Scope\s+Global\b', '-Scope Script'
    $modified = $true
    Write-Verbose "Replaced -Scope Global with -Scope Script"
  }

  # Pattern 2: -Scope 'Global' or -Scope "Global" (quoted)
  if ($result -match "-Scope\s+['\`"]Global['\`"]") {
    $result = $result -replace "-Scope\s+['\`"]Global['\`"]", "-Scope 'Script'"
    $modified = $true
    Write-Verbose "Replaced -Scope 'Global' with -Scope 'Script'"
  }

  # Pattern 3: -Scope:Global (no space)
  if ($result -match '-Scope:Global\b') {
    $result = $result -replace '-Scope:Global\b', '-Scope:Script'
    $modified = $true
    Write-Verbose "Replaced -Scope:Global with -Scope:Script"
  }

  # Pattern 4: -Scope:'Global' or -Scope:"Global" (colon with quotes)
  if ($result -match "-Scope:['\`"]Global['\`"]") {
    $result = $result -replace "-Scope:['\`"]Global['\`"]", "-Scope:'Script'"
    $modified = $true
    Write-Verbose "Replaced -Scope:'Global' with -Scope:'Script'"
  }

  if ($modified) {
    Write-Verbose "Changed global aliases to script scope"
  }

  return $result
}

# Export functions
Export-ModuleMember -Function @(
  'Invoke-MissingModuleManifestFieldFix',
  'Invoke-UseToExportFieldsInManifestFix',
  'Invoke-AvoidGlobalAliasesFix'
)
