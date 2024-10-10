#!/bin/bash

sudo apt install -y nginx

sudo rm /etc/nginx/sites-enabled/default

sudo service nginx restart