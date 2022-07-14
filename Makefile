.DEFAULT_GOAL := help

include .env
export

#dep.init: @ Install all depencies for Ubuntu
dep.init:
	git submodule update --init --recursive
	make -C gateway dep.init

#build : @ Build components locally
build: b.nextcloud b.hipapp b.socialapp b.gateway b.bids-tools

b.nextcloud:
	docker-compose \
		-f nextcloud-docker/docker-compose.yml \
		--env-file ./.env \
		build app
	docker-compose \
		-f nextcloud-docker/docker-compose.yml \
		--env-file ./.env \
		build cron

b.hipapp:
	# cd hip && git checkout master && cd ..
	make -C hip build

b.socialapp:
	make -C nextcloud-social-login build

b.gateway:
	#cd gateway && git checkout master && cd ..
	sudo make -C gateway build

b.bids-tools:
	sudo make -C bids-tools build

#deploy: @ Deploy the frontend stack in production mode
deploy: build d.nextcloud d.hipapp d.socialapp d.gateway d.reddis 

d.nextcloud:
	cp ./settings/Caddyfile ./nextcloud-docker/caddy/Caddyfile
	docker-compose \
		-f nextcloud-docker/docker-compose.yml \
		--env-file ./.env \
		up -d

d.hipapp:
	sudo rm -rf /mnt/nextcloud-dp/nextcloud/apps/hip
	sudo mkdir /mnt/nextcloud-dp/nextcloud/apps/hip
	sudo tar -zxvf hip/release.tar.gz -C /mnt/nextcloud-dp/nextcloud/apps/hip
	sudo chown -R www-data:root $(NC_APP_FOLDER)

d.socialapp:
	sudo rm -rf $(SOCIAL_APP_FOLDER)
	sudo cp -r ./nextcloud-social-login $(SOCIAL_APP_FOLDER)
	sudo chown -R www-data:root $(SOCIAL_APP_FOLDER)

d.gateway:
	make -C gateway deploy

d.reddis:
	docker-compose \
		-f ./docker-compose.yml \
		--env-file ./.env \
		up -d

#deploy.stop: @ Stop the frontend stack in production mode
deploy.stop: 
	docker-compose \
		-f nextcloud-docker/docker-compose.yml \
		--env-file ./.env \
		stop
	docker-compose \
		-f ./docker-compose.yml \
		--env-file ./.env \
		stop
	make -C gateway deploy.stop

#deploy.dev: @ Deploy the frontend stack in dev mode
deploy.dev: d.nextcloud.dev d.hipapp.dev d.socialapp.dev d.bids-tools.dev d.gateway.dev

d.nextcloud.dev:
	cp ./settings/Caddyfile.dev ./nextcloud-docker/caddy/Caddyfile
	docker-compose \
		-f nextcloud-docker/docker-compose.yml \
		--env-file ./.env \
		up -d

d.hipapp.dev:
	sudo mkdir -p $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/appinfo $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/lib $(NC_APP_FOLDER)/hip
	sudo cp -rf ./hip/img $(NC_APP_FOLDER)/hip
	sudo cp -f ./hip/templates/index.php $(NC_APP_FOLDER)/hip/templates/index.php
	sudo chown -R www-data:root $(NC_APP_FOLDER)/hip
	docker-compose \
		-f docker-compose-dev.yml \
		--env-file ./.env \
		up -d

d.socialapp.dev:
	make -C nextcloud-social-login build
	sudo rm -rf $(SOCIAL_APP_FOLDER)
	sudo cp -r ./nextcloud-social-login $(SOCIAL_APP_FOLDER)
	sudo chown -R www-data:root $(SOCIAL_APP_FOLDER)

d.bids-tools.dev:
	make -C bids-tools build

d.gateway.dev:
	make -C gateway deploy.dev

#deploy.dev.stop: @ Stop the frontend stack in dev mode
deploy.dev.stop: 
	docker-compose \
		-f nextcloud-docker/docker-compose.yml \
		--env-file ./.env \
		stop
	docker-compose \
    -f docker-compose-dev.yml \
    stop
	make -C gateway deploy.dev.stop

#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

