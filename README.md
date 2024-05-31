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

- Ubuntu 22.04
- A Keycloak instance
  - as in https://github.com/HIP-infrastructure/keycloak
  - as well as the collab backend `install_keycloak_backend.sh`
- Nextcloud 24.0.x installed, as in [Nextcloud install](https://github.com/HIP-infrastructure/nextcloud-docker)
- Configured Nextcloud for the HIP: [NextcloudConfig.md)](NextcloudConfig.md)

## Deploy, production

- Clone this repo, `git clone --recurse-submodules https://github.com/HIP-infrastructure/frontend.git`
- `cd frontend`
- `git checkout master`
- You can checkout the submodules to the desired branch, default is the latest version
- Copy `.env.template` to `.env` and edit the variables according to your needs.

### First time install

- install all the dependencies by calling
- `./hip-required_ubuntu-22.04.sh`
- You might want to logout and login again, in order to gain access to the docker command for your current user

#### GhostFS

- a distributed file system tailored to the HIP
- `make install-ghostfs`
- You will need to provide a user/password for the server, that you will need to install on the [backend](https://github.com/HIP-infrastructure/app-in-browser#configuring-app-in-browser))
- pm2 cannot start ghostfs at this time, as Nextcloud data storage doesn't exist yet. A pm2 error for the service is ok at this time.

#### Nextcloud

if you want to migrate an existing install to a new location, here are a few tips [Nextcloud-migration.md](https://github.com/HIP-infrastructure/frontend/blob/master/Nextcloud-Migration.md)

Create a folder named secrets and add the following txt files to `nextcloud-docker/secrets` :
- nextcloud_admin_password.txt # put admin password to this file
- nextcloud_admin_user.txt # put admin username to this file
- postgres_db.txt # put postgresql db name to this file
- postgres_password.txt # put postgresql password to this file
- postgres_user.txt # put postgresql username to this file

- `make install-nextcloud` Nextcloud will fail. Don't bother
- Once Nextcloud is installed, we need to replace the created php-settings by our own in order to parametrize it for docker etc.
  - `sudo rm -rf /mnt/nextcloud-dp/php-settings`
  - `sudo cp -r php-settings /mnt/nextcloud-dp`

- `make install-nextcloud` It will fail, again. 
  - `make occ c=maintenance:install`
  - Nextcloud install asks fo a password for admin, use the one provided in secrets in [nextcloud_admin_password.txt]

- Add some params to the Nextcloud php config in  `/mnt/nextcloud-dp/nextcloud/config/config.php`
```
    'htaccess.RewriteBase' => '/',
    'htaccess.IgnoreFrontController' => true,
    'defaultapp' => 'hip',
    'trusted_domains' => ['hip.local'],
```
- `make install`
- Open your browser to your ip or hostname
- Access NextCloud with admin/[nextcloud_admin_password.txt]
- NextCloud could complain about Access through untrusted domain, and in that case, re-add your domain to the `/mnt/nextcloud-dp/nextcloud/config/config.php` file again. This yhould fix it.
- sudo pm2 restart all to restart ghostfs

#### Social-login app, OIDC client, groups
Social login is a Nextcloud app, customized for our need, helping the OIDC login process for users.

- With the current Keycloak setup, you need an EBRAINS account. 
  - Either on production https://iam.ebrains.eu/register or development, https://[iam-provider-url]/register
- Center will be mapped to EBRAINS keycloak groups, we will need to add you there manually on EBRAINS for authorization purposes.
- Create a group for your Center via the NC api.
  - `make occ c="group:add  --display-name CHUV chuv"`

- Open settings under you profile, on the top right.
- Choose "Social Login" under the administration menu, in the left sidebar  
  - [x] Update user profile every login
  - [x] Hide default login
  - [x] Button text without prefix


- Add a Custom OpenID Connect client.

| Key | Value |
| --- | --- |
| Internal name | dev.thehip.app |
| Title | EBRAINS-INT |
| Authorize url | https://[iam-provider-url]/auth/realms/hbp/protocol/openid-connect/auth |
| Token url | https://[iam-provider-url]/auth/realms/hbp/protocol/openid-connect/token |
| Display name claim (optional) | name |
| Username claim (optional) | preferred_username |
| User info URL (optional) | https://[iam-provider-url]/auth/realms/hbp/protocol/openid-connect/userinfo | 
| Client Id | [iam-client_id] | 
| Client Secret | [iam-client_secret] |
| Scope | openid group profile email roles team | 
| Groups claim (optional) | roles.group |

Add group mapping 

| Key | Value |
| --- | --- |
| group-HIP-dev-CHUV | chuv | 

Save everything, logout, and try to login with your EBBRAINS credentials

## Deploy, dev

Change the NODE_ENV to development in the .env file

`make dev-install`

deploy/reload gateway
`make dev-install-gateway`

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


## Acknowledgement

This research was supported by the EBRAINS research infrastructure, funded from the European Union’s Horizon 2020 Framework Programme for Research and Innovation under the Specific Grant Agreement No. 945539 (Human Brain Project SGA3).
