#!/bin/bash
# Build CPU-only server binary
# This creates a ~500MB binary without CUDA support

set -e

echo "============================================================"
echo "Building CPU-only server binary"
echo "============================================================"

echo ""
echo "Step 1: Installing CPU-only PyTorch..."
pip uninstall -y torch torchvision torchaudio || true
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

echo ""
echo "Step 2: Building binary with PyInstaller..."
python build_binary.py cpu

echo ""
echo "Step 3: Restoring CUDA PyTorch for development..."
pip uninstall -y torch torchvision torchaudio || true
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo ""
echo "============================================================"
echo "CPU binary built successfully!"
echo "Location: dist/voicebox-server"
echo "Size: ~500MB"
echo "============================================================"
