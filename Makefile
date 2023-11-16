# SHELL=/bin/bash

# Make available environment variables defined in .env file
include .env
export

.DEFAULT_GOAL := help

DC=docker compose --env-file ./.env -f docker-compose.yml
OCC=docker compose exec --user www-data cron php occ

require:
	@echo "Checking the programs required for the build are installed..."
	@make --version >/dev/null 2>&1 || (echo -e "\033[31mERROR: make is required. (sudo apt install -y build-essential)"; exit 1)
	./hip-required_ubuntu-22.04.sh

pm2: 
	sudo pm2 start pm2/ecosystem.config.js
	sudo pm2 save
	sudo pm2 startup
	sudo systemctl start pm2-root
	sudo systemctl enable pm2-root

#install: Install the latest HIP. Without GhostFS 
install: require stop install-web build-datahipy pm2

#install-ghostfs: @ Stop, update and install GhostFS only
install-ghostfs: require
	cd pm2 && npm i && cd ..
	echo "AUTH_BACKEND_DOMAIN=${REMOTE_APP_API}" > ghostfs/auth_backend/auth_backend.env      
	sudo pm2 stop pm2/ecosystem.ghostfs.config.js
	bash ./install_ghostfs.sh
	$(DC) restart cron
	sudo pm2 start pm2/ecosystem.ghostfs.config.js
	sudo pm2 save

#status: @ Show the status of the HIP
status:
	@echo "\n"
	sudo pm2 status
	docker-compose ps
	@echo "\n"
	@echo "**** NODE_ENV=$(NODE_ENV) ****"

logs:
	sudo pm2 logs $(n)

build-datahipy:
	docker login $(GL_REGISTRY) -u $(GL_USER) -p $(GL_TOKEN)
	docker pull $(GL_REGISTRY)/$(DataHIPy_IMAGE):$(DataHIPy_VERSION)
	docker logout

build-web:
	cp .env gateway/.env
	make -C gateway build
	make -C hip build
	sudo pm2 start pm2/ecosystem.config.js
	sudo pm2 restart gateway
	sudo pm2 status

#install-web: @ Build & install the webapp and the gateway
install-web: maintenance-on build-web install-hipapp maintenance-off

build-ui:
	make -C hip build

install-ui: build-web install-hipapp

install-gateway:
	cp .env gateway/.env
	make -C gateway build

	pm2 restart gateway || true
	pm2 status

#start: @ Start all services (-GhostFS)
start:
	$(DC) up -d
	sudo pm2 start pm2/ecosystem.config.js

#stop: @ Stop all services (-GhostFS)
stop: dev-stop
	$(DC) stop
	sudo pm2 stop pm2/ecosystem.config.js

install-hipapp:
	$(OCC) app:disable hip
	sudo rm -rf $(NC_APP_FOLDER)/hip
	sudo mkdir $(NC_APP_FOLDER)/hip
	sudo tar -zxvf hip/release.tar.gz -C $(NC_APP_FOLDER)/hip
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)
	$(OCC) app:enable hip

## Utils

#maintenance: @ Enable/disable maintenance mode (make maintenance-on/maintenance-off)	
maintenance-%:
	$(OCC) maintenance:mode --$(@:maintenance-%=%)

#dc: @ Run docker-compose (make dc c="ps")
dc:
	$(DC) -f docker-compose-dev.yml $(c)

sleep-%:
	sleep $(@:sleep-%=%)

## Dev

dev-build: build-datahipy
	$(DC) build cron
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R www-data:www-data /var/www/html
	$(DC) -f docker-compose-dev.yml build --no-cache hip

#dev-install: @ Install dev stack for frontend & gateway, use update branch=dev to switch branch, you should have NODE_ENV=development
dev-install: stop dev-stop dev-stop-gateway dev-build dev-up sleep-5 dev-hipapp
	sudo pm2 start pm2/ecosystem.dev.config.js
	[ -f ../app-in-browser/scripts/installbackend.sh ] && (cd ../app-in-browser; ./scripts/installbackend.sh && cd ../frontend) || true
	cp .env gateway/.env
	@echo "**** NODE_ENV=$(NODE_ENV) ****"
	@echo WARNING you should have NODE_ENV=development in your .env file
	make -C gateway deploy.dev

#dev-install-gateway: @ Restart the dev gateway
dev-install-gateway: dev-stop-gateway sleep-5
	cp .env gateway/.env
	make -C gateway deploy.dev

dev-install-frontend:
	$(DC) -f docker-compose-dev.yml build --no-cache hip
	$(DC) -f docker-compose-dev.yml stop hip
	$(DC) -f docker-compose-dev.yml start hip

dev-stop-gateway:
	./stop_gateway.sh

dev-stop: dev-stop-gateway
	$(DC) -f docker-compose-dev.yml -f docker-compose-dev.yml stop
	sudo pm2 stop pm2/ecosystem.dev.config.js

dev-up:
	$(DC) -f docker-compose-dev.yml -f docker-compose-dev.yml up -d

dev-hipapp:
	sudo mkdir -p $(NC_APP_FOLDER)/hip/templates
	sudo cp -rf ./hip/appinfo $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/lib $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/img $(NC_APP_FOLDER)/hip
	sudo cp -f ./hip/templates/index.dev.php $(NC_APP_FOLDER)/hip/templates/index.php
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)/hip

#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(firstword $(MAKEFILE_LIST)) | tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

