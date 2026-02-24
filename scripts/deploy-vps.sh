#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# VOICEBOX → VPS Deployment Script
# Deploys to Sovereign VPS (31.97.52.22) for remote voice API
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

VPS_HOST="31.97.52.22"
VPS_USER="root"
REMOTE_DIR="/opt/voicebox"
PORT="17493"
DOMAIN="voicebox.prime-ai.fr"  # optional — configure nginx later

echo "═══════════════════════════════════════════════"
echo "  VOICEBOX → VPS DEPLOYMENT"
echo "  Target: ${VPS_USER}@${VPS_HOST}:${REMOTE_DIR}"
echo "═══════════════════════════════════════════════"

# 1. Sync backend to VPS
echo ""
echo "📦 Syncing backend to VPS..."
rsync -avz --progress \
    --exclude '.venv' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'data/' \
    --exclude '.git' \
    --exclude 'app/' \
    --exclude 'tauri/' \
    --exclude 'landing/' \
    --exclude 'web/' \
    --exclude 'node_modules/' \
    --exclude 'bun.lock' \
    ./ ${VPS_USER}@${VPS_HOST}:${REMOTE_DIR}/

# 2. Remote setup
echo ""
echo "🔧 Setting up Python environment on VPS..."
ssh ${VPS_USER}@${VPS_HOST} << 'REMOTE_SCRIPT'
set -euo pipefail

cd /opt/voicebox

# Install Python 3.12 if not present
if ! command -v python3.12 &> /dev/null; then
    apt-get update && apt-get install -y python3.12 python3.12-venv python3.12-dev
fi

# Create venv
if [ ! -d ".venv" ]; then
    python3.12 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip

# Install PyTorch (CPU for VPS — no Apple Silicon)
pip install -r backend/requirements.txt

# Create systemd service
cat > /etc/systemd/system/voicebox.service << EOF
[Unit]
Description=Voicebox TTS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/voicebox
ExecStart=/opt/voicebox/.venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 17493
Restart=always
RestartSec=5
Environment=PYTHONPATH=/opt/voicebox

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl daemon-reload
systemctl enable voicebox
systemctl restart voicebox

echo ""
echo "✅ Voicebox service deployed!"
systemctl status voicebox --no-pager -l | head -15
REMOTE_SCRIPT

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ DEPLOYMENT COMPLETE"
echo ""
echo "  Local:  http://127.0.0.1:${PORT}"
echo "  VPS:    http://${VPS_HOST}:${PORT}"
echo "  Health: curl http://${VPS_HOST}:${PORT}/health"
echo "═══════════════════════════════════════════════"
