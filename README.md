# HIP Frontend
## Meta package for NextCloud, HIP web app and gateway API
This is the install for the HIP frontend

Includes 
- Nextcloud install [nextcloud-docker](https://github.com/HIP-infrastructure/nextcloud-docker)
- Nextcloud HIP app [hip](https://github.com/HIP-infrastructure/hip)
- HIP Gateway [gateway](https://github.com/HIP-infrastructure/gateway)
- https://github.com/HIP-infrastructure/bids-converter
- https://github.com/HIP-infrastructure/nextcloud-social-login

The install is based on make and git submodules.
As the package will migrate to K8s, everything is build on the host 

### Prerequisite
- Make sure you have [docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04) and docker-compose installed
- Have make installed as well `sudo apt install build-essential`

## Deploy, production
- Clone this repo, 
- `cd frontend`
- `git checkout dev`
- `git submodule update --recursive --init`
- Copy `.env.template` to `.env` and edit the variables according to your needs.

`make dep.init` the first time
`make deploy `

The first time, you have to install Nextcloud. 


- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- Run the `./init.sh`, wait for the db to be installed then `^C`
- Once Nextcloud is installed, we need to replace the created php-settings by our own in order to parametrize it for docker etc.
  - `make deploy.stop`
  - `sudo rm -rf /mnt/nextcloud-dp/php-settings`
  - `sudo cp -r php-settings /mnt/nextcloud-dp`
- Add some params to the Nextcloud php config
    'htaccess.RewriteBase' => '/',
    'htaccess.IgnoreFrontController' => true, 
    'defaultapp' => 'hip'
    in  `/mnt/nextcloud-dp/nextcloud/config/config.php`
- `make deploy`
- Open your browser to your ip or hostname
- Go in apps -> disabled apps -> enable untested app -> HIP


to stop 
`make deploy.stop`

dev:
`make deploy.dev`
