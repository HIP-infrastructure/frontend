#!/bin/bash

NC_HIP_APP_FOLDER=/mnt/nextcloud-dp/nextcloud/apps/hip

echo Copy Caddyfile to 
cp Caddyfile.dev ./nextcloud-docker/caddy/Caddyfile

# copy bootsrap files into nextcloud app folder
sudo cp -rf ./hip $NC_HIP_APP_FOLDER
sudo cp -rf ./hip/appinfo $NC_HIP_APP_FOLDER
sudo cp -f ./hip/templates/index.dev.php $NC_HIP_APP_FOLDER/templates/index.php
sudo chown -R www-data:root $NC_HIP_APP_FOLDER

# start both gateway & cache && Nextcloud 
docker-compose \
    -f nextcloud-docker/docker-compose.yml \
    $@

docker-compose \
    -f docker-compose-dev.yml \
    $@