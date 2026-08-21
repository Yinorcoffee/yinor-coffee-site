# ============================================================
# Yinor Coffee - static site builder
# Usage: pwsh build.ps1
# Reads src/ (partials + pages + products + posts) -> out/
# ============================================================
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $root 'src'
$out  = Join-Path $root 'docs'   # docs/ = GitHub Pages branch-deploy convention
$domain = 'https://yinorcoffee.com'
$today = (Get-Date).ToString('yyyy-MM-dd')

# ---------- clean output ----------
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $out | Out-Null

# ---------- copy assets ----------
Copy-Item (Join-Path $root 'assets') (Join-Path $out 'assets') -Recurse

# ---------- templates ----------
$header = Get-Content (Join-Path $src 'partials\header.html') -Raw
$footer = Get-Content (Join-Path $src 'partials\footer.html') -Raw

# ---------- helpers ----------
function Get-FrontMatter([string]$content) {
  $fields = @{}
  $m = [regex]::Match($content, '(?s)^<!--\s*(.*?)\s*-->')
  if ($m.Success) {
    foreach ($line in ($m.Groups[1].Value -split "`n")) {
      if ($line -match '^\s*([A-Za-z0-9_]+)\s*:\s*(.*?)\s*$') {
        $fields[$Matches[1]] = $Matches[2].Trim()
      }
    }
  }
  return $fields
}

function Strip-FrontMatter([string]$content) {
  return [regex]::Replace($content, '(?s)^<!--\s*.*?\s*-->', '').Trim()
}

# ---------- collect products ----------
$products = @()
Get-ChildItem (Join-Path $src 'products') -Filter '*.body.html' | Sort-Object Name | ForEach-Object {
  $c = Get-Content $_.FullName -Raw
  $f = Get-FrontMatter $c
  $products += [pscustomobject]@{
    slug     = $_.BaseName -replace '\.body$', ''
    title    = $f['title']
    desc     = $f['desc']
    ogimage  = $f['ogimage']
    pname    = $f['pname']
    category = $f['category']
    flavor   = $f['flavor']
  }
}

$catLabel = @{ regular = 'Regular Espresso Blend'; premium = 'Premium Espresso Blend'; soe = 'Single Origin Espresso' }

function New-ProductCard($p) {
  $label = $catLabel[$p.category]
  $html = @"
<a class="product-card" href="/$($p.slug)">
  <img src="$($p.ogimage)" alt="$($p.pname) - wholesale coffee beans - Yinor Coffee" loading="lazy">
  <div class="body">
    <div class="meta">$label</div>
    <h3>$($p.pname)</h3>
    <p class="flavor">$($p.flavor)</p>
    <span class="btn btn-dark">View Product</span>
  </div>
</a>
"@
  return $html.Trim()
}

function Get-Grid([string]$which) {
  $list = switch ($which) {
    'all'     { $products }
    'regular' { $products | Where-Object { $_.category -eq 'regular' } }
    'premium' { $products | Where-Object { $_.category -eq 'premium' } }
    'soe'     { $products | Where-Object { $_.category -eq 'soe' } }
    default   { $products }
  }
  return ($list | ForEach-Object { New-ProductCard $_ }) -join "`n"
}

$featured = @(
  'fruit-sugar-signature-espresso-medium-roast-sidama-and-yirgacheffe-blend-naturally-sweet-coffee-bean',
  'high-quality-espresso-blends-coffee-beans-dark-roastedmalt-creamy-chocolate-toast-hazelnut-flavor',
  'kenya-nyeri-aa-soe-espresso-coffeeberry-brown-sugar-medium-aciditymedium-roast-coffee-bean',
  'yirgacheffe-natural-soe-espresso-coffee-ethiopia-g1-2400m-heirloom-lemon-and-tropical-fruit-flavor-coffee-bean',
  'sunshine-orchard-whole-bean-coffee-454g-medium-dark-roast-espresso-blend',
  'wholesale-high-quality-yunnan-ethiopia-coffee-beans-grizzly-basque-10-series-espresso-coffee-beans-454gbag-oem-customizable'
)
function Get-HomeProducts() {
  $list = $featured | ForEach-Object {
    $slug = $_
    $p = $products | Where-Object { $_.slug -eq $slug }
    if ($p) { New-ProductCard $p }
  }
  return $list -join "`n"
}

# ---------- collect posts ----------
$posts = @()
Get-ChildItem (Join-Path $src 'posts') -Filter '*.body.html' | ForEach-Object {
  $c = Get-Content $_.FullName -Raw
  $f = Get-FrontMatter $c
  $posts += [pscustomobject]@{
    slug  = $_.BaseName -replace '\.body$', ''
    title = $f['title']
    desc  = $f['desc']
    date  = $f['date']
    ogimage = $f['ogimage']
  }
}
$posts = $posts | Sort-Object date -Descending

function Get-PostList() {
  return ($posts | ForEach-Object {
    $html = @"
<a class="post-list-item" href="/$($_.slug)">
  <div class="post-meta">$($_.date) &middot; Yinor Coffee</div>
  <h3>$($_.title)</h3>
  <p>$($_.desc)</p>
</a>
"@
    return $html.Trim()
  }) -join "`n"
}

# ---------- page assembler ----------
$sitemap = New-Object System.Collections.Generic.List[string]

function New-Page {
  param([string]$BodyFile, [string]$Slug, [switch]$IsIndex, [string]$Priority, [switch]$ExcludeFromSitemap)
  $content = Get-Content $BodyFile -Raw
  $fm = Get-FrontMatter $content
  $body = Strip-FrontMatter $content

  $canonPath = if ($IsIndex) { '/' } else { "/$Slug" }
  $canonical = $domain + $canonPath
  $ogImage   = $fm['ogimage']; if (-not $ogImage) { $ogImage = '/assets/img/hero-home.jpg' }
  $ogTitle   = $fm['title'];   if (-not $ogTitle) { $ogTitle = 'Yinor Coffee - Wholesale Specialty Coffee Beans' }
  $ogDesc    = $fm['desc'];    if (-not $ogDesc)  { $ogDesc = 'Wholesale specialty coffee beans from China. Custom roasting, private label & OEM for cafes and roasters.' }

  $pageHeader = $header
  $pageHeader = $pageHeader.Replace('{{TITLE}}', $fm['title'])
  $pageHeader = $pageHeader.Replace('{{DESC}}', $fm['desc'])
  $pageHeader = $pageHeader.Replace('{{CANONICAL}}', $canonical)
  $pageHeader = $pageHeader.Replace('{{OG_TITLE}}', $ogTitle)
  $pageHeader = $pageHeader.Replace('{{OG_DESC}}', $ogDesc)
  $pageHeader = $pageHeader.Replace('{{OG_IMAGE}}', $ogImage)

  $html = $pageHeader + "`n" + $body + "`n" + $footer

  # replace content tokens
  $html = $html -replace '\{\{PRODUCT_GRID:all\}\}', (Get-Grid 'all')
  $html = $html -replace '\{\{PRODUCT_GRID:regular\}\}', (Get-Grid 'regular')
  $html = $html -replace '\{\{PRODUCT_GRID:premium\}\}', (Get-Grid 'premium')
  $html = $html -replace '\{\{PRODUCT_GRID:soe\}\}', (Get-Grid 'soe')
  $html = $html -replace '\{\{HOME_PRODUCTS\}\}', (Get-HomeProducts)
  $html = $html -replace '\{\{POST_LIST\}\}', (Get-PostList)

  # write file (directory structure for clean URLs)
  $dir = if ($IsIndex) { $out } else { Join-Path $out $Slug }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $file = Join-Path $dir 'index.html'

  # base path support (GitHub Pages project sites): prefix internal links
  if ($env:BASE_PATH) {
    $bp = $env:BASE_PATH.TrimEnd('/')
    $html = [regex]::Replace($html, '(href|src)="/', ('$1="' + $bp + '/'))
  }

  [System.IO.File]::WriteAllText($file, $html, (New-Object System.Text.UTF8Encoding($false)))

  if (-not $ExcludeFromSitemap) {
    $loc = if ($IsIndex) { $domain + '/' } else { $domain + '/' + $Slug }
    $sitemap.Add("  <url><loc>$loc</loc><lastmod>$today</lastmod><priority>$Priority</priority></url>")
  }
  Write-Host "built: $file"
}

# ---------- build pages ----------
$pages = @(
  @{ f = 'index.body.html';                                        s = 'index';                                       i = $true;  p = '1.0' },
  @{ f = 'premium-espresso-blends-coffee-beans.body.html';         s = 'premium-espresso-blends-coffee-beans';       i = $false; p = '0.9' },
  @{ f = 'regular-espresso-blends-coffee-beans.body.html';         s = 'regular-espresso-blends-coffee-beans';       i = $false; p = '0.8' },
  @{ f = 'premium-espresso-coffee-beans.body.html';                s = 'premium-espresso-coffee-beans';              i = $false; p = '0.8' },
  @{ f = 'single-origin-espresso-soe-coffee-beans.body.html';      s = 'single-origin-espresso-soe-coffee-beans';    i = $false; p = '0.8' },
  @{ f = 'about-us-coffee-beans.body.html';                        s = 'about-us-coffee-beans';                      i = $false; p = '0.6' },
  @{ f = 'request-a-consultation-coffee-wholesale-inquiry.body.html'; s = 'request-a-consultation-coffee-wholesale-inquiry'; i = $false; p = '0.6' },
  @{ f = 'blog.body.html';                                         s = 'blog';                                       i = $false; p = '0.6' },
  @{ f = 'privacy-policy.body.html';                               s = 'privacy-policy';                             i = $false; p = '0.3' },
  @{ f = 'terms-and-conditions.body.html';                         s = 'terms-and-conditions';                       i = $false; p = '0.3' },
  @{ f = 'product-catalog.body.html';                              s = 'product-catalog';                            i = $false; p = '0.0'; x = $true }
)
foreach ($pg in $pages) {
  New-Page -BodyFile (Join-Path $src "pages\$($pg.f)") -Slug $pg.s -IsIndex:$pg.i -Priority $pg.p -ExcludeFromSitemap:$pg.x
}

# ---------- build product pages ----------
foreach ($p in $products) {
  New-Page -BodyFile (Join-Path $src "products\$($p.slug).body.html") -Slug $p.slug -Priority '0.7'
}

# ---------- build post pages ----------
foreach ($p in $posts) {
  New-Page -BodyFile (Join-Path $src "posts\$($p.slug).body.html") -Slug $p.slug -Priority '0.6'
}

# ---------- 404 ----------
$c404 = Get-Content (Join-Path $src 'pages\404.body.html') -Raw
$fm404 = Get-FrontMatter $c404
$h404 = $header.Replace('{{TITLE}}', $fm404['title']).Replace('{{DESC}}', $fm404['desc'])
$h404 = $h404.Replace('{{CANONICAL}}', $domain + '/404.html')
$h404 = $h404.Replace('{{OG_TITLE}}', $fm404['title']).Replace('{{OG_DESC}}', $fm404['desc']).Replace('{{OG_IMAGE}}', '/assets/img/hero-home.jpg')
$html404 = $h404 + "`n" + (Strip-FrontMatter $c404) + "`n" + $footer
[System.IO.File]::WriteAllText((Join-Path $out '404.html'), $html404, (New-Object System.Text.UTF8Encoding($false)))

# ---------- robots.txt ----------
$robots = @"
User-agent: *
Allow: /

Sitemap: $domain/sitemap.xml
"@
[System.IO.File]::WriteAllText((Join-Path $out 'robots.txt'), $robots, (New-Object System.Text.UTF8Encoding($false)))

# ---------- sitemap.xml ----------
$sm = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$($sitemap -join "`n")
</urlset>
"@
[System.IO.File]::WriteAllText((Join-Path $out 'sitemap.xml'), $sm, (New-Object System.Text.UTF8Encoding($false)))

# ---------- _redirects (Netlify) ----------
$redir = @"
/product-catalog  $domain/premium-espresso-blends-coffee-beans  301
"@
[System.IO.File]::WriteAllText((Join-Path $out '_redirects'), $redir, (New-Object System.Text.UTF8Encoding($false)))

# ---------- GitHub Pages helper ----------
[System.IO.File]::WriteAllText((Join-Path $out '.nojekyll'), '', (New-Object System.Text.UTF8Encoding($false)))

Write-Host "`n=== Build complete ==="
Write-Host "Pages: $($sitemap.Count) URLs in sitemap, $($products.Count) products, $($posts.Count) posts"
$fileCount = (Get-ChildItem $out -Recurse -File).Count
Write-Host "Files generated: $fileCount"
