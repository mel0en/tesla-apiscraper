#!/bin/bash

teslaEmail=$1
teslaPassword=$2

if [[ $teslaEmail == "" || $teslaPassword == "" ]]; then 
    echo "Please enter your email and password"
    exit
fi

device=$(cat /proc/device-tree/model)
if [[ $device == *"Raspberry Pi Zero"* ]]; then 
    echo "This will not work on a Pi Zero, quitting install"
    exit
fi

# Create the config file
cp config.py.compose config.py
sed -i "s/<email>/${teslaEmail}/g" ./config.py
sed -i "s/<password>/${teslaPassword}/g" ./config.py

currentDirectory=$(echo $PWD | sed 's_/_\\/_g')
originalDirectory=$(echo /home/pi/tesla-apiscraper | sed 's_/_\\/_g')
sed -i "s/${originalDirectory}/${currentDirectory}/g" ./tesla-apiscraper.service
sed -i "s/Users=pi/Users=$(id -u -n)/g" ./tesla-apiscraper.service

# Important: Create empty Log, otherwise bindmount will fail.
touch apiscraper.log

# Create Directories for persistent Data:
# mkdir -p data/influxdb
# mkdir -p data/grafana
# sudo chown 472 data/grafana

# Install docker/docker-compose if not exists
if ! which docker >/dev/null; then
  curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
fi

if ! which docker-compose >/dev/null; then
  sudo apt-get install docker-compose
fi

# Check if we have docker permissions
if [ "$EUID" -ne 0 ] && ! (groups | grep &>/dev/null '\bdocker\b'); then
    echo "Run this script as a user with docker rights"
    echo "Or add this user to the docker group:"
    echo
    echo "  sudo usermod -aG docker $(id -u -n)"
    echo
    echo "Then re-login"
    exit
fi

# Start Docker Stack
# ./dashboard2docker.sh
docker-compose up -d

# Make the scraper start start on boot
sudo cp tesla-apiscraper.service /lib/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable tesla-apiscraper.service

# Add pi or any other user you would like to the Docker Group
# usermod -aG docker $(id -u -n)
# reboot
