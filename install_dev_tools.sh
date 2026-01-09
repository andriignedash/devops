#!/usr/bin/env bash
set -euo pipefail

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }

# Make user-installed pip scripts (django-admin, pip, etc.) discoverable
export PATH="$HOME/.local/bin:$PATH"

log "Starting DevOps tools installation..."

# ---------------- System update ----------------
sudo apt update

# ---------------- Docker ----------------
if command -v docker >/dev/null 2>&1; then
  log "Docker already installed: $(docker --version || true)"
else
  log "Installing Docker..."
  sudo apt install -y ca-certificates curl gnupg lsb-release
  curl -fsSL https://get.docker.com | sudo bash
  sudo systemctl enable docker || true
  sudo systemctl start docker || true
  log "Docker installed: $(docker --version || true)"
fi

# ---------------- Docker Compose ----------------
if docker compose version >/dev/null 2>&1; then
  log "Docker Compose already installed: $(docker compose version || true)"
else
  log "Installing Docker Compose plugin..."
  sudo apt install -y docker-compose-plugin
  log "Docker Compose installed: $(docker compose version || true)"
fi

# ---------------- Python ----------------
if command -v python3 >/dev/null 2>&1; then
  log "Python already installed: $(python3 --version)"
else
  log "Installing Python..."
  sudo apt install -y python3
  log "Python installed: $(python3 --version)"
fi

# ---------------- pip + venv ----------------
if python3 -m pip --version >/dev/null 2>&1; then
  log "pip already installed: $(python3 -m pip --version)"
else
  log "Installing pip and venv..."
  sudo apt install -y python3-pip python3-venv
  log "pip installed: $(python3 -m pip --version)"
fi

# ---------------- Django ----------------
if python3 -m django --version >/dev/null 2>&1; then
  log "Django already installed: $(python3 -m django --version)"
else
  log "Installing Django via pip..."
  # Upgrade pip (may install into user site if system site-packages is not writable)
  python3 -m pip install --upgrade pip
  python3 -m pip install django
  log "Django installed: $(python3 -m django --version)"
fi

# ---------------- Optional post-checks ----------------
warn "If you were added to the docker group, log out and log back in to use docker without sudo."

log "All tools installed successfully."

