#!/bin/bash

builder_directory=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

title "Laravel Builder"

status "Create Symlinks"
source $builder_directory/symlinks.sh

if [ ! -f archived_deployed.lock ]; then
  status "Composer Install"
  composer install

  status "NPM Install"
  npm install

  status "Build Front End Assets"
  npm run build
else
  status "Build completed when creating archive"
fi

status "Migrations"
php artisan migrate --force

