#!/bin/bash

sudo apt-get install -y postgresql-16 postgresql-server-dev-16 postgresql-16-postgis-3 postgresql-16-postgis-3-scripts

sudo -u postgres psql -c "CREATE ROLE homestead LOGIN PASSWORD '$db_root_password' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/16/main/postgresql.conf
sudo echo "host    all             all             8.0.2.2/32               md5" | tee -a /etc/postgresql/16/main/pg_hba.conf

sudo -u postgres /usr/bin/createdb --echo --owner=homestead homestead
sudo service postgresql restart
sudo systemctl disable postgresql