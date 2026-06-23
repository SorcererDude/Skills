# Windows Azure Diagrams

Codex skill for generating Azure architecture and process-flow diagrams in locked-down Windows environments where Graphviz, Mermaid tooling, extra executables, or DLLs are not allowed.

The skill turns any user-provided scenario into a JSON model, then renders a self-contained SVG and optional editable Draw.io `.drawio` file using PowerShell and bundled SVG service icons. When PNG or JPG output is needed, it uses the installed Microsoft Edge renderer for SVG-to-PNG and .NET `System.Drawing` for JPG conversion.

## What It Generates

The generator is scenario-driven. It can render arbitrary Azure flows such as:

- MSP/client authentication and support flows
- application-to-data architecture diagrams
- identity and Key Vault access flows
- hub-and-spoke resource access diagrams
- process flows across Azure and external systems

For reports, use the generated SVG. For manual editing, open the generated `.drawio` file in diagrams.net/draw.io. If no scenario is provided, the script renders a small MSP SRE Agent to Key Vault to client resources example as a smoke test.

Bundled icon assets include:

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
- [`scripts/New-AzureProcessFlow.ps1`](./scripts/New-AzureProcessFlow.ps1) - Generates self-contained SVG and editable `.drawio` diagrams from scenario JSON
- [`scripts/Export-SvgRasterImages.ps1`](./scripts/Export-SvgRasterImages.ps1) - Exports SVG diagrams to PNG and JPG
- [`references/scenario-schema.md`](./references/scenario-schema.md) - Scenario JSON schema, icon keys, and example
- [`references/icon-assets.md`](./references/icon-assets.md) - Icon source and update notes
- [`assets/icons/`](./assets/icons/) - Bundled SVG service icons

## Usage

Create a scenario JSON file:

```json
{
  "title": "App service reads secrets and writes data",
  "description": "Application flow using Key Vault, managed identity, and SQL Database.",
  "diagramType": "architecture",
  "lanes": [
    { "id": "app", "title": "Application" },
    { "id": "security", "title": "Security" },
    { "id": "data", "title": "Data" }
  ],
  "nodes": [
    { "id": "web", "label": "App Service", "subtitle": "web API", "lane": "app", "icon": "app-service", "order": 1 },
    { "id": "identity", "label": "Managed Identity", "subtitle": "token request", "lane": "security", "icon": "managed-identity", "kind": "auth", "order": 1 },
    { "id": "vault", "label": "Key Vault", "subtitle": "secret retrieval", "lane": "security", "icon": "key-vault", "order": 2 },
    { "id": "sql", "label": "SQL Database", "subtitle": "application data", "lane": "data", "icon": "sql-database", "kind": "data", "order": 1 }
  ],
  "edges": [
    { "from": "web", "to": "identity", "label": "requests token" },
    { "from": "identity", "to": "vault", "label": "authorizes" },
    { "from": "web", "to": "sql", "label": "writes data" }
  ]
}
```

Render SVG and editable Draw.io files:

```powershell
.\scripts\New-AzureProcessFlow.ps1 -ScenarioPath .\scenario.json -OutputDir diagrams -Name app-service-data-flow -OutputFormat Both
```

Use `-OutputFormat Svg` or `-OutputFormat Drawio` when only one source format is needed.

Render the built-in smoke-test example:

```powershell
.\scripts\New-AzureProcessFlow.ps1 -OutputDir diagrams -OutputFormat Both
```

Export PNG and JPG copies:

```powershell
.\scripts\Export-SvgRasterImages.ps1 -InputDir diagrams -OutputDir raster -Filter app-service-data-flow.svg -Format Both
```

## Installing As A Codex Skill

Copy the `windows-azure-diagrams` folder into your Codex skills directory:

```powershell
Copy-Item -LiteralPath .\windows-azure-diagrams -Destination "$env:USERPROFILE\.codex\skills" -Recurse -Force
```

Then invoke it in Codex with a scenario:

```text
Use $windows-azure-diagrams to create SVG, .drawio, PNG, and JPG architecture diagrams for an App Service using managed identity to read Key Vault secrets and write to SQL Database.
```

## Notes

- The generated SVGs and `.drawio` files are self-contained because icons are embedded as data URIs.
- The package does not include `.exe` or `.dll` files.
- PNG/JPG export requires Microsoft Edge to already be installed.
- Prefer changing the scenario JSON and regenerating outputs. Use `.drawio` only when manual visual editing is needed.
