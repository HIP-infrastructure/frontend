
#!/bin/bash

# start both gateway & cache && Nextcloud 
./nextcloud-docker/fix-contab.sh
docker-compose \
    -f ./nextcloud-docker/docker-compose.yml \
    up caddy db