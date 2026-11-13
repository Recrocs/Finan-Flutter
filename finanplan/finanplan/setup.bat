@echo off
setlocal
cd /d "%~dp0"

echo ========================================
echo              FinanPlan
echo ========================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
    echo ERRO: Flutter nao foi encontrado no PATH.
    echo Instale/configure o Flutter antes de continuar.
    pause
    exit /b 1
)

echo [1/2] Criando plataformas do Flutter, se necessario...
if not exist android (
    flutter create --platforms=android,web,windows .
    if errorlevel 1 goto erro
) else (
    echo Pasta android ja existe. Pulando flutter create.
)

echo.
echo [2/2] Instalando dependencias...
flutter pub get
if errorlevel 1 goto erro

echo.
echo ========================================
echo       PROJETO PRONTO!
echo ========================================
echo.
echo Para executar:
echo   flutter run
echo.
echo Para ver os dispositivos:
echo   flutter devices
pause
exit /b 0

:erro
echo.
echo Ocorreu um erro durante a configuracao.
pause
exit /b 1
