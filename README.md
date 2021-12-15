# HIP Frontend
## Meta package for NextCloud, HIP web app and gateway API

Includes 
- Nextcloud
- Nextcloud cron instance, with file watcher
- 
## Deploy

To install the frontend
- Login to the HIP registry `docker login to registry.hbp.link`
- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- Run the `./init.sh`, wait for the db to be installed then `^C`
- Launch `./start.sh`