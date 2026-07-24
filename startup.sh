#!/bin/bash
set -e

echo "============================================"
echo "  Sanayei Panel - Starting Services"
echo "============================================"

export DB_PATH=${DB_PATH:-"/app/data/sanayei.db"}
export LOG_PATH=${LOG_PATH:-"/app/logs"}
export PANEL_PORT=${PORT:-8000}
export API_PORT=${API_PORT:-8080}
export SECRET_KEY=${SECRET_KEY:-$(openssl rand -hex 32)}
export ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-$(openssl rand -hex 8)}

mkdir -p /app/data /app/logs /app/clients

echo "[1/4] Initializing database..."
if [ -x /app/sanayei-backend ]; then
  /app/sanayei-backend init-db \
    --db-path "$DB_PATH" \
    --admin-username "$ADMIN_USERNAME" \
    --admin-password "$ADMIN_PASSWORD" || true
else
  echo "Warning: backend binary not found, skipping init-db"
fi

echo "[2/4] Starting backend server..."
if [ -x /app/sanayei-backend ]; then
  /app/sanayei-backend server \
    --port "$API_PORT" \
    --db-path "$DB_PATH" \
    --secret-key "$SECRET_KEY" \
    --log-path "$LOG_PATH" &
  BACKEND_PID=$!
else
  echo "Backend not available"
fi

# Start Xray if config present
if [ -f /app/config/xray.json ]; then
  echo "[3/4] Starting Xray..."
  if command -v xray >/dev/null 2>&1; then
    xray -c /app/config/xray.json &
    XRAY_PID=$!
  else
    echo "xray binary not found, skipping Xray start"
  fi
else
  echo "No xray config found at /app/config/xray.json, skipping Xray"
fi

echo "[4/4] Starting nginx to serve frontend..."
# Ensure nginx logs to stdout
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
nginx -g 'daemon off;' &
NGINX_PID=$!

echo "============================================"
echo "  Sanayei Panel is running!"
echo "  Panel URL:  http://0.0.0.0:${PANEL_PORT}"
echo "  API URL:    http://0.0.0.0:${API_PORT}"
echo "  Username:   $ADMIN_USERNAME"
echo "  Password:   $ADMIN_PASSWORD"
echo "============================================"

# Save credentials
cat > /app/data/credentials.txt <<EOF
Username: $ADMIN_USERNAME
Password: $ADMIN_PASSWORD
Panel URL: http://0.0.0.0:${PANEL_PORT}
API URL: http://0.0.0.0:${API_PORT}
EOF

# Wait for any process to exit
wait -n ${BACKEND_PID:-} ${NGINX_PID:-} ${XRAY_PID:-}
