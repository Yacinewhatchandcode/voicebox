@echo off
REM Build CUDA server binary for Windows
REM This creates a ~3GB binary with CUDA support

echo ============================================================
echo Building CUDA server binary
echo ============================================================

echo.
echo Step 1: Ensuring CUDA PyTorch is installed...
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 --upgrade

echo.
echo Step 2: Building binary with PyInstaller...
python build_binary.py cuda

echo.
echo ============================================================
echo CUDA binary built successfully!
echo Location: dist\voicebox-server-cuda.exe
echo Size: ~3GB
echo ============================================================
