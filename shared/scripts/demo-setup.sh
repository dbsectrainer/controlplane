#!/bin/bash
# demo-setup.sh — One-command bootstrap for the portfolio demo
# Usage: ./shared/scripts/demo-setup.sh
set -e

BOLD=$(tput bold 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
BLUE=$(tput setaf 4 2>/dev/null || echo "")

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "${BOLD}${BLUE}╔══════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${BLUE}║   ControlPlane — Demo Setup                      ║${RESET}"
echo "${BOLD}${BLUE}╚══════════════════════════════════════════════════╝${RESET}"
echo ""

# Prerequisites check
echo "${BOLD}Checking prerequisites...${RESET}"
for cmd in docker docker-compose curl jq; do
  if command -v "$cmd" > /dev/null 2>&1; then
    echo "  ${GREEN}✓${RESET} $cmd"
  else
    echo "  ✗ $cmd — required but not found"
    exit 1
  fi
done
echo ""

# Make all scripts executable
chmod +x "$ROOT/shared/scripts/"*.sh

# Pull images (parallel, verbose)
echo "${BOLD}Pulling Docker images (this may take a few minutes the first time)...${RESET}"
docker-compose pull --quiet 2>/dev/null || true
echo ""

echo "${BOLD}${GREEN}Setup complete!${RESET}"
echo ""
echo "  ${BOLD}Start the platform:${RESET}"
echo "    docker-compose up -d"
echo ""
echo "  ${BOLD}Service URLs (after startup):${RESET}"
echo "    Demo App:           ${BLUE}http://localhost:3000/api-docs${RESET}"
echo "    Grafana:            ${BLUE}http://localhost:3100${RESET}  (admin/admin)"
echo "    Vault:              ${BLUE}http://localhost:8200/ui${RESET}  (token: root)"
echo "    Keycloak:           ${BLUE}http://localhost:8080${RESET}  (admin/admin)"
echo "    OPA:                ${BLUE}http://localhost:8181${RESET}"
echo "    Prometheus:         ${BLUE}http://localhost:9090${RESET}"
echo "    Compliance:         ${BLUE}http://localhost:8088/dashboard${RESET}"
echo "    MobSF:              ${BLUE}http://localhost:8008${RESET}"
echo "    SonarQube:          ${BLUE}http://localhost:9000${RESET}  (admin/admin)"
echo "    Mail (Mailhog):     ${BLUE}http://localhost:8025${RESET}"
echo ""
echo "  ${BOLD}Demo scenarios:${RESET}"
echo "    docker-compose --profile demo up -d attacker"
echo "    ./shared/scripts/demo-attack.sh brute-force"
echo "    ./shared/scripts/demo-compliance.sh inject-drift"
echo "    ./shared/scripts/demo-supply-chain.sh"
echo "    ./shared/scripts/demo-mobile-leak.sh"
echo ""
echo "  ${BOLD}See docs/CONFERENCE-RUNBOOK.md for the full demo script.${RESET}"
