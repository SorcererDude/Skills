param(
    [string]$ScenarioPath,
    [string]$OutputDir = "diagrams",
    [string]$Name
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = (Get-Location).Path
}

$iconRoot = Join-Path $scriptRoot "..\assets\icons"
if (-not (Test-Path -LiteralPath $iconRoot)) {
    throw "Skill icon assets not found at '$iconRoot'."
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$resolvedOutputDir = (Resolve-Path -LiteralPath $OutputDir).Path

$iconFiles = @{
    "sre-agent" = "sre-agent.svg"
    "azure-sre-agent" = "sre-agent.svg"
    "key-vault" = "key-vaults.svg"
    "key-vaults" = "key-vaults.svg"
    "app-registration" = "app-registrations.svg"
    "app-registrations" = "app-registrations.svg"
    "managed-identity" = "managed-identities.svg"
    "managed-identities" = "managed-identities.svg"
    "identity" = "managed-identities.svg"
    "resource-group" = "resource-groups.svg"
    "resource-groups" = "resource-groups.svg"
    "virtual-machine" = "virtual-machine.svg"
    "vm" = "virtual-machine.svg"
    "app-service" = "app-services.svg"
    "app-services" = "app-services.svg"
    "storage-account" = "storage-accounts.svg"
    "storage-accounts" = "storage-accounts.svg"
    "sql-database" = "sql-database.svg"
    "database" = "sql-database.svg"
    "monitor" = "monitor.svg"
}

function Get-OptionalValue {
    param(
        [object]$Object,
        [string]$PropertyName,
        [object]$DefaultValue = $null
    )

    if ($null -eq $Object) {
        return $DefaultValue
    }

    $property = $Object.PSObject.Properties[$PropertyName]
    if ($null -eq $property -or $null -eq $property.Value) {
        return $DefaultValue
    }

    if ($property.Value -is [string] -and [string]::IsNullOrWhiteSpace($property.Value)) {
        return $DefaultValue
    }

    return $property.Value
}

function ConvertTo-SvgText {
    param([object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function Get-Slug {
    param([string]$Value)

    $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "diagram"
    }

    return $slug
}

function Split-Text {
    param(
        [string]$Text,
        [int]$MaxChars,
        [int]$MaxLines
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $words = $Text.Trim() -split "\s+"
    $lines = New-Object System.Collections.Generic.List[string]
    $current = ""

    foreach ($originalWord in $words) {
        $word = $originalWord
        while ($word.Length -gt $MaxChars) {
            if (-not [string]::IsNullOrWhiteSpace($current)) {
                $lines.Add($current)
                $current = ""
            }
            $lines.Add($word.Substring(0, [Math]::Max(1, $MaxChars - 1)) + "-")
            $word = $word.Substring([Math]::Max(1, $MaxChars - 1))
        }

        if ([string]::IsNullOrWhiteSpace($current)) {
            $current = $word
        }
        elseif (($current.Length + 1 + $word.Length) -le $MaxChars) {
            $current = "$current $word"
        }
        else {
            $lines.Add($current)
            $current = $word
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($current)) {
        $lines.Add($current)
    }

    if ($lines.Count -le $MaxLines) {
        return [string[]]$lines.ToArray()
    }

    $trimmed = @()
    for ($i = 0; $i -lt $MaxLines; $i++) {
        $trimmed += $lines[$i]
    }
    $trimmed[$MaxLines - 1] = ($trimmed[$MaxLines - 1].TrimEnd(".") + "...")
    return [string[]]$trimmed
}

function New-TextBlockSvg {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [string]$CssClass,
        [int]$MaxChars,
        [int]$MaxLines,
        [int]$LineHeight
    )

    $lines = @(Split-Text -Text $Text -MaxChars $MaxChars -MaxLines $MaxLines)
    $output = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineY = $Y + ($i * $LineHeight)
        $escaped = ConvertTo-SvgText $lines[$i]
        $output.Add("  <text x=""$X"" y=""$lineY"" class=""$CssClass"">$escaped</text>")
    }

    return ($output -join "`n")
}

function Get-IconDataUri {
    param([string]$IconName)

    if ([string]::IsNullOrWhiteSpace($IconName)) {
        return $null
    }

    $normalized = $IconName.ToLowerInvariant() -replace "[\s_]+", "-"
    if ($normalized.EndsWith(".svg")) {
        $relativePath = $normalized
    }
    elseif ($iconFiles.ContainsKey($normalized)) {
        $relativePath = $iconFiles[$normalized]
    }
    else {
        return $null
    }

    $path = Join-Path $iconRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Icon not found: $path"
    }

    $bytes = [System.IO.File]::ReadAllBytes($path)
    $base64 = [Convert]::ToBase64String($bytes)
    return "data:image/svg+xml;base64,$base64"
}

function New-PlaceholderIconSvg {
    param(
        [int]$X,
        [int]$Y,
        [int]$Size,
        [string]$Label
    )

    $initial = "?"
    if (-not [string]::IsNullOrWhiteSpace($Label)) {
        $initial = (ConvertTo-SvgText $Label.Substring(0, 1).ToUpperInvariant())
    }

    $center = $X + [Math]::Round($Size / 2)
    $textY = $Y + [Math]::Round($Size / 2) + 7
    $radius = [Math]::Round($Size / 2)
    return @"
  <circle cx="$center" cy="$center" r="$radius" class="placeholderIcon"/>
  <text x="$center" y="$textY" text-anchor="middle" class="placeholderIconText">$initial</text>
"@
}

function Get-DefaultScenario {
    return [pscustomobject]@{
        title = "MSP authentication flow to client resources"
        description = "Azure SRE Agent uses Key Vault, authenticates with the client, and accesses client resources."
        diagramType = "process"
        lanes = @(
            [pscustomobject]@{ id = "msp"; title = "MSP side" },
            [pscustomobject]@{ id = "client"; title = "Client side" }
        )
        nodes = @(
            [pscustomobject]@{ id = "sre"; label = "Azure SRE Agent"; subtitle = "support automation agent"; lane = "msp"; icon = "sre-agent"; sequence = "1"; order = 1 },
            [pscustomobject]@{ id = "vault"; label = "Key Vault"; subtitle = "secrets, certs, client auth material"; lane = "msp"; icon = "key-vault"; sequence = "2"; order = 2 },
            [pscustomobject]@{ id = "auth"; label = "Authenticate with client"; subtitle = "client identity boundary"; lane = "client"; icon = "app-registration"; kind = "auth"; order = 1 },
            [pscustomobject]@{ id = "resources"; label = "Access various resources"; subtitle = "VMs, apps, storage, databases, monitoring"; lane = "client"; icon = "resource-group"; sequence = "3"; order = 2 }
        )
        edges = @(
            [pscustomobject]@{ from = "sre"; to = "vault"; label = "retrieves secret" },
            [pscustomobject]@{ from = "vault"; to = "auth"; label = "presents credential" },
            [pscustomobject]@{ from = "auth"; to = "resources"; label = "authorized access" }
        )
    }
}

function Read-Scenario {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return Get-DefaultScenario
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    return Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
}

$scenario = Read-Scenario -Path $ScenarioPath
$rawNodes = @(Get-OptionalValue -Object $scenario -PropertyName "nodes" -DefaultValue @())
if ($rawNodes.Count -eq 0) {
    throw "Scenario must include at least one node."
}

$nodes = New-Object System.Collections.Generic.List[object]
$nodeIndex = 0
foreach ($rawNode in $rawNodes) {
    $nodeIndex++
    $id = [string](Get-OptionalValue -Object $rawNode -PropertyName "id" -DefaultValue "node-$nodeIndex")
    $label = [string](Get-OptionalValue -Object $rawNode -PropertyName "label" -DefaultValue $id)
    $lane = [string](Get-OptionalValue -Object $rawNode -PropertyName "lane" -DefaultValue (Get-OptionalValue -Object $rawNode -PropertyName "group" -DefaultValue "main"))
    $orderValue = Get-OptionalValue -Object $rawNode -PropertyName "order" -DefaultValue $nodeIndex
    [double]$order = 0
    if (-not [double]::TryParse([string]$orderValue, [ref]$order)) {
        $order = $nodeIndex
    }

    $nodes.Add([pscustomobject]@{
        Id = $id
        Label = $label
        Subtitle = [string](Get-OptionalValue -Object $rawNode -PropertyName "subtitle" -DefaultValue "")
        Lane = $lane
        Icon = [string](Get-OptionalValue -Object $rawNode -PropertyName "icon" -DefaultValue "")
        Kind = [string](Get-OptionalValue -Object $rawNode -PropertyName "kind" -DefaultValue "node")
        Sequence = [string](Get-OptionalValue -Object $rawNode -PropertyName "sequence" -DefaultValue "")
        Order = $order
        InputIndex = $nodeIndex
    })
}

$rawLanes = @(Get-OptionalValue -Object $scenario -PropertyName "lanes" -DefaultValue @())
$lanes = New-Object System.Collections.Generic.List[object]
if ($rawLanes.Count -gt 0) {
    foreach ($rawLane in $rawLanes) {
        $laneId = [string](Get-OptionalValue -Object $rawLane -PropertyName "id" -DefaultValue "")
        if ([string]::IsNullOrWhiteSpace($laneId)) {
            continue
        }
        $lanes.Add([pscustomobject]@{
            Id = $laneId
            Title = [string](Get-OptionalValue -Object $rawLane -PropertyName "title" -DefaultValue $laneId)
        })
    }
}

foreach ($laneId in @($nodes | ForEach-Object { $_.Lane } | Select-Object -Unique)) {
    if (-not ($lanes | Where-Object { $_.Id -eq $laneId })) {
        $lanes.Add([pscustomobject]@{ Id = $laneId; Title = $laneId })
    }
}

if ($lanes.Count -eq 0) {
    $lanes.Add([pscustomobject]@{ Id = "main"; Title = "Flow" })
}

$rawEdges = @(Get-OptionalValue -Object $scenario -PropertyName "edges" -DefaultValue @())
$edges = New-Object System.Collections.Generic.List[object]
foreach ($rawEdge in $rawEdges) {
    $from = [string](Get-OptionalValue -Object $rawEdge -PropertyName "from" -DefaultValue "")
    $to = [string](Get-OptionalValue -Object $rawEdge -PropertyName "to" -Defaulue "")
    if ([string]::IsNullOrWhiteSpace($from) -or [string]::IsNullOrWhiteSpace($to)) {
        continue
    }
    $edges.Add([pscustomobject]@{
        From = $from
        To = $to
        Label = [string](Get-OptionalValue -Object $rawEdge -PropertyName "label" -DefaultValue "")
    })
}

$margin = 36
$laneGap = 28
$laneWidth = 360
$nodeWidth = 282
$nodeHeight = 96
$nodeGap = 42
$headerHeight = 104
$bottomMargin = 52
$topMargin = 30

$maxLaneNodes = 1
foreach ($lane in $lanes) {
    $count = @($nodes | Where-Object { $_.Lane -eq $lane.Id }).Count
    if ($count -gt $maxLaneNodes) {
        $maxLaneNodes = $count
    }
}

$width = ($margin * 2) + ($lanes.Count * $laneWidth) + (($lanes.Count - 1) * $laneGap)
$height = [Math]::Max(520, $topMargin + $headerHeight + ($maxLaneNodes * $nodeHeight) + (($maxLaneNodes - 1) * $nodeGap) + $bottomMargin)

$laneMap = @{}
for ($i = 0; $i -lt $lanes.Count; $i++) {
    $laneMap[$lanes[$i].Id] = [pscustomobject]@{
        Index = $i
        X = $margin + ($i * ($laneWidth + $laneGap))
        Y = $topMargin + 64
        Width = $laneWidth
        Height = $height - $topMargin - 84
    }
}

$nodeLayout = @{}
foreach ($lane in $lanes) {
    $laneNodes = @($nodes | Where-Object { $_.Lane -eq $lane.Id } | Sort-Object Order, InputIndex)
    for ($i = 0; $i -lt $laneNodes.Count; $i++) {
        $laneBox = $laneMap[$lane.Id]
        $x = [int]($laneBox.X + (($laneWidth - $nodeWidth) / 2))
        $y = [int]($topMargin + $headerHeight + ($i * ($nodeHeight + $nodeGap)))
        $nodeLayout[$laneNodes[$i].Id] = [pscustomobject]@{
            X = $x
            Y = $y
            Width = $nodeWidth
            Height = $nodeHeight
            LaneIndex = $laneBox.Index
            Node = $laneNodes[$i]
        }
    }
}

$title = [string](Get-OptionalValue -Object $scenario -PropertyName "title" -DefaultValue "Azure diagram")
$description = [string](Get-OptionalValue -Object $scenario -PropertyName "description" -DefaultValue "")
$diagramType = [string](Get-OptionalValue -Object $scenario -PropertyName "diagramType" -DefaultValue "process")
$fileName = if ([string]::IsNullOrWhiteSpace($Name)) { Get-Slug $title } else { $Name }
if (-not $fileName.ToLowerInvariant().EndsWith(".svg")) {
    $fileName = "$fileName.svg"
}

$svg = New-Object System.Collections.Generic.List[string]
$svg.Add("<svg xmlns=""http://www.w3.org/2000/svg"" width=""$width"" height=""$height"" viewBox=""0 0 $width $height"" role=""img"" aria-labelledby=""title desc"">")
$svg.Add("  <title id=""title"">$(ConvertTo-SvgText $title)</title>")
$svg.Add("  <desc id=""desc"">$(ConvertTo-SvgText $description)</desc>")
$svg.Add(@"
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#233142"/>
    </marker>
    <style>
      text { font-family: Segoe UI, Arial, sans-serif; fill: #1f2937; }
      .diagramTitle { font-size: 24px; font-weight: 700; }
      .diagramSub { font-size: 13px; fill: #526070; }
      .lane { fill: #f8fafc; stroke: #cbd5e1; stroke-width: 2; rx: 8; }
      .lane:nth-of-type(2n) { fill: #f4fbf7; }
      .laneTitle { font-size: 17px; font-weight: 700; fill: #334155; }
      .card { fill: #ffffff; stroke: #9aa8b8; stroke-width: 1.8; rx: 8; }
      .auth { fill: #fff7ed; stroke: #ea8a16; stroke-width: 2; rx: 8; }
      .data { fill: #f0f9ff; stroke: #0284c7; stroke-width: 1.8; rx: 8; }
      .external { fill: #f8fafc; stroke: #64748b; stroke-width: 1.8; stroke-dasharray: 6 5; rx: 8; }
      .nodeTitle { font-size: 14px; font-weight: 700; }
      .nodeSub { font-size: 12px; fill: #64748b; }
      .sequence { font-size: 11px; font-weight: 700; fill: #475569; }
      .edge { fill: none; stroke: #233142; stroke-width: 2.2; marker-end: url(#arrow); }
      .edgeLabel { font-size: 12px; font-weight: 600; fill: #334155; }
      .edgeLabelBg { fill: #ffffff; opacity: 0.86; rx: 5; }
      .placeholderIcon { fill: #e2e8f0; stroke: #94a3b8; stroke-width: 1.5; }
      .placeholderIconText { font-size: 22px; font-weight: 700; fill: #475569; }
      .meta { font-size: 11px; fill: #64748b; text-transform: uppercase; }
    </style>
  </defs>
"A)
$svg.Add("  <rect x=""0"" y=""0"" width=""$width"" height=""$height"" fill=""#ffffff""/>")
$svg.Add((New-TextBlockSvg -Text $title -X 36 -Y 42 -CssClass "diagramTitle" -MaxChars 78 -MaxLines 1 -LineHeight 28))
if (-not [string]::IsNullOrWhiteSpace($description)) {
    $svg.Add((New-TextBlockSvg -Text $description -X 36 -Y 66 -CssClass "diagramSub" -MaxChars 126 -MaxLines 1 -LineHeight 18))
}
$svg.Add("  <text x=""$($width - 36)"" y=""42"" text-anchor=""end"" class=""meta"">$(ConvertTo-SvgText $diagramType)</text>")

foreach ($lane in $lanes) {
    $box = $laneMap[$lane.Id]
    $svg.Add("  <rect x=""$($box.X)"" y=""$($box.Y)"" width=""$($box.Width)"" height=""$($box.Height)"" class=""lane""/>")
    $svg.Add((New-TextBlockSvg -Text $lane.Title -X ($box.X + 20) -Y ($box.Y + 34) -CssClass "laneTitle" -MaxChars 34 -MaxLines 1 -LineHeight 20))
}

foreach ($edge in $edges) {
    if (-not $nodeLayout.ContainsKey($edge.From) -or -not $nodeLayout.ContainsKey($edge.To)) {
        Write-Warning "Skipping edge '$($edge.From)' -> '$($edge.To)' because one endpoint was not found."
        continue
    }

    $fromBox = $nodeLayout[$edge.From]
    $toBox = $nodeLayout[$edge.To]
    $fromRightX = $fromBox.X + $fromBox.Width
    $fromLeftX = $fromBox.X
    $fromY = $fromBox.Y + [Math]::Round($fromBox.Height / 2)
    $toLeftX = $toBox.X
    $toRightX = $toBox.X + $toBox.Width
    $toY = $toBox.Y + [Math]::Round($toBox.Height / 2)

    if ($toBox.X -gt $fromBox.X) {
        $x1 = $fromRightX
        $x2 = $toLeftX
        $c1 = $x1 + [Math]::Min(110, [Math]::Max(50, [Math]::Round(($x2 - $x1) / 2)))
        $c2 = $x2 - [Math]::Min(110, [Math]::Max(50, [Math]::Round((‘àÈ€´€‘àÄ¤€¼€È¤¤¤(€€€€€€€€‘Á…Ñ €ô€‰4€‘àÄ€‘™É½µd€‘ŒÄ€‘™É½µd€‘ŒÈ€‘Ñ½d€‘àÈ€‘Ñ½dˆ(€€€ô(€€€•±Í•¥˜€ ‘Ñ½	½à¹`€µ±Ğ€‘™É½µ	½à¹`¤ì(€€€€€€€€‘àÄ€ô€‘™É½µ1•™Ñ`(€€€€€€€€‘àÈ€ô€‘Ñ½I¥¡Ñ`(€€€€€€€€‘ŒÄ€ô€‘àÄ€´€äÀ(€€€€€€€€‘ŒÈ€ô€‘àÈ€¬€äÀ(€€€€€€€€‘Á…Ñ €ô€‰4€‘àÄ€‘™É½µd€‘ŒÄ€‘™É½µd€‘ŒÈ€‘Ñ½d€‘àÈ€‘Ñ½dˆ(€€€ô(€€€•±Í”ì(€€€€€€€€‘àÄ€ô€‘™É½µI¥¡Ñ`(€€€€€€€€‘àÈ€ô€‘Ñ½I¥¡Ñ`(€€€€€€€€‘Í¥‘•`€ô€‘™É½µI¥¡Ñ`€¬€ÌĞ(€€€€€€€€‘Á…Ñ €ô€‰4€‘àÄ€‘™É½µd0€‘Í¥‘•`€‘™É½µd0€‘Í¥‘•`€‘Ñ½d0€‘àÈ€‘Ñ½dˆ(€€€ô((€€€€‘ÍÙœ¹‘ ˆ€€ñÁ…Ñ ôˆˆ‘Á…Ñ ˆˆ±…ÍÌôˆ‰•‘”ˆˆ¼øˆ¤(€€€¥˜€ µ¹½ĞmÍÑÉ¥¹tèé%Í9Õ±±=É]¡¥Ñ•MÁ…” ‘•‘”¹1…‰•°¤¤ì(€€€€€€€€‘±…‰•±`€ôm¥¹Ñt  ‘™É½µI¥¡Ñ`€¬€‘Ñ½1•™Ñ`¤€¼€È¤(€€€€€€€¥˜€ ‘Ñ½	½à¹`€µ±”€‘™É½µ	½à¹`¤ì(€€€€€€€€€€€€‘±…‰•±`€ôm¥¹Ñt  ‘™É½µ1•™Ñ`€¬€‘Ñ½I¥¡Ñ`¤€¼€È¤(€€€€€€€ô(€€€€€€€€‘±…‰•±d€ôm¥¹Ñt  ‘™É½µd€¬€‘Ñ½d¤€¼€È¤€´€à(€€€€€€€€‘±…‰•°€ô½¹Ù•ÉÑQ¼µMÙQ•áĞ€‘•‘”¹1…‰•°(€€€€€€€€‘ÍÙœ¹‘ ˆ€€ñÉ•Ğàôˆˆ ‘±…‰•±`€´€Ôà¤ˆˆäôˆˆ ‘±…‰•±d€´€ÄÔ¤ˆˆİ¥‘Ñ ôˆˆÄÄØˆˆ¡•¥¡ĞôˆˆÈÈˆˆ±…ÍÌôˆ‰•‘•1…‰•±	œˆˆ¼øˆ¤(€€€€€€€€‘ÍÙœ¹‘ ˆ€€ñÑ•áĞàôˆˆ‘±…‰•±`ˆˆäôˆˆ‘±…‰•±dˆˆÑ•áĞµ…¹¡½Èôˆ‰µ¥‘‘±”ˆˆ±…ÍÌôˆ‰•‘•1…‰•°ˆˆø‘±…‰•°ğ½Ñ•áĞøˆ¤(€€€ô)ô()™½É•… € ‘¹½‘”¥¸€‘¹½‘•Ì¤ì(€€€€‘‰½à€ô€‘¹½‘•1…å½ÕÑl‘¹½‘”¹%‘t(€€€€‘…É‘±…ÍÌ€ôÍİ¥Ñ € ‘¹½‘”¹-¥¹¹Q½1½İ•É%¹Ù…É¥…¹Ğ ¤¤ì(€€€€€€€€‰…ÕÑ ˆì€‰…ÕÑ ˆô(€€€€€€€€‰¥‘•¹Ñ¥Ñäˆì€‰…ÕÑ ˆô(€€€€€€€€‰ÑÉÕÍĞˆì€‰…ÕÑ ˆô(€€€€€€€€‰‘…Ñ„ˆì€‰‘…Ñ„ˆô(€€€€€€€€‰‘…Ñ…‰…Í”ˆì€‰‘…Ñ„ˆô(€€€€€€€€‰•áÑ•É¹…°ˆì€‰•áÑ•É¹…°ˆô(€€€€€€€‘•™…Õ±Ğì€‰…Éˆô(€€€ô((€€€€‘ÍÙœ¹‘ ˆ€€ñÉ•Ğàôˆˆ ‘‰½à¹`¤ˆˆäôˆˆ ‘‰½à¹dˆˆİ¥‘Ñ ôˆˆ ‘‰½à¹]¥‘Ñ ¤ˆˆ¡•¥¡Ğôˆˆ ‘‰½à¹!•¥¡Ğ¤ˆˆ±…ÍÌôˆˆ‘…É‘±…ÍÌˆˆ¼øˆ¤((€€€€‘¥½¹`€ô€‘‰½à¹`€¬€Äà(€€€€‘¥½¹d€ô€‘‰½à¹d€¬€ÈÀ(€€€€‘¥½¹M¥é”€ô€ÔØ(€€€€‘¥½¹UÉ¤€ô•Ğµ%½¹…Ñ…UÉ¤€µ%½¹9…µ”€‘¹½‘”¹%½¸(€€€¥˜€ ‘¹Õ±°€µ¹”€‘¥½¹UÉ¤¤ì(€€€€€€€€‘ÍÙœ¹‘ ˆ€€ñ¥µ…”¡É•˜ôˆˆ‘¥½¹UÉ¤ˆˆàôˆˆ‘¥½¹`ˆˆäôˆˆ‘¥½¹dˆˆİ¥‘Ñ ôˆˆ‘¥½¹M¥é”ˆˆ¡•¥¡Ğôˆˆ‘¥½¹M¥é”ˆˆ¼øˆ¤(€€€ô(€€€•±Í”ì(€€€€€€€€‘ÍÙœ¹‘ ¡9•ÜµA±…•¡½±‘•É%½¹MÙœ€µ`€‘¥½¹`€µd€‘¥½¹d€µM¥é”€‘¥½¹M¥é”€µ1…‰•°€‘¹½‘”¹1…‰•°¤¤(€€€ô((€€€€‘Ñ•áÑ`€ô€‘‰½à¹`€¬€àà(€€€¥˜€ µ¹½ĞmÍÑÉ¥¹tèé%Í9Õ±±=É]¡¥Ñ•MÁ…” ‘¹½‘”¹M•ÅÕ•¹”¤¤ì(€€€€€€€€‘Í•ÅÕ•¹”€ô½¹Ù•ÉÑQ¼µMÙQ•áĞ€‘¹½‘”¹M•ÅÕ•¹”(€€€€€€€€‘ÍÙœ¹‘ ˆ€€ñÑ•áĞàôˆˆ‘Ñ•áÑ`ˆˆäôˆˆ ‘‰½à¹d€¬€ÈĞ¤ˆˆ±…ÍÌôˆ‰Í•ÅÕ•¹”ˆˆø‘Í•ÅÕ•¹”ğ½Ñ•áĞøˆ¤(€€€€€€€€‘Ñ¥Ñ±•d€ô€‘‰½à¹d€¬€ĞÔ(€€€ô(€€€•±Í”ì(€€€€€€€€‘Ñ¥Ñ±•d€ô€‘‰½à¹d€¬€ÌÌ(€€€ô((€€€€‘ÍÙœ¹‘ ¡9•ÜµQ•áÑ	±½­MÙœ€µQ•áĞ€‘¹½‘”¹1…‰•°€µ`€‘Ñ•áÑ`€µd€‘Ñ¥Ñ±•d€µÍÍ±…ÍÌ€‰¹½‘•Q¥Ñ±”ˆ€µ5…á¡…ÉÌ€ÈÔ€µ5…á1¥¹•Ì€È€µ1¥¹•!•¥¡Ğ€ÄÜ¤¤(€€€¥˜€ µ¹½ĞmÍÑÉ¥¹tèé%Í9Õ±±=É]¡¥Ñ•MÁ…” ‘¹½‘”¹MÕ‰Ñ¥Ñ±”¤¤ì(€€€€€€€€‘ÍÙœ¹‘ ¡9•ÜµQ•áÑ	±½­MÙœ€µQ•áĞ€‘¹½‘”¹MÕ‰Ñ¥Ñ±”€µ`€‘Ñ•áÑ`€µd€ ‘‰½à¹d€¬€ÜØ¤€µÍÍ±…ÍÌ€‰¹½‘•MÕˆˆ€µ5…á¡…ÉÌ€ÌÄ€µ5…á1¥¹•Ì€Ä€µ1¥¹•!•¥¡Ğ€ÄÔ¤¤(€€€ô)ô((‘ÍÙœ¹‘ ˆğ½ÍÙœøˆ¤((‘½ÕÑÁÕÑA…Ñ €ô)½¥¸µA…Ñ €‘É•Í½±Ù•‘=ÕÑÁÕÑ¥È€‘™¥±•9…µ”)mMåÍÑ•´¹%<¹¥±•tèé]É¥Ñ•±±Q•áĞ ‘½ÕÑÁÕÑA…Ñ °€ ‘ÍÙœ€µ©½¥¸€‰¸ˆ¤°mMåÍÑ•´¹Q•áĞ¹UQá¹½‘¥¹tèé¹•Ü ‘™…±Í”¤¤)]É¥Ñ”µ!½ÍĞ€‰]É½Ñ”€‘½ÕÑÁÕÑA…Ñ ˆ(