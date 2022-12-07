SHELL=/bin/bash

.DEFAULT_GOAL := help

NC_DATA_FOLDER=/mnt/nextcloud-dp/nextcloud
NC_APP_FOLDER=/mnt/nextcloud-dp/nextcloud/apps
SOCIAL_APP_FOLDER=/mnt/nextcloud-dp/nextcloud/custom_apps/sociallogin

DC=docker-compose --env-file ./.env -f docker-compose.yml
OCC=docker-compose exec --user www-data app php occ

#install: @ ** USE THIS ONE ** Stop, update, build and install the latest HIP, without GhostFS 
install: maintenance-on stop configure build install-nextcloud nextcloud-config install-hipapp install-socialapp maintenance-off
	sudo pm2 start pm2/ecosystem.config.js
	sudo pm2 save
	sudo pm2 startup
	sudo systemctl start pm2-root
	sudo systemctl enable pm2-root

#install-ghostfs: @ Stop, update and install GhostFS only
install-ghostfs: 
	sudo pm2 stop pm2/ecosystem.ghostfs.config.js
	bash ./install_ghostfs.sh
	sudo pm2 start pm2/ecosystem.ghostfs.config.js

#status: @ Show the status of the HIP
status:
	sudo pm2 status
	docker-compose ps

update:
	git pull
	git submodule update --init --recursive
	cd pm2 && npm i && cd ..

build:
	$(DC) build app
	$(DC) ./.env build cron
	sudo chown root:root nextcloud-docker/crontab
	make -C nextcloud-social-login build
	sudo make -C bids-tools build
	sudo make -C gateway build
	sudo make -C hip build
	# TODO echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p

build-web:
	sudo make -C bids-tools build
	sudo make -C gateway build
	sudo make -C hip build

#install-web: @ Build & nnstall only the gateway, bids-tools and the webapp
install-web: maintenance-on build-web install-hipapp maintenance-off
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
	sudo cp -r hip/skeleton ${NC_DATA_FOLDER}/core/
	sudo chown -R www-data:www-data ${NC_DATA_FOLDER}/core/skeleton
	$(DC) up -d

install-hipapp:
	sudo rm -rf $(NC_APP_FOLDER)/hip
	sudo mkdir $(NC_APP_FOLDER)/hip
	sudo tar -zxvf hip/release.tar.gz -C $(NC_APP_FOLDER)/hip
	sudo chown -R www-data:www-data $(NC_APP_FOLDER)

install-socialapp:
	sudo rm -rf $(SOCIAL_APP_FOLDER)
	sudo cp -r ./nextcloud-social-login $(SOCIAL_APP_FOLDER)
	sudo chown -R www-data:www-data $(SOCIAL_APP_FOLDER)

## Utils

#maintenance: @ Enable/disable maintenance mode (make maintenance-on/maintenance-off)	
maintenance-%:
	$(OCC) maintenance:mode --$(@:maintenance-%=%)

#nextcloud-repair: @ Attempt to repair NextCloud
nextcloud-repair: d.nextcloud.upgrade
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

#nextcloud-dump: @ Dump the current NextCloud DB (Postgres)
nextcloud-dump:
	$(DC) exec db pg_dump -U hipadmin nextcloud_db > $(shell date +%Y%m%d_%H%M%S).dump

lazydocker:
	[ ! -f ~/.local/bin/lazydocker ] && (curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash) || true
	~/.local/bin/lazydocker

sleep-%:
	sleep $(@:sleep-%=%)

## Dev

# eg: dev-update branch=dev
dev-update:
	git pull
	cd hip && git stash && git checkout $(branch) && git pull && cd ..
	cd gateway && git stash && git checkout $(branch) && git pull && cd ..
	# cd nextcloud-docker && git stash && git checkout $(branch) && git pull && cd ..
	# cd bids-tools && && git stash git checkout $(branch) && git pull && cd ..
	# cd nextcloud-social-login && git stash && git checkout $(branch) && git pull && cd ..

dev-build:
	$(DC) build app
	$(DC) build cron
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R www-data:www-data /var/www/html
	$(DC) -f docker-compose-dev.yml build --no-cache hip
	make -C bids-tools build

#dev-install: @ Install dev stack for frontend & gateway, use dev-update branch=dev to switch branch
dev-install: stop dev-stop dev-stop-gateway dev-build dev-up sleep-5 nextcloud-config dev-hipapp dev-socialapp
	sudo pm2 start pm2/ecosystem.dev.config.js
	[ -f ../app-in-browser/scripts/installbackend.sh ] && (cd ../app-in-browser; ./scripts/installbackend.sh && cd ../frontend) || true
	sudo make -C gateway dev-install

#dev-restart-gateway: @ Restart the dev gateway
dev-restart-gateway:
	sudo make -C gateway dev-install

dev-stop-gateway:
	for pid in $(ps -fu www-data  | grep gateway | awk '{ print $2 }'); do sudo kill -9 $pid; done 

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
	sudo rm -rf $(SOCIAL_APP_FOLDER)
	sudo cp -r ./nextcloud-social-login $(SOCIAL_APP_FOLDER)
	sudo chown -R www-data:www-data $(SOCIAL_APP_FOLDER)

#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

