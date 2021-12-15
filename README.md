# HIP Frontend
## Meta package for NextCloud, HIP web app and gateway API
This is the frontend install for the HIP frontend

Includes 
- Nextcloud install [nextcloud-docker](https://github.com/HIP-infrastructure/nextcloud-docker)
- Nextcloud HIP app [hip](https://github.com/HIP-infrastructure/hip)
- HIP Gateway [gateway](https://github.com/HIP-infrastructure/gateway)
## Deploy

To install the frontend
- Login to the HIP registry `docker login to registry.hbp.link`
- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- Run the `./init.sh`, wait for the db to be installed then `^C`
- Launch `./start.sh`