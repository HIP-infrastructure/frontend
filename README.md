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
- `git checkout master`
- Copy `.env.template` to `.env` and edit the variables according to your needs.

The first time, you have also to install Nextcloud. 

- Follow the first 3 steps in [Nextcloud Install](./nextcloud-docker/README.md)
- In the nextcloud-docker folder, run `./init.sh`, wait for the db to be installed then `^C`
- Once Nextcloud is installed, we need to replace the created php-settings by our own in order to parametrize it for docker etc.
  - `make stop`
  - `sudo rm -rf /mnt/nextcloud-dp/php-settings`
  - `sudo cp -r php-settings /mnt/nextcloud-dp`
- Add some params to the Nextcloud php config in  `/mnt/nextcloud-dp/nextcloud/config/config.php`
    ```
    'htaccess.RewriteBase' => '/',    
    'htaccess.IgnoreFrontController' => true,     
    'defaultapp' => 'hip'  
    ```  
- `make install`
- Open your browser to your ip or hostname

to stop 
`make stop`

help:
  `make`

```
install                        ** USE THIS ONE ** Stop, update, build and install the latest HIP, without GhostFS 
install-ghostfs                Stop, update and install GhostFS only
status                         Show the status of the HIP
install-web                    Build & nnstall only the gateway, bids-tools and the webapp
start                          Start all services (-GhostFS)
stop                           Stop all services (-GhostFS)
maintenance                    Enable/disable maintenance mode (make maintenance-on/maintenance-off)
nextcloud-repair               Attempt to repair NextCloud
nextcloud-upgrade              Upgrade NextCloud
nextcloud-dump                 Dump the current NextCloud DB (Postgres)
dev-install                    Install dev stack for frontend & gateway, use dev-update branch=dev to switch branch, you should have NODE_ENV=development
dev-restart-gateway            Restart the dev gateway
help                           List available tasks on this project

```
## Deploy, dev
dev:
`make dev-install`

## Deploy a specific branch in production
`make dev-update branch=dev`
`make install-current-branch`




