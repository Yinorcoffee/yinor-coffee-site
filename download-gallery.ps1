# Download all product gallery images from old site CDN, compress to JPEG 800px
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing

$srcFile = "$env:TEMP\prod_imgs2.txt"
$galleryDir = 'E:\deepseekharenss\yinor-site\assets\img\gallery'
New-Item -ItemType Directory -Force -Path $galleryDir | Out-Null

$products = @()
Get-Content $srcFile | ForEach-Object {
  if ($_ -match '^(https://yinorcoffee\.com/[^\t]+)\t(.+)$') {
    $slug = ($Matches[1] -replace '^https://yinorcoffee\.com/', '')
    $urls = $Matches[2] -split ' ; ' | Where-Object { $_ }
    $products += [pscustomobject]@{ slug = $slug; urls = $urls }
  }
}
Write-Host "Products: $($products.Count)"

$allUrls = $products | ForEach-Object { $_.urls } | Select-Object -Unique
Write-Host "Unique image URLs: $($allUrls.Count)"

$map = @{}
$i = 0
foreach ($u in $allUrls) {
  $i++
  $uuid = [regex]::Match($u, 'assets/([a-f0-9\-]+)\.(jpg|png|webp)')
  $name = $uuid.Groups[1].Value
  $ext = $uuid.Groups[2].Value
  $outJpg = Join-Path $galleryDir ($name + '.jpg')
  if (Test-Path $outJpg) { $map[$u] = '/assets/img/gallery/' + $name + '.jpg'; continue }
  $tmp = Join-Path $env:TEMP ($name + '.' + $ext)
  try {
    Invoke-WebRequest -Uri $u -OutFile $tmp -UseBasicParsing -TimeoutSec 45
    $img = [System.Drawing.Image]::FromFile($tmp)
    $maxDim = 800
    $ratio = [Math]::Min(1.0, $maxDim / [Math]::Max($img.Width, $img.Height))
    $nw = [int]($img.Width * $ratio); $nh = [int]($img.Height * $ratio)
    $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $nw, $nh)
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]78)
    $bmp.Save($outJpg, $enc, $ep)
    $g.Dispose(); $bmp.Dispose(); $img.Dispose()
    Remove-Item $tmp -Force
    $map[$u] = '/assets/img/gallery/' + $name + '.jpg'
    Write-Host "OK $name ($([math]::Round((Get-Item $outJpg).Length/1KB)) KB)"
  } catch {
    Write-Host "FAIL $name : $($_.Exception.Message)"
  }
}

$gallery = @{}
foreach ($p in $products) {
  $imgs = @()
  foreach ($u in $p.urls) {
    if ($map[$u]) { $imgs += $map[$u] }
  }
  $gallery[$p.slug] = $imgs
}
$gallery | ConvertTo-Json -Depth 3 | Out-File 'E:\deepseekharenss\yinor-site\assets\img\gallery\gallery-map.json' -Encoding utf8
Write-Host "Gallery images: $((Get-ChildItem $galleryDir -Filter '*.jpg').Count)"
Write-Host "Map saved"
