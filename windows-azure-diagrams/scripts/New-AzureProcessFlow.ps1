param(
    [string]$ScenarioPath,
    [string]$OutputDir = "diagrams",
    [string]$Name
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptRoot)) { $scriptRoot = (Get-Location).Path }
$iconRoot = Join-Path $scriptRoot "..\assets\icons"
if (-not (Test-Path -LiteralPath $iconRoot)) { throw "Icon assets not found at '$iconRoot'." }
if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

$iconFiles = @{
    "sre-agent" = "sre-agent.svg"; "azure-sre-agent" = "sre-agent.svg"
    "key-vault" = "key-vaults.svg"; "key-vaults" = "key-vaults.svg"
    "app-registration" = "app-registrations.svg"; "app-registrations" = "app-registrations.svg"
    "managed-identity" = "managed-identities.svg"; "managed-identities" = "managed-identities.svg"; "identity" = "managed-identities.svg"
    "resource-group" = "resource-groups.svg"; "resource-groups" = "resource-groups.svg"
    "virtual-machine" = "virtual-machine.svg"; "vm" = "virtual-machine.svg"
    "app-service" = "app-services.svg"; "app-services" = "app-services.svg"
    "storage-account" = "storage-accounts.svg"; "storage-accounts" = "storage-accounts.svg"
    "sql-database" = "sql-database.svg"; "database" = "sql-database.svg"
    "monitor" = "monitor.svg"
}

function Get-Val($Object, [string]$Name, $Default) {
    if ($null -eq $Object) { return $Default }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p -or $null -eq $p.Value) { return $Default }
    if ($p.Value -is [string] -and [string]::IsNullOrWhiteSpace($p.Value)) { return $Default }
    return $p.Value
}

function Escape-Svg($Value) {
    if ($null -eq $Value) { return "" }
    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function Limit-Text([string]$Value, [int]$Length) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
    if ($Value.Length -le $Length) { return $Value }
    return $Value.Substring(0, [Math]::Max(1, $Length - 3)) + "..."
}

function Get-Slug([string]$Value) {
    $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    if ([string]::IsNullOrWhiteSpace($slug)) { return "diagram" }
    return $slug
}

function Get-IconUri([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return $null }
    $key = $Name.ToLowerInvariant() -replace "[\s_]+", "-"
    if ($key.EndsWith(".svg")) { $file = $key }
    elseif ($iconFiles.ContainsKey($key)) { $file = $iconFiles[$key] }
    else { return $null }
    $path = Join-Path $iconRoot $file
    if (-not (Test-Path -LiteralPath $path)) { throw "Icon not found: $path" }
    return "data:image/svg+xml;base64,$([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)))"
}

$defaultScenario = @'
{
  "title": "MSP authentication flow to client resources",
  "description": "Azure SRE Agent uses Key Vault, authenticates with the client, and accesses client resources.",
  "diagramType": "process",
  "lanes": [
    { "id": "msp", "title": "MSP side" },
    { "id": "client", "title": "Client side" }
  ],
  "nodes": [
    { "id": "sre", "label": "Azure SRE Agent", "subtitle": "support automation agent", "lane": "msp", "icon": "sre-agent", "sequence": "1", "order": 1 },
    { "id": "vault", "label": "Key Vault", "subtitle": "secrets and certs", "lane": "msp", "icon": "key-vault", "sequence": "2", "order": 2 },
    { "id": "auth", "label": "Authenticate with client", "subtitle": "client identity boundary", "lane": "client", "icon": "app-registration", "kind": "auth", "order": 1 },
    { "id": "resources", "label": "Access various resources", "subtitle": "VMs, apps, data, monitor", "lane": "client", "icon": "resource-group", "sequence": "3", "order": 2 }
  ],
  "edges": [
    { "from": "sre", "to": "vault", "label": "retrieves secret" },
    { "from": "vault", "to": "auth", "label": "presents credential" },
    { "from": "auth", "to": "resources", "label": "authorized access" }
  ]
}
'@

$scenario = if ([string]::IsNullOrWhiteSpace($ScenarioPath)) {
    $defaultScenario | ConvertFrom-Json
} else {
    Get-Content -Raw -LiteralPath (Resolve-Path -LiteralPath $ScenarioPath).Path | ConvertFrom-Json
}

$nodes = @()
$i = 0
foreach ($n in @(Get-Val $scenario "nodes" @())) {
    $i++
    $order = 0.0
    $orderValue = Get-Val $n "order" $i
    if (-not [double]::TryParse([string]$orderValue, [ref]$order)) { $order = $i }
    $id = [string](Get-Val $n "id" "node-$i")
    $lane = [string](Get-Val $n "lane" (Get-Val $n "group" "main"))
    $nodes += [pscustomobject]@{
        Id = $id; Lane = $lane; Order = $order; Index = $i
        Label = [string](Get-Val $n "label" $id)
        Subtitle = [string](Get-Val $n "subtitle" "")
        Icon = [string](Get-Val $n "icon" "")
        Kind = [string](Get-Val $n "kind" "node")
        Sequence = [string](Get-Val $n "sequence" "")
    }
}
if ($nodes.Count -eq 0) { throw "Scenario must include at least one node." }

$lanes = @()
foreach ($l in @(Get-Val $scenario "lanes" @())) {
    $id = [string](Get-Val $l "id" "")
    if (-not [string]::IsNullOrWhiteSpace($id)) {
        $lanes += [pscustomobject]@{ Id = $id; Title = [string](Get-Val $l "title" $id) }
    }
}
foreach ($laneId in @($nodes | ForEach-Object Lane | Select-Object -Unique)) {
    if (-not ($lanes | Where-Object { $_.Id -eq $laneId })) { $lanes += [pscustomobject]@{ Id = $laneId; Title = $laneId } }
}

$edges = @(Get-Val $scenario "edges" @())
$title = [string](Get-Val $scenario "title" "Azure diagram")
$description = [string](Get-Val $scenario "description" "")
$diagramType = [string](Get-Val $scenario "diagramType" "process")
$fileName = if ([string]::IsNullOrWhiteSpace($Name)) { Get-Slug $title } else { $Name }
if (-not $fileName.ToLowerInvariant().EndsWith(".svg")) { $fileName = "$fileName.svg" }

$laneW = 360; $laneGap = 28; $nodeW = 282; $nodeH = 96; $rowGap = 42; $margin = 36; $top = 138
$maxRows = 1
foreach ($lane in $lanes) { $maxRows = [Math]::Max($maxRows, @($nodes | Where-Object Lane -eq $lane.Id).Count) }
$width = ($margin * 2) + ($lanes.Count * $laneW) + (($lanes.Count - 1) * $laneGap)
$height = [Math]::Max(520, $top + ($maxRows * $nodeH) + (($maxRows - 1) * $rowGap) + 58)

$laneBox = @{}; $nodeBox = @{}
for ($l = 0; $l -lt $lanes.Count; $l++) {
    $laneBox[$lanes[$l].Id] = [pscustomobject]@{ X = $margin + ($l * ($laneW + $laneGap)); Y = 92; W = $laneW; H = $height - 112 }
    $laneNodes = @($nodes | Where-Object Lane -eq $lanes[$l].Id | Sort-Object Order, Index)
    for ($r = 0; $r -lt $laneNodes.Count; $r++) {
        $nodeBox[$laneNodes[$r].Id] = [pscustomobject]@{
            X = $laneBox[$lanes[$l].Id].X + [int](($laneW - $nodeW) / 2)
            Y = $top + ($r * ($nodeH + $rowGap)); W = $nodeW; H = $nodeH
        }
    }
}

$svg = New-Object System.Collections.Generic.List[string]
$svg.Add("<svg xmlns=""http://www.w3.org/2000/svg"" width=""$width"" height=""$height"" viewBox=""0 0 $width $height"" role=""img"" aria-labelledby=""title desc"">")
$svg.Add("<title id=""title"">$(Escape-Svg $title)</title><desc id=""desc"">$(Escape-Svg $description)</desc>")
$svg.Add('<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto"><path d="M0 0L10 5L0 10z" fill="#233142"/></marker><style>text{font-family:Segoe UI,Arial,sans-serif;fill:#1f2937}.t{font-size:24px;font-weight:700}.s{font-size:13px;fill:#526070}.lane{fill:#f8fafc;stroke:#cbd5e1;stroke-width:2;rx:8}.lt{font-size:17px;font-weight:700}.card{fill:#fff;stroke:#9aa8b8;stroke-width:1.8;rx:8}.auth{fill:#fff7ed;stroke:#ea8a16;stroke-width:2;rx:8}.data{fill:#f0f9ff;stroke:#0284c7;stroke-width:1.8;rx:8}.external{fill:#f8fafc;stroke:#64748b;stroke-dasharray:6 5;stroke-width:1.8;rx:8}.nt{font-size:14px;font-weight:700}.ns{font-size:12px;fill:#64748b}.seq{font-size:11px;font-weight:700;fill:#475569}.edge{fill:none;stroke:#233142;stroke-width:2.2;marker-end:url(#arrow)}.el{font-size:12px;font-weight:600;fill:#334155}.eb{fill:#fff;opacity:.86;rx:5}.ph{fill:#e2e8f0;stroke:#94a3b8;stroke-width:1.5}.pt{font-size:22px;font-weight:700;fill:#475569}</style></defs>')
$svg.Add("<rect x=""0"" y=""0"" width=""$width"" height=""$height"" fill=""#fff""/>")
$svg.Add("<text x=""36"" y=""42"" class=""t"">$(Escape-Svg (Limit-Text $title 72))</text>")
if ($description) { $svg.Add("<text x=""36"" y=""66"" class=""s"">$(Escape-Svg (Limit-Text $description 126))</text>") }
$svg.Add("<text x=""$($width - 36)"" y=""42"" text-anchor=""end"" class=""s"">$(Escape-Svg $diagramType)</text>")

foreach ($lane in $lanes) {
    $b = $laneBox[$lane.Id]
    $svg.Add("<rect x=""$($b.X)"" y=""$($b.Y)"" width=""$($b.W)"" height=""$($b.H)"" class=""lane""/>")
    $svg.Add("<text x=""$($b.X + 20)"" y=""$($b.Y + 34)"" class=""lt"">$(Escape-Svg (Limit-Text $lane.Title 34))</text>")
}

foreach ($edge in $edges) {
    $from = [string](Get-Val $edge "from" ""); $to = [string](Get-Val $edge "to" "")
    if (-not $nodeBox.ContainsKey($from) -or -not $nodeBox.ContainsKey($to)) { continue }
    $a = $nodeBox[$from]; $b = $nodeBox[$to]
    $x1 = $a.X + $a.W; $y1 = $a.Y + [int]($a.H / 2); $x2 = $b.X; $y2 = $b.Y + [int]($b.H / 2)
    if ($x2 -gt $x1) { $path = "M $x1 $y1 C $($x1 + 70) $y1 $($x2 - 70) $y2 $x2 $y2" }
    else { $path = "M $x1 $y1 L $($x1 + 34) $y1 L $($x1 + 34) $y2 L $($b.X + $b.W) $y2" }
    $svg.Add("<path d=""$path"" class=""edge""/>")
    $label = [string](Get-Val $edge "label" "")
    if ($label) {
        $lx = [int](($x1 + $x2) / 2); $ly = [int](($y1 + $y2) / 2) - 8
        $svg.Add("<rect x=""$($lx - 58)"" y=""$($ly - 15)"" width=""116"" height=""22"" class=""eb""/><text x=""$lx"" y=""$ly"" text-anchor=""middle"" class=""el"">$(Escape-Svg (Limit-Text $label 18))</text>")
    }
}

foreach ($n in $nodes) {
    $b = $nodeBox[$n.Id]
    $class = if ($n.Kind -in @("auth","identity","trust")) { "auth" } elseif ($n.Kind -in @("data","database")) { "data" } elseif ($n.Kind -eq "external") { "external" } else { "card" }
    $svg.Add("<rect x=""$($b.X)"" y=""$($b.Y)"" width=""$($b.W)"" height=""$($b.H)"" class=""$class""/>")
    $ix = $b.X + 18; $iy = $b.Y + 20; $uri = Get-IconUri $n.Icon
    if ($uri) { $svg.Add("<image href=""$uri"" x=""$ix"" y=""$iy"" width=""56"" height=""56""/>") }
    else {
        $initial = if ($n.Label) { (Escape-Svg $n.Label.Substring(0,1).ToUpperInvariant()) } else { "?" }
        $svg.Add("<circle cx=""$($ix + 28)"" cy=""$($iy + 28)"" r=""28"" class=""ph""/><text x=""$($ix + 28)"" y=""$($iy + 35)"" text-anchor=""middle"" class=""pt"">$initial</text>")
    }
    $tx = $b.X + 88
    if ($n.Sequence) { $svg.Add("<text x=""$tx"" y=""$($b.Y + 24)"" class=""seq"">$(Escape-Svg $n.Sequence)</text>"); $titleY = $b.Y + 45 }
    else { $titleY = $b.Y + 33 }
    $svg.Add("<text x=""$tx"" y=""$titleY"" class=""nt"">$(Escape-Svg (Limit-Text $n.Label 28))</text>")
    if ($n.Subtitle) { $svg.Add("<text x=""$tx"" y=""$($b.Y + 76)"" class=""ns"">$(Escape-Svg (Limit-Text $n.Subtitle 34))</text>") }
}

$svg.Add("</svg>")
$outputPath = Join-Path (Resolve-Path -LiteralPath $OutputDir).Path $fileName
[IO.File]::WriteAllText($outputPath, ($svg -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host "Wrote $outputPath"
