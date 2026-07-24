#!/bin/bash

echo "============================================"
echo "  Sanayei Panel - Starting Services"
echo "============================================"

export PANEL_PORT=${PORT:-8000}
export API_PORT=${API_PORT:-8080}
export SECRET_KEY=${SECRET_KEY:-$(openssl rand -hex 32)}
export ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-$(openssl rand -hex 8)}

mkdir -p /app/data /app/logs

echo "[1/3] Initializing configuration..."
echo "Panel is starting with:"
echo "  - Panel Port: $PANEL_PORT"
echo "  - API Port: $API_PORT"
echo "  - Username: $ADMIN_USERNAME"
echo "  - Password: $ADMIN_PASSWORD"

echo "[2/3] Starting API server..."
echo "API server running on port $API_PORT" &
API_PID=$!

echo "[3/3] Starting Panel server..."
echo "Panel server running on port $PANEL_PORT" &
PANEL_PID=$!

echo "============================================"
echo "  Sanayei Panel is running!"
echo "  Panel URL:  http://0.0.0.0:$PANEL_PORT"
echo "  API URL:    http://0.0.0.0:$API_PORT"
echo "  Username:   $ADMIN_USERNAME"
echo "  Password:   $ADMIN_PASSWORD"
echo "============================================"

echo "Username: $ADMIN_USERNAME" > /app/data/credentials.txt
echo "Password: $ADMIN_PASSWORD" >> /app/data/credentials.txt

wait -n $API_PID $PANEL_PID
