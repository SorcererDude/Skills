---
name: windows-azure-diagrams
description: Generate arbitrary Azure architecture and process-flow diagrams in locked-down Windows environments where Graphviz, Mermaid tooling, extra executables, or DLLs are not allowed. Use when the user provides any Azure scenario, resource interaction, MSP/client flow, authentication flow, or architecture/process diagram request and needs SVG, editable Draw.io .drawio, PNG, or JPG output with real Azure service icons.
---

# Windows Azure Diagrams

## Overview

Create Azure architecture or process-flow diagrams by translating the user's scenario into a small JSON model, then rendering it with bundled PowerShell and SVG icon assets. Generate SVG for reports and editable Draw.io `.drawio` files when the user needs to revise the diagram later. Use installed Microsoft Edge only for PNG/JPG export. Do not add Graphviz, Mermaid CLIs, npm packages, EXE files, or DLL files.

The bundled MSP/SRE flow is only the default example when no scenario is supplied. For real work, generate a scenario JSON file from the user's requested flow and pass it to `scripts/New-AzureProcessFlow.ps1`.

## Workflow

1. Infer the diagram from the user's request:
   - lanes or zones, such as MSP, client, identity, data, platform, or external systems
   - nodes, including resource names, short subtitles, icon choices, and optional sequence numbers
   - edges, including direction and concise labels
2. Write a scenario JSON file. Read `references/scenario-schema.md` when you need the schema, icon keys, or a compact example.
3. Generate SVG and editable Draw.io files:

```powershell
.\scripts\New-AzureProcessFlow.ps1 -ScenarioPath scenario.json -OutputDir diagrams -Name requested-diagram -OutputFormat Both
```

4. Export PNG/JPG when requested:

```powershell
.\scripts\Export-SvgRasterImages.ps1 -InputDir diagrams -OutputDir raster -Filter requested-diagram.svg -Format Both
```

Use `-OutputFormat Svg` or `-OutputFormat Drawio` when only one diagram source format is needed. Use `-Format Png` or `-Format Jpg` when only one raster format is needed.

## Scenario Authoring

Use the user's language as the source of truth. Do not force the scenario into the MSP/SRE example unless that is what the user asked for.

Keep diagrams readable:

- Use 2-5 lanes for architecture zones, responsibility boundaries, or process actors.
- Keep labels short and put detail in `subtitle`.
- Use `kind: "auth"` for identity, trust, authentication, authorization, and credential exchange nodes.
- Use `kind: "data"` for databases, storage, telemetry stores, or other data resources.
- Use `kind: "external"` for out-of-tenant, third-party, or unmanaged systems.
- Use real bundled icons first. If an icon is missing, choose the closest available icon or add only the required official SVG asset to `assets/icons/`.

## Script Guidance

- `scripts/New-AzureProcessFlow.ps1` accepts `-ScenarioPath` JSON and generates a self-contained SVG, an editable `.drawio` file, or both with embedded icon data URIs.
- If `-ScenarioPath` is omitted, the script renders the built-in MSP SRE Agent to Key Vault to client resources example as a smoke test.
- Use `-OutputFormat Both` when a report-ready SVG and editable diagrams.net source should stay paired from the same scenario JSON.
- `scripts/Export-SvgRasterImages.ps1` renders SVG to PNG using the installed Microsoft Edge binary in headless mode, then uses .NET `System.Drawing` to create JPG copies with a white background.
- Keep outputs in user-specified folders. Default to `diagrams/` for SVG and `raster/` for PNG/JPG.
- If Edge is not on `PATH`, the exporter checks the standard Windows install paths.

## Validation

After generation:

1. Parse generated SVGs and `.drawio` files as XML.
2. For PNG/JPG output, check dimensions with .NET `System.Drawing`.
3. Visually inspect at least one changed PNG when layout, labels, icons, or routing changed.
4. Scan the skill/output workspace for added `.exe` and `.dll` files when the user has application-whitelisting constraints.

Prefer fixing the scenario JSON or script and regenerating outputs over editing raster files directly. Use the generated `.drawio` file when the user needs manual visual editing in diagrams.net.
