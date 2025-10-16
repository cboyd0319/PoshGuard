# PoshGuard Module Directory

This directory contains the PowerShell Gallery module manifest and root module.

## Structure

```
PoshGuard/
├── PoshGuard.psd1        # Module manifest (metadata for PSGallery)
├── PoshGuard.psm1        # Root module (loads submodules dynamically)
└── VERSION.txt           # Version marker
```

## Development vs. Published Structure

### Development (Current Repo)
```
PoshGuard/              <- Manifest only
tools/
  ├── Apply-AutoFix.ps1 <- Main entry point
  └── lib/              <- All module files
```

**Usage**: `./tools/Apply-AutoFix.ps1 -Path ./script.ps1`

### PowerShell Gallery (Published)
```
PoshGuard/
  ├── PoshGuard.psd1
  ├── PoshGuard.psm1
  ├── Apply-AutoFix.ps1  <- Copied from tools/
  └── lib/               <- Copied from tools/lib/
```

**Usage**: `Invoke-PoshGuard -Path ./script.ps1`

## Publishing to PowerShell Gallery

Run the preparation script to restructure for PSGallery:

```powershell
./tools/Prepare-PSGalleryPackage.ps1
```

This creates a `./publish/PoshGuard/` directory with the correct structure.

Then publish:

```powershell
Publish-Module -Path ./publish/PoshGuard -NuGetApiKey $env:PSGALLERY_API_KEY -Verbose
```

## Why Two Structures?

- **Development**: Keeps tools separate from module metadata for clarity
- **Published**: Follows PSGallery conventions (all files under module name)

The `PoshGuard.psm1` root module handles both structures by detecting which environment it's in and adjusting paths accordingly.
