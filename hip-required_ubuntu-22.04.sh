#!/usr/bin/env bash

# set -e 

if ! command -v sudo &> /dev/null
then
    echo "sudo could not be found, please install it."
    exit 1;
fi

sudo apt-get update

if ! command -v make &> /dev/null
then
    echo "make could not be found, installing..."
    sudo apt install -y build-essential
    echo "make installed."
fi

if ! command -v caddy &> /dev/null
then
    echo "caddy could not be found, installing..."
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update
    sudo apt install -y caddy
    sudo systemctl stop caddy
    sudo systemctl disable caddy
    echo "caddy installed."
fi

if ! command -v gunicorn &> /dev/null
then
    echo "gunicorn could not be found, installing..."
    sudo apt install -y gunicorn
    echo "gunicorn installed."
fi

if ! command -v envsubst &> /dev/null
then
    echo "envsubst could not be found, installing..."
    sudo apt install -y gettext-base
    echo "envsubst installed."
fi

if ! command -v node &> /dev/null
then
    echo "node could not be found, installing..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    NODE_MAJOR=16
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get install nodejs -y
    echo "node installed."
fi

if ! command -v docker &> /dev/null
then
    echo "docker could not be found, installing..."
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo groupadd docker
    sudo usermod -aG docker $USER
    echo "docker installed."
    echo -e "\033[31m Logout and login again to use docker in your session"
    echo
fi

if ! command -v pm2 &> /dev/null
then
    echo "pm2 could not be found, installing..."
    sudo npm install pm2 -g
    echo "pm2 installed."
fi

if ! command -v husky &> /dev/null
then
    echo "husky could not be found, installing..."
    sudo npm install husky -g
    echo "husky installed."
fi

if ! command -v nest &> /dev/null
then
    echo "nest could not be found, installing..."
	sudo npm i --location=global @nestjs/cli
    echo "nest cli installed."
fi

sudo npm install dotenv || true

dpkg -l | grep libfuse2 | grep -q ii
if [ $? -eq 1 ];
then
    echo "libfuse2 could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y libfuse2
    echo "libfuse2 installed."
fi

if ! grep -q max_user_watches /etc/sysctl.conf
then
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p
fi
