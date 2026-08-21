# Deploy docs/ to Netlify via API (token from env NETLIFY_TOKEN)
$ErrorActionPreference = 'Stop'
$token = $env:NETLIFY_TOKEN
if (-not $token) { throw 'NETLIFY_TOKEN env var not set' }
$docs = 'E:\deepseekharenss\yinor-site\docs'
$zip = Join-Path $env:TEMP 'yinor-site-deploy.zip'

# 1. zip docs/ contents with FORWARD SLASH paths (required by Netlify)
if (Test-Path $zip) { Remove-Item $zip -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fs = [System.IO.File]::Create($zip)
$archive = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
$files = Get-ChildItem $docs -Recurse -File
foreach ($f in $files) {
  $rel = $f.FullName.Substring($docs.Length).TrimStart('\').TrimStart('/') -replace '\\', '/'
  $entry = $archive.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
  $es = $entry.Open()
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $es.Write($bytes, 0, $bytes.Length)
  $es.Close()
}
$archive.Dispose()
$fs.Close()
Write-Host "Zip ready: $((Get-Item $zip).Length / 1KB) KB, $($files.Count) files (forward-slash paths)"

$h = @{ Authorization = "Bearer $token"; 'User-Agent' = 'yinor-deploy' }

# 2. create site (unique name) OR reuse existing site id from env NETLIFY_SITE_ID
if ($env:NETLIFY_SITE_ID) {
  $siteId = $env:NETLIFY_SITE_ID
  $site = Invoke-RestMethod -Uri "https://api.netlify.com/api/v1/sites/$siteId" -Headers $h -Method Get -TimeoutSec 30
  $url = $site.ssl_url
  if (-not $url) { $url = $site.url }
  Write-Host "Reusing site: $url  (id: $siteId)"
} else {
  $siteName = 'yinor-coffee-' + (Get-Random -Minimum 1000 -Maximum 9999)
  $siteBody = @{ name = $siteName } | ConvertTo-Json -Compress
  $site = Invoke-RestMethod -Uri 'https://api.netlify.com/api/v1/sites' -Headers $h -Method Post -Body $siteBody -ContentType 'application/json' -TimeoutSec 60
  $siteId = $site.id
  $url = $site.ssl_url
  if (-not $url) { $url = $site.url }
  Write-Host "Site created: $url  (id: $siteId)"
}

# 2b. disable SSO login protection (account default enables it - breaks public access)
$ssoBody = @{ sso_login = $false } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "https://api.netlify.com/api/v1/sites/$siteId" -Headers $h -Method Put -Body $ssoBody -ContentType 'application/json' -TimeoutSec 30 | Out-Null
Write-Host "SSO login protection disabled"

# 3. upload deploy (zip)
$bytes = [System.IO.File]::ReadAllBytes($zip)
$deploy = Invoke-RestMethod -Uri "https://api.netlify.com/api/v1/sites/$siteId/deploys" -Headers $h -Method Post -Body $bytes -ContentType 'application/zip' -TimeoutSec 120
$deployId = $deploy.id
Write-Host "Deploy submitted: $deployId"

# 4. wait for ready
$status = ''
for ($i = 0; $i -lt 30; $i++) {
  Start-Sleep -Seconds 3
  $d = Invoke-RestMethod -Uri "https://api.netlify.com/api/v1/deploys/$deployId" -Headers $h -Method Get -TimeoutSec 30
  $status = $d.state
  Write-Host "  deploy state: $status"
  if ($status -eq 'ready' -or $status -eq 'error') { break }
}

if ($status -eq 'ready') {
  Write-Host "`n=== DEPLOYED ==="
  Write-Host "Preview URL: $url"
} else {
  Write-Host "`nDeploy ended with state: $status - check Netlify dashboard"
}
