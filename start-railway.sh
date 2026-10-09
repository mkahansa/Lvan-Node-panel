#!/usr/bin/env bash
# Railway entrypoint for Marzban-node.
#
# The official Marzban panel ALWAYS connects to nodes over HTTPS with a
# client certificate (mutual TLS) - this is stock Marzban-node behavior,
# unmodified. The only Railway-specific convenience here is: since you can't
# just scp a file onto a Railway container, paste the certificate text shown
# by the panel's "Add Node" dialog into the SSL_CLIENT_CERT variable
# (multi-line values are fine in Railway's Variables editor) and this script
# writes it to disk where Marzban-node expects it.
#
# IMPORTANT: SSL_CLIENT_CERT_FILE is intentionally left UNSET here unless a
# cert was actually provided. Upstream main.py does `exit(0)` immediately if
# SSL_CLIENT_CERT_FILE points at a file that doesn't exist - if we hardcoded
# that env var, the container would crash-loop forever with no listening
# port at all whenever the cert hasn't been configured yet, which looks like
# a plain "connection refused" from the panel side and is hard to debug.
set -euo pipefail

cd /code

mkdir -p "${SSL_DIR:-/var/lib/marzban-node}"

if [ -n "${SSL_CLIENT_CERT:-}" ]; then
    export SSL_CLIENT_CERT_FILE="${SSL_CLIENT_CERT_FILE:-/var/lib/marzban-node/ssl_client_cert.pem}"
    echo "==> [railway] Writing SSL_CLIENT_CERT to ${SSL_CLIENT_CERT_FILE}..."
    printf '%s\n' "${SSL_CLIENT_CERT}" > "${SSL_CLIENT_CERT_FILE}"
else
    unset SSL_CLIENT_CERT_FILE || true
    echo "!! [railway] SSL_CLIENT_CERT is not set."
    echo "    The node will start WITHOUT a client certificate (insecure - anyone"
    echo "    could connect), just so you can see it come up and check logs."
    echo "    Open the panel -> Node Settings -> Add Node, copy the certificate"
    echo "    shown there (or use the eye icon / Download certificate button),"
    echo "    paste it into the SSL_CLIENT_CERT variable of this Railway"
    echo "    service, and redeploy to secure the connection properly."
fi

echo "==> [railway] Marzban-node starting - main port: ${SERVICE_PORT}   xray api port: ${XRAY_API_PORT}"

exec python main.py
