#!/bin/bash

# start both gateway & cache && Nextcloud 
docker-compose \
    -f nextcloud-docker/docker-compose.yml \
    stop

docker-compose \
    -f docker-compose-dev.yml \
    stop
