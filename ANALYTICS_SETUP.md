# Analytics Setup (Heatmap / Scroll / Rage / Session Replay)

## 1) Supabase 마이그레이션 적용

필수 값:
- `SUPABASE_ACCESS_TOKEN` (Supabase Personal Access Token)
- `SUPABASE_DB_PASSWORD` (프로젝트 DB 비밀번호)

PowerShell:

```powershell
$env:SUPABASE_ACCESS_TOKEN="YOUR_ACCESS_TOKEN"
$env:SUPABASE_DB_PASSWORD="YOUR_DB_PASSWORD"
.\apply_analytics_migration.ps1
```

또는 직접 파라미터 전달:

```powershell
.\apply_analytics_migration.ps1 -AccessToken "YOUR_ACCESS_TOKEN" -DbPassword "YOUR_DB_PASSWORD"
```

스크립트는 자동으로 아래를 순서대로 수행합니다.
- `supabase link`
- 기존 베이스라인 마이그레이션 정합화(`migration repair`)
- `db push` (비대화식)

## 2) 앱 실행

```powershell
flutter run -d chrome
```

## 3) 수집 확인 체크리스트

1. 일반 사용자 화면에서 페이지 클릭/스크롤/버튼 클릭 수행
2. 같은 위치를 짧게 연타해서 Rage Click 이벤트 생성
3. 관리자 로그인 후 `/admin/heatmap` 접속
4. 날짜 필터(`오늘/7일/30일`)와 페이지 필터를 바꿔 데이터 확인

CLI로 ingest 상태를 빠르게 검증하려면:

```powershell
.\verify_analytics_ingest.ps1 -AnonKey "YOUR_ANON_KEY"
```

## 4) 구현된 이벤트 타입

- `page_view`
- `click`
- `cta_click`
- `scroll_depth`
- `dead_click`
- `rage_click`
- `page_dwell`
