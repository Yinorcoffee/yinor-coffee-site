# Wait for GitHub Pages SSL certificate for yinorcoffee.com
# Checks every 3 minutes, up to ~70 minutes
$started = Get-Date
$ok = $false
for ($i = 1; $i -le 24; $i++) {
  Start-Sleep -Seconds 180
  $code = curl.exe -s -o NUL -w "%{http_code}" --max-time 25 'https://yinorcoffee.com/'
  $elapsed = [math]::Round(((Get-Date) - $started).TotalMinutes)
  if ($code -eq '200') {
    Write-Output "HTTPS READY after ${elapsed} minutes - https://yinorcoffee.com works (HTTP $code)"
    $ok = $true
    break
  } else {
    Write-Output "check $i (${elapsed} min): https = $code"
  }
}
if (-not $ok) {
  Write-Output "NOT READY after ~70 minutes - last check: $code"
}
