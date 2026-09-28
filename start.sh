#!/bin/bash
set -e

service ssh start

# Start ngrok tunnel (random port auto-assign hoga)
ngrok start ssh --log=stdout > /tmp/ngrok.log 2>&1 &

# Wait for ngrok to initialize
sleep 5

# Fetch public URL (random port)
echo "=========================================="
echo "NGROK TUNNEL URLS:"
echo "=========================================="
curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
data = json.load(sys.stdin)
for tunnel in data.get('tunnels', []):
    proto = tunnel.get('proto', 'unknown')
    url = tunnel.get('public_url', 'N/A')
    print(f'{proto.upper()}: {url}')
" 2>/dev/null || echo "Ngrok API not ready yet — check /tmp/ngrok.log"
echo "=========================================="

# Start web server
python3 -m http.server ${PORT:-8080} &

# Keep container running
tail -f /dev/null
