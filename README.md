# Pi Media Server

A single `docker compose` stack that runs a complete media server on a Raspberry Pi: indexer
search, automatic downloading, importing, and streaming. The point of the repo is the *path
layout* — every container sees the same `/data` tree, so Sonarr and Radarr can hardlink finished
downloads into the library instead of copying them, and no remote path mapping is needed anywhere.

## Services

Sonarr, Radarr and Prowlarr always run. Everything else is opt-in through `COMPOSE_PROFILES`
in `.env`.

| Service | Profile | Port | Role |
| --- | --- | --- | --- |
| [Sonarr](https://github.com/Sonarr/Sonarr) | *always* | 8989 | Monitors and imports TV shows |
| [Radarr](https://github.com/Radarr/Radarr) | *always* | 7878 | Monitors and imports movies |
| [Prowlarr](https://github.com/Prowlarr/Prowlarr) | *always* | 9696 | Indexer manager, feeds Sonarr and Radarr |
| [Jellyfin](https://github.com/jellyfin/jellyfin) | `jellyfin` | 8096 | Streaming frontend, fully self-hosted |
| [Plex](https://www.plex.tv/) | `plex` | 32400 | Streaming frontend, easy to share with others |
| [Transmission](https://github.com/transmission/transmission) | `transmission` | 9091 | BitTorrent client |
| [Transmission + OpenVPN](https://haugene.github.io/docker-transmission-openvpn/) | `transmission-openvpn` | 9091 | Same, tunnelled through a VPN provider |
| [Seerr](https://github.com/seerr-team/seerr) | `seerr` | 5055 | Request frontend for users |
| [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) | `flaresolverr` | 8191 | Solves Cloudflare challenges for Prowlarr |

Pick **at most one** media server and **at most one** download client. `transmission` and
`transmission-openvpn` both publish port 9091 and cannot run together; `setup.sh` refuses that
combination.

## Folder layout

`DATA_PATH` must be a **single filesystem**. Sonarr and Radarr mount it whole as `/data`, and a
hardlink cannot cross a mount point — put `media/` and `torrents/` on different disks and every
import silently becomes a full copy that also breaks seeding.

```
DATA_PATH/
├── media/
│   ├── movies/       Radarr library, served to Plex/Jellyfin
│   └── tv/           Sonarr library, served to Plex/Jellyfin
├── torrents/
│   ├── complete/     finished downloads, imported from here
│   └── incomplete/   in-progress downloads
└── watch/            drop .torrent files here to add them manually

CONFIG_PATH/          databases, artwork caches, logs — put this on an SSD
├── sonarr/
├── radarr/
├── prowlarr/
└── ...               one directory per enabled profile
```

Both `DATA_PATH` and `CONFIG_PATH` must be owned by the `PUID`/`PGID` set in `.env`.

## Prerequisites

Docker, including the Compose v2 plugin:

```bash
curl -sSL https://get.docker.com | sh
sudo apt install docker-compose-plugin
sudo usermod -aG docker "$USER"   # log out and back in afterwards
```

Verify with `docker compose version`. The old standalone `docker-compose` v1 binary is not
supported — the scripts call `docker compose`.

## Setup

```bash
git clone https://github.com/HatboyWonder/PiMediaServer.git
cd PiMediaServer/docker-compose

cp .env-template .env
$EDITOR .env          # set DATA_PATH, CONFIG_PATH, PUID, PGID, TZ, COMPOSE_PROFILES

./setup.sh            # creates the folder layout and checks it
./start.sh
```

`setup.sh` only creates directories for the profiles you enabled, and warns about the two things
that are easy to get wrong: a `DATA_PATH` spanning multiple filesystems, and wrong ownership.

## Day to day

All scripts live in `docker-compose/` and work from any directory:

| Script | Action |
| --- | --- |
| `./start.sh` | Start everything in the enabled profiles |
| `./down.sh` | Stop and remove the containers |
| `./restart.sh` | Restart the running containers |
| `./upgrade.sh` | Pull newer images and recreate the containers |
| `./setup.sh` | Re-create missing directories, e.g. after enabling a profile |

Changing `COMPOSE_PROFILES` needs `./setup.sh && ./start.sh`; `--remove-orphans` takes care of
containers whose profile you disabled.

## Post-install configuration

Containers reach each other by service name on the compose network, so the hostnames below are
literal. The exception is Plex, which runs with `network_mode: host` and must be addressed by the
Pi's IP address.

**1. Prowlarr** (`:9696`)
* Add your indexers.
* With the `flaresolverr` profile: Settings > Indexers > add a FlareSolverr proxy at
  `http://flaresolverr:8191`, and tag the indexers that need it.
* Settings > Apps: add Sonarr (`http://sonarr:8989`) and Radarr (`http://radarr:7878`) with their
  API keys. Indexers then sync automatically instead of being configured twice.

**2. Download client** (`:9091`)
* `transmission`: set the download directory to `/data/torrents/complete` and the incomplete
  directory to `/data/torrents/incomplete`.
* `transmission-openvpn`: already configured through environment variables, nothing to do.

**3. Sonarr** (`:8989`) and **Radarr** (`:7878`)
* Settings > Download Clients: add Transmission, host `transmission` or `transmission-openvpn`,
  port 9091.
* Leave remote path mapping empty. The download client and the *arrs agree on `/data/...`, which
  is the whole reason for the layout above.
* Settings > Media Management: add the root folder `/data/media/tv` (Sonarr) or
  `/data/media/movies` (Radarr).

**4. Media server**
* Jellyfin (`:8096`): add libraries pointing at `/data/movies` and `/data/tvshows`.
* Plex (`:32400`): add libraries pointing at `/movies` and `/tv`. To claim a new server, put a
  token from [plex.tv/claim](https://plex.tv/claim) into `PLEX_CLAIM` and restart within four
  minutes, then clear it again.

**5. Seerr** (`:5055`)
* Connect it to Jellyfin (`http://jellyfin:8096`) or Plex (`http://<pi-ip>:32400`), then to Sonarr
  and Radarr with the same URLs as in step 1.

## Migrating from an older checkout

* The Seerr config directory was `$CONFIG_PATH/seer`, now correctly `$CONFIG_PATH/seerr`. Rename
  it before starting, otherwise Seerr comes up unconfigured:
  `mv "$CONFIG_PATH/seer" "$CONFIG_PATH/seerr"`.
* Transmission's watch directory moved from `$DATA_PATH/torrents` to `$DATA_PATH/watch`. It used
  to watch its own download directory and re-add the `.torrent` files it wrote there.
* `TZ`, `PUID` and `PGID` come from `.env` now instead of being hardcoded to `Europe/London` and
  `1000`.
* Seerr and FlareSolverr have profiles now and no longer start unless listed in
  `COMPOSE_PROFILES`.
