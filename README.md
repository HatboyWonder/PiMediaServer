# PI Media Server

This project provides a single `docker-compose` file which sets up a whole media server including the right file path setup. The server is composed of 4 services:

* [Plex](https://www.plex.tv/): Media server which is the frontend for showing the shows and movies. It can be exposed externally and shared with others very easily. 

* [Sonarr](https://github.com/Sonarr/Sonarr): "Sonarr is a PVR for Usenet and BitTorrent users. It can monitor multiple RSS feeds for new episodes of your favorite shows and will grab, sort and rename them. It can also be configured to automatically upgrade the quality of files already downloaded when a better quality format becomes available".

* [Radarr](https://github.com/Radarr/Radarr): Same as `Sonarr` but for movies.

* [Jackett](https://github.com/Jackett/Jackett): "Jackett works as a proxy server: it translates queries from apps (Sonarr, Radarr, SickRage, CouchPotato, Mylar, Lidarr, DuckieTV, qBittorrent, Nefarious etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software. This allows for getting recent uploads (like RSS) and performing searches. Jackett is a single repository of maintained indexer scraping & translation logic - removing the burden from other apps."

* [Deluge](https://github.com/deluge-torrent/deluge): "Deluge is a BitTorrent client that utilizes a daemon/client model. It has various user interfaces available such as the GTK-UI, Web-UI and a Console-UI. It uses libtorrent at it's core to handle the BitTorrent protocol."

## Prerequisites
Installing docker on the raspberry pi should be as simple as calling:
```
curl -sSL https://get.docker.com | sh
```

To install `docker-compose` on raspberry pi the easiest way is to install [pip](https://www.raspberrypi.org/documentation/linux/software/python.md) and then call:
```
pip install docker-compose
```

For other operating systems the installation should be straight forward.

## Running it
With `docker-compose` installed it is as simple as calling
```
docker-compose up -d
```

## Setup
With all containers running there is some more configuration tasks to do. Starting bottom up:

1. Navigate to the `Jackett` web interface ([localhost:9117](localhost:9117)). Search and add your favourite to you indexer list.

2. Navigate to the `Deluge` web interface ([localhost:8112](localhost:8112)). Set the download directory to `/downloads`. Activate the `Label` and `Extractor` plugins. Also download the `AutoRemovePlus` plugin from [here](https://github.com/omaralvarez/deluge-autoremoveplus) and install it. This will remove completed downloads from the torrent location.

3. Navigate to the `Sonarr` and/or `Radarr` web interface. Go to the Settings page. Now configure your indexers to point to the `Jackett` indexer urls and setup the download client.

4. Navigate to the `Plex` web interface ([localhost:32400](localhost:32400)). Setup your libraries, pointing them to the ones configured in the `docker-compose`.

5. Enjoy!