#!/bin/bash

# tear down both gateway & cache && Nextcloud 
docker-compose \
    -f nextcloud-docker/docker-compose.yml \
    --env-file ./.env \
    down --remove-orphans

docker-compose \
    -f docker-compose-dev.yml \
    down --remove-orphans
