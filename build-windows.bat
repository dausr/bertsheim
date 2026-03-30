@echo off
REM Bertsheim Windows Build Script
echo ===================================
echo Bertsheim DJ Software - Windows Build
echo ===================================

set BUILD_TYPE=Release
set BUILD_DIR=build_windows
set INSTALL_PREFIX=%cd%\install

where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake not found
    pause
    exit /b 1
)

if not exist %BUILD_DIR% mkdir %BUILD_DIR%
cd %BUILD_DIR%

cmake -G "Visual Studio 17 2022" ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -DCMAKE_INSTALL_PREFIX=%INSTALL_PREFIX% ^
    -DENABLE_CUDA=ON ^
    ..

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake failed
    cd ..
    pause
    exit /b 1
)

cmake --build . --config %BUILD_TYPE% --parallel %NUMBER_OF_PROCESSORS%

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    cd ..
    pause
    exit /b 1
)

cmake --install . --config %BUILD_TYPE%

cd ..
echo ===================================
echo Build completed successfully!
echo Output: %INSTALL_PREFIX%\bin
echo ===================================
pause
