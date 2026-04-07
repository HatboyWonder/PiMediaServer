#!/usr/bin/env bash
# status.sh — Shows running services, mapped ports, and resource usage.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose/docker-compose.yaml"

COMPOSE="docker compose -f ${COMPOSE_FILE}"

echo "=== Container Status ==="
echo ""
$COMPOSE ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Resource Usage ==="
echo ""

# Collect container names from the stack and pass to docker stats for a snapshot
CONTAINERS=$($COMPOSE ps --format "{{.Name}}" 2>/dev/null | tr '\n' ' ')

if [[ -z "$CONTAINERS" ]]; then
    echo "No running containers found."
else
    # shellcheck disable=SC2086
    docker stats --no-stream --format \
        "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" \
        $CONTAINERS
fi
