# SHELL=/bin/bash

# Make available environment variables defined in .env file
include .env
export

.DEFAULT_GOAL := help

DC=docker compose --env-file ./.env -f docker-compose.yml
OCC=docker exec --user www-data cron php occ

.PHONY: require
require:
	@echo "Checking the programs required for the build are installed..."
	@make --version >/dev/null 2>&1 || (echo -e "\033[31mERROR: make is required. (sudo apt install -y build-essential)"; exit 1)
	./hip-required_ubuntu-22.04.sh

.PHONY: pm2
pm2:
	sudo pm2 start pm2/ecosystem.config.js
	sudo pm2 save
	sudo pm2 startup
	sudo systemctl start pm2-root || true
	sudo systemctl enable pm2-root || true

.PHONY: install
#install: Install the latest HIP. Without GhostFS 
install: require stop install-web build-datahipy pm2

.PHONY: install-ghostfs
#install-ghostfs: @ Stop, update and install GhostFS only
install-ghostfs: require
	cd pm2 && npm i && cd ..
	echo "AUTH_BACKEND_DOMAIN=${REMOTE_APP_API}" > ghostfs/auth_backend/auth_backend.env
	sudo pm2 stop pm2/ecosystem.ghostfs.config.js
	bash ./install_ghostfs.sh
	sudo pm2 start pm2/ecosystem.ghostfs.config.js
	sudo pm2 save

.PHONY: status
#status: @ Show the status of the HIP
status:
	@echo "\n"
	sudo pm2 status
	docker-compose ps
	@echo "\n"
	@echo "**** NODE_ENV=$(NODE_ENV) ****"

.PHONY: logs
logs:
	sudo pm2 logs $(n)

.PHONY: pm2-install
pm2-install:
	sudo npm i -g pm2
	cd pm2 && npm i && cd ..

.PHONY: build
build: pm2-install build-datahipy
	$(DC) build cron
	sudo chown root:root nextcloud-docker/crontab
	make -C nextcloud-social-login build
	cp .env gateway/.env
	sudo make -C gateway build
	sudo make -C hip build
	# TODO echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p

.PHONY: build-datahipy
build-datahipy:
	docker pull $(GL_REGISTRY)/$(DataHIPy_IMAGE):$(DataHIPy_VERSION)

.PHONY: build-web
build-web:
	$(DC) up -d
	cp .env gateway/.env
	make -C gateway build
	make -C hip build
	sudo pm2 start pm2/ecosystem.config.js
	sudo pm2 restart gateway
	sudo pm2 status

.PHONY: install-web
#install-web: @ Build & install the webapp and the gateway
install-web: maintenance-on build-web install-hipapp maintenance-off

.PHONY: build-ui
build-ui:
	make -C hip build

.PHONY: install-ui
install-ui: build-ui install-hipapp

.PHONY: install-gateway
install-gateway:
	$(DC) up -d
	cp .env gateway/.env
	sudo make -C gateway build
	sudo pm2 restart gateway || true
	sudo pm2 status

.PHONY: start
#start: @ Start all services (-GhostFS)
start:
	$(DC) up -d
	sudo pm2 start pm2/ecosystem.config.js

.PHONY: stop
#stop: @ Stop all services (-GhostFS)
stop: pm2-install dev-stop
	$(DC) stop
	sudo pm2 stop pm2/ecosystem.config.js

.PHONY: install-nextcloud
install-nextcloud:
	$(DC) stop
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R www-data:www-data /var/www/html
	sudo rm -rf ${NC_DATA_FOLDER}/core/skeleton
	sudo mkdir -p ${NC_DATA_FOLDER}/core/skeleton
	sudo cp hip/skeleton/* ${NC_DATA_FOLDER}/core/skeleton
	sudo chown -R www-data:www-data ${NC_DATA_FOLDER}/core/skeleton
	$(DC) build cron
	sudo chown root:root nextcloud-docker/crontab
	$(DC) up -d

.PHONY: install-hipapp
install-hipapp:
	$(OCC) app:disable hip
	sudo rm -rf $(NC_APP_FOLDER)/hip
	sudo mkdir $(NC_APP_FOLDER)/hip
	sudo tar -zxvf hip/release.tar.gz -C $(NC_APP_FOLDER)/hip
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)
	$(OCC) app:enable hip

.PHONY: install-socialapp
install-socialapp:
	cd nextcloud-social-login && git checkout hip && cd ..
	sudo rm -rf $(NC_APP_FOLDER)/sociallogin
	sudo cp -r ./nextcloud-social-login $(NC_APP_FOLDER)/sociallogin
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)/sociallogin
	$(OCC) app:enable sociallogin

## Utils

.PHONY: maintenance-%
#maintenance: @ Enable/disable maintenance mode (make maintenance-on/maintenance-off)
maintenance-%:
	$(OCC) maintenance:mode --$(@:maintenance-%=%)

.PHONY: dc
#dc: @ Run docker-compose (make dc c="ps")
dc:
	$(DC) -f docker-compose-dev.yml $(c)

.PHONY: occ
#occ: @ Run occ command (make occ c="status") (make occ c="files:scan --all") etc
occ:
	$(OCC) $(c)

.PHONY: nextcloud-repair
#nextcloud-repair: @ Attempt to repair NextCloud
nextcloud-repair: nextcloud-upgrade
	$(OCC) maintenance:repair
	$(OCC) files:scan --all
	$(OCC) files:cleanup 

.PHONY: nextcloud-upgrade
#nextcloud-upgrade: @ Upgrade NextCloud
nextcloud-upgrade:
	$(OCC) upgrade
	$(OCC) maintenance:mimetype:update-db
	$(OCC) maintenance:mimetype:update-js 
	$(OCC) db:add-missing-columns
	$(OCC) db:add-missing-indices
	$(OCC) db:add-missing-primary-keys

.PHONY: nextcloud-config
nextcloud-config:
	$(OCC) app:enable hip
	$(OCC) app:enable sociallogin
	$(OCC) app:enable groupfolders
	$(OCC) app:enable bruteforcesettings
	$(OCC) app:enable richdocumentscode
	$(OCC) app:enable sharingpath
	$(OCC) app:disable dashboard
	$(OCC) app:disable photos
	$(OCC) app:disable activity
	$(OCC) app:disable forms
	$(OCC) app:disable spreed
	$(OCC) app:disable user_status
	
## Utils

.PHONY: nextcloud-create-groups
nextcloud-create-groups:
	$(OCC) group:add  --display-name CHUV chuv

.PHONY: nextcloud-dump
#nextcloud-dump: @ Dump the current NextCloud DB (Postgres)
nextcloud-dump:
	$(DC) exec db pg_dump -U hipadmin nextcloud_db > $(shell date +%Y%m%d_%H%M%S).dump

.PHONY: sleep-%
sleep-%:
	sleep $(@:sleep-%=%)

## Dev

.PHONY: dev-build
dev-build: build-datahipy
	$(DC) build cron
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R www-data:www-data /var/www/html
	$(DC) -f docker-compose-dev.yml build --no-cache hip

.PHONY: dev-install
#dev-install: @ Install dev stack for frontend & gateway, use update branch=dev to switch branch, you should have NODE_ENV=development
dev-install: stop dev-stop dev-stop-gateway dev-build dev-up sleep-5 dev-hipapp
	sudo pm2 start pm2/ecosystem.dev.config.js
	[ -f ../app-in-browser/scripts/installbackend.sh ] && (cd ../app-in-browser; ./scripts/installbackend.sh && cd ../frontend) || true
	cp .env gateway/.env
	@echo "**** NODE_ENV=$(NODE_ENV) ****"
	@echo WARNING you should have NODE_ENV=development in your .env file
	make -C gateway deploy.dev

.PHONY: dev-install-gateway
#dev-install-gateway: @ Restart the dev gateway
dev-install-gateway: dev-stop-gateway sleep-5
	cp .env gateway/.env
	make -C gateway deploy.dev

.PHONY: dev-install-frontend
dev-install-frontend:
	$(DC) -f docker-compose-dev.yml build --no-cache hip
	$(DC) -f docker-compose-dev.yml stop hip
	$(DC) -f docker-compose-dev.yml start hip

.PHONY: dev-stop-gateway
dev-stop-gateway:
	./stop_gateway.sh

.PHONY: dev-stop
dev-stop: dev-stop-gateway
	$(DC) -f docker-compose-dev.yml stop
	sudo pm2 stop pm2/ecosystem.dev.config.js

.PHONY: dev-up
dev-up:
	$(DC) -f docker-compose-dev.yml up -d

.PHONY: dev-hipapp
dev-hipapp:
	sudo mkdir -p $(NC_APP_FOLDER)/hip/templates
	sudo cp -rf ./hip/appinfo $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/lib $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/img $(NC_APP_FOLDER)/hip
	sudo cp -f ./hip/templates/index.dev.php $(NC_APP_FOLDER)/hip/templates/index.php
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)/hip

.PHONY: dev-socialapp
dev-socialapp:
	# make -C nextcloud-social-login build
	sudo rm -rf $(NC_APP_FOLDER)/sociallogin
	sudo cp -r ./nextcloud-social-login $(NC_APP_FOLDER)/sociallogin
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)/sociallogin

.PHONY: help
#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(firstword $(MAKEFILE_LIST)) | tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
