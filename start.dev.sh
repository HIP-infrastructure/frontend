#!/bin/bash

NC_APP_FOLDER=/mnt/nextcloud-dp/nextcloud/apps

# copy bootstrap files into nextcloud app folder
sudo mkdir -p $NC_APP_FOLDER/hip
sudo cp -r ./hip $NC_APP_FOLDER/
sudo cp -rf ./hip/appinfo $NC_APP_FOLDER/hip
sudo cp -rf ./hip/lib $NC_APP_FOLDER/hip
sudo cp -f ./hip/templates/index.dev.php $NC_APP_FOLDER/hip/templates/index.php
sudo chown -R www-data:root $NC_APP_FOLDER/hip

# start both gateway & cache && Nextcloud 
docker-compose \
    -f nextcloud-docker/docker-compose.yml \
    --env-file ./.env \
    up -d

docker-compose \
    -f docker-compose-dev.yml \
    --env-file ./.env \
    up -d