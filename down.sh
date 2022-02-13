#!/bin/bash

# stop both gateway & cache && Nextcloud 
docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    down --remove-orphans

docker-compose \
    -f ./docker-compose.yml \
    down --remove-orphans
