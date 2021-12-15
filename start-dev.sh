#!/bin/bash

# Get the HIP app Nextcloud app
git submodule update hip
cd hip
git checkout dev
cd ..

# start both gateway & cache && Nextcloud 
docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    -f ./docker-compose-dev.yml \
    up -d

# copy bundled app into nextcloud app folder
sudo cp -rf ./hip /mnt/nextcloud-dp/nextcloud/apps
sudo chown -R www-data:root /mnt/nextcloud-dp/nextcloud/apps/hip