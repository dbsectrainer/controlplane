#!/bin/bash
# demo-mobile-leak.sh — Demo Scenario 5: Mobile Secret Exfiltration
# Shows: Semgrep detects hardcoded API key → MobSF finding → Vault integration fix
#
# Usage: ./shared/scripts/demo-mobile-leak.sh [inject|scan|fix|restore]
set -e

MOBILE_DIR="$(cd "$(dirname "$0")/../../projects/mobile" && pwd)"
LEAK_FILE="$MOBILE_DIR/android/security/SecretLeak.kt"
BACKUP="${LEAK_FILE}.backup"

case "${1:-scan}" in
  inject)
    echo "=== SCENARIO 5: Injecting hardcoded secret into Android source ==="
    mkdir -p "$(dirname "$LEAK_FILE")"
    cat > "$LEAK_FILE" << 'EOF'
package com.portfolio.demo.security

// DEMO ONLY — intentionally insecure for security testing demonstration
object AppConfig {
    // BUG: API key hardcoded in source — will be detected by SAST
    const val API_KEY = "sk-prod-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
    const val STRIPE_KEY = "sk_live_abcdef123456789"
    const val DATABASE_URL = "mongodb://admin:password123@prod-db.example.com:27017"
}
EOF
    echo "Injected: $LEAK_FILE"
    echo ""
    echo "  Run: $0 scan"
    ;;

  scan)
    echo "=== Running mobile SAST scan for secret leakage ==="
    echo ""
    if command -v semgrep > /dev/null 2>&1; then
      echo "--- Semgrep scan ---"
      semgrep --config=auto \
        --include="*.kt" --include="*.swift" \
        --error \
        "$MOBILE_DIR" 2>&1 || echo ""
    else
      echo "Semgrep not installed locally. Simulating scan output..."
      echo ""
    fi

    echo "--- Pattern-based secret scan (simulated pipeline output) ---"
    for f in $(find "$MOBILE_DIR" -name "*.kt" -o -name "*.swift" 2>/dev/null); do
      if grep -nE '(API_KEY|SECRET|PASSWORD|STRIPE|sk_live|sk-prod)\s*=\s*"[^"]+"' "$f" 2>/dev/null; then
        echo "  CRITICAL: Hardcoded secret found in $f"
      fi
    done

    echo ""
    echo "--- Certificate pinning verification ---"
    for f in $(find "$MOBILE_DIR" -name "*.kt" 2>/dev/null); do
      if grep -q "CertificatePinner\|certificatePinner\|sslPinning" "$f" 2>/dev/null; then
        echo "  PASS: Certificate pinning present in $f"
      fi
    done
    for f in $(find "$MOBILE_DIR" -name "*.swift" 2>/dev/null); do
      if grep -q "pinnedCertificates\|certificatePinning\|TrustKit" "$f" 2>/dev/null; then
        echo "  PASS: Certificate pinning present in $f"
      fi
    done

    echo ""
    echo "  MobSF UI: http://localhost:8008 (upload APK/IPA for dynamic analysis)"
    ;;

  fix)
    echo "=== Showing secure Vault-backed alternative ==="
    cat << 'EOF'

BEFORE (insecure — hardcoded secret):
  const val API_KEY = "sk-prod-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"

AFTER (secure — fetched from Vault at runtime):
  class SecretsManager(private val vaultClient: VaultClient) {
      fun getApiKey(): String {
          return vaultClient.read("kv/demo-app/config")
                            .data["api_key"] as String
      }
  }

Key principle: Secrets live in Vault (http://localhost:8200),
not in source code. The CI pipeline gates on detect-secrets and
Semgrep to catch any regressions.

EOF
    ;;

  restore)
    rm -f "$LEAK_FILE"
    echo "Removed leak file: $LEAK_FILE"
    ;;

  *)
    echo "Usage: $0 [inject|scan|fix|restore]"
    exit 1
    ;;
esac
