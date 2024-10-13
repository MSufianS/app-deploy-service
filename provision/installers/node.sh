#!/bin/bash

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

sudo apt-get update -y

sudo apt install -y nodejs
sudo /usr/bin/npm install -g npm
sudo /usr/bin/npm install -g gulp-cli
sudo /usr/bin/npm install -g bower
sudo /usr/bin/npm install -g yarn
sudo /usr/bin/npm install -g grunt-cli