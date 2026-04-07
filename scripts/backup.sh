#!/usr/bin/env bash
# backup.sh — Backs up all service config directories to a timestamped tar archive.
#
# Usage:
#   ./backup.sh                          # backs up to current directory
#   ./backup.sh /mnt/backup              # backs up to a specific destination
#
# What is backed up:
#   All subdirectories under $CONFIG_PATH (sonarr, radarr, prowlarr, etc.)
#   These contain SQLite databases, XML configs, and API keys — everything
#   needed to restore the stack without reconfiguration.
#
# What is NOT backed up:
#   $DATA_PATH (media files and torrents) — these are large and not config.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="${SCRIPT_DIR}/../docker-compose"

DEST="${1:-"${SCRIPT_DIR}"}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="${DEST}/mediaserver-config-backup-${TIMESTAMP}.tar.gz"

# Read CONFIG_PATH from .env
ENV_FILE="${COMPOSE_DIR}/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found at ${ENV_FILE}. Run setup.sh first." >&2
    exit 1
fi

CONFIG_PATH=""
while IFS='=' read -r key value; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    key="${key// /}"
    value="${value// /}"
    [[ "$key" == "CONFIG_PATH" ]] && CONFIG_PATH="$value"
done < "$ENV_FILE"

if [[ -z "$CONFIG_PATH" || "$CONFIG_PATH" == "/path/to/config/data/on/fast/disk" ]]; then
    echo "ERROR: CONFIG_PATH is not configured in .env." >&2
    exit 1
fi

if [[ ! -d "$CONFIG_PATH" ]]; then
    echo "ERROR: CONFIG_PATH directory does not exist: ${CONFIG_PATH}" >&2
    exit 1
fi

mkdir -p "$DEST"

echo "Backing up config from: ${CONFIG_PATH}"
echo "Archive destination:    ${ARCHIVE}"
echo ""

tar -czf "$ARCHIVE" -C "$(dirname "$CONFIG_PATH")" "$(basename "$CONFIG_PATH")"

SIZE=$(du -sh "$ARCHIVE" | cut -f1)
echo "Done. Archive size: ${SIZE}"
echo "  ${ARCHIVE}"
