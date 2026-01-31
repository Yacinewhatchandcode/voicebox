@echo off
REM Build both CPU and CUDA server binaries for Windows

echo ============================================================
echo Building BOTH server binaries (CPU + CUDA)
echo This will take a while...
echo ============================================================

call build_cpu.bat
if errorlevel 1 (
    echo CPU build failed!
    exit /b 1
)

echo.
echo.

call build_cuda.bat
if errorlevel 1 (
    echo CUDA build failed!
    exit /b 1
)

echo.
echo ============================================================
echo Both binaries built successfully!
echo ============================================================
echo CPU binary:  dist\voicebox-server.exe (~500MB)
echo CUDA binary: dist\voicebox-server-cuda.exe (~3GB)
echo ============================================================
