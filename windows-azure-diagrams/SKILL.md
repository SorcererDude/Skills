---
name: windows-azure-diagrams
description: Generate Azure process-flow and architecture-style diagrams in locked-down Windows environments where Graphviz, Mermaid tooling, extra executables, or DLLs are not allowed. Use when the user needs SVG, PNG, or JPG diagrams with real Azure service icons, especially MSP/client authentication flows involving Azure SRE Agent, Key Vault, identity, and client resources.
---

# Windows Azure Diagrams

## Overview

Create Azure process diagrams with PowerShell-generated SVG and bundled SVG icon assets. Use installed Microsoft Edge only for raster export when PNG or JPG output is requested; do not add Graphviz, Mermaid CLIs, npm packages, EXE files, or DLL files.

The bundled workflow creates three example diagrams:

- basic MSP-to-client authentication flow
- MSP/client swimlane flow
- client resource fan-out flow

## Workflow

1. Generate SVG diagrams:

```powershell
.\scripts\New-AzureProcessFlow.ps1 -OutputDir diagrams
```

2. Export PNG/JPG when requested:

```powershell
.\scripts\Export-SvgRasterImages.ps1 -InputDir diagrams -OutputDir raster -Filter *azure-icons.svg -Format Both
```

Use `-Format Png` or `-Format Jpg` when only one raster format is needed.

## Script Guidance

- `scripts/New-AzureProcessFlow.ps1` embeds icons as SVG data URIs so generated diagrams are self-contained.
- `scripts/Export-SvgRasterImages.ps1` renders SVG to PNG using the installed Microsoft Edge binary in headless mode, then uses .NET `System.Drawing` to create JPG copies with a white background.
- Keep outputs in user-specified folders. Default to `diagrams/` for SVG and `raster/` for PNG/JPG.
- If Edge is not on `PATH`, the exporter checks the standard Windows install paths.
- Do not download or install renderers unless the user explicitly asks and approvals allow it.

## Customization

Modify the SVG template blocks in `New-AzureProcessFlow.ps1` for labels, node positions, edge routing, and resource choices. Keep the diagram source text-based and deterministic.

Use bundled icons from `assets/icons/` before looking elsewhere. If a requested Azure service icon is missing, prefer the official Microsoft Azure Architecture Icons pack and copy only the needed SVG asset into `assets/icons/`; avoid adding the full ZIP to the skill.

The current Azure SRE Agent icon is bundled as `assets/icons/sre-agent.svg`.

## Validation

After generation:

1. Parse generated SVGs as XML.
2. For PNG/JPG output, check dimensions with .NET `System.Drawing`.
3. Visually inspect at least one changed PNG when layout, labels, icons, or routing changed.
4. Scan the skill/output workspace for added `.exe` and `.dll` files if the user has application-whitelisting constraints.

Prefer fixing source SVG templates and regenerating outputs over editing raster files directly.
