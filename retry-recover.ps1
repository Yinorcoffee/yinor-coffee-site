# Retry sending recovery email until rate limit clears
$ErrorActionPreference = 'Continue'
for ($i = 1; $i -le 10; $i++) {
  Start-Sleep -Seconds 150
  try {
    $b = @{ email = 'yinor168@gmail.com' } | ConvertTo-Json -Compress
    $null = Invoke-RestMethod -Uri 'https://yinorcoffee.com/.netlify/identity/recover' -Headers @{ 'Content-Type' = 'application/json' } -Method Post -Body $b -TimeoutSec 30
    Write-Output "RECOVERY EMAIL SENT at $(Get-Date -Format 'HH:mm:ss')"
    break
  } catch {
    Write-Output ("attempt $i at $(Get-Date -Format 'HH:mm:ss'): still rate limited")
  }
}
