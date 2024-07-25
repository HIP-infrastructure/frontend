#! /bin/bash


set -e
cd "${0%/*}"

start-docker.sh
until docker info; do sleep 1; done

# cd ..
# git clone https://github.com/HIP-infrastructure/nextcloud-docker.git

cd nextcloud-docker
cp caddy/Caddyfile.template caddy/Caddyfile

curl https://raw.githubusercontent.com/HIP-infrastructure/nextcloud-inotifyscan/hip/nextcloud-inotifyscan > nextcloud/nextcloud-inotifyscan

cp .env.template .env
cat .env >> ../.env

./fix_crontab.sh

# setup caddy & db
docker compose up -d caddy db
echo "Waiting for caddy and db to be ready, waiting 60sec..."
sleep 30
docker compose down

# previously make install-nextcloud
export NC_DATA_FOLDER=/mnt/nextcloud-dp/nextcloud
sudo mkdir -p /var/www
[ ! -L /var/www/html ] && sudo ln -sf ${NC_DATA_FOLDER} /var/www/html || true
sudo chown -R www-data:www-data /var/www/html
sudo rm -rf ${NC_DATA_FOLDER}/core/skeleton
sudo mkdir -p ${NC_DATA_FOLDER}/core/skeleton
sudo cp ../hip/skeleton/* ${NC_DATA_FOLDER}/core/skeleton
sudo chown -R www-data:www-data ${NC_DATA_FOLDER}/core/skeleton
docker compose --env-file ../.env -f docker-compose.yml build cron
sudo chown root:root crontab
docker compose --env-file ../.env -f docker-compose.yml up -d || true

sudo rm -rf /mnt/nextcloud-dp/php-settings
sudo cp -r ../php-settings /mnt/nextcloud-dp

docker compose --env-file ../.env -f docker-compose.yml up -d || true

# make occ c=maintenance:install

