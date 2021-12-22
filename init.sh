
#!/bin/bash

# start both gateway & cache && Nextcloud 
./nextcloud-docker/fix-crontab.sh
docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    up caddy db