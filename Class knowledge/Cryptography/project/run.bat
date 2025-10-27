@echo off
chcp 65001 >nul
echo ========================================
echo Run DLP Attack Demo
echo ========================================
echo.

REM Check if compiled
if not exist "bin\Main.class" (
    echo Error: Program not compiled yet!
    echo Please run compile.bat first
    echo.
    pause
    exit /b 1
)

REM Run program
cd bin
java Main
cd ..

pause

