param(
  [string]$SupabaseUrl = "https://iyvercsvligervllxnjb.supabase.co",
  [string]$AnonKey = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AnonKey)) {
  Write-Error "AnonKey 값을 전달해주세요. 예: .\verify_analytics_ingest.ps1 -AnonKey \"your_anon_key\""
}

$payload = @"
[
  {
    "event_type": "click",
    "page_url": "/healthcheck",
    "element_info": {"source": "ingest_check"},
    "x_pos": 1,
    "y_pos": 1,
    "session_id": "sess_ingest_check",
    "user_agent": "powershell",
    "referrer": ""
  }
]
"@

$tmpPath = Join-Path $PSScriptRoot "tmp_ingest_check.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tmpPath, $payload, $utf8NoBom)

$url = "$($SupabaseUrl.TrimEnd('/'))/rest/v1/analytics_events"
$dataArg = "@$tmpPath"
$status = & curl.exe -s -o NUL -w "%{http_code}" -X POST $url -H "apikey: $AnonKey" -H "Authorization: Bearer $AnonKey" -H "Content-Type: application/json" -H "Prefer: return=minimal" --data-binary $dataArg

Remove-Item -Force $tmpPath

if ($status -ne "201") {
  Write-Error "Analytics ingest check failed. HTTP status: $status"
}

Write-Host "Analytics ingest check succeeded. HTTP status: $status"
