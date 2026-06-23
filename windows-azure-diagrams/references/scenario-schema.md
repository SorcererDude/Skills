# Scenario Schema

Use this schema when translating a user's architecture or process-flow request into a renderable diagram. The same scenario JSON can render SVG, editable Draw.io `.drawio`, or both.

## JSON Shape

```json
{
  "title": "Diagram title",
  "description": "One sentence description for SVG accessibility metadata.",
  "diagramType": "architecture",
  "lanes": [
    { "id": "lane-id", "title": "Lane title" }
  ],
  "nodes": [
    {
      "id": "unique-node-id",
      "label": "Short node label",
      "subtitle": "Optional detail",
      "lane": "lane-id",
      "icon": "key-vault",
      "kind": "node",
      "sequence": "1",
      "order": 1
    }
  ],
  "edges": [
    { "from": "source-node-id", "to": "target-node-id", "label": "edge label" }
  ]
}
```

## Fields

- `title`: Required. Used for the SVG title, Draw.io page metadata, and default file name.
- `description`: Optional but recommended. Used for SVG accessibility metadata and the Draw.io description text.
- `diagramType`: Optional. Use `process`, `architecture`, `identity`, `network`, or a short user-relevant type.
- `lanes`: Optional. Use lanes for zones, actors, trust boundaries, tenants, subscriptions, or system groups. If omitted, lanes are inferred from node `lane` values.
- `nodes`: Required. Each node needs a stable `id`, short `label`, and `lane`.
- `edges`: Optional. Each edge points from one node `id` to another and may include a short `label`.

## Node Options

- `subtitle`: Short supporting text. Keep it under one line where possible.
- `icon`: Use one of the icon keys below. Unknown icons render as a neutral placeholder.
- `kind`: Use `node`, `auth`, `identity`, `trust`, `data`, `database`, or `external`.
- `sequence`: Optional visible step number or short token, such as `1`, `2a`, or `A`.
- `order`: Numeric sort order within the lane.

## Bundled Icon Keys

- `sre-agent`
- `key-vault`
- `app-registration`
- `managed-identity`
- `resource-group`
- `virtual-machine` or `vm`
- `app-service`
- `storage-account`
- `sql-database`
- `monitor`

## Example

```json
{
  "title": "Function app event processing flow",
  "description": "Function App receives events, reads secrets, and stores processed data.",
  "diagramType": "process",
  "lanes": [
    { "id": "ingest", "title": "Ingest" },
    { "id": "security", "title": "Security" },
    { "id": "data", "title": "Data" }
  ],
  "nodes": [
    { "id": "events", "label": "Storage Account", "subtitle": "event source", "lane": "ingest", "icon": "storage-account", "order": 1 },
    { "id": "function", "label": "Function App", "subtitle": "event processor", "lane": "ingest", "icon": "app-service", "order": 2 },
    { "id": "identity", "label": "Managed Identity", "subtitle": "token request", "lane": "security", "icon": "managed-identity", "kind": "auth", "order": 1 },
    { "id": "vault", "label": "Key Vault", "subtitle": "secret lookup", "lane": "security", "icon": "key-vault", "order": 2 },
    { "id": "sql", "label": "SQL Database", "subtitle": "processed records", "lane": "data", "icon": "sql-database", "kind": "data", "order": 1 }
  ],
  "edges": [
    { "from": "events", "to": "function", "label": "triggers" },
    { "from": "function", "to": "identity", "label": "requests token" },
    { "from": "identity", "to": "vault", "label": "authorizes" },
    { "from": "function", "to": "sql", "label": "writes records" }
  ]
}
```
