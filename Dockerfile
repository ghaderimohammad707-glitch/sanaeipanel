# ===== Stage 1: Build Backend =====
FROM golang:1.21-alpine AS backend-builder

WORKDIR /src/backend
RUN apk add --no-cache git gcc musl-dev

# Copy go.mod first for caching
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# Copy backend sources and build
COPY backend/ .
# Build statically
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /sanayei-backend .

# ===== Stage 2: Build Frontend =====
FROM node:20-alpine AS frontend-builder

WORKDIR /src/frontend
COPY frontend/package*.json ./
RUN npm ci --production=false
COPY frontend/ .
RUN npm run build

# ===== Stage 3: Production =====
FROM alpine:3.19

WORKDIR /app

# runtime deps: nginx for static files, openssl if startup uses it, unzip + curl for xray install, jq for scripts
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl \
    bash \
    jq \
    nginx \
    unzip \
    openssl

# Create directories
RUN mkdir -p /app/data /app/logs /app/config /var/cache/nginx /app/clients

# Copy backend binary
COPY --from=backend-builder /sanayei-backend /app/sanayei-backend

# Copy frontend build output to nginx html dir (serve on :8000)
COPY --from=frontend-builder /src/frontend/dist /app/frontend
RUN rm -rf /usr/share/nginx/html && ln -s /app/frontend /usr/share/nginx/html

# Copy configuration and startup
COPY config/ /app/config/
COPY nginx.conf /etc/nginx/nginx.conf
COPY startup.sh /app/startup.sh
COPY scripts/generate_xray_client.sh /app/scripts/generate_xray_client.sh
RUN chmod +x /app/startup.sh /app/scripts/generate_xray_client.sh

# Expose ports
EXPOSE 8000 8080 443

# Install Xray core (if not present at runtime, startup will warn)
# NOTE: this downloads a release binary during image build. If you prefer to ship the binary separately, adjust accordingly.
RUN XRAY_VERSION=1.8.4 && \
    ARCH=linux-64 && \
    URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/xray-${ARCH}.zip" && \
    echo "Downloading Xray from ${URL}" && \
    curl -sSL "$URL" -o /tmp/xray.zip && \
    unzip /tmp/xray.zip -d /tmp/xray && \
    mv /tmp/xray/xray /usr/local/bin/xray && \
    chmod +x /usr/local/bin/xray || echo "xray install failed, continue without xray"

# Health check (checks backend)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://127.0.0.1:8080/health || exit 1

CMD ["/app/startup.sh"]
