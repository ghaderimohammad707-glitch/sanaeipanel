FROM alpine:3.19

WORKDIR /app

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl \
    bash \
    jq \
    openssl

RUN mkdir -p /app/data /app/logs /app/config

COPY config/ /app/config/
COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

EXPOSE 8000 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["/app/startup.sh"]
