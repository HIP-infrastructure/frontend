SHELL=/bin/bash

.DEFAULT_GOAL := help

include .env
export

sleep-%:
	sleep $(@:sleep-%=%)

#install: @ Install all depencies for the HIP
install:
	make -C gateway install
	bash ./install_ghostfs.sh
	cd pm2 && npm i && cd ..
	# TODO echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p


#update: @ Update all submodules for the HIP
update:
	git pull
	git submodule update --init --recursive
	rm -f ghostfs/GhostFS
	wget https://github.com/pouya-eghbali/ghostfs-builds/releases/download/linux-${GHOSTFS_VERSION}/GhostFS -O ghostfs/GhostFS
	chmod +x ghostfs/GhostFS
	echo `./ghostfs/GhostFS --version`


#dump: @ Dump the current NextCloud DB of the HIP
dump:
	docker-compose exec db pg_dump -U hipadmin nextcloud_db > $(shell date +%Y%m%d_%H%M%S).dump

#repair: @ Attempt to repair NextCloud
repair: d.nextcloud.upgrade
	docker-compose exec --user ${DATA_USER} cron php occ maintenance:repair
	docker-compose exec --user ${DATA_USER} cron php occ files:scan --all
	docker-compose exec --user ${DATA_USER} cron php occ files:cleanup 

#build : @ Build components locally
build: b.nextcloud b.hipapp b.socialapp b.gateway b.bids-tools

b.nextcloud:
	docker-compose --env-file ./.env build app
	docker-compose --env-file ./.env build cron
	sudo chown root:root nextcloud-docker/crontab

b.nextcloud.no-cache:
	docker-compose --env-file ./.env build --no-cache app
	docker-compose --env-file ./.env build --no-cache cron
	sudo chown root:root nextcloud-docker/crontab

b.hipapp:
	make -C hip build

b.socialapp:
	make -C nextcloud-social-login build

b.gateway:
	sudo make -C gateway build

b.bids-tools:
	sudo make -C bids-tools build

#deploy: @ Deploy the frontend stack without ghsotfs in production mode
deploy: build d.nextcloud d.pm2.caddy d.nextcloud sleep-5 d.nextcloud.config d.nextcloud.upgrade d.hipapp d.socialapp
	sudo pm2 save
	sudo pm2 startup
	sudo systemctl start pm2-root
	sudo systemctl enable pm2-root
	sudo pm2 status
	docker ps

#deploy: @ Deploy the frontend stack and ghostfs in production mode
deploy.with-ghostf: deploy d.pm2.ghostfs
	sudo pm2 status

deploy.webapp: b.hipapp d.hipapp b.gateway
	sudo pm2 restart gateway
	sudo pm2 status

d.nextcloud:
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R ${DATA_USER}:${DATA_USER} /var/www/html

	sudo rm -rf ${NC_DATA_FOLDER}/core/skeleton
	sudo cp -r hip/skeleton/ ${NC_DATA_FOLDER}/core/
	sudo chown -R ${DATA_USER}:${DATA_USER} ${NC_DATA_FOLDER}/core/skeleton

	docker-compose --env-file ./.env up -d

d.nextcloud.config:
	docker-compose exec --user www-data app php occ app:enable hip
	docker-compose exec --user www-data app php occ app:enable user_status
	docker-compose exec --user www-data app php occ app:enable sociallogin
	docker-compose exec --user www-data app php occ app:enable spreed
	docker-compose exec --user www-data app php occ app:enable forms
	docker-compose exec --user www-data app php occ app:enable groupfolders
	docker-compose exec --user www-data app php occ app:enable bruteforcesettings
	docker-compose exec --user www-data app php occ app:enable richdocumentscode

d.nextcloud.upgrade:
	docker-compose exec --user ${DATA_USER} cron php occ upgrade
	docker-compose exec --user ${DATA_USER} cron php occ maintenance:mimetype:update-db
	docker-compose exec --user ${DATA_USER} cron php occ maintenance:mimetype:update-js 
	docker-compose exec --user ${DATA_USER} cron php occ db:add-missing-columns
	docker-compose exec --user ${DATA_USER} cron php occ db:add-missing-indices
	docker-compose exec --user ${DATA_USER} cron php occ db:add-missing-primary-keys

d.pm2.caddy:
	sudo pm2 start pm2/ecosystem.config.js

d.pm2.ghostfs:
	sudo pm2 start pm2/ecosystem.ghostfs.config.js

d.hipapp:
	sudo rm -rf $(NC_APP_FOLDER)/hip
	sudo mkdir $(NC_APP_FOLDER)/hip
	sudo tar -zxvf hip/release.tar.gz -C $(NC_APP_FOLDER)/hip
	sudo chown -R ${DATA_USER}:${DATA_USER} $(NC_APP_FOLDER)

d.socialapp:
	sudo rm -rf $(SOCIAL_APP_FOLDER)
	sudo cp -r ./nextcloud-social-login $(SOCIAL_APP_FOLDER)
	sudo chown -R ${DATA_USER}:${DATA_USER} $(SOCIAL_APP_FOLDER)

#deploy.stop: @ Stop the frontend stack and ghostfs in production mode
deploy.stop: 
	docker-compose stop
	sudo pm2 stop pm2/ecosystem.config.js
	sudo pm2 status
	docker ps

#deploy.stop: @ Stop the frontend stack with ghostfs in production mode
deploy.stop.with-ghostfs: deploy.stop
	sudo pm2 stop pm2/ecosystem.ghostfs.config.js
	sudo pm2 status

#deploy.dev: @ Deploy the frontend stack in dev mode
deploy.dev: b.nextcloud.no-cache d.nextcloud.dev sleep-5 d.nextcloud.config d.nextcloud.upgrade d.pm2.dev d.hipapp.dev d.socialapp.dev d.bids-tools.dev d.gateway.dev

deploy.dev.gateway:
	sudo make -C gateway deploy.dev
	sudo make -C gateway deploy.dev.stop

d.nextcloud.dev:
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R ${DATA_USER}:${DATA_USER} /var/www/html
	docker-compose \
		-f docker-compose.yml \
		-f docker-compose-dev.yml \
		--env-file ./.env \
		up -d

d.pm2.dev:
	sudo pm2 start pm2/ecosystem.dev.config.js

d.hipapp.dev:
	sudo mkdir -p $(NC_APP_FOLDER)/hip/templates
	sudo cp -rf ./hip/appinfo $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/lib $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/img $(NC_APP_FOLDER)/hip
	sudo cp -f ./hip/templates/index.dev.php $(NC_APP_FOLDER)/hip/templates/index.php
	sudo chown -R ${DATA_USER}:${DATA_USER} $(NC_APP_FOLDER)/hip

d.socialapp.dev:
	make -C nextcloud-social-login build
	sudo rm -rf $(SOCIAL_APP_FOLDER)
	sudo cp -r ./nextcloud-social-login $(SOCIAL_APP_FOLDER)
	sudo chown -R ${DATA_USER}:${DATA_USER} $(SOCIAL_APP_FOLDER)

d.bids-tools.dev:
	make -C bids-tools build

d.gateway.dev:
	make -C gateway deploy.dev

#deploy.dev.stop: @ Stop the frontend stack in dev mode
deploy.dev.stop: d.gateway.dev.stop
	docker-compose \
		-f docker-compose.yml \
		-f docker-compose-dev.yml \
		down
	sudo pm2 stop pm2/ecosystem.dev.config.js

d.gateway.dev.stop:
	make -C gateway deploy.dev.stop

#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

