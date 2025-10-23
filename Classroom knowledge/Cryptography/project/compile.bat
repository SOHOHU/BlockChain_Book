@echo off
chcp 65001 >nul
echo ========================================
echo Compile DLP Attack Project
echo ========================================
echo.

REM Create output directory
if not exist "bin" mkdir bin

echo Compiling...
echo.

REM Compile utilities
javac -encoding UTF-8 -d bin src\utils\MathUtils.java
if %errorlevel% neq 0 (
    echo Failed to compile MathUtils!
    pause
    exit /b %errorlevel%
)
echo [OK] Utils compiled

REM Compile attack algorithms
javac -encoding UTF-8 -d bin -cp bin src\attacks\BabyStepGiantStep.java
javac -encoding UTF-8 -d bin -cp bin src\attacks\PollardRho.java
javac -encoding UTF-8 -d bin -cp bin src\attacks\PohligHellman.java
if %errorlevel% neq 0 (
    echo Failed to compile attack algorithms!
    pause
    exit /b %errorlevel%
)
echo [OK] Attacks compiled

REM Compile main program
javac -encoding UTF-8 -d bin -cp bin src\Main.java
if %errorlevel% neq 0 (
    echo Failed to compile Main!
    pause
    exit /b %errorlevel%
)
echo [OK] Main compiled

echo.
echo ========================================
echo Compilation Successful!
echo ========================================
echo.
echo To run:
echo   cd bin
echo   java Main
echo.
pause

