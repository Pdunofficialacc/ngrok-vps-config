#!/bin/bash
set -e

service ssh start

# Function to keep ngrok alive
keep_ngrok_alive() {
    while true; do
        echo "[$(date)] Starting ngrok tunnel..."

        # Start ngrok in background
        ngrok start ssh web --log=stdout > /tmp/ngrok.log 2>&1 &
        NGROK_PID=$!

        # Wait for ngrok to initialize
        sleep 8

        # Display URLs
        echo "=========================================="
        echo "NGROK TUNNEL URLS:"
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
    print('Ngrok not ready yet')
" 2>/dev/null || echo "Check /tmp/ngrok.log for details"
        echo "=========================================="

        # Monitor ngrok — if it dies or times out, restart
        while kill -0 $NGROK_PID 2>/dev/null; do
            # Check if tunnel is still active (2 hour limit check)
            if ! curl -s http://localhost:4040/api/tunnels | grep -q "public_url"; then
                echo "[$(date)] Ngrok tunnel lost — restarting..."
                kill $NGROK_PID 2>/dev/null || true
                break
            fi
            sleep 30
        done

        # Cleanup before restart
        kill $NGROK_PID 2>/dev/null || true
        pkill -f "ngrok start" 2>/dev/null || true
        sleep 5
    done
}

# Start the keep-alive function in background
keep_ngrok_alive &

# Start web server
python3 -m http.server ${PORT:-8080} &

# Keep container running
tail -f /dev/null
