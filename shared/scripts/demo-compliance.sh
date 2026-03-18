#!/bin/bash
# demo-compliance.sh — Demo Scenario 3: Compliance Drift Auto-Detection
# Shows: Control mutation → compliance-reporter red → auto-recovery
#
# Usage: ./shared/scripts/demo-compliance.sh [inject-drift|restore|status]
set -e

REPORTER_URL="${REPORTER_URL:-http://localhost:8088}"

case "${1:-status}" in
  inject-drift)
    FRAMEWORK="${2:-SOC2}"
    CONTROL="${3:-CC1.0}"
    echo "=== SCENARIO 3: Injecting compliance drift ==="
    echo "Framework: ${FRAMEWORK}"
    echo "Control:   ${CONTROL}"
    echo ""
    RESULT=$(curl -s -X POST \
      "${REPORTER_URL}/inject-drift?framework=${FRAMEWORK}&control=${CONTROL}")
    echo "Response: ${RESULT}"
    echo ""
    echo "=== Expected outcomes ==="
    echo "  1. Compliance dashboard at ${REPORTER_URL}/dashboard shows ${CONTROL} as FAIL"
    echo "  2. compliance_controls_failing_total{framework=\"${FRAMEWORK}\"} > 0 in Prometheus"
    echo "  3. Grafana alert 'ComplianceDrift' fires (if alert rules configured)"
    echo ""
    echo "  Check dashboard: ${REPORTER_URL}/dashboard"
    echo "  Restore with:    $0 restore"
    ;;

  restore)
    echo "=== Restoring all compliance controls to PASS ==="
    RESULT=$(curl -s -X POST "${REPORTER_URL}/restore")
    echo "Response: ${RESULT}"
    echo "Dashboard: ${REPORTER_URL}/dashboard"
    ;;

  status)
    echo "=== Current compliance status ==="
    curl -s "${REPORTER_URL}/api/controls" | jq '
      to_entries[] |
      .key as $fw |
      .value[] |
      "\($fw) | \(.id) | \(.title) | \(.status)"
    ' -r 2>/dev/null || echo "  Is compliance-reporter running? docker-compose ps compliance-reporter"
    ;;

  *)
    echo "Usage: $0 [inject-drift [FRAMEWORK [CONTROL]]|restore|status]"
    echo "Examples:"
    echo "  $0 inject-drift SOC2 CC1.0"
    echo "  $0 inject-drift HIPAA access-control"
    echo "  $0 restore"
    exit 1
    ;;
esac
