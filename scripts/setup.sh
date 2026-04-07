#!/usr/bin/env bash
# setup.sh — First-time setup: validates prerequisites, creates directory structure,
#             and generates a .env file from the template.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="${SCRIPT_DIR}/../docker-compose"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }

echo "=== PiMediaServer Setup ==="
echo ""

# ── 1. Check prerequisites ───────────────────────────────────────────────────

MISSING=0

if ! command -v docker &>/dev/null; then
    err "Docker is not installed. Install it with:"
    echo "       curl -fsSL https://get.docker.com | sh"
    MISSING=1
else
    ok "Docker found: $(docker --version)"
fi

if ! docker compose version &>/dev/null; then
    err "Docker Compose v2 plugin not found. Update Docker or install the plugin:"
    echo "       https://docs.docker.com/compose/install/"
    MISSING=1
else
    ok "Docker Compose found: $(docker compose version --short)"
fi

if [[ "$MISSING" -ne 0 ]]; then
    err "Prerequisites missing. Please install them and re-run this script."
    exit 1
fi

echo ""

# ── 2. Create .env from template ─────────────────────────────────────────────

ENV_FILE="${COMPOSE_DIR}/.env"
TEMPLATE_FILE="${COMPOSE_DIR}/.env-template"

if [[ -f "$ENV_FILE" ]]; then
    warn ".env already exists — skipping copy. Edit it manually if needed."
else
    cp "$TEMPLATE_FILE" "$ENV_FILE"
    ok "Created .env from template. Please edit it before starting:"
    echo "       ${ENV_FILE}"
fi

echo ""

# ── 3. Read paths from .env ───────────────────────────────────────────────────

# Source only the DATA_PATH and CONFIG_PATH variables safely
DATA_PATH=""
CONFIG_PATH=""
while IFS='=' read -r key value; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    key="${key// /}"
    value="${value// /}"
    case "$key" in
        DATA_PATH)   DATA_PATH="$value" ;;
        CONFIG_PATH) CONFIG_PATH="$value" ;;
    esac
done < "$ENV_FILE"

if [[ -z "$DATA_PATH" || "$DATA_PATH" == "/path/to/media/data" ]]; then
    warn "DATA_PATH is not configured in .env. Skipping directory creation."
    warn "Edit ${ENV_FILE} and re-run this script."
    exit 0
fi

if [[ -z "$CONFIG_PATH" || "$CONFIG_PATH" == "/path/to/config/data/on/fast/disk" ]]; then
    warn "CONFIG_PATH is not configured in .env. Skipping directory creation."
    warn "Edit ${ENV_FILE} and re-run this script."
    exit 0
fi

# ── 4. Create data directory structure ───────────────────────────────────────

echo "Creating data directory structure under: ${DATA_PATH}"
mkdir -p \
    "${DATA_PATH}/torrents/watch" \
    "${DATA_PATH}/media/movies" \
    "${DATA_PATH}/media/tv"
ok "Data directories ready."

echo ""
echo "Creating config directory structure under: ${CONFIG_PATH}"
mkdir -p \
    "${CONFIG_PATH}/sonarr" \
    "${CONFIG_PATH}/radarr" \
    "${CONFIG_PATH}/prowlarr" \
    "${CONFIG_PATH}/plex" \
    "${CONFIG_PATH}/jellyfin" \
    "${CONFIG_PATH}/transmission" \
    "${CONFIG_PATH}/transmission-openvpn"
ok "Config directories ready."

echo ""
echo "=== Setup complete. Next steps ==="
echo "  1. Review and finish editing: ${ENV_FILE}"
echo "  2. Start the stack:           ${SCRIPT_DIR}/start.sh"
