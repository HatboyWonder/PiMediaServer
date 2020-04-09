# PI Media Server

This project provides a single `docker-compose` file which sets up a whole media server including the right file path setup. The server is composed of 5 services:

* [Plex](https://www.plex.tv/): Media server which is the frontend for showing the shows and movies. It can be exposed externally and shared with others very easily. 

* [Sonarr](https://github.com/Sonarr/Sonarr): "Sonarr is a PVR for Usenet and BitTorrent users. It can monitor multiple RSS feeds for new episodes of your favorite shows and will grab, sort and rename them. It can also be configured to automatically upgrade the quality of files already downloaded when a better quality format becomes available".

* [Radarr](https://github.com/Radarr/Radarr): Same as `Sonarr` but for movies.

* [Jackett](https://github.com/Jackett/Jackett): "Jackett works as a proxy server: it translates queries from apps (Sonarr, Radarr, SickRage, CouchPotato, Mylar, Lidarr, DuckieTV, qBittorrent, Nefarious etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software. This allows for getting recent uploads (like RSS) and performing searches. Jackett is a single repository of maintained indexer scraping & translation logic - removing the burden from other apps."

* [Ombi](https://github.com/tidusjar/Ombi): Request movies or shows on `Radarr` or `Sonarr` via a single interface.

* [Transmission](https://github.com/transmission/transmission): "Uses fewer resources than other clients. Daemon ideal for servers, embedded systems, and headless use."

## Prerequisites

### Software
Installing docker on the raspberry pi should be as simple as calling:
```
curl -sSL https://get.docker.com | sh
```

To install `docker-compose` on raspberry pi the easiest way is to install [pip](https://www.raspberrypi.org/documentation/linux/software/python.md) and then call:
```
pip install docker-compose
```

For other operating systems the installation should be straight forward.

### Data location
The location where you store your data has to be handled with care in order for everything to function properly. Many docker images suggest a different approach which is most of the time simply wrong. Therefore the following file hierarchy is suggested:

```
# root folder for sonarr as it needs to be able to see both /torrents and /media

# somewhere on SSD or storage where I/O does not hurt as much
configs
    /plex
    /sonarr
    /radarr
    /jackett
    /transmission
data
    # location for the actual media. moved here by sonarr and consumed by plex
    /media
        /tv
        /movies

    # location for download client. this must be also visible to sonarr, 
    # as it picks up the files from there and moves them to the media folder
    /torrents
```

Create the folder structure in the same directory as the `docker-compose` file
```
mkdir -p configs/{plex,sonarr,radarr,jackett,transmission,ombi} data/{media/{tv,movies},torrents}
```

## Running it
With `docker-compose` installing it is as simple as calling
```
docker-compose up -f docker-compose.yaml -f docker-compose.transmission.yml -d
```

To include `Ombi`, instead call
```
docker-compose -f docker-compose.yml -f docker-compose.transmission.yml -f docker-compose.ombi.yml up -d
```

## Setup
With all containers running there is some more configuration tasks to do. Starting bottom up:

1. Navigate to the `Jackett` web interface (port: 9117). 
    * Search and add your favourite indexers to your indexer list.

2. Navigate to the `Sonarr` (port: 8989) and/or `Radarr` (port: 7878) web interface. 
    * Go to the Settings page. 
    * Configure your indexers to point to the `Jackett` indexer urls.
    * Setup the download client.
        * Add transmission and set Category `tv` (sonarr) or `movies` (radarr).
        * Add Remote Path Mapping
            * Host: transmission url
            * Remote Path: `/downloads`
            * Local Path: `/data/torrents/`
    * Add default paths (Add new series/movie > Search > Add different path)
        * Sonarr: `/data/media/tv`
        * Radarr: `/data/media/movies`
        
3. Navigate to the `Plex` web interface (port: 32400). 
    * Setup your libraries, pointing them to the ones configured in the `docker-compose`.

4. If `Ombi` is included, navigate to the `Ombi` web interface (port: 3579).
    * Go to the Settings page.
    * Configure `Plex` (Media Server > Plex).
    * Configure `Sonarr` (TV > Sonarr).
    * Configure `Radarr` (Movies > Radarr).

5. Enjoy!
