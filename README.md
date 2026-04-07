# PI Media Server

A single `docker-compose` file that sets up a complete self-hosted media server stack on a Raspberry Pi (or any Linux host). Services are enabled and disabled via **Docker Compose profiles** — no need to juggle multiple compose files.

## Services

| Service | Description | Port | Profile |
|---|---|---|---|
| [Sonarr](https://sonarr.tv/) | PVR for TV shows — monitors RSS feeds, grabs, sorts and renames episodes | 8989 | *(always on)* |
| [Radarr](https://radarr.video/) | Same as Sonarr but for movies | 7878 | *(always on)* |
| [Prowlarr](https://github.com/Prowlarr/Prowlarr) | Centralized indexer manager — syncs indexers to Sonarr & Radarr automatically | 9696 | *(always on)* |
| [Plex](https://www.plex.tv/) | Media frontend for streaming; supports external sharing | host network | `plex` |
| [Jellyfin](https://jellyfin.org/) | Open-source Plex alternative, fully self-hosted | 8096 | `jellyfin` |
| [Transmission](https://transmissionbt.com/) | Lightweight BitTorrent download client | 9091 | `transmission` |
| [Transmission + OpenVPN](https://github.com/haugene/docker-transmission-openvpn) | Transmission routed through a VPN tunnel | 9091 | `transmission-openvpn` |

> **Note:** `transmission` and `transmission-openvpn` both bind host port 9091. Only activate **one** of them at a time.

> **Note:** `plex` uses `network_mode: host` (required for DLNA/discovery) and therefore does not participate in the shared Docker network. It accesses media via host-mounted volumes.

## Prerequisites

### Docker and Docker Compose v2

```bash
# Install Docker (Raspberry Pi / Debian-based)
curl -fsSL https://get.docker.com | sh

# Add your user to the docker group (avoid needing sudo)
sudo usermod -aG docker $USER
# Log out and back in for this to take effect

# Docker Compose v2 is bundled with Docker Desktop and modern Docker Engine.
# Verify:
docker compose version
```

### Data directory layout

Sonarr and Radarr must share a single data root so they can see both the download folder and the media library. This enables **hardlinks** (instant, zero-copy moves) instead of slow cross-filesystem copies.

```
$DATA_PATH/
├── torrents/
│   └── watch/          ← drop .torrent files here for auto-import
├── media/
│   ├── movies/         ← Radarr moves completed movies here
│   └── tv/             ← Sonarr moves completed episodes here
```

Run `scripts/setup.sh` to create this structure automatically (see [Quick Start](#quick-start)), or create it manually:

```bash
mkdir -p /path/to/data/{torrents/watch,media/{movies,tv}}
```

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/HatboyWonder/PiMediaServer.git
cd PiMediaServer

# 2. Run setup: checks prerequisites, creates directories, generates .env
./scripts/setup.sh

# 3. Edit the generated .env file
nano docker-compose/.env

# 4. Start the stack
./scripts/start.sh
```

## Configuration (.env)

Copy `docker-compose/.env-template` to `docker-compose/.env` and fill in your values:

```bash
cp docker-compose/.env-template docker-compose/.env
nano docker-compose/.env
```

Key variables:

| Variable | Description |
|---|---|
| `COMPOSE_PROFILES` | Comma-separated list of profiles to activate (e.g. `jellyfin,transmission`) |
| `DATA_PATH` | Absolute path to the media data root (see layout above) |
| `CONFIG_PATH` | Absolute path for service config databases (preferably on SSD) |
| `TZ` | Your timezone (e.g. `Europe/London`). [Full list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |
| `OPENVPN_PROVIDER` | VPN provider name — only needed for `transmission-openvpn` profile |
| `OPENVPN_CONFIG` | VPN server config name |
| `OPENVPN_USERNAME` | VPN account username |
| `OPENVPN_PASSWORD` | VPN account password |

Supported OpenVPN providers: https://haugene.github.io/docker-transmission-openvpn/supported-providers/

## Scripts

All scripts live in `scripts/` and work from any working directory (they resolve their own path to the compose file).

| Script | Description |
|---|---|
| `scripts/setup.sh` | First-time setup: check prerequisites, create directories, generate `.env` |
| `scripts/start.sh` | Start (or recreate) all services in detached mode |
| `scripts/restart.sh` | Restart running containers without recreating them |
| `scripts/down.sh` | Stop and remove all containers |
| `scripts/upgrade.sh` | Pull latest images then restart the stack |
| `scripts/status.sh` | Show container state and resource usage (CPU, memory, I/O) |
| `scripts/health-check.sh` | Show Docker health status for each container |
| `scripts/logs.sh [service...]` | Tail logs for one or all services |
| `scripts/backup.sh [dest]` | Back up all service config directories to a `.tar.gz` archive |

## Post-install Setup

See **[docs/post-install.md](docs/post-install.md)** for the full step-by-step guide to configuring Prowlarr, Sonarr, Radarr, Transmission, Plex, and Jellyfin after the stack is running.

## Repository Structure

```
PiMediaServer/
├── README.md
├── docker-compose/
│   ├── docker-compose.yaml    ← service definitions
│   └── .env-template          ← copy to .env and fill in your values
├── scripts/
│   ├── setup.sh               ← first-time setup
│   ├── start.sh               ← start the stack
│   ├── restart.sh             ← restart containers
│   ├── down.sh                ← stop the stack
│   ├── upgrade.sh             ← pull latest images and restart
│   ├── status.sh              ← show resource usage
│   ├── health-check.sh        ← show container health
│   ├── logs.sh                ← tail service logs
│   └── backup.sh              ← back up config directories
└── docs/
    └── post-install.md        ← detailed post-install configuration guide
```
