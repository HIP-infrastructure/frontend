
#!/bin/bash

# start both gateway & cache && Nextcloud 
./nextcloud-docker/fix_crontab.sh
docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    up caddy db