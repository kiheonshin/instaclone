# Insta Clone

Flutter Web + Supabase 기반 Instagram 클론 프로젝트 (MVP)

## 기술 스택

- **Frontend**: Flutter Web
- **Backend**: Supabase (Auth, Database, Storage)
- **상태관리**: Riverpod
- **라우팅**: go_router

## 기능

- ✅ 회원가입 / 로그인
- ✅ 홈 피드 (게시물 목록)
- ✅ 게시물 작성 (이미지 + 캡션)
- ✅ 좋아요 / 댓글
- ✅ 프로필 조회 / 편집
- ✅ 팔로우 / 언팔로우
- ✅ 유저 검색
- ✅ **관리자 도구** (서브도메인)

## 관리자 도구

관리자 기능은 **/admin** 경로에서 사용합니다.

- **접속**: `http://localhost:포트/admin` 또는 `https://yourdomain.com/admin`
- **로그인 화면** 하단의 "관리자 로그인" 링크 클릭
- **관리자 계정**으로 로그인 시 좌측 사이드바에 "관리자" 메뉴 표시

### 관리자 설정

1. Supabase **SQL Editor**에서 아래 마이그레이션 실행:
   - `supabase/migrations/20240211000002_admin_support.sql`
   - `supabase/migrations/20240211000003_admin_rls.sql`

2. 관리자 계정 지정 (Supabase SQL Editor):
   ```sql
   update public.profiles set is_admin = true where username = '관리자사용자명';
   ```

3. admin 서브도메인으로 접속 후 관리자 계정으로 로그인

### 관리자 기능

- 사용자 목록 조회
- 게시물 목록 조회 및 삭제

## 시작하기

### 1. Supabase 프로젝트 생성

1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. **SQL Editor**에서 `supabase/migrations/20240211000000_initial_schema.sql` 실행
3. **Storage**에서 버킷 생성:
   - `avatars` (public)
   - `posts` (public)

### 2. 환경 설정

`lib/config/supabase_config.dart` 수정 또는 실행 시 설정:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### 3. 실행

```bash
flutter pub get
flutter run -d chrome --web-port=8080
```

또는 `run_web.bat` 더블클릭 (Windows)

### 4. Vercel 배포 (선택)

**방법 A: GitHub + Vercel 자동 배포 (권장)**

푸시할 때마다 자동으로 배포됩니다. 자세한 설정은 **[GITHUB_VERCEL_연동_가이드.md](GITHUB_VERCEL_연동_가이드.md)**를 참고하세요.

**방법 B: 로컬 수동 배포**

1. **Vercel CLI 설치** (최초 1회): `npm install -g vercel`
2. **배포 실행**: `flutter build web` 후 `vercel build/web --prod`
   - 또는 `deploy_vercel.bat` 더블클릭 (Windows)

> **참고**: Supabase 연결을 위해 `lib/config/supabase_config.dart`에 URL과 anon key가 설정되어 있어야 합니다.

### 5. 접속 URL

| 용도 | URL |
|------|-----|
| 메인 앱 | http://localhost:8080 |
| 관리자 | http://localhost:8080/admin |

**웹페이지가 실행되지 않는 경우:**
- Flutter가 PATH에 등록되어 있는지 확인: `flutter doctor`
- `flutter pub get` 실행 후 다시 시도
- `web/index.html`에 `flutter_bootstrap.js` 참조가 있는지 확인 (빌드 시 자동 생성됨)

## 프로젝트 구조

```
lib/
├── main.dart
├── app.dart
├── router.dart
├── config/
├── features/
│   ├── auth/      # 인증
│   ├── feed/      # 피드
│   ├── post/      # 게시물
│   ├── profile/   # 프로필
│   └── search/    # 검색
└── shared/        # 레이아웃 등
```

## 라이선스

MIT

## Analytics (Heatmap / Scroll / Replay)

This project now includes web behavior analytics.

- Automatic event tracking on all pages
  - click coordinates + element metadata
  - scroll depth milestones (25/50/75/100)
  - CTA tracking
  - rage click / dead click detection
  - page dwell time
- Admin analytics page: `/admin/heatmap`

### Setup

Apply Supabase migration:

```powershell
$env:SUPABASE_ACCESS_TOKEN="YOUR_ACCESS_TOKEN"
$env:SUPABASE_DB_PASSWORD="YOUR_DB_PASSWORD"
.\apply_analytics_migration.ps1
```

Run app:

```powershell
flutter run -d chrome
```
