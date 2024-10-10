#!/bin/bash

sudo apt-get install -y beanstalkd

sudo sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
