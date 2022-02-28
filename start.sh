#!/bin/bash

NC_HIP_APP_FOLDER=/mnt/nextcloud-dp/nextcloud/apps/hip

# Get the HIP app Nextcloud app
git submodule update hip
cd hip
git checkout master
cd ..

# start both gateway & cache && Nextcloud 
docker network create nextcloud-docker_frontend

# echo "Copy Caddyfile to ./nextcloud-docker/caddy/Caddyfile"
# cp Caddyfile ./nextcloud-docker/caddy/Caddyfile

docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    --env-file ./.env \
    up -d

docker-compose \
    -f ./docker-compose.yml \
    up -d

# copy bundled app into nextcloud app folder
sudo cp -rf ./hip /mnt/nextcloud-dp/nextcloud/apps
sudo chown -R www-data:root $NC_HIP_APP_FOLDER