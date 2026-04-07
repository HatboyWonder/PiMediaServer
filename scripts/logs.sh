#!/usr/bin/env bash
# logs.sh — Tail logs for one or all services.
#
# Usage:
#   ./logs.sh                  # tail all services
#   ./logs.sh sonarr           # tail a specific service
#   ./logs.sh sonarr radarr    # tail multiple services
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose/docker-compose.yaml"

docker compose -f "${COMPOSE_FILE}" logs --follow --tail=100 "$@"
