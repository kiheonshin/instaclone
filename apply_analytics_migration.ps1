param(
  [string]$ProjectRef = "iyvercsvligervllxnjb",
  [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN,
  [string]$DbPassword = $env:SUPABASE_DB_PASSWORD
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  Write-Error "SUPABASE_ACCESS_TOKEN 값이 필요합니다. 환경변수 또는 -AccessToken 파라미터로 전달해주세요."
}

if ([string]::IsNullOrWhiteSpace($DbPassword)) {
  Write-Error "SUPABASE_DB_PASSWORD 값이 필요합니다. 환경변수 또는 -DbPassword 파라미터로 전달해주세요."
}

$env:SUPABASE_ACCESS_TOKEN = $AccessToken

Write-Host "[1/3] Supabase 프로젝트 링크: $ProjectRef"
npx supabase link --project-ref $ProjectRef --password $DbPassword

Write-Host "[2/3] 기존 마이그레이션 정합화(이미 적용된 베이스라인)"
npx supabase migration repair --status applied `
  20240211000000 20240211000001 20240211000002 20240211000003 `
  --password $DbPassword --yes

Write-Host "[3/3] 마이그레이션 적용: db push"
npx supabase db push --password $DbPassword --yes

Write-Host "완료: analytics_events 마이그레이션이 적용되었습니다."
