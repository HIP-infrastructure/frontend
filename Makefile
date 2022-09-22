.DEFAULT_GOAL := help

include .env
export

sleep-%:
	sleep $(@:sleep-%=%)

#install: @ Install all depencies for the HIP
# TODO: SHELL:=/bin/bash
install:
	make -C gateway install
	bash ./install_ghostfs.sh

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
	docker-compose exec --user ${DATA_USER} app php occ maintenance:repair
	docker-compose exec --user ${DATA_USER} app php occ files:scan --all
	docker-compose exec --user ${DATA_USER} app php occ files:cleanup 

#build : @ Build components locally
build: b.nextcloud b.hipapp b.socialapp b.gateway b.bids-tools

b.nextcloud:
	docker-compose --env-file ./.env build app
	docker-compose --env-file ./.env build cron
	sudo chown root:root nextcloud-docker/crontab

b.hipapp:
	make -C hip build

b.socialapp:
	make -C nextcloud-social-login build

b.gateway:
	sudo make -C gateway build

b.bids-tools:
	sudo make -C bids-tools build

#deploy: @ Deploy the frontend stack in production mode
deploy: build d.nextcloud d.pm2 d.nextcloud sleep-5 d.nextcloud.upgrade d.hipapp d.socialapp
	sudo pm2 status
	docker ps

d.nextcloud:
	sudo mkdir -p /var/www
	[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
	sudo chown -R ${DATA_USER}:${DATA_USER} /var/www/html
	docker-compose --env-file ./.env up -d

d.nextcloud.upgrade:
	docker-compose exec --user ${DATA_USER} app php occ upgrade
	docker-compose exec --user ${DATA_USER} app php occ maintenance:mimetype:update-db
	docker-compose exec --user ${DATA_USER} app php occ maintenance:mimetype:update-js 
	docker-compose exec --user ${DATA_USER} app php occ db:add-missing-columns
	docker-compose exec --user ${DATA_USER} app php occ db:add-missing-indices
	docker-compose exec --user ${DATA_USER} app php occ db:add-missing-primary-keys

d.pm2:
	sudo pm2 save
	sudo pm2 start pm2/ecosystem.config.js

d.hipapp:
	sudo rm -rf $(NC_APP_FOLDER)/hip
	sudo mkdir $(NC_APP_FOLDER)/hip
	sudo tar -zxvf hip/release.tar.gz -C $(NC_APP_FOLDER)/hip
	sudo chown -R ${DATA_USER}:${DATA_USER} $(NC_APP_FOLDER)

d.socialapp:
	sudo rm -rf $(SOCIAL_APP_FOLDER)
	sudo cp -r ./nextcloud-social-login $(SOCIAL_APP_FOLDER)
	sudo chown -R ${DATA_USER}:${DATA_USER} $(SOCIAL_APP_FOLDER)

#deploy.stop: @ Stop the frontend stack in production mode
deploy.stop: 
	docker-compose stop
	sudo pm2 stop pm2/ecosystem.config.js
	sudo pm2 status
	docker ps

#deploy.dev: @ Deploy the frontend stack in dev mode
deploy.dev: b.nextcloud d.nextcloud.dev sleep-5 d.nextcloud.upgrade d.pm2.dev d.hipapp.dev d.socialapp.dev d.bids-tools.dev d.gateway.dev

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

