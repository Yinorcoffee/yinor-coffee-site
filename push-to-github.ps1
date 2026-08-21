# Push yinor-site contents to GitHub via API (no local git required)
# Token passed via env GITHUB_TOKEN (never stored on disk)
$ErrorActionPreference = 'Stop'
$root = 'E:\deepseekharenss\yinor-site'
$owner = 'Yinorcoffee'
$repo = 'yinor-coffee-site'
$token = $env:GITHUB_TOKEN
if (-not $token) { throw 'GITHUB_TOKEN env var not set' }

$h = @{ Authorization = "Bearer $token"; 'User-Agent' = 'yinor-deploy'; 'X-GitHub-Api-Version' = '2022-11-28' }
$base = "https://api.github.com/repos/$owner/$repo"

# 0. bootstrap: empty repo needs an initial commit before blobs can be created
$hasCommit = $false
try {
  $null = Invoke-RestMethod -Uri "$base/commits?per_page=1" -Headers $h -Method Get -TimeoutSec 30
  $hasCommit = $true
} catch { $hasCommit = $false }
if (-not $hasCommit) {
  Write-Host 'Empty repo detected - bootstrapping initial commit'
  $emptyTree = Invoke-RestMethod -Uri "$base/git/trees" -Headers $h -Method Post -Body '{"tree":[]}' -ContentType 'application/json' -TimeoutSec 60
  $initCommit = Invoke-RestMethod -Uri "$base/git/commits" -Headers $h -Method Post -Body (@{ message = 'bootstrap'; tree = $emptyTree.sha } | ConvertTo-Json -Compress) -ContentType 'application/json' -TimeoutSec 60
  $refBody = @{ ref = 'refs/heads/main'; sha = $initCommit.sha } | ConvertTo-Json -Compress
  Invoke-RestMethod -Uri "$base/git/refs" -Headers $h -Method Post -Body $refBody -ContentType 'application/json' -TimeoutSec 60 | Out-Null
  Write-Host "Bootstrap commit: $($initCommit.sha)"
}

# 1. enumerate files (exclude .git)
$files = Get-ChildItem $root -Recurse -File | Where-Object { $_.FullName -notmatch '\\.git\\' }
Write-Host "Files to push: $($files.Count)"

# 2. create blobs
$tree = @()
$i = 0
foreach ($f in $files) {
  $i++
  $rel = $f.FullName.Substring($root.Length).TrimStart('\') -replace '\\','/'
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $b64 = [Convert]::ToBase64String($bytes)
  $body = @{ content = $b64; encoding = 'base64' } | ConvertTo-Json -Compress
  $resp = Invoke-RestMethod -Uri "$base/git/blobs" -Headers $h -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 60
  $tree += @{ path = $rel; mode = '100644'; type = 'blob'; sha = $resp.sha }
  if ($i % 25 -eq 0) { Write-Host "  blobs: $i/$($files.Count)" }
}
Write-Host "Blobs created: $($tree.Count)"

# 3. create tree
$treeBody = @{ tree = $tree } | ConvertTo-Json -Depth 10 -Compress
$treeResp = Invoke-RestMethod -Uri "$base/git/trees" -Headers $h -Method Post -Body $treeBody -ContentType 'application/json' -TimeoutSec 120
Write-Host "Tree: $($treeResp.sha)"

# 4. create commit (parent = current main HEAD)
$head = Invoke-RestMethod -Uri "$base/git/ref/heads/main" -Headers $h -Method Get -TimeoutSec 30
$commitBody = @{
  message = "Yinor Coffee site v1: 29 pages, clean SEO meta, JSON-LD, optimized assets, GH Actions deploy"
  tree = $treeResp.sha
  parents = @($head.object.sha)
} | ConvertTo-Json -Depth 5 -Compress
$commitResp = Invoke-RestMethod -Uri "$base/git/commits" -Headers $h -Method Post -Body $commitBody -ContentType 'application/json' -TimeoutSec 60
Write-Host "Commit: $($commitResp.sha)"

# 5. fast-forward update of main
$updBody = @{ sha = $commitResp.sha; force = $false } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "$base/git/refs/heads/main" -Headers $h -Method Patch -Body $updBody -ContentType 'application/json' -TimeoutSec 60 | Out-Null
Write-Host "Branch main updated"

Write-Host "`n=== PUSH COMPLETE ==="
$verify = Invoke-RestMethod -Uri "$base/contents" -Headers $h -Method Get -TimeoutSec 30
Write-Host "Repo root entries: $($verify.Count)"
$verify | ForEach-Object { "  $($_.type): $($_.path)" }
