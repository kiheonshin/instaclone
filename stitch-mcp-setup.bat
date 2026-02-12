@echo off
chcp 65001 >nul
echo ========================================
echo   Stitch MCP - 프로젝트 설정 마무리
echo ========================================
echo.
echo 현재 상태: gcloud, 인증, ADC 완료
echo 남은 작업: GCP 프로젝트 선택
echo.
echo 프로젝트 선택 후 생성되는 JSON을 복사하여
echo C:\Users\%USERNAME%\.cursor\mcp.json 의 stitch 항목에 붙여넣으세요.
echo.
echo 시작하려면 아무 키나 누르세요...
pause >nul

npx -y @_davideast/stitch-mcp init -c cursor

echo.
echo ========================================
echo   설정 완료 후: Cursor를 재시작하세요.
echo ========================================
pause

