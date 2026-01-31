# Dual Server Binary System

## Overview

Voicebox now uses a dual-binary approach to manage the size difference between CPU-only and CUDA-enabled builds:

- **CPU Binary** (~500MB): Ships with the installer by default
- **CUDA Binary** (~3GB): Downloaded on-demand for GPU users

## Problem Solved

Previously, bundling PyTorch with CUDA support created a 3GB server binary, which:
- Made the installer too large (failed CI builds with WiX)
- Forced all users to download CUDA libraries even without NVIDIA GPUs
- Created poor user experience

## Solution

### Build Process

**Two separate binaries are built:**

1. **voicebox-server.exe** (CPU)
   - Built with: `pip install torch --index-url https://download.pytorch.org/whl/cpu`
   - Size: ~500MB
   - Works on all Windows machines
   - Included in the installer by default

2. **voicebox-server-cuda.exe** (CUDA)
   - Built with: `pip install torch --index-url https://download.pytorch.org/whl/cu121`
   - Size: ~3GB
   - Requires NVIDIA GPU + drivers
   - Uploaded as separate GitHub Release asset

### User Experience

**First Launch:**
1. User installs app (~500MB download)
2. App starts with CPU server
3. If NVIDIA GPU detected:
   - Show notification: "Download CUDA support for 4-5x faster inference?"
   - User clicks "Download"
   - Download voicebox-server-cuda.exe from GitHub (~3GB)
   - Save to `%APPDATA%/voicebox/binaries/`
   - Restart server with CUDA version

**Settings Panel:**
- Toggle between CPU/CUDA modes
- Download CUDA if not already installed
- Show current inference backend

### Build Scripts

**Windows:**
```bash
cd backend

# Build CPU only
build_cpu.bat

# Build CUDA only
build_cuda.bat

# Build both
build_both.bat
```

**Unix (macOS/Linux):**
```bash
cd backend

# Build CPU only
./build_cpu.sh
```

### CI/CD Workflow

**GitHub Actions (.github/workflows/release.yml):**

1. Install CPU PyTorch
2. Build CPU server → Copy to Tauri binaries
3. Install CUDA PyTorch
4. Build CUDA server → Save for upload
5. Build Tauri app (bundles CPU server)
6. Upload CUDA server as separate release asset

### File Structure

```
Release Assets:
├── Voicebox_0.1.12_x64_en-US.msi           (~500MB - includes CPU server)
├── voicebox-server-cuda-x86_64-pc-windows-msvc.exe   (~3GB - optional download)
└── latest.json                              (updater manifest)
```

## Implementation Details

### Modified Files

1. **backend/build_binary.py**
   - Added `variant` parameter ('cpu' or 'cuda')
   - Outputs different binary names based on variant

2. **backend/build_cpu.bat** (new)
   - Installs CPU PyTorch
   - Builds CPU binary
   - Restores CUDA PyTorch for dev

3. **backend/build_cuda.bat** (new)
   - Ensures CUDA PyTorch is installed
   - Builds CUDA binary

4. **.github/workflows/release.yml**
   - Build CPU binary first (for installer)
   - Build CUDA binary second (for upload)
   - Upload CUDA binary as additional release asset
   - Updated release notes to explain GPU acceleration

### Future Frontend Work

**TODO: Implement CUDA download in the app**

Location: `tauri/src/`

Features needed:
1. GPU detection on startup
2. Download manager for CUDA binary
3. Server binary path switcher
4. Settings UI for CPU/CUDA toggle
5. Progress indicator for 3GB download

API endpoints needed (already exist):
- `/health` - Shows GPU availability
- Server restart mechanism

## Benefits

✓ **Smaller installer**: ~500MB instead of 3GB
✓ **Faster CI builds**: WiX can handle 500MB easily
✓ **User choice**: CPU users don't download unnecessary files
✓ **Better UX**: Optional performance upgrade for GPU users
✓ **Cost savings**: Reduced bandwidth for users without GPUs

## Testing

**Test CPU build:**
```bash
cd backend
python build_binary.py cpu
./dist/voicebox-server.exe --version
```

**Test CUDA build:**
```bash
cd backend
python build_binary.py cuda
./dist/voicebox-server-cuda.exe --version
```

**Verify size:**
```bash
ls -lh backend/dist/
# Should see:
# voicebox-server.exe       ~500MB
# voicebox-server-cuda.exe  ~3GB
```

**Test server startup:**
```bash
# CPU version
./backend/dist/voicebox-server.exe
# Check logs: Should show CPU inference

# CUDA version (requires NVIDIA GPU)
./backend/dist/voicebox-server-cuda.exe
# Check logs: Should show CUDA inference
```
