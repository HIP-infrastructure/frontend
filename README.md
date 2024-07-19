# HIP Frontend
## Meta package for HIP web app and gateway API
This is the install for the HIP frontend

Includes 
- Web app [hip](https://github.com/HIP-infrastructure/hip)
- Gateway [gateway](https://github.com/HIP-infrastructure/gateway)

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

#### Post-install
- Enable the `Group folders` app via the administration panel or occ CLI.

## Deploy, dev

Change the NODE_ENV to development in the .env file

`make dev-install`

deploy/reload gateway
`make dev-install-gateway`


Quick summary for make (after install)
```
install-ghostfs                Stop, update and install GhostFS only
status                         Show the status of the HIP
install-web                    Build & install the webapp and the gateway
start                          Start all services (-GhostFS)
stop                           Stop all services (-GhostFS)
maintenance                    Enable/disable maintenance mode (make maintenance-on/maintenance-off)
dc                             Run docker-compose (make dc c="ps")
dev-install                    Install dev stack for frontend & gateway, use update branch=dev to switch branch, you should have NODE_ENV=development
dev-install-gateway            Restart the dev gateway
help                           List available tasks on this project
```



