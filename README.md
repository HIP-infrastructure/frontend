# HIP Frontend
## Meta package for NextCloud, HIP web app and gateway API
This is the frontend install for the HIP frontend

Includes 
- Nextcloud install [nextcloud-docker](https://github.com/HIP-infrastructure/nextcloud-docker)
- Nextcloud HIP app [hip](https://github.com/HIP-infrastructure/hip)
- HIP Gateway [gateway](https://github.com/HIP-infrastructure/gateway)
## Deploy, production

### Prerequisite
- Make sure you have [docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04) and docker-compose installed
- Login to the HIP registry `docker login registry.hbp.link`


To install the frontend
- Clone this repository
- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Add the following line to the nextcloud-docker/caddy/Caddyfile 
```
    handle /api/v1/* {
        reverse_proxy gateway:4000
    }
```
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- Run the `./init.sh`, wait for the db to be installed then `^C`
- Nextcloud:
    - Start from scratch by configuring Nextcloud correctly 
    - Or
    - Copy the installation files from a previous installation. 
      - `php-settings` to `/mnt/nextcloud-dp/`
      - `nextcloud` to `/mnt/nextcould-dp`
- sudo chown -R www-data:root /mnt/nextcloud-dp/
- Launch `./start.sh`
- Open your browser to your ip or hostname

## Dev
To install the frontend in development mode
- `checkout dev`
- `cd hip && checkout dev && cd ..`
- `cd gateway && checkout dev && cd ..`
- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- Change the hostname in Caddyfile.dev to your hostname
- Run the `./init.dev.sh`, wait for the db to be installed then `^C`
- Launch `./start.dev.sh`
- wait a bit
- Launch `./stop.dev.sh`
- `sudo rm -rf /mnt/nextcloud-dp/php-settings`
- `sudo cp -r  php-settings /mnt/nextcloud-dp`
- Launch `./start.dev.sh`
- Point you browser to your ${HOSTNAME}
- Login with the nextcloud-docker/secrets/ user & password
- Go in apps -> disabled apps -> enable untested app -> HIP


Side note, reinstall dev
./down.dev.sh
sudo rm -rf nextcloud-docker/caddy/caddy_data/ nextcloud-docker/db
sudo rm -rf /mnt/nexcloud-dp
