$token = $env:NETLIFY_TOKEN
$h = @{ Authorization = "Bearer $token"; 'User-Agent' = 'yinor-deploy' }
$siteId = '474fa885-9d93-46d1-b2ae-5132c0c51be8'
$challenge = 'netlify-verify-98p365dgtjivfrhy'
$ready = $false
for ($i = 1; $i -le 40; $i++) {
  Start-Sleep -Seconds 60
  try {
    $s = Invoke-RestMethod -Uri "https://api.netlify.com/api/v1/sites/$siteId" -Headers $h -TimeoutSec 30
    Write-Output ("[{0}] poll #{1}: ssl={2} ssl_status='{3}'" -f (Get-Date -Format 'HH:mm:ss'), $i, $s.ssl, $s.ssl_status)
    if ($s.ssl -eq $true) {
      try {
        $body = @{ custom_domain = 'www.yinorcoffee.com'; txt_record_value = $challenge } | ConvertTo-Json -Compress
        $r = Invoke-RestMethod -Uri "https://api.netlify.com/api/v1/sites/$siteId" -Headers $h -Method Patch -Body $body -ContentType 'application/json' -TimeoutSec 30
        Write-Output ("www added. aliases: " + ($r.domain_aliases -join ', '))
      } catch {
        Write-Output ("www PATCH failed: " + $_.ErrorDetails.Message)
      }
      Start-Sleep -Seconds 10
      $code = curl.exe -s -o NUL -w '%{http_code}' --resolve yinorcoffee.com:443:75.2.60.5 --max-time 25 'https://yinorcoffee.com/'
      Write-Output ("Production https check: HTTP " + $code)
      $ready = $true
      break
    }
  } catch {
    Write-Output ("poll error: " + $_.Exception.Message)
  }
}
if (-not $ready) { Write-Output 'TIMEOUT: SSL not ready after 40 minutes' }
