@echo off
echo ===================================
echo Bertsheim Windows Development Setup
echo ===================================

echo Checking for required software...

where devenv >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] Visual Studio not installed
    echo    Download from: https://visualstudio.microsoft.com/download/
) else (
    echo [OK] Visual Studio found
)

where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] CMake not installed
    echo    Download from: https://cmake.org/download/
) else (
    echo [OK] CMake found
)

where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] Git not installed
    echo    Download from: https://git-scm.com/download/win
) else (
    echo [OK] Git found
)

if exist "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.0" (
    echo [OK] CUDA Toolkit found
) else (
    echo [!] CUDA Toolkit not installed (optional)
    echo    Download from: https://developer.nvidia.com/cuda-downloads
)

echo.
echo ===================================
echo Setup check complete!
echo Run: build-windows.bat
echo ===================================
pause
