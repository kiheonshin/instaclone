# GitHub + Vercel 연동 가이드

이 가이드를 따라하면 `main` 또는 `master` 브랜치에 푸시할 때마다 자동으로 Vercel에 배포됩니다.

---

## 1단계: GitHub 저장소 생성

1. [GitHub](https://github.com)에서 새 저장소 생성 (예: `insta-clone`)
2. **"Add a README file"** 체크 해제 (로컬 프로젝트가 이미 있음)
3. 생성 완료 후 저장소 URL 확인 (예: `https://github.com/사용자명/insta-clone`)

---

## 2단계: 프로젝트를 GitHub에 푸시

프로젝트 루트에서 실행:

```powershell
cd "e:\Cursor\Insta Clone"

# Git 초기화 (이미 되어 있으면 생략)
git init

# 원격 저장소 연결
git remote add origin https://github.com/사용자명/insta-clone.git

# 커밋 및 푸시
git add .
git commit -m "Initial commit: Insta Clone with GitHub + Vercel"
git branch -M main
git push -u origin main
```

> `insta-clone`과 `사용자명`을 본인 저장소 정보로 바꾸세요.

---

## 3단계: Vercel 프로젝트 생성

1. [Vercel](https://vercel.com) 로그인 (GitHub 계정 권장)
2. **Add New** → **Project** 클릭
3. **Import Git Repository**에서 방금 만든 저장소 선택
4. **Import** 클릭
5. **프로젝트 설정 화면**에서:
   - **Framework Preset**: `Other`
   - **Root Directory**: `./` (그대로)
   - **Build / Output 설정**: `vercel.json`에 이미 정의되어 있으므로 **Override** 체크 해제 후 기본값 사용
6. **Deploy** 클릭 → Flutter 빌드에 5~10분 정도 소요될 수 있습니다.

---

## 4단계: Vercel 시크릿 값 확인

1. [Vercel Dashboard](https://vercel.com/dashboard) → 프로젝트 선택
2. **Settings** → **General** 이동
3. 아래 값 확인:
   - **Project ID** (prj_로 시작)
   - **Vercel Team/Org ID** (team_ 또는 org_로 시작)

4. [Vercel Account Tokens](https://vercel.com/account/tokens)에서:
   - **Create Token** 클릭
   - 이름 입력 (예: `github-actions`) 후 생성
   - **토큰 값** 복사 (다시 볼 수 없으니 안전한 곳에 보관)

---

## 5단계: GitHub Secrets 등록

1. GitHub 저장소 → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭 후 아래 3개 추가:

| Name | Value |
|------|-------|
| `VERCEL_TOKEN` | 4단계에서 생성한 토큰 |
| `VERCEL_ORG_ID` | team_ 또는 org_로 시작하는 ID |
| `VERCEL_PROJECT_ID` | prj_로 시작하는 ID |

---

## 6단계: 배포 확인

1. 코드를 수정한 뒤 푸시:
   ```powershell
   git add .
   git commit -m "Update"
   git push origin main
   ```

2. GitHub 저장소 → **Actions** 탭에서 워크플로우 실행 확인
3. 성공 시 Vercel 대시보드에서 **배포 URL** 확인 (예: `https://insta-clone-xxx.vercel.app`)

---

## 참고

- **Supabase**: `lib/config/supabase_config.dart`에 URL과 anon key가 설정되어 있어야 합니다.
- **트리거**: `main` 또는 `master` 브랜치에 푸시할 때마다 자동 배포됩니다.
- **수동 배포**: GitHub → Actions → **Deploy to Vercel** → **Run workflow**로 수동 실행 가능합니다.
