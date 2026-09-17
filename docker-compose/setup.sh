#!/usr/bin/env bash
# Creates the folder structure the compose file expects and checks the parts of
# it that silently break Sonarr and Radarr imports when they are wrong.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "error: no .env found, copy .env-template to .env and fill it in first" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source ./.env
set +a

: "${DATA_PATH:?not set in .env}"
: "${CONFIG_PATH:?not set in .env}"

services=(sonarr radarr prowlarr)
IFS=',' read -r -a profiles <<<"${COMPOSE_PROFILES:-}"
for profile in "${profiles[@]}"; do
  case "$profile" in
    plex | jellyfin | transmission | transmission-openvpn | seerr) services+=("$profile") ;;
    flaresolverr | "") ;; # keeps no state on disk
    *) echo "warning: unknown profile '$profile' in COMPOSE_PROFILES" >&2 ;;
  esac
done

if [[ " ${services[*]} " == *" transmission "* && " ${services[*]} " == *" transmission-openvpn "* ]]; then
  echo "error: transmission and transmission-openvpn both publish port 9091, enable only one" >&2
  exit 1
fi

for path in "$DATA_PATH" "$CONFIG_PATH"; do
  mkdir -p "$path" 2>/dev/null || true
  if [[ ! -w "$path" ]]; then
    echo "error: $path is not writable by $(id -un)" >&2
    echo "       fix with: sudo chown -R $(id -u):$(id -g) $path" >&2
    exit 1
  fi
done

mkdir -p \
  "$DATA_PATH/media/movies" \
  "$DATA_PATH/media/tv" \
  "$DATA_PATH/torrents/complete" \
  "$DATA_PATH/torrents/incomplete" \
  "$DATA_PATH/watch"

for service in "${services[@]}"; do
  mkdir -p "$CONFIG_PATH/$service"
done

# Hardlinking only works within one filesystem, so a separate mount under
# DATA_PATH turns every import into a full copy.
data_device=$(stat -c %d "$DATA_PATH")
for path in "$DATA_PATH/media" "$DATA_PATH/torrents" "$DATA_PATH/watch"; do
  if [[ "$(stat -c %d "$path")" != "$data_device" ]]; then
    echo "warning: $path is on a different filesystem than $DATA_PATH, imports will copy instead of hardlink" >&2
  fi
done

owner="${PUID:-1000}:${PGID:-1000}"
if [[ "$(stat -c %u:%g "$DATA_PATH")" != "$owner" ]]; then
  echo "warning: $DATA_PATH is not owned by $owner, containers may not be able to write to it" >&2
  echo "         fix with: sudo chown -R $owner $DATA_PATH $CONFIG_PATH" >&2
fi

echo "Created media tree under $DATA_PATH and config dirs for: ${services[*]}"
