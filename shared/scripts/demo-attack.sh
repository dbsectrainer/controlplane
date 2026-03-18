#!/bin/bash
# demo-attack.sh — Demo Scenario 1: Credential Brute-Force Attack
# Shows: Keycloak lockout → Prometheus alert → Grafana live alert
#
# Usage: ./shared/scripts/demo-attack.sh [brute-force|reset]
set -e

KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
REALM="zero-trust"
CLIENT_ID="demo-app"
CLIENT_SECRET="demo-app-secret"
TARGET_USER="admin-user"
WRONG_PASSWORD="WrongPassword123!"
ATTEMPTS="${ATTEMPTS:-6}"

case "${1:-brute-force}" in
  brute-force)
    echo "=== SCENARIO 1: Credential Brute-Force Attack ==="
    echo ""
    echo "Target:   ${KEYCLOAK_URL}/realms/${REALM}"
    echo "User:     ${TARGET_USER}"
    echo "Attempts: ${ATTEMPTS}"
    echo ""
    echo "Firing ${ATTEMPTS} rapid authentication attempts..."
    echo ""

    for i in $(seq 1 "$ATTEMPTS"); do
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=password" \
        -d "client_id=${CLIENT_ID}" \
        -d "client_secret=${CLIENT_SECRET}" \
        -d "username=${TARGET_USER}" \
        -d "password=${WRONG_PASSWORD}" 2>/dev/null || echo "000")
      echo "  Attempt ${i}: HTTP ${STATUS}"
      sleep 0.3
    done

    echo ""
    echo "=== Expected outcomes ==="
    echo "  1. Keycloak brute-force protection triggers after 3 failures (failureFactor=3)"
    echo "  2. Account locked for 60s (waitIncrementSeconds=60)"
    echo "  3. LOGIN_ERROR events logged to Keycloak audit trail"
    echo "  4. Prometheus 'authentication_failures_total' counter rises"
    echo "  5. Grafana fires 'HighAuthenticationFailures' alert"
    echo ""
    echo "  Check Grafana: http://localhost:3100"
    echo "  Check Keycloak events: http://localhost:8080/admin/master/console/#/zero-trust/events"
    ;;

  reset)
    echo "Resetting brute-force lockout (requires Keycloak admin)..."
    TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
      -d "grant_type=password&client_id=admin-cli&username=admin&password=admin" \
      | jq -r '.access_token' 2>/dev/null || echo "")
    if [ -z "$TOKEN" ]; then
      echo "Could not obtain admin token. Is Keycloak running?"
      exit 1
    fi
    curl -s -X DELETE \
      "${KEYCLOAK_URL}/admin/realms/${REALM}/attack-detection/brute-force/users" \
      -H "Authorization: Bearer ${TOKEN}" > /dev/null
    echo "Lockout reset."
    ;;

  *)
    echo "Usage: $0 [brute-force|reset]"
    exit 1
    ;;
esac
