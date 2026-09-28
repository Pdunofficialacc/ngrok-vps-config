#!/bin/bash
set -e

service ssh start

echo "=========================================="
echo "LOCALHOST.RUN — FIXED TCP ADDRESS"
echo "=========================================="

# localhost.run — free SSH tunnel, fixed port, no time limit
# No domain needed — direct TCP access

# Start SSH tunnel with fixed port request
while true; do
    echo "[$(date)] Starting localhost.run tunnel..."

    # Request specific port (fixed) — or auto-assign if not available
    ssh -o StrictHostKeyChecking=no \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        -R 0:localhost:22 \
        localhost.run &

    TUNNEL_PID=$!

    # Wait and extract address
    sleep 10
    ADDRESS=$(grep -oP "tcp://[a-z0-9.-]+:\d+" /tmp/localhost.log 2>/dev/null | head -1 || echo "Starting...")

    echo "TCP ADDRESS: $ADDRESS"
    echo "SSH: ssh root@${ADDRESS#tcp://} -p ${ADDRESS##*:}"
    echo "=========================================="

    # Keep alive — restart if dies
    wait $TUNNEL_PID 2>/dev/null || true
    echo "[$(date)] Tunnel lost — restarting in 5s..."
    sleep 5
done &

# Also keep ngrok as backup (optional — comment out if not needed)
# ngrok start ssh --log=stdout > /tmp/ngrok.log 2>&1 &

# Web server
python3 -m http.server ${PORT:-8080} &

tail -f /dev/null
