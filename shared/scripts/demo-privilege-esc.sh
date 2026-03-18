#!/bin/bash
# demo-privilege-esc.sh — Demo Scenario 2: Privilege Escalation Attempt
# Shows: Developer token → OPA policy denial → policy_violations_total metric
#
# Usage: ./shared/scripts/demo-privilege-esc.sh
set -e

KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
OPA_URL="${OPA_URL:-http://localhost:8181}"
REALM="zero-trust"
CLIENT_ID="demo-app"
CLIENT_SECRET="demo-app-secret"

echo "=== SCENARIO 2: Privilege Escalation Attempt ==="
echo ""

echo "Step 1: Obtain developer token from Keycloak..."
DEV_TOKEN=$(curl -s -X POST \
  "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -d "grant_type=password" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "username=dev-user" \
  -d "password=Dev@1234" \
  | jq -r '.access_token' 2>/dev/null || echo "")

if [ -z "$DEV_TOKEN" ] || [ "$DEV_TOKEN" = "null" ]; then
  echo "  Could not get developer token. Is Keycloak running and realm imported?"
  echo "  Try: docker-compose logs keycloak | tail -20"
  exit 1
fi
echo "  Developer token obtained (truncated): ${DEV_TOKEN:0:40}..."
echo ""

echo "Step 2: Attempt admin-level operation via OPA policy check..."
RESPONSE=$(curl -s -X POST "${OPA_URL}/v1/data/authorization/allow" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "user": {
        "name": "dev-user",
        "roles": ["developer"],
        "groups": ["/development-team"],
        "team": "development",
        "type": "human"
      },
      "resource": {
        "name": "admin-panel",
        "type": "ui",
        "environment": "production",
        "team": "security",
        "allowed_service_accounts": []
      },
      "request": {
        "method": "POST",
        "protocol": "https",
        "source_ip": "172.20.0.1",
        "authenticated": true,
        "mfa_verified": true,
        "headers": {
          "Content-Security-Policy": "default-src",
          "X-Frame-Options": "DENY"
        }
      },
      "context": {
        "incident_id": null,
        "emergency_approved": false
      }
    }
  }')

ALLOWED=$(echo "$RESPONSE" | jq -r '.result' 2>/dev/null || echo "false")
echo "  OPA decision: allow = ${ALLOWED}"
echo ""

if [ "$ALLOWED" = "false" ]; then
  echo "=== Expected outcomes ==="
  echo "  1. OPA correctly DENIED the privilege escalation (allow=false)"
  echo "  2. Developer cannot access admin resources (team mismatch + production env)"
  echo "  3. Violations captured:"
  curl -s -X POST "${OPA_URL}/v1/data/authorization/violations" \
    -H "Content-Type: application/json" \
    -d '{"input":{"user":{"name":"dev-user","roles":["developer"],"groups":[],"team":"development"},"resource":{"name":"admin","environment":"production","team":"security","allowed_service_accounts":[]},"request":{"method":"POST","source_ip":"172.20.0.1","authenticated":true,"mfa_verified":true,"headers":{}},"context":{}}}' \
    | jq '.result' 2>/dev/null || echo "  (OPA violations endpoint)"
  echo ""
  echo "  Check OPA:      http://localhost:8181/v1/data/authorization"
  echo "  Check Grafana:  http://localhost:3100 → policy_violations_total"
else
  echo "  WARNING: OPA allowed the request (check policy configuration)"
fi
