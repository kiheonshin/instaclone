@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ========================================
echo   Insta Clone - Vercel 배포
echo ========================================
echo.

echo [1/2] Flutter 웹 빌드 중...
call flutter build web
if errorlevel 1 (
    echo 빌드 실패.
    pause
    exit /b 1
)
echo 빌드 완료.
echo.

echo [2/2] Vercel 배포 중...
echo (처음 실행 시 Vercel 로그인 필요)
echo.
call vercel build\web --prod
if errorlevel 1 (
    echo.
    echo Vercel CLI가 설치되어 있지 않으면 다음 명령으로 설치하세요:
    echo   npm install -g vercel
    echo.
    pause
    exit /b 1
)

echo.
echo 배포 완료!
pause
