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
- Ubuntu 20.04
- Make sure you have [docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04) and docker-compose installed
- Install `make`: `sudo apt install build-essential`

## Deploy, production
- Clone this repo, `git clone --recurse-submodules https://github.com/HIP-infrastructure/frontend.git`
- `cd frontend`
- `git checkout master`
- Copy `.env.template` to `.env` and edit the variables according to your needs.
- if you are installing with make install, NODE_ENV=production, with make dev-install NODE_ENV=developement
- If on a local domain, add a choosen local domain name to your `/etc/hosts`
  - your_ip   hip.local

The first time, you have also to install Nextcloud. 

`cp nextcloud-docker/Caddyfile.template caddy/Caddyfile`
- Edit and add your domain name

Create a folder named secrets and add the following txt files to `nextcloud-docker/secrets` :
- nextcloud_admin_password.txt # put admin password to this file
- nextcloud_admin_user.txt # put admin username to this file
- postgres_db.txt # put postgresql db name to this file
- postgres_password.txt # put postgresql password to this file
- postgres_user.txt # put postgresql username to this file

- `make install` It will fail.
- Once Nextcloud is installed, we need to replace the created php-settings by our own in order to parametrize it for docker etc.
  - `sudo rm -rf /mnt/nextcloud-dp/php-settings`
  - `sudo cp -r php-settings /mnt/nextcloud-dp`
  - `make occ c=maintenance:install`
- Add some params to the Nextcloud php config in  `/mnt/nextcloud-dp/nextcloud/config/config.php`
    ```
    'htaccess.RewriteBase' => '/',    
    'htaccess.IgnoreFrontController' => true,     
    'defaultapp' => 'hip'  
    ```  

  if you are local instance with self-signe SSL, add
```
  'trusted_domains' => ['hip.local'],

```
- `make install` again
- Open your browser to your ip or hostname

- next steps:
  - Configure sociallogin

to stop 
`make stop`

help:
  `make`


## Deploy, dev

Change the NODE_ENV to development in the .env file

`make dev-update branch=dev`
`make dev-install`

deploy/reload gateway
`make dev-install-gateway`

## Deploy a specific branch in production

Change the NODE_ENV to production in the .env file

`make dev-update branch=dev`
`make install-current-branch`


Quick summary for make (after install)
```
install                        * USE THIS ONE * Stop, update, build and install the latest HIP, without GhostFS 
install-ghostfs                Stop, update and install GhostFS only
status                         Show the status of the HIP
install-web                    Build & install only the gateway, bids-tools and the webapp
start                          Start all services (-GhostFS)
stop                           Stop all services (-GhostFS)
maintenance                    Enable/disable maintenance mode (make maintenance-on/maintenance-off)
nextcloud-repair               Attempt to repair NextCloud
nextcloud-upgrade              Upgrade NextCloud
nextcloud-dump                 Dump the current NextCloud DB (Postgres)
dev-update                     Pull and update git submodules to a given branch eg. dev-update branch=dev
dev-install                    Install dev stack for frontend & gateway, use dev-update branch=dev to switch branch, you should have NODE_ENV=development
dev-install-gateway            Restart the dev gateway
help                           List available tasks on this project
```



