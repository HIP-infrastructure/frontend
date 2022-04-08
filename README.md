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
- Run `./start.sh`, this starts the Nextcloud stack, the frontend and the gateway
- Wait a bit
- Run `./stop.sh`
- Once Nextcloud is installed, we need to replace the created php-settings by our own in order to parametrize it for docker etc.
  - `sudo rm -rf /mnt/nextcloud-dp/php-settings`
  - `sudo cp -r php-settings /mnt/nextcloud-dp`
- Re run `./start.sh`
- Add some params to the Nextcloud php config
    'htaccess.RewriteBase' => '/',
    'htaccess.IgnoreFrontController' => true, 
    in  `/mnt/nextcloud-dp/nextcloud/config/config.php`
- Open your browser to your ip or hostname

## Dev
To install the frontend in development mode
- Clone this repo, 
- `cd frontend`
- `git checkout dev`
- `git submodule update --recursive --init`
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- add your ${HOSTNAME} to `/etc/hosts`, like `127.0.0.1 hip.local`
- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Change the hostname in Caddyfile.dev to your ${HOSTNAME}
- cp Caddyfile.dev ./nextcloud-docker/caddy/Caddyfile
- Run the `./init.sh`, wait for the db to be installed then `^C`
- Run `./start.dev.sh`, this starts the Nextcloud stack, the frontend and the gateway
- Wait a bit
- Run `./stop.dev.sh`
- Once Nextcloud is installed, we need to replace the created php-settings by our own in order to parametrize it for docker etc.
  - `sudo rm -rf /mnt/nextcloud-dp/php-settings`
  - `sudo cp -r php-settings /mnt/nextcloud-dp`
- Re run `./start.dev.sh`
- Add some params to the Nextcloud php config
    'htaccess.RewriteBase' => '/',
    'htaccess.IgnoreFrontController' => true, 
    on top of the array in  `/mnt/nextcloud-dp/nextcloud/config/config.php`
- Point you browser to your ${HOSTNAME}
- Login with the nextcloud-docker/secrets/ user & password
- Go in apps -> disabled apps -> enable untested app -> HIP


Side note, reinstall dev
./down.dev.sh  
sudo rm -rf nextcloud-docker/caddy/caddy_data/ nextcloud-docker/db  
sudo rm -rf /mnt/nexcloud-dp  
