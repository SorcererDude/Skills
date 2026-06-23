param(
    [string]$InputDir = "diagrams",
    [string]$OutputDir = "raster",
    [string]$Filter = "*azure-icons.svg",
    [ValidateSet("Png", "Jpg", "Both")]
    [string]$Format = "Both",
    [int]$JpegQuality = 92,
    [string]$EdgePath = ""
)

$ErrorActionPreference = "Stop"

function Get-EdgePath {
    param([string]$PreferredPath)

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        if (Test-Path -LiteralPath $PreferredPath) {
            return (Resolve-Path -LiteralPath $PreferredPath).Path
        }
        throw "EdgePath was supplied but does not exist: $PreferredPath"
    }

    $fromPath = Get-Command msedge.exe -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }

    $candidates = @(
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "Microsoft Edge was not found on PATH or in the standard install locations."
}

function Get-SvgSize {
    param([Parameter(Mandatory)][System.IO.FileInfo]$SvgFile)

    [xml]$svgXml = Get-Content -LiteralPath $SvgFile.FullName -Raw
    $root = $svgXml.DocumentElement

    $width = 0
    $height = 0

    if ($root.width) {
        $widthText = [string]$root.width
        $width = [int][double]($widthText -replace "[^\d.]", "")
    }

    if ($root.height) {
        $heightText = [string]$root.height
        $height = [int][double]($heightText -replace "[^\d.]", "")
    }

    if (($width -le 0 -or $height -le 0) -and $root.viewBox) {
        $parts = ([string]$root.viewBox) -split "[,\s]+" | Where-Object { $_ -ne "" }
        if ($parts.Count -eq 4) {
            $width = [int][double]$parts[2]
            $height = [int][double]$parts[3]
        }
    }

    if ($width -le 0 -or $height -le 0) {
        throw "Could not determine SVG dimensions for $($SvgFile.FullName)"
    }

    return [pscustomobject]@{
        Width = $width
        Height = $height
    }
}

function Convert-PngToJpg {
    param(
        [Parameter(Mandatory)][string]$PngPath,
        [Parameter(Mandatory)][string]$JpgPath,
        [Parameter(Mandatory)][int]$Quality
    )

    Add-Type -AssemblyName System.Drawing

    $image = $null
    $bitmap = $null
    $graphics = $null
    $encoderParams = $null

    try {
        $image = [System.Drawing.Image]::FromFile($PngPath)
        $bitmap = [System.Drawing.Bitmap]::new($image.Width, $image.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.DrawImage($image, 0, 0, $image.Width, $image.Height)

        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
            Where-Object { $_.MimeType -eq "image/jpeg" } |
            Select-Object -First 1

        $encoderParams = [System.Drawing.Imaging.EncoderParameters]::new(1)
        $encoderParams.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
            [System.Drawing.Imaging.Encoder]::Quality,
            [int64]$Quality
        )

        $bitmap.Save($JpgPath, $jpegCodec, $encoderParams)
    }
    finally {
        if ($encoderParams) { $encoderParams.Dispose() }
        if ($graphics) { $graphics.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        if ($image) { $image.Dispose() }
    }
}

$edge = Get-EdgePath -PreferredPath $EdgePath

if (-not (Test-Path -LiteralPath $InputDir)) {
    throw "InputDir not found: $InputDir"
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$inputPath = (Resolve-Path -LiteralPath $InputDir).Path
$outputPath = (Resolve-Path -LiteralPath $OutputDir).Path
$svgFiles = Get-ChildItem -LiteralPath $inputPath -Filter $Filter -File

if ($svgFiles.Count -eq 0) {
    throw "No SVG files matched '$Filter' in '$inputPath'."
}

foreach ($svg in $svgFiles) {
    $size = Get-SvgSize -SvgFile $svg
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($svg.Name)
    $pngPath = Join-Path $outputPath "$baseName.png"
    $jpgPath = Join-Path $outputPath "$baseName.jpg"
    $svgUri = ([System.Uri]$svg.FullName).AbsoluteUri

    $edgeArgs = @(
        "--headless=new",
        "--disable-gpu",
        "--no-first-run",
        "--disable-extensions",
        "--hide-scrollbars",
        "--screenshot=$pngPath",
        "--window-size=$($size.Width),$($size.Height)",
        $svgUri
    )

    $process = Start-Process -FilePath $edge -ArgumentList $edgeArgs -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Edge failed to render $($svg.Name). Exit code: $($process.ExitCode)"
    }

    if (-not (Test-Path -LiteralPath $pngPath)) {
        throw "Expected PNG was not created: $pngPath"
    }

    if ($Format -eq "Jpg" -or $Format -eq "Both") {
        Convert-PngToJpg -PngPath $pngPath -JpgPath $jpgPath -Quality $JpegQuality
    }

    if ($Format -eq "Jpg") {
        Remove-Item -LiteralPath $pngPath
        Write-Host "Wrote $jpgPath"
    }
    elseif ($Format -eq "Png") {
        Write-Host "Wrote $pngPath"
    }
    else {
        Write-Host "Wrote $pngPath"
        Write-Host "Wrote $jpgPath"
    }
}
