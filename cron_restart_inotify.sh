#!/bin/env sh


# This script is used temporarely to restart inotify service
# install with 

# 0 */2 * * * /bin/sh /home/hipadmin/frontend/cron_restart_inotify.sh > /dev/null 2>&1

docker-compose stop cron 
docker-compose start cron
sleep 5

docker-compose exec --user www-data cron php occ files:scan --all

