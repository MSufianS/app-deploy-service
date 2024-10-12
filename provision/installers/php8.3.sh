#!/bin/bash

sudo apt-add-repository ppa:ondrej/php -y

sudo apt-get update -y

sudo apt-get install -y --allow-change-held-packages \
php-imagick php-memcached php-redis php-xdebug php-dev imagemagick mcrypt

sudo apt-get install -y --allow-change-held-packages \
php8.3 php8.3-bcmath php8.3-bz2 php8.3-cgi php8.3-cli php8.3-common php8.3-curl php8.3-dba php8.3-dev \
php8.3-enchant php8.3-fpm php8.3-gd php8.3-gmp php8.3-imap php8.3-interbase php8.3-intl php8.3-ldap \
php8.3-mbstring php8.3-mysql php8.3-odbc php8.3-opcache php8.3-pgsql php8.3-phpdbg php8.3-pspell php8.3-readline \
php8.3-snmp php8.3-soap php8.3-sqlite3 php8.3-sybase php8.3-tidy php8.3-xdebug php8.3-xml php8.3-xmlrpc php8.3-xsl \
php8.3-zip php8.3-memcached php8.3-redis php8.3-imagick

sudo update-alternatives --set php /usr/bin/php8.3

php8.3 -i | grep imagick

if [ ! -f /etc/php/8.3/cli/php.ini.bak ]; then
  sudo cp /etc/php/8.3/cli/php.ini /etc/php/8.3/cli/php.ini.bak
fi
if [ ! -f /etc/php/8.3/fpm/php.ini.bak ]; then
  sudo cp /etc/php/8.3/fpm/php.ini /etc/php/8.3/fpm/php.ini.bak
fi
if [ ! -f /etc/php/8.3/mods-available/xdebug.ini.bak ]; then
  sudo cp /etc/php/8.3/mods-available/xdebug.ini /etc/php/8.3/mods-available/xdebug.ini.bak
fi
if [ ! -f /etc/php/8.3/mods-available/opcache.ini.bak ]; then
  sudo cp /etc/php/8.3/mods-available/opcache.ini /etc/php/8.3/mods-available/opcache.ini.bak
fi
if [ ! -f /etc/php/8.3/fpm/pool.d/www.conf.bak ]; then
  sudo cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.bak
fi
