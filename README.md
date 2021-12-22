# HIP Frontend
## Meta package for NextCloud, HIP web app and gateway API
This is the frontend install for the HIP frontend

Includes 
- Nextcloud install [nextcloud-docker](https://github.com/HIP-infrastructure/nextcloud-docker)
- Nextcloud HIP app [hip](https://github.com/HIP-infrastructure/hip)
- HIP Gateway [gateway](https://github.com/HIP-infrastructure/gateway)
## Deploy
To install the frontend
- Clone this repository
- Make sure you have [docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04) and docker-compose installed
- Login to the HIP registry `docker login registry.hbp.link`
- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Add the following line to the nextcloud-docker/caddy/Caddyfile 
```
    handle /api/v1/* {
        reverse_proxy gateway:4000
    }
```
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- Run the `./init.sh`, wait for the db to be installed then `^C`
- Launch `./start.sh`
- Open your browser to your ip or hostname

## Dev
To install the frontend
- Login to the HIP registry `docker login registry.hbp.link`
- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- Run the `./init.sh`, wait for the db to be installed then `^C`
- Launch `./start-dev.sh up -d`