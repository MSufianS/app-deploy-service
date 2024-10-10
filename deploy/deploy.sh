#!/bin/bash

app_name=$(whoami)

initial_working_directory=$(pwd)
my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $my_path

source $my_path/../common/load_common.sh

title "Deploying to other servers"

status "servers: $servers"
if [ -n "$servers" ]; then
  for i in "${!servers[@]}"; do
    echo "inside the for loop: ${servers[$i]}"
    if [ -f $deploy_directory/build*.zip ]; then
      echo "inside the if block"
      scp -i ~/.ssh/laravel_demo.pem $deploy_directory/build*.zip  ubuntu@${servers[$i]}:/home/ubuntu
      ssh -i ~/.ssh/laravel_demo.pem ubuntu@"${servers[$1]}" <<ENDSSH
        sudo mv /home/ubuntu/build*.zip /home/$username/deployments
        sudo chown -R $username:$username /home/$username/deployments
        sudo -u $username /usr/local/bin/devops/deploy/deploy.sh
ENDSSH
      status "Build copied and deployed to: ${servers[$i]}"
    fi
  done
else
  status "No other servers configured"
fi

current_user=$(whoami)
if [ ! "$username" == "$current_user" ]; then
  error "Expected user: $username"
  error "Current user: $current_user"
  error "Try running like sudo -u app_name deploy.sh"
  exit 1
fi


title "Starting Deployment: $username"

if [ ! -d $deploy_directory/releases ]; then
    mkdir -p $deploy_directory/releases
fi

date_string=$(date +"%Y-%m-%d-%H-%M-%S")

if [ -d $deploy_directory/current ]; then
  cd $deploy_directory/current/
  remote_git_line=$(git ls-remote | head -n 1)
  remote_hash=${remote_git_line:0:7}
  local_hash=$(git rev-parse --short HEAD 2> /dev/null | sed "s/\(.*\)/\1/")
  status "remote_hash=$remote_hash, local_hash=$local_hash"
  if [ $remote_hash = $local_hash ]; then
    status "No code changes detected...but deploying anyway!"
  fi
fi

foldername="$date_string-$remote_hash"
version_str=$foldername
status "Folder Name: $foldername"
status "Deployment Directory: $deploy_directory/releases/$foldername"

cd $deploy_directory/releases
if [ -f $deploy_directory/build*.zip ]; then
  status "Deploying from an archive..."

  file=$(ls "$deploy_directory" | grep "^build.*zip$" | head -1)
  version_str=$(echo "$file" | cut -f 1 -d '.')
  echo "file=$file"
  echo "version_str=$version_str"

  mkdir $foldername
  cd $foldername
  unzip -q $deploy_directory/build*.zip
  touch "archived_deployed.lock"

  rm $deploy_directory/build*.zip
else
  status "Deploying from a git repository..."
  git clone --depth 1 $repo $foldername
fi

cd $deploy_directory/releases/$foldername

chmod 660 hash*

source $my_path/builders/$app_type/build.sh

title "Updating APP_VERSION in the .env"
if [ -f $deploy_directory/symlinks/.env ]; then
  echo "app_version=$version_str"
  sed -i "s|APP_VERSION=.*|APP_VERSION=$version_str|" $deploy_directory/symlinks/.env
fi

title "Activate"
if [[ -h $deploy_directory/current ]]; then
  current_link=$(readlink $deploy_directory/current)
  status "Unlinking: $current_link"
  unlink $deploy_directory/current
fi
status "  Linking: $deploy_directory/releases/$foldername"
ln -sf $deploy_directory/releases/$foldername $deploy_directory/current

max_to_keep=6
title "Cleanup (keeping the most recent $max_to_keep deployments)"
ls -dt $deploy_directory/releases/* | tail -n +$max_to_keep | xargs rm -rf

cd $initial_working_directory
