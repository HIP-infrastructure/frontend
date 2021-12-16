#!/bin/bash

./nextcloud-docker/fix_crontab.sh
docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    up caddy db