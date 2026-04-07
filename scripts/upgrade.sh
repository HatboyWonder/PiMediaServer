#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose/docker-compose.yaml"

echo "Pulling latest images..."
docker compose -f "${COMPOSE_FILE}" pull

echo "Recreating containers with updated images..."
"${SCRIPT_DIR}/start.sh"
