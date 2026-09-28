#!/bin/bash
set -e

service ssh start

# Multiple ngrok tokens — rotate every 100 minutes to bypass 2-hour limit
TOKENS=(
    "3Jrwa91Fa0w4BpqnWdIAr2TNfFB_4G4vnYDy2oFkdoRMBtQUb"
    # Add more tokens here — one per line
    # "TOKEN_2_HERE"
    # "TOKEN_3_HERE"
)

CURRENT_TOKEN_INDEX=0

rotate_ngrok() {
    while true; do
        TOKEN="${TOKENS[$CURRENT_TOKEN_INDEX]}"
        echo "[$(date)] Starting ngrok with token #$((CURRENT_TOKEN_INDEX+1))..."

        # Kill existing ngrok
        pkill -f "ngrok start" 2>/dev/null || true
        sleep 3

        # Update config with current token
        cat > /root/.config/ngrok/ngrok.yml << EOF
version: "2"
authtoken: ${TOKEN}
region: ap
tunnels:
  ssh:
    proto: tcp
    addr: 22
  web:
    proto: http
    addr: 8080
EOF

        # Start ngrok
        ngrok start ssh web --log=stdout > /tmp/ngrok.log 2>&1 &
        NGROK_PID=$!

        sleep 8

        # Display current URLs
        echo "=========================================="
        echo "NGROK TUNNEL ACTIVE — Token #$((CURRENT_TOKEN_INDEX+1))"
        echo "=========================================="
        curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        proto = tunnel.get('proto', 'unknown')
        url = tunnel.get('public_url', 'N/A')
        print(f'{proto.upper()}: {url}')
except:
    print('Starting...')
" 2>/dev/null || echo "Check logs: docker logs <container>"
        echo "=========================================="

        # Run for 100 minutes (1h 40m) — safely under 2-hour limit
        END_TIME=$((SECONDS + 6000))
        while [ $SECONDS -lt $END_TIME ]; do
            if ! kill -0 $NGROK_PID 2>/dev/null; then
                echo "[$(date)] Ngrok died early — rotating..."
                break
            fi
            sleep 30
        done

        # Rotate to next token
        kill $NGROK_PID 2>/dev/null || true
        pkill -f "ngrok start" 2>/dev/null || true

        CURRENT_TOKEN_INDEX=$(( (CURRENT_TOKEN_INDEX + 1) % ${#TOKENS[@]} ))
        echo "[$(date)] Rotating to token #$((CURRENT_TOKEN_INDEX+1))..."
        sleep 5
    done
}

# Start rotation in background
rotate_ngrok &

# Web server
python3 -m http.server ${PORT:-8080} &

tail -f /dev/null
