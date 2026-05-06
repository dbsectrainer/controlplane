#!/usr/bin/env bash
# Generates a self-signed certificate for localhost Keycloak HTTPS proxy
set -euo pipefail

CERT_DIR="shared/infrastructure/nginx/certs"
mkdir -p "$CERT_DIR"

if [[ -f "$CERT_DIR/keycloak.crt" ]]; then
  echo "Certs already exist at $CERT_DIR/, skipping."
  exit 0
fi

openssl req -x509 -newkey rsa:4096 -keyout "$CERT_DIR/keycloak.key" \
  -out "$CERT_DIR/keycloak.crt" -sha256 -days 365 -nodes \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo "Self-signed cert written to $CERT_DIR/"
