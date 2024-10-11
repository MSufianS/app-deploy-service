#!/bin/bash

initial_working_directory=$(pwd)
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

source $parent_path/../common/helpers.sh

source $parent_path/../common/parse_yaml.sh
eval $(parse_yaml $parent_path/../config.yml)

title "Enabling Service Auto Restart"
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf

title "Update Package List"
sudo apt update

title "Upgrade Packages"
sudo apt upgrade -y

# Basic
title "Install Basic Packages"
sudo apt-get install -y software-properties-common curl gnupg debian-keyring debian-archive-keyring apt-transport-https \
ca-certificates build-essential dos2unix gcc git git-lfs libmcrypt4 libpcre3-dev libpng-dev chrony make pv \
python3-pip re2c supervisor unattended-upgrades whois vim cifs-utils bash-completion zsh zip unzip expect

title "Create Swap Space"
case $installs_swapspace in
  [yY][eE][sS]|[yY])
    if [ -f /swapfile ]; then
      status "swapfile already exists"
    else
      total_ram=$(free -m | grep Mem: | awk '{print $2}')
      sudo fallocate -l ${total_ram}M /swapfile
      sudo chmod 600 /swapfile
      sudo mkswap /swapfile
      sudo swapon /swapfile
      status "swapfile created"
    fi;;
  *)
    status "not creating swap space";;
esac

title "Install Nginx"
case $installs_nginx in
  [yY][eE][sS]|[yY])
    source ./installers/nginx.sh
    status "nginx installed";;
  *)
    status "not installing nginx";;
esac

title "Install PHP Version"
case $installs_php_install in
  [yY][eE][sS]|[yY])
    source "./installers/php${installs_php_version}.sh"
    status "php$installs_php_version installed";;
  *)
    status "not installing php$installs_php_version";;
esac

title "Install Composer"
case $installs_php_composer in
  [yY][eE][sS]|[yY])
  source ./installers/composer.sh
  status "composer installed";;
  *)
  status "not installing composer";;
esac

title "Install Node and NPM"
case $installs_node_and_npm in
  [yY][eE][sS]|[yY])
  source ./installers/node.sh
  status "node installed";;
  *)
  status "not installing node";;
esac

title "Install Redis"
case $installs_redis in
  [yY][eE][sS]|[yY])
  source ./installers/redis.sh
  status "redis installed";;
  *)
  status "not installing redis";;
esac

title "Install PostgreSQL"
case $installs_database_postgres in
  [yY][eE][sS]|[yY])
  source ./installers/postgres.sh
  status "postgres installed";;
  *)
  status "not installing postgres";;
esac

title "Install MySQL"
case $installs_database_mysql in
  [yY][eE][sS]|[yY])
  source ./installers/mysql.sh
  status "mysql installed";;
  *)
  status "not installing mysql";;
esac

title "Install memcache"
case $installs_memcache in
  [yY][eE][sS]|[yY])
  source ./installers/memcache.sh
  status "memcache installed";;
  *)
  status "not installing memcache";;
esac

title "Install beanstalk"
case $installs_beanstalk in
  [yY][eE][sS]|[yY])
  source ./installers/beanstalk.sh
  status "beanstalk installed";;
  *)
  status "not installing beanstalk";;
esac

title "Install mailhog"
case $installs_mailhog in
  [yY][eE][sS]|[yY])
  source ./installers/mailhog.sh
  status "mailhog installed";;
  *)
  status "not installing mailhog";;
esac

title "Install ngrok"
case $installs_mailhog in
  [yY][eE][sS]|[yY])
  source ./installers/ngrok.sh
  status "ngrok installed";;
  *)
  status "not installing ngrok";;
esac

title "Install postfix"
case $installs_postfix in
  [yY][eE][sS]|[yY])
  source ./installers/postfix.sh
  status "postfix installed";;
  *)
  status "not installing postfix";;
esac

title "One Last Upgrade Check"
sudo apt upgrade -y

title "Clean Up"
sudo apt -y autoremove
sudo apt -y clean

title "Status Report"
status "Nginx Version: $(nginx -v)"
status "PHP VERSION: $(php -r 'echo PHP_VERSION;')"
status "Composer Version: $(composer -V)"
status "Node Version: $(node -v)"
status "NPM Version: $(npm -v)"
status "Redis Version: $(redis-cli -v)"
status "PostgreSQL Version: $(psql -V)"
status "MySQL Version: $(mysql -V)"
status "Swap Space: $(swapon --show)"

cd $initial_working_directory



