@echo off
cd /d "%~dp0"
echo Insta Clone - Flutter Web 실행
echo.
echo 접속 URL:
echo   메인: http://localhost:8080
echo   관리자: http://localhost:8080/admin
echo.
flutter run -d chrome --web-port=8080
pause
