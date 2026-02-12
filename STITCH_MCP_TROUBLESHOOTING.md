# Stitch MCP 연결 문제 해결 가이드

## 현재 상태 (최신)

| 항목 | 상태 |
|------|------|
| npm/npx 캐시 | ✅ 해결됨 |
| Google Cloud CLI | ✅ 설치됨 (bundled v556) |
| 사용자 인증 | ✅ heavenlydesigner@gmail.com |
| Application Credentials | ✅ 완료 |
| **GCP 프로젝트** | ❌ **미설정** ← 마지막 단계 |

### mcp.json 설정 불일치
- 현재 `STITCH_API_KEY` 사용 중 → 공식 문서와 **불일치**
- `init` 완료 후 `STITCH_PROJECT_ID`로 교체 필요

---

## 해결 단계

### Step 1: Stitch MCP 초기 설정 (처음 설정 또는 재설정)

터미널에서 다음 명령 실행:

```powershell
npx @_davideast/stitch-mcp init
```

이 명령이 자동으로:
1. Google Cloud CLI 설치 (필요시 ~/.stitch-mcp 에)
2. gcloud 로그인 안내
3. Application Default Credentials 설정
4. GCP 프로젝트 선택
5. Stitch API 활성화
6. **올바른 mcp.json 설정** 생성

### Step 2: 생성된 설정을 mcp.json에 적용

`init` 완료 후 출력되는 JSON을 복사해서 `C:\Users\신기헌\.cursor\mcp.json`의 stitch 항목에 붙여넣기.

예시 (init 출력):
```json
{
  "mcpServers": {
    "stitch": {
      "command": "npx",
      "args": ["@_davideast/stitch-mcp", "proxy"],
      "env": {
        "STITCH_PROJECT_ID": "your-project-id"
      }
    }
  }
}
```

### Step 3: Cursor 재시작

mcp.json 변경 후 **Cursor를 완전히 종료 후 재실행**해야 MCP 서버가 새 설정으로 연결됩니다.

### Step 4: 연결 확인

재시작 후:
- Cursor 설정 > MCP 탭에서 stitch 서버 상태 확인
- 또는 채팅에서 Stitch 관련 도구 호출 테스트

---

## 이미 gcloud가 있다면 (빠른 설정)

gcloud가 이미 설치·인증되어 있다면:

```powershell
# 1. 인증 확인
gcloud auth application-default login

# 2. 프로젝트 설정
gcloud config set project YOUR_PROJECT_ID

# 3. Stitch API 활성화 (beta 필요)
gcloud components install beta
gcloud beta services mcp enable stitch.googleapis.com --project=YOUR_PROJECT_ID
```

그 후 `mcp.json`에 다음 사용:
```json
"stitch": {
  "command": "npx",
  "args": ["-y", "@_davideast/stitch-mcp", "proxy"],
  "env": {
    "STITCH_USE_SYSTEM_GCLOUD": "1"
  }
}
```

---

## 문제 지속 시

1. **doctor로 진단**:
   ```powershell
   npx @_davideast/stitch-mcp doctor --verbose
   ```

2. **로그아웃 후 재설정**:
   ```powershell
   npx @_davideast/stitch-mcp logout --force --clear-config
   npx @_davideast/stitch-mcp init
   ```

3. **노드 버전**: Node.js v24 사용 중. 호환 문제 시 v20 LTS 권장.
