# Windows Azure Diagrams

Codex skill for generating Azure process-flow diagrams in locked-down Windows environments where Graphviz, Mermaid tooling, extra executables, or DLLs are not allowed.

The skill creates SVG diagrams using PowerShell and bundled SVG service icons. When PNG or JPG output is needed, it uses the installed Microsoft Edge renderer for SVG-to-PNG and .NET `System.Drawing` for JPG conversion.

## What It Generates

The bundled generator creates three Azure SRE flow examples:

- Basic MSP-to-client authentication flow
- MSP/client swimlane flow
- Client resource fan-out flow

The diagrams include icons for:

- Azure SRE Agent
- Key Vault
- App Registrations
- Entra Managed Identities
- Resource Groups
- Virtual Machines
- App Services
- Storage Accounts
- SQL Database
- Monitor

## Contents

- [`SKILL.md`](./SKILL.md) - Codex skill instructions
- [`scripts/New-AzureProcessFlow.ps1`](./scripts/New-AzureProcessFlow.ps1) - Generates self-contained SVG diagrams
- [`scripts/Export-SvgRasterImages.ps1`](./scripts/Export-SvgRasterImages.ps1) - Exports SVG diagrams to PNG and JPG
- [`assets/icons/`](./assets/icons/) - Bundled SVG service icons
- [`references/icon-assets.md`](./references/icon-assets.md) - Icon source and update notes

## Usage

From this folder:

```powershell
.\scripts\New-AzureProcessFlow.ps1 -OutputDir diagrams
```

Export PNG and JPG copies:

```powershell
.\scripts\Export-SvgRasterImages.ps1 -InputDir diagrams -OutputDir raster -Filter *azure-icons.svg -Format Both
```

Use only one raster format:

```powershell
.\scripts\Export-SvgRasterImages.ps1 -InputDir diagrams -OutputDir raster -Filter *azure-icons.svg -Format Png
.\scripts\Export-SvgRasterImages.ps1 -InputDir diagrams -OutputDir raster -Filter *azure-icons.svg -Format Jpg
```

## Installing As A Codex Skill

Copy the `windows-azure-diagrams` folder into your Codex skills directory:

```powershell
Copy-Item -LiteralPath .\windows-azure-diagrams -Destination "$env:USERPROFILE\.codex\skills" -Recurse -Force
```

Then invoke it in Codex with:

```text
Use $windows-azure-diagrams to create an Azure SRE Agent to Key Vault to client resources diagram as PNG and SVG.
```

## Notes

- The generated SVGs are self-contained because icons are embedded as data URIs.
- The package does not include `.exe` or `.dll` files.
- PNG/JPG export requires Microsoft Edge to already be installed.
- Prefer editing the SVG templates in `New-AzureProcessFlow.ps1` and regenerating outputs instead of manually editing raster images.
