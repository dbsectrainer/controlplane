#!/bin/bash
# demo-supply-chain.sh — Demo Scenario 4: Supply Chain Attack Simulation
# Shows: Malicious dep injection → Trivy detection → pipeline gate blocks build
#
# Usage: ./shared/scripts/demo-supply-chain.sh [inject|scan|restore]
set -e

APP_DIR="$(cd "$(dirname "$0")/../../projects/app-devsecops" && pwd)"
PKG_JSON="$APP_DIR/package.json"
BACKUP="$APP_DIR/.package.json.backup"

MALICIOUS_PKG='  "event-stream": "3.3.6"'  # known compromised version (historical)

case "${1:-scan}" in
  inject)
    echo "=== SCENARIO 4: Injecting malicious dependency ==="
    echo ""
    cp "$PKG_JSON" "$BACKUP"

    # Add malicious package to dependencies section
    python3 -c "
import json, sys
with open('$PKG_JSON') as f:
    pkg = json.load(f)
pkg.setdefault('dependencies', {})['event-stream'] = '3.3.6'
with open('$PKG_JSON', 'w') as f:
    json.dump(pkg, f, indent=2)
print('Injected: event-stream@3.3.6 (known compromised package)')
"
    echo ""
    echo "  Now run:  $0 scan"
    echo "  To fix:   $0 restore"
    ;;

  scan)
    echo "=== Running supply chain security scan ==="
    echo ""
    if command -v trivy > /dev/null 2>&1; then
      echo "--- Trivy filesystem scan ---"
      trivy fs --exit-code 1 --severity HIGH,CRITICAL "$APP_DIR" 2>&1 || {
        echo ""
        echo "=== Pipeline GATE: Trivy found HIGH/CRITICAL vulnerabilities — build blocked ==="
      }
    else
      echo "Trivy not installed locally. Simulating scan output..."
      echo ""
      echo "  trivy fs --exit-code 1 --severity HIGH,CRITICAL projects/app-devsecops/"
      echo ""
      if python3 -c "import json; d=json.load(open('$PKG_JSON')); print(d.get('dependencies',{}).get('event-stream',''))" 2>/dev/null | grep -q "3.3.6"; then
        echo "  [SIMULATED] CRITICAL: event-stream@3.3.6 — Malicious code injection (CVE-2018-20834)"
        echo "  [SIMULATED] Build blocked: exit code 1"
      else
        echo "  [SIMULATED] No HIGH/CRITICAL vulnerabilities found."
      fi
    fi

    echo ""
    echo "  Check detect-secrets:"
    if command -v detect-secrets > /dev/null 2>&1; then
      detect-secrets scan "$APP_DIR" 2>&1 | head -20
    else
      echo "  detect-secrets not installed — in CI pipeline this runs as: detect-secrets scan src/"
    fi
    ;;

  restore)
    echo "=== Restoring clean package.json ==="
    if [ -f "$BACKUP" ]; then
      cp "$BACKUP" "$PKG_JSON"
      rm -f "$BACKUP"
      echo "Restored from backup."
    else
      python3 -c "
import json
with open('$PKG_JSON') as f:
    pkg = json.load(f)
pkg.get('dependencies', {}).pop('event-stream', None)
with open('$PKG_JSON', 'w') as f:
    json.dump(pkg, f, indent=2)
print('event-stream removed from dependencies.')
"
    fi
    ;;

  *)
    echo "Usage: $0 [inject|scan|restore]"
    exit 1
    ;;
esac
