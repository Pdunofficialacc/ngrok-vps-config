#!/bin/bash
set -e

service ssh start
ngrok start ssh --log=stdout > /tmp/ngrok.log 2>&1 &
python3 -m http.server ${PORT:-8080} &
tail -f /dev/null
