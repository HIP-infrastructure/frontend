#!/bin/bash

# start both gateway & cache && Nextcloud 
cd nextcloud-docker
./fix_crontab.sh
cd ..

docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    --env-file ./.env \
    up caddy db