#!/bin/bash

# stop both gateway & cache && Nextcloud 
docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    -f ./docker-compose.yml \
    stop
