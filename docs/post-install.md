# Post-Install Configuration Guide

After running `scripts/setup.sh` and `scripts/start.sh`, the individual services need to be configured to talk to each other. Follow these steps from the bottom of the stack upward.

---

## 1. Prowlarr — Indexer Manager (port 9696)

Prowlarr is the central hub for torrent indexers. Configure it first so Sonarr and Radarr inherit indexers automatically.

1. Open `http://<host>:9696` and complete the initial setup wizard (create an admin account).
2. Go to **Indexers** → **Add Indexer** and search for your preferred public or private torrent indexers. Add as many as you like.
3. Go to **Settings → Apps** and add Sonarr and Radarr as applications:
   - **Sonarr**: server `http://sonarr:8989`, API key from Sonarr's Settings → General
   - **Radarr**: server `http://radarr:7878`, API key from Radarr's Settings → General
4. Click **Sync App Indexers** — Prowlarr will push all configured indexers to both apps immediately.

---

## 2. Sonarr — TV Show PVR (port 8989)

1. Open `http://<host>:8989`.
2. **Settings → Media Management**
   - Enable **Rename Episodes** (recommended).
   - Set the root folder for TV shows to `/data/media/tv`.
3. **Settings → Download Clients** → Add → Transmission:
   - Host: `transmission` (resolved via Docker network)
   - Port: `9091`
   - Category: `tv`
   - Remote Path Mapping:
     - Host: `transmission`
     - Remote Path: `/data/torrents`
     - Local Path: `/data/torrents`
4. **Settings → Indexers** — these should already be populated by Prowlarr (step 1). Verify.
5. **Settings → General** — note the API key (needed for Prowlarr and any request management tool).

---

## 3. Radarr — Movie PVR (port 7878)

Same steps as Sonarr with movie-specific values:

1. Open `http://<host>:7878`.
2. **Settings → Media Management**
   - Enable **Rename Movies** (recommended).
   - Set the root folder for movies to `/data/media/movies`.
3. **Settings → Download Clients** → Add → Transmission:
   - Host: `transmission`
   - Port: `9091`
   - Category: `movies`
   - Remote Path Mapping:
     - Host: `transmission`
     - Remote Path: `/data/torrents`
     - Local Path: `/data/torrents`
4. **Settings → Indexers** — verify indexers were synced from Prowlarr.
5. **Settings → General** — note the API key.

---

## 4. Transmission — Download Client (port 9091)

Transmission requires no manual configuration to function. Sonarr and Radarr will submit downloads directly via its RPC API.

Optionally:
- Open `http://<host>:9091` to monitor active downloads.
- Drop `.torrent` files into `$DATA_PATH/torrents/watch/` for automatic import.

---

## 5. Plex Media Server (host network, port 32400)

> Plex uses `network_mode: host`, so it is only accessible via the host IP, not the Docker service name.

1. Open `http://<host>:32400/web`.
2. Sign in with your Plex account (required for remote access and sharing).
3. Add libraries:
   - **Movies** — folder: `/data/movies`
   - **TV Shows** — folder: `/data/tv`
4. Plex will scan and match your media automatically.

To enable remote access and share with others, go to **Settings → Remote Access** and follow the instructions.

---

## 5 (alt). Jellyfin (port 8096)

> Use this section if you activated the `jellyfin` profile instead of `plex`.

1. Open `http://<host>:8096`.
2. Complete the first-run wizard (create a local admin account — no external account required).
3. Add media libraries:
   - **Movies** — folder: `/data/movies`
   - **TV Shows** — folder: `/data/tv`
4. Jellyfin will scan and match your media automatically.

---

## Using OpenVPN with Transmission

If you activated the `transmission-openvpn` profile instead of `transmission`, the setup steps for Sonarr and Radarr are identical. The only differences:

- Ensure `OPENVPN_PROVIDER`, `OPENVPN_CONFIG`, `OPENVPN_USERNAME`, and `OPENVPN_PASSWORD` are set in `docker-compose/.env`.
- The container requires `NET_ADMIN` capability (already set in the compose file).
- Supported providers: https://haugene.github.io/docker-transmission-openvpn/supported-providers/
- Logs from the OpenVPN container can be verbose; they are capped at 10 MB via the `json-file` log driver.

---

## Verifying the Pipeline End-to-End

1. In Sonarr, search for a TV show → Add it → trigger a manual search.
2. Sonarr should find results via Prowlarr indexers and push the torrent to Transmission.
3. Transmission downloads the file to `$DATA_PATH/torrents/`.
4. Sonarr detects the completed download, moves/hardlinks the file to `$DATA_PATH/media/tv/`, and renames it.
5. Plex or Jellyfin detects the new file (via scheduled scan or inotify) and adds it to the library.
6. Stream from Plex/Jellyfin.
