#!/usr/bin/env bash

set -o allexport; source .env; set +o allexport

if ! command -v pip3 &> /dev/null
then
    echo "pip3 could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y python3-pip
    echo "pip3 installed."
fi
sudo pip3 install -r ghostfs/auth_backend/requirements.txt

if ! command -v pm2 &> /dev/null
then
    echo "pm2 could not be found, installing..."
    # curl -sL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    # sudo apt-get install -y nodejs
    sudo npm install pm2 -g
    echo "pm2 installed."
fi
cd pm2 && npm i && cd ..

if ! command -v caddy &> /dev/null
then
    echo "caddy could not be found, installing..."
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt-get update && sudo apt-get install -y caddy
    sudo systemctl stop caddy
    sudo systemctl disable caddy
    echo "caddy installed."
fi

if [ -f ./ghostfs/auth_backend/auth_backend.secret ]; then
    echo "./ghostfs/auth_backend.secret exists, not creating."
else
    echo -n "Enter auth_backend username: "
    read -r auth_backend_username
    echo -n "Enter auth_backend password: "
    read -rs auth_backend_password
    echo

    auth_backend_hash=`python3 -c "from werkzeug.security import generate_password_hash as g; print(g(\"$auth_backend_password\"), end=\"\");"`

    echo -n "$auth_backend_username@$auth_backend_hash" > ./ghostfs/auth_backend/auth_backend.secret
fi

if [ -f ./ghostfs/auth_backend/auth_backend.env ]; then
    echo "./ghostfs/auth_backend/auth_backend.secret exists, not creating."
else
    cp ghostfs/auth_backend/auth_backend.env.template ghostfs/auth_backend/auth_backend.env
fi

if [ -f ./ghostfs/key.pem ]; then
    echo "./ghostfs/key.pem exists, not creating."
else
    echo "Creating SSL certificate..."
    openssl req -nodes -x509 -newkey rsa:4096 -keyout ghostfs/key.pem -out ghostfs/cert.pem -sha256 -days 365 -subj "/CN=${HOSTNAME}"
    sudo chgrp www-data ghostfs/key.pem ghostfs/cert.pem
fi

rm -f ghostfs/GhostFS
curl -L# https://github.com/pouya-eghbali/ghostfs-builds/releases/download/linux-$GHOSTFS_VERSION/GhostFS -o ghostfs/GhostFS
chmod +x ghostfs/GhostFS

sudo pm2 startup
sudo systemctl start pm2-root
sudo systemctl enable pm2-root
