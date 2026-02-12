# Stitch MCP 연결 테스트 결과 및 상세 설정 가이드

## 📋 테스트 결과 요약 (최신)

| 검사 항목 | 결과 | 설명 |
|-----------|------|------|
| GCP 프로젝트 | ✅ 완료 | `news-1b612` 설정됨 |
| mcp.json | ✅ 수정됨 | `STITCH_PROJECT_ID` 사용 중 |
| **Stitch API** | ❌ **403 에러** | API 활성화 필요 |

---

## 🔍 현재 상태 상세

### ✅ 완료된 항목
- **Google Cloud CLI**: 설치됨 (v556)
- **사용자 인증**: heavenlydesigner@gmail.com
- **Application Credentials**: 설정 완료
- **GCP 프로젝트**: `news-1b612` 설정됨
- **mcp.json**: `STITCH_PROJECT_ID` 적용됨

### ❌ 마지막 단계: Stitch API 활성화
- **에러**: `API request failed with status 403`
- **원인**: 프로젝트에서 Stitch API가 활성화되지 않음

---

## 📝 마지막으로 할 작업: Stitch API 활성화

프로젝트 `news-1b612`에서 Stitch API를 활성화해야 합니다.

### 방법 A: Google Cloud Console에서 활성화 (권장)

1. 다음 링크로 이동:  
   https://console.cloud.google.com/apis/library/stitch.googleapis.com?project=news-1b612

2. **"사용"** 또는 **"Enable"** 버튼 클릭

3. 활성화가 완료될 때까지 1~2분 대기

4. **결제 계정**이 없다면 먼저 연결 필요  
   - [결제 페이지](https://console.cloud.google.com/billing?project=news-1b612)에서 결제 프로필 연결

---

### 방법 B: gcloud 명령어로 활성화

```powershell
# 1. stitch-mcp의 gcloud 사용 (환경변수 설정)
$env:CLOUDSDK_CONFIG="$env:USERPROFILE\.stitch-mcp\config"

# 2. beta 컴포넌트 설치 (처음 한 번만)
& "$env:USERPROFILE\.stitch-mcp\google-cloud-sdk\bin\gcloud.cmd" components install beta -q

# 3. Stitch API 활성화
& "$env:USERPROFILE\.stitch-mcp\google-cloud-sdk\bin\gcloud.cmd" beta services mcp enable stitch.googleapis.com --project=news-1b612
```

---

### 활성화 후

1. **Cursor 재시작** (완전 종료 후 다시 실행)

2. **연결 확인:**
   ```powershell
   npx @_davideast/stitch-mcp doctor
   ```
   Stitch API 항목이 ✔ 이면 성공

---

## 🔧 문제 발생 시

### "Permission Denied" / "403" 에러
- GCP 프로젝트에 **결제 계정** 연결 확인
- 프로젝트에 **Owner** 또는 **Editor** 역할 있는지 확인

### init 실행 시 프로젝트 목록이 비어 있음
- Google Cloud Console에서 새 프로젝트 생성
- 생성 후 몇 분 기다린 뒤 init 다시 실행

### mcp.json 수정 후에도 연결 안 됨
- Cursor를 **완전히 종료** 후 재시작했는지 확인
- `npx @_davideast/stitch-mcp doctor`로 설정 재확인

### 그래도 안 될 때
```powershell
# 전체 초기화 후 재설정
npx @_davideast/stitch-mcp logout --force --clear-config
npx @_davideast/stitch-mcp init -c cursor
```

---

## 📌 요약 체크리스트

- [ ] Google Cloud Console에서 프로젝트 확인/생성
- [ ] 결제 계정 연결
- [ ] `npx @_davideast/stitch-mcp init -c cursor` 실행
- [ ] 프로젝트 선택
- [ ] 출력된 JSON으로 mcp.json의 stitch 부분 교체
- [ ] Cursor 완전 종료 후 재시작
- [ ] Doctor로 최종 확인
