# SHELL=/bin/bash

# Make available environment variables defined in .env file
include .env
export

.DEFAULT_GOAL := help

DC=docker compose --env-file ./.env -f docker-compose.yml
OCC=docker compose exec --user www-data cron php occ

install-current-branch: stop build install-nextcloud install-web nextcloud-config install-socialapp
	sudo pm2 start pm2/ecosystem.config.js
	sudo pm2 save
	sudo pm2 startup
	sudo systemctl start pm2-root
	sudo systemctl enable pm2-root

#install: Install the latest HIP. Without GhostFS 
install: install-current-branch
	@echo "**** NODE_ENV=$(NODE_ENV) ****"
	@echo WARNING you should have NODE_ENV=production in your .env file

#install-ghostfs: @ Stop, update and install GhostFS only
install-ghostfs:
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

pm2-install: 
	cd pm2 && npm i && cd ..

build: pm2-install build-datahipy
	$(DC) build cron
	sudo chown root:root nextcloud-docker/crontab
	make -C nextcloud-social-login build
	cp .env gateway/.env
	sudo make -C gateway build
	sudo make -C hip build
	# TODO echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p

build-datahipy:
	docker login $(GL_REGISTRY) -u $(GL_USER) -p $(GL_TOKEN)
	docker pull $(GL_REGISTRY)/$(DataHIPy_IMAGE):$(DataHIPy_VERSION)
	docker logout

build-web:
	cp .env gateway/.env
	sudo make -C gateway build
	sudo make -C hip build
	sudo pm2 restart gateway
	sudo pm2 status

#install-web: @ Build & install the webapp and the gateway
install-web: maintenance-on build-web install-hipapp maintenance-off

build-ui:
	sudo make -C hip build

install-ui: build-web install-hipapp

install-gateway:
	cp .env gateway/.env
	sudo make -C gateway build
	sudo pm2 restart gateway
	sudo pm2 status

#start: @ Start all services (-GhostFS)
start:
	$(DC) up -d
	sudo pm2 start pm2/ecosystem.config.js

#stop: @ Stop all services (-GhostFS)
stop: dev-stop
	$(DC) stop
	sudo pm2 stop pm2/ecosystem.config.js

install-nextcloud:
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R www-data:www-data /var/www/html
	sudo rm -rf ${NC_DATA_FOLDER}/core/skeleton
	sudo mkdir -p ${NC_DATA_FOLDER}/core/skeleton
	sudo cp hip/skeleton/* ${NC_DATA_FOLDER}/core/skeleton
	sudo chown -R www-data:www-data ${NC_DATA_FOLDER}/core/skeleton
	$(DC) up -d

install-hipapp:
	$(OCC) app:disable hip
	sudo rm -rf $(NC_APP_FOLDER)/hip
	sudo mkdir $(NC_APP_FOLDER)/hip
	sudo tar -zxvf hip/release.tar.gz -C $(NC_APP_FOLDER)/hip
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)
	$(OCC) app:enable hip

install-socialapp:
	cd nextcloud-social-login && git checkout hip && cd ..
	sudo rm -rf $(NC_APP_FOLDER)/sociallogin
	sudo cp -r ./nextcloud-social-login $(NC_APP_FOLDER)/sociallogin
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)/sociallogin

## Utils

#maintenance: @ Enable/disable maintenance mode (make maintenance-on/maintenance-off)	
maintenance-%:
	$(OCC) maintenance:mode --$(@:maintenance-%=%)

#dc: @ Run docker-compose (make dc c="ps")
dc:
	$(DC) -f docker-compose-dev.yml $(c)

#occ: @ Run occ command (make occ c="status") (make occ c="files:scan --all") etc
occ:
	$(OCC) $(c)

#nextcloud-repair: @ Attempt to repair NextCloud
nextcloud-repair: nextcloud-upgrade
	$(OCC) maintenance:repair
	$(OCC) files:scan --all
	$(OCC) files:cleanup 

#nextcloud-upgrade: @ Upgrade NextCloud
nextcloud-upgrade:
	$(OCC) upgrade
	$(OCC) maintenance:mimetype:update-db
	$(OCC) maintenance:mimetype:update-js 
	$(OCC) db:add-missing-columns
	$(OCC) db:add-missing-indices
	$(OCC) db:add-missing-primary-keys

nextcloud-config:
	$(OCC) app:enable hip
	$(OCC) app:enable user_status
	$(OCC) app:enable sociallogin
	$(OCC) app:enable spreed
	$(OCC) app:enable forms
	$(OCC) app:enable groupfolders
	$(OCC) app:enable bruteforcesettings
	$(OCC) app:enable richdocumentscode
	$(OCC) app:disable dashboard
	$(OCC) app:disable photos
	$(OCC) app:disable activity
	$(OCC) app:disable forms

nextcloud-create-groups:
	$(OCC) group:add  --display-name CHUV chuv

#nextcloud-dump: @ Dump the current NextCloud DB (Postgres)
nextcloud-dump:
	$(DC) exec db pg_dump -U hipadmin nextcloud_db > $(shell date +%Y%m%d_%H%M%S).dump

lazydocker:
	[ ! -f ~/.local/bin/lazydocker ] && (curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash) || true
	~/.local/bin/lazydocker

sleep-%:
	sleep $(@:sleep-%=%)

## Dev

#update: @ Pull and update git submodules to a given branch eg. update branch=dev
update:
	git pull
	cd hip 										&& git stash && git checkout $(branch) && git pull && cd ..
	cd gateway 								&& git stash && git checkout $(branch) && git pull && cd ..
	cd nextcloud-docker 			&& git stash && git checkout $(branch) && git pull && cd ..
	cd nextcloud-social-login && git stash && git checkout hip && cd ..
	# cd ghostfs 							&& git stash && git checkout $(branch) && git pull && cd ..

dev-build: build-datahipy
	$(DC) build cron
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R www-data:www-data /var/www/html
	$(DC) -f docker-compose-dev.yml build --no-cache hip

#dev-install: @ Install dev stack for frontend & gateway, use update branch=dev to switch branch, you should have NODE_ENV=development
dev-install: stop dev-stop dev-stop-gateway dev-build dev-up sleep-5 nextcloud-config dev-hipapp dev-socialapp
	sudo pm2 start pm2/ecosystem.dev.config.js
	[ -f ../app-in-browser/scripts/installbackend.sh ] && (cd ../app-in-browser; ./scripts/installbackend.sh && cd ../frontend) || true
	cp .env gateway/.env
	@echo "**** NODE_ENV=$(NODE_ENV) ****"
	@echo WARNING you should have NODE_ENV=development in your .env file
	sudo make -C gateway deploy.dev

#dev-install-gateway: @ Restart the dev gateway
dev-install-gateway: dev-stop-gateway sleep-5
	cp .env gateway/.env
	sudo make -C gateway deploy.dev

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

dev-socialapp:
	# make -C nextcloud-social-login build
	sudo rm -rf $(NC_APP_FOLDER)/sociallogin
	sudo cp -r ./nextcloud-social-login $(NC_APP_FOLDER)/sociallogin
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)/sociallogin

#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(firstword $(MAKEFILE_LIST)) | tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

