param(
    [string]$OutputDir = "diagrams"
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

function Get-IconDataUri {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    $path = Join-Path $iconRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Icon not found: $path"
    }

    $bytes = [System.IO.File]::ReadAllBytes($path)
    $base64 = [Convert]::ToBase64String($bytes)
    return "data:image/svg+xml;base64,$base64"
}

function Save-Svg {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Svg
    )

    $resolvedOutputDir = (Resolve-Path -LiteralPath $OutputDir).Path
    $path = Join-Path $resolvedOutputDir $Name
    [System.IO.File]::WriteAllText($path, $Svg, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Wrote $path"
}

$icons = @{
    SreAgent = Get-IconDataUri "sre-agent.svg"
    KeyVault = Get-IconDataUri "key-vaults.svg"
    AppRegistration = Get-IconDataUri "app-registrations.svg"
    ManagedIdentity = Get-IconDataUri "managed-identities.svg"
    ResourceGroup = Get-IconDataUri "resource-groups.svg"
    VirtualMachine = Get-IconDataUri "virtual-machine.svg"
    AppService = Get-IconDataUri "app-services.svg"
    StorageAccount = Get-IconDataUri "storage-accounts.svg"
    SqlDatabase = Get-IconDataUri "sql-database.svg"
    Monitor = Get-IconDataUri "monitor.svg"
}

$basicIconFlow = @"
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="520" viewBox="0 0 1080 520" role="img" aria-labelledby="title desc">
  <title id="title">MSP to client authentication flow with Azure service icons</title>
  <desc id="desc">Azure SRE Agent uses Key Vault, authenticates with the client, and accesses multiple client resources.</desc>
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#243447"/>
    </marker>
    <style>
      text { font-family: Segoe UI, Arial, sans-serif; fill: #1f2937; }
      .lane { fill: #f8fafc; stroke: #cbd5e1; stroke-width: 2; rx: 8; }
      .laneTitle { font-size: 18px; font-weight: 700; }
      .card { fill: #ffffff; stroke: #aab7c4; stroke-width: 1.8; rx: 8; }
      .authCard { fill: #fff7ed; stroke: #f59e0b; stroke-width: 2; rx: 8; }
      .nodeTitle { font-size: 15px; font-weight: 700; }
      .nodeSub { font-size: 12px; fill: #5f6b7a; }
      .edge { fill: none; stroke: #243447; stroke-width: 2.4; marker-end: url(#arrow); }
      .edgeLabel { font-size: 12px; font-weight: 600; fill: #3b4a5a; }
      .boundary { stroke: #64748b; stroke-width: 2; stroke-dasharray: 8 8; }
    </style>
  </defs>

  <rect x="30" y="40" width="450" height="420" class="lane"/>
  <rect x="600" y="40" width="450" height="420" class="lane"/>
  <line x1="540" y1="30" x2="540" y2="470" class="boundary"/>
  <text x="55" y="76" class="laneTitle">MSP side</text>
  <text x="625" y="76" class="laneTitle">Client side</text>

  <rect x="95" y="125" width="285" height="100" class="card"/>
  <image href="$($icons.SreAgent)" x="118" y="145" width="58" height="58"/>
  <text x="195" y="166" class="nodeTitle">1. Azure SRE Agent</text>
  <text x="195" y="189" class="nodeSub">support automation agent</text>

  <rect x="95" y="295" width="285" height="100" class="card"/>
  <image href="$($icons.KeyVault)" x="118" y="315" width="58" height="58"/>
  <text x="195" y="336" class="nodeTitle">2. Key Vault</text>
  <text x="195" y="359" class="nodeSub">secrets, certs, client auth material</text>

  <rect x="410" y="206" width="260" height="105" class="authCard"/>
  <image href="$($icons.AppRegistration)" x="435" y="228" width="58" height="58"/>
  <text x="512" y="244" class="nodeTitle">Authenticate</text>
  <text x="512" y="264" class="nodeTitle">with client</text>
  <text x="512" y="287" class="nodeSub">client service principal</text>

  <rect x="710" y="125" width="265" height="78" class="card"/>
  <image href="$($icons.VirtualMachine)" x="730" y="140" width="46" height="46"/>
  <text x="795" y="158" class="nodeTitle">3a. Virtual machines</text>
  <text x="795" y="179" class="nodeSub">compute resources</text>

  <rect x="710" y="225" width="265" height="78" class="card"/>
  <image href="$($icons.AppService)" x="730" y="240" width="46" height="46"/>
  <text x="795" y="258" class="nodeTitle">3b. App Services</text>
  <text x="795" y="279" class="nodeSub">apps and APIs</text>

  <rect x="710" y="325" width="265" height="78" class="card"/>
  <image href="$($icons.StorageAccount)" x="730" y="340" width="46" height="46"/>
  <text x="795" y="358" class="nodeTitle">3c. Storage accounts</text>
  <text x="795" y="379" class="nodeSub">files, blobs, queues</text>

  <path d="M 380 175 C 405 175 409 227 430 237" class="edge"/>
  <path d="M 380 345 C 412 345 409 290 430 278" class="edge"/>
  <path d="M 670 258 C 690 198 692 168 710 164" class="edge"/>
  <path d="M 670 258 L 710 264" class="edge"/>
  <path d="M 670 258 C 690 320 692 360 710 364" class="edge"/>

  <text x="382" y="151" class="edgeLabel">runs workflow</text>
  <text x="385" y="376" class="edgeLabel">retrieves secret</text>
</svg>
"@

$swimlaneIconFlow = @"
<svg xmlns="http://www.w3.org/2000/svg" width="1160" height="640" viewBox="0 0 1160 640" role="img" aria-labelledby="title desc">
  <title id="title">Swimlane process flow with official Azure icons</title>
  <desc id="desc">MSP-side automation retrieves Key Vault material, authenticates through client identity, and accesses client-side resources.</desc>
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#293241"/>
    </marker>
    <style>
      text { font-family: Segoe UI, Arial, sans-serif; fill: #1f2937; }
      .title { font-size: 22px; font-weight: 700; }
      .laneTitle { font-size: 17px; font-weight: 700; }
      .bandMsp { fill: #eef6ff; }
      .bandClient { fill: #effaf1; }
      .frame { fill: #ffffff; stroke: #d0d7de; stroke-width: 2; rx: 8; }
      .boundary { stroke: #64748b; stroke-width: 2; stroke-dasharray: 8 8; }
      .step { fill: #ffffff; stroke: #9aa8b8; stroke-width: 1.8; rx: 8; }
      .trust { fill: #fff7ed; stroke: #f59e0b; stroke-width: 2; rx: 8; }
      .nodeTitle { font-size: 14px; font-weight: 700; }
      .nodeSub { font-size: 12px; fill: #667085; }
      .edge { fill: none; stroke: #293241; stroke-width: 2.4; marker-end: url(#arrow); }
      .edgeLabel { font-size: 12px; font-weight: 600; fill: #3c4a5b; }
    </style>
  </defs>

  <rect x="30" y="30" width="1100" height="560" class="frame"/>
  <rect x="30" y="92" width="1100" height="210" class="bandMsp"/>
  <rect x="30" y="302" width="1100" height="288" class="bandClient"/>
  <line x1="30" y1="302" x2="1130" y2="302" class="boundary"/>

  <text x="55" y="69" class="title">MSP Authentication Flow to Client Resources</text>
  <text x="55" y="126" class="laneTitle">MSP side</text>
  <text x="55" y="336" class="laneTitle">Client side</text>

  <rect x="180" y="145" width="235" height="92" class="step"/>
  <image href="$($icons.SreAgent)" x="202" y="164" width="54" height="54"/>
  <text x="272" y="184" class="nodeTitle">1. Azure SRE Agent</text>
  <text x="272" y="207" class="nodeSub">automation workflow</text>

  <rect x="490" y="145" width="235" height="92" class="step"/>
  <image href="$($icons.KeyVault)" x="512" y="164" width="54" height="54"/>
  <text x="582" y="184" class="nodeTitle">2. Key Vault</text>
  <text x="582" y="207" class="nodeSub">credential material</text>

  <rect x="805" y="233" width="245" height="92" class="trust"/>
  <image href="$($icons.ManagedIdentity)" x="827" y="252" width="54" height="54"/>
  <text x="897" y="272" class="nodeTitle">Authenticate</text>
  <text x="897" y="295" class="nodeSub">client identity boundary</text>

  <rect x="180" y="390" width="205" height="82" class="step"/>
  <image href="$($icons.ResourceGroup)" x="200" y="405" width="50" height="50"/>
  <text x="265" y="424" class="nodeTitle">3a. Resource groups</text>
  <text x="265" y="446" class="nodeSub">scope and organize</text>

  <rect x="445" y="390" width="205" height="82" class="step"/>
  <image href="$($icons.VirtualMachine)" x="465" y="405" width="50" height="50"/>
  <text x="530" y="424" class="nodeTitle">3b. Virtual machines</text>
  <text x="530" y="446" class="nodeSub">compute access</text>

  <rect x="710" y="390" width="205" height="82" class="step"/>
  <image href="$($icons.SqlDatabase)" x="730" y="405" width="50" height="50"/>
  <text x="795" y="424" class="nodeTitle">3c. SQL Database</text>
  <text x="795" y="446" class="nodeSub">data access</text>

  <rect x="445" y="500" width="205" height="82" class="step"/>
  <image href="$($icons.Monitor)" x="465" y="515" width="50" height="50"/>
  <text x="530" y="534" class="nodeTitle">3d. Monitor</text>
  <text x="530" y="556" class="nodeSub">logs and health</text>

  <path d="M 415 191 L 490 191" class="edge"/>
  <path d="M 725 191 C 785 191 810 223 840 233" class="edge"/>
  <path d="M 928 325 C 850 350 355 350 282 390" class="edge"/>
  <path d="M 928 325 C 840 352 615 352 548 390" class="edge"/>
  <path d="M 928 325 C 890 352 840 360 813 390" class="edge"/>
  <path d="M 928 325 C 1030 390 1030 585 548 585 L 548 582" class="edge"/>

  <text x="430" y="173" class="edgeLabel">request credential</text>
  <text x="735" y="169" class="edgeLabel">present credential</text>
</svg>
"@

$fanoutIconFlow = @"
<svg xmlns="http://www.w3.org/2000/svg" width="1160" height="700" viewBox="0 0 1160 700" role="img" aria-labelledby="title desc">
  <title id="title">Hub-and-spoke client resource access flow with Azure icons</title>
  <desc id="desc">MSP-side Azure SRE Agent and Key Vault authenticate to the client, then access multiple Azure resource types.</desc>
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#22313f"/>
    </marker>
    <style>
      text { font-family: Segoe UI, Arial, sans-serif; fill: #1f2937; }
      .heading { font-size: 22px; font-weight: 700; }
      .zone { fill: #f8fafc; stroke: #cbd5e1; stroke-width: 2; rx: 8; }
      .zoneTitle { font-size: 16px; font-weight: 700; fill: #334155; }
      .card { fill: #ffffff; stroke: #9aa8b8; stroke-width: 1.8; rx: 8; }
      .auth { fill: #fff7ed; stroke: #ea580c; stroke-width: 2; rx: 8; }
      .nodeTitle { font-size: 14px; font-weight: 700; }
      .nodeSub { font-size: 12px; fill: #667085; }
      .edge { fill: none; stroke: #22313f; stroke-width: 2.4; marker-end: url(#arrow); }
      .lightEdge { fill: none; stroke: #475569; stroke-width: 2; marker-end: url(#arrow); }
      .label { font-size: 12px; font-weight: 600; fill: #334155; }
    </style>
  </defs>

  <text x="40" y="48" class="heading">Hub-and-Spoke Flow with Azure Service Icons</text>

  <rect x="40" y="80" width="405" height="565" class="zone"/>
  <text x="65" y="115" class="zoneTitle">MSP side</text>

  <rect x="700" y="80" width="420" height="565" class="zone"/>
  <text x="725" y="115" class="zoneTitle">Client side</text>

  <rect x="105" y="175" width="275" height="100" class="card"/>
  <image href="$($icons.SreAgent)" x="130" y="197" width="56" height="56"/>
  <text x="205" y="217" class="nodeTitle">1. Azure SRE Agent</text>
  <text x="205" y="240" class="nodeSub">automation / support workflow</text>

  <rect x="105" y="390" width="275" height="100" class="card"/>
  <image href="$($icons.KeyVault)" x="130" y="412" width="56" height="56"/>
  <text x="205" y="432" class="nodeTitle">2. Key Vault</text>
  <text x="205" y="455" class="nodeSub">secrets and certificates</text>

  <rect x="475" y="294" width="210" height="112" class="auth"/>
  <image href="$($icons.AppRegistration)" x="498" y="320" width="58" height="58"/>
  <text x="572" y="340" class="nodeTitle">Authenticate</text>
  <text x="572" y="363" class="nodeSub">client tenant trust</text>

  <rect x="760" y="140" width="280" height="78" class="card"/>
  <image href="$($icons.ResourceGroup)" x="780" y="155" width="48" height="48"/>
  <text x="845" y="174" class="nodeTitle">3a. Resource groups</text>
  <text x="845" y="195" class="nodeSub">management scope</text>

  <rect x="760" y="245" width="280" height="78" class="card"/>
  <image href="$($icons.VirtualMachine)" x="780" y="260" width="48" height="48"/>
  <text x="845" y="279" class="nodeTitle">3b. Virtual machines</text>
  <text x="845" y="300" class="nodeSub">Windows / Linux compute</text>

  <rect x="760" y="350" width="280" height="78" class="card"/>
  <image href="$($icons.AppService)" x="780" y="365" width="48" height="48"/>
  <text x="845" y="384" class="nodeTitle">3c. App Services</text>
  <text x="845" y="405" class="nodeSub">web apps and APIs</text>

  <rect x="760" y="455" width="280" height="78" class="card"/>
  <image href="$($icons.SqlDatabase)" x="780" y="470" width="48" height="48"/>
  <text x="845" y="489" class="nodeTitle">3d. SQL Database</text>
  <text x="845" y="510" class="nodeSub">structured data</text>

  <rect x="760" y="560" width="280" height="78" class="card"/>
  <image href="$($icons.StorageAccount)" x="780" y="575" width="48" height="48"/>
  <text x="845" y="594" class="nodeTitle">3e. Storage accounts</text>
  <text x="845" y="615" class="nodeSub">blobs, files, queues</text>

  <path d="M 242 275 L 242 390" class="lightEdge"/>
  <path d="M 380 225 C 430 225 435 308 475 326" class="edge"/>
  <path d="M 380 440 C 430 440 435 382 475 374" class="edge"/>
  <path d="M 685 350 C 725 260 735 183 760 179" class="edge"/>
  <path d="M 685 350 C 725 310 735 286 760 284" class="edge"/>
  <path d="M 685 350 C 724 361 735 386 760 389" class="edge"/>
  <path d="M 685 350 C 725 430 735 490 760 494" class="edge"/>
  <path d="M 685 350 C 725 505 735 595 760 599" class="edge"/>

  <text x="247" y="334" class="label">uses vault material</text>
  <text x="392" y="203" class="label">request access</text>
  <text x="391" y="466" class="label">retrieve credential</text>
  <text x="704" y="339" class="label">authorized access</text>
</svg>
"@

Save-Svg -Name "04-basic-flow-azure-icons.svg" -Svg $basicIconFlow
Save-Svg -Name "05-swimlane-flow-azure-icons.svg" -Svg $swimlaneIconFlow
Save-Svg -Name "06-resource-fanout-azure-icons.svg" -Svg $fanoutIconFlow
