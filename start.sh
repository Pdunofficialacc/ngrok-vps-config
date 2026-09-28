#!/bin/bash
set -e

service ssh start

echo "=========================================="
echo "NGROK PERSISTENT SESSION — 30 DAYS SAME ADDRESS"
echo "=========================================="

# Ngrok config with your token
cat > /root/.config/ngrok/ngrok.yml << EOF
version: "2"
authtoken: 3Jrwa91Fa0w4BpqnWdIAr2TNfFB_4G4vnYDy2oFkdoRMBtQUb
region: ap
tunnels:
  ssh:
    proto: tcp
    addr: 22
  web:
    proto: http
    addr: 8080
EOF

# Start ngrok — keep alive with heartbeat
start_ngrok() {
    echo "[$(date)] Starting ngrok persistent session..."

    # Kill any existing
    pkill -f "ngrok start" 2>/dev/null || true
    sleep 2

    # Start with keep-alive settings
    ngrok start ssh web \
        --log=stdout \
        --log-level=info \
        > /tmp/ngrok.log 2>&1 &

    NGROK_PID=$!
    echo $NGROK_PID > /tmp/ngrok.pid

    sleep 8

    # Extract and display address
    echo "=========================================="
    echo "NGROK TCP ADDRESS (Save this — same for 30 days):"
    echo "=========================================="
    curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        proto = tunnel.get('proto', 'unknown')
        url = tunnel.get('public_url', 'N/A')
        print(f'{proto.upper()}: {url}')
        if proto == 'tcp':
            print(f'\nSSH COMMAND:')
            print(f'ssh root@{url.replace("tcp://", "").split(":")[0]} -p {url.split(":")[-1]}')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null
    echo "=========================================="

    # Keep-alive loop — prevent 2-hour timeout
    # Send keep-alive every 30 minutes
    while kill -0 $NGROK_PID 2>/dev/null; do
        # Check if tunnel still active
        if ! curl -s http://localhost:4040/api/tunnels | grep -q "tcp.ap.ngrok.io"; then
            echo "[$(date)] Tunnel lost — restarting..."
            break
        fi

        # Keep-alive ping (prevents idle timeout)
        curl -s http://localhost:4040/api/tunnels > /dev/null

        echo "[$(date)] Session alive — $(curl -s http://localhost:4040/api/tunnels | grep -oP 'tcp://[a-z0-9.-]+:\d+' | head -1)"
        sleep 1800  # 30 minutes
    done

    # If we get here, restart ngrok
    echo "[$(date)] Restarting ngrok..."
    start_ngrok
}

# Start persistent session
start_ngrok &

# Web server
python3 -m http.server ${PORT:-8080} &

tail -f /dev/null
