#!/usr/bin/env bash
# health-check.sh — Reports the health and running state of all stack containers.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose/docker-compose.yaml"

COMPOSE="docker compose -f ${COMPOSE_FILE}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== PiMediaServer Health Check ==="
echo ""

# Show overall container state table
$COMPOSE ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Per-service health ==="

# Iterate over running containers and report Docker health status
while IFS= read -r name; do
    status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no healthcheck{{end}}' "$name" 2>/dev/null || echo "not found")
    case "$status" in
        healthy)          echo -e "  ${GREEN}healthy${NC}         ${name}" ;;
        unhealthy)        echo -e "  ${RED}unhealthy${NC}       ${name}" ;;
        starting)         echo -e "  ${YELLOW}starting${NC}        ${name}" ;;
        "no healthcheck") echo -e "  ${YELLOW}no healthcheck${NC}  ${name}" ;;
        *)                echo -e "  ${YELLOW}${status}${NC}  ${name}" ;;
    esac
done < <($COMPOSE ps --format "{{.Name}}" 2>/dev/null)

echo ""
echo "Run '${SCRIPT_DIR}/logs.sh <service>' to inspect a specific service."
