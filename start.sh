#!/bin/sh

if [ -z "$1" ] || [ $1 = "up" ]; then
    #docker-compose -f ./nextcloud-docker/docker-compose.yml up caddy db
    docker-compose -f ./nextcloud-docker/docker-compose.yml up -d
    docker-compose up -d

    # This will install the submodule hip into the static path of Nextcloud install
    sudo cp -rf ./hip /mnt/nextcloud-dp/nextcloud/apps
    sudo chown -R www-data:root /mnt/nextcloud-dp/nextcloud/apps/hip
else
    docker-compose -f ./nextcloud-docker/docker-compose.yml down
    docker-compose down
fi

