#!/bin/bash
set -e

service ssh start

# Cloudflare Tunnel — fixed TCP, 30+ days continuous, no restart needed
# Setup: cloudflared tunnel login (one time) — then fixed address milta hai

echo "=========================================="
echo "CLOUDFLARE TUNNEL — FIXED TCP ADDRESS"
echo "=========================================="

# Check if tunnel config exists
if [ -f /root/.cloudflared/config.yml ]; then
    echo "Starting Cloudflare Tunnel..."
    cloudflared tunnel run vps-ssh &
    sleep 5
    echo "Tunnel active — TCP address fixed, no time limit"
else
    echo "ERROR: Cloudflare Tunnel not configured!"
    echo "Run: cloudflared tunnel login"
    echo "Then: cloudflared tunnel create vps-ssh"
    echo "Then: cloudflared tunnel route dns vps-ssh <subdomain>.cfargotunnel.com"
fi

echo "=========================================="

# Web server
python3 -m http.server ${PORT:-8080} &

tail -f /dev/null
