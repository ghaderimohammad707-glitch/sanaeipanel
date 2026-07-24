#!/bin/bash
# generate_xray_client.sh
# Usage: ./generate_xray_client.sh <id> [name]
# Generates a client-side simple JSON config (VLESS over TCP example) and saves to /app/clients/<id>.json

set -e

ID="$1"
NAME="$2"
if [ -z "$ID" ]; then
  echo "Usage: $0 <client-id> [name]"
  exit 2
fi

OUTDIR=/app/clients
mkdir -p "$OUTDIR"

cat > "$OUTDIR/$ID.json" <<EOF
{
  "v": "2",
  "ps": "${NAME:-client}",
  "add": "YOUR_SERVER_HOST",
  "port": "443",
  "id": "$ID",
  "aid": "0",
  "net": "tcp",
  "type": "none",
  "host": "",
  "path": "",
  "tls": "tls"
}
EOF

echo "Client config generated: $OUTDIR/$ID.json"
