# syntax=docker/dockerfile:1
# ---------------------------------------------------------------------------
# Marzban-node - Railway deploy wrapper (build-time clone, like PasarGuard-Node)
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS builder

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential git curl unzip ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG NODE_REPO=https://github.com/Gozargah/Marzban-node.git
ARG NODE_REF=master
RUN git clone --depth 1 --branch ${NODE_REF} ${NODE_REPO} .

# Install Xray-core (same official helper the panel image uses, always current).
RUN curl -L https://github.com/Gozargah/Marzban-scripts/raw/master/install_latest_xray.sh | bash

RUN python3 -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# No source patches needed here (unlike the panel): stock Marzban-node already
# runs REST-over-TLS with a client certificate, which is exactly what the
# official Marzban panel expects when it connects to a node - so we ship it
# unmodified and only add a small startup convenience (writing the pasted
# client certificate to disk) in start-railway.sh.

# ---------------------------------------------------------------------------
# Runtime image
# ---------------------------------------------------------------------------
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    SERVICE_HOST=0.0.0.0 \
    SERVICE_PORT=62050 \
    XRAY_API_PORT=62051 \
    SERVICE_PROTOCOL=rest \
    XRAY_EXECUTABLE_PATH=/usr/local/bin/xray \
    XRAY_ASSETS_PATH=/usr/local/share/xray \
    SSL_DIR=/var/lib/marzban-node \
    SSL_CERT_FILE=/var/lib/marzban-node/ssl_cert.pem \
    SSL_KEY_FILE=/var/lib/marzban-node/ssl_key.pem

WORKDIR /code

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/xray /usr/local/bin/xray
COPY --from=builder /usr/local/share/xray /usr/local/share/xray
COPY --from=builder /build /code

# Same defensive fix as the panel image: newest setuptools releases removed
# pkg_resources entirely, so pin a version that still ships it in case any
# dependency imports it at runtime.
RUN pip install --no-cache-dir "setuptools==75.8.0"

COPY start-railway.sh /code/start-railway.sh
RUN groupadd --system --gid 1001 app \
    && useradd --system --uid 1001 --gid app app \
    && mkdir -p /var/lib/marzban-node \
    && chown -R app:app /code /var/lib/marzban-node \
    && chmod +x /code/start-railway.sh

USER app

EXPOSE 62050 62051

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import socket,os; s=socket.create_connection(('127.0.0.1', int(os.getenv('SERVICE_PORT','62050'))), timeout=3); s.close()" || exit 1

ENTRYPOINT ["bash", "/code/start-railway.sh"]
