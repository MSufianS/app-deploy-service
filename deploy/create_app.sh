#!/bin/bash

my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
if [ $# -eq 0 ]; then
  echo "No app specified!"
  existing_apps=$(ls $my_path/../apps/ | sed -e 's|\.[^.]*$||')
  echo "Try one of these applications:"
  echo "$existing_apps"
  exit 1
fi

app_name="$1"

initial_working_directory=$(pwd)
my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$my_path"

source $my_path/../common/load_common.sh

title "Create Deployment User: $username"
if id "$username" >/dev/null 2>&1; then
  error "This user already exists. Username: $username"
else
  sudo adduser --gecos "" --disabled-password $username
  sudo chpasswd <<<"$username:$password"

  title "Creating Github Deployment Keys"
  sudo su - $username <<EOF
# Create the Github keys
ssh-keygen -f ~/.ssh/github_rsa -t rsa -N ""
cat <<EOT >> ~/.ssh/config
Host github.com
        IdentityFile ~/.ssh/github_rsa
        IdentitiesOnly yes
EOT
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*

echo "----------------------COPY PUB KEY TO GITHUB DEPLOYMENT KEYS---------------------"
cat < ~/.ssh/github_rsa.pub
echo "---------------------------------------------------------------------------------"

# End session
exit
EOF

  title "Adding www-data to user group: $username"
  sudo usermod -a -G $username www-data

  title "Creating Laravel .env File"
  sudo su - $username <<EOF
if [ ! -d $deploy_directory/symlinks ]; then
  mkdir -p $deploy_directory/symlinks
fi
if [ ! -f $deploy_directory/symlinks/.env ]; then
  cp $my_path/_laravel.env $deploy_directory/symlinks/.env
  sed -i "s|DB_DATABASE=.*|DB_DATABASE=$db_database|" $deploy_directory/symlinks/.env
  sed -i "s|DB_USERNAME=.*|DB_USERNAME=$db_username|" $deploy_directory/symlinks/.env
  sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$db_password|" $deploy_directory/symlinks/.env
  sed -i "s|HORIZON_PREFIX=.*|HORIZON_PREFIX=$username|" $deploy_directory/symlinks/.env

  echo "Created .env file: $deploy_directory/symlinks/.env"
else
  echo "Found .env file: $deploy_directory/symlinks/.env"
fi
EOF

  title "Next Steps"
  echo "1. Install the above deployment key into your Git repo."
  echo "2. Review the created .env ($deploy_directory/symlinks/.env) and make desired changes."
  echo "3. Re run the following: appCreate $username"

  exit
fi

title "Adding SSH public key to authorized_keys for user: $username"
sudo su - $username <<EOF
if [ ! -f /home/$username/.ssh/authorized_keys ]; then
    touch /home/$username/.ssh/authorized_keys
    chmod 600 /home/$username/.ssh/authorized_keys
fi
if grep -q "$public_ssh_key" /home/$username/.ssh/authorized_keys; then
  echo "Key Already Installed: /home/$username/.ssh/authorized_keys"
else
  echo "$public_ssh_key" >> /home/$username/.ssh/authorized_keys
  echo "Key Installed: /home/$username/.ssh/authorized_keys"
fi
EOF
status "You should now be able to SSH in using this user. Something like:"
public_ip_address=$(curl -s ifconfig.me)
status "ssh -i path/to/key $username@$public_ip_address"

title "Adding a deployment for user: $username"
alias_str="alias deploy='/usr/local/bin/devops/deploy/deploy.sh'"
sudo su - $username <<EOF
if [ ! -f /home/$username/.bash_aliases ]; then
    touch /home/$username/.bash_aliases
fi
if grep -q "$alias_str" /home/$username/.bash_aliases; then
  echo "Alias Already Exists: /home/$username/.bash_aliases"
else
  echo "$alias_str" >> /home/$username/.bash_aliases
  source /home/$username/.bashrc
  echo "Alias Created: /home/$username/.bash_aliases"
fi
EOF
status "You should now be able to deploy running 'deploy' while logged in as $username"

title "Creating Initial Deployment"
sudo -u $username $root_path/deploy/deploy.sh

title "Generating Application Key"
sudo -u $username php $deploy_directory/current/artisan key:generate

if [ -f $root_path/deploy/builders/$app_type/init_symlink_data.sh ]; then
  title "Creating Initial Symlinked Data"
  sudo -u $username $root_path/deploy/builders/$app_type/init_symlink_data.sh
fi

title "Creating Crontab for User: $username"
cron_expression="* * * * * cd $deploy_directory/current/ && php artisan schedule:run >> $deploy_directory/current/storage/logs/cron.log 2>&1"
if [ $(sudo -u $username crontab -l | wc -c) -eq 0 ]; then
  sudo -u $username echo "$cron_expression" | sudo crontab -u $username -
  status "Created crontab: $cron_expression"
else
  status "Found crontabs"
fi

# Create nginx conf
title "Creating Nginx Conf"
if [ ! -f /etc/nginx/sites-available/$username.conf ]; then
  if [ "$has_reverb" == "y" ]; then
    sudo cp $root_path/deploy/_nginx_reverb.conf /etc/nginx/sites-available/$username.conf
  else
    sudo cp $root_path/deploy/_nginx.conf /etc/nginx/sites-available/$username.conf
  fi
    sudo sed -i "s|listen PORT;|listen $app_port;|" /etc/nginx/sites-available/$username.conf
    sudo sed -i "s|listen \[::\]:PORT;|listen [::]:$app_port;|" /etc/nginx/sites-available/$username.conf
    sudo sed -i "s|root;|root $deploy_directory/current/public;|" /etc/nginx/sites-available/$username.conf
    sudo sed -i "s|phpXXXX|php$installs_php_version-$username|" /etc/nginx/sites-available/$username.conf
    sudo ln -s /etc/nginx/sites-available/$username.conf /etc/nginx/sites-enabled/$username.conf
    sudo service nginx reload
    status "Created: /etc/nginx/sites-available/$username.conf"
else
  status "Already exists: /etc/nginx/sites-available/$username.conf"
fi

title "Creating PHP-FPM Pool Conf"
if [ ! -f /etc/php/$installs_php_version/fpm/pool.d/$username.conf ]; then
    sudo cp /etc/php/$installs_php_version/fpm/pool.d/www.conf /etc/php/$installs_php_version/fpm/pool.d/$username.conf
    sudo sed -i "s|\[www\]|[$username]|" /etc/php/$installs_php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/user =.*/user = $username/" /etc/php/$installs_php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/group =.*/group = $username/" /etc/php/$installs_php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/listen\.owner.*/listen.owner = $username/" /etc/php/$installs_php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/listen\.group.*/listen.group = $username/" /etc/php/$installs_php_version/fpm/pool.d/$username.conf
    sudo sed -i "s|listen =.*|listen = /run/php/php$installs_php_version-$username-fpm.sock|" /etc/php/$installs_php_version/fpm/pool.d/$username.conf
    sudo service php$installs_php_version-fpm restart
    status "Created: /etc/php/$installs_php_version/fpm/pool.d/$username"
else
  status "Already existsL /etc/php/$installs_php_version/fpm/pool.d/$username.conf"
fi

title "Creating Supervisor Conf"
log_dir="$deploy_directory/current/storage/logs"
# Ensure log directory exists and has the correct permissions
if [ ! -d "$log_dir" ]; then
    sudo mkdir -p "$log_dir"
    sudo chown $username:$username "$log_dir"
    sudo chmod 775 "$log_dir"
    status "Log directory created: $log_dir"
else
    status "Log directory already exists: $log_dir"
fi

# Horizon service setup
if [ "$has_horizon" == "y" ]; then
  if [ ! -f /etc/supervisor/conf.d/$username.conf ]; then
      sudo cp $root_path/deploy/_supervisor.conf /etc/supervisor/conf.d/$username.conf
      sudo sed -i "s|program:|program:horizon_$username|" /etc/supervisor/conf.d/$username.conf
      sudo sed -i "s|command=|command=php $deploy_directory/current/artisan horizon|" /etc/supervisor/conf.d/$username.conf
      sudo sed -i "s|user=|user=$username|" /etc/supervisor/conf.d/$username.conf
      sudo sed -i "s|stdout_logfile=|stdout_logfile=$deploy_directory/current/storage/logs/horizon.log|" /etc/supervisor/conf.d/$username.conf
      sudo supervisorctl reread
      sudo supervisorctl update
      status "Created: /etc/supervisor/conf.d/$username.conf"
  else
      status "Already exists: /etc/supervisor/conf.d/$username.conf"
  fi
else
    status "Horizon is disabled in config.yml. Skipping Supervisor conf for Horizon."
fi

# Pulse service setup
if [ "$has_pulse" == "y" ]; then
  pulse_conf_file="/etc/supervisor/conf.d/${username}_pulse.conf"
  if [ ! -f "$pulse_conf_file" ]; then
      sudo cp $root_path/deploy/_supervisor.conf "$pulse_conf_file"
      sudo sed -i "s|program:|program:pulse_$username|" "$pulse_conf_file"
      sudo sed -i "s|command=|command=php $deploy_directory/current/artisan pulse:check|" "$pulse_conf_file"
      sudo sed -i "s|user=|user=$username|" "$pulse_conf_file"
      sudo sed -i "s|stdout_logfile=|stdout_logfile=$deploy_directory/current/storage/logs/pulse.log|" "$pulse_conf_file"
      sudo supervisorctl reread
      sudo supervisorctl update
      status "Created: $pulse_conf_file"
  else
      status "Already exists: $pulse_conf_file"
  fi
else
    status "Pulse is disabled in config.yml. Skipping Supervisor conf for Pulse."
fi

# Reverb service setup
if [ "$has_reverb" == "y" ]; then
  reverb_conf_file="/etc/supervisor/conf.d/${username}_reverb.conf"
  if [ ! -f "$reverb_conf_file" ]; then
      sudo cp $root_path/deploy/_supervisor.conf "$reverb_conf_file"
      sudo sed -i "s|program:|program:reverb_$username|" "$reverb_conf_file"
      sudo sed -i "s|command=|command=php $deploy_directory/current/artisan reverb:start|" "$reverb_conf_file"
      sudo sed -i "s|user=|user=$username|" "$reverb_conf_file"
      sudo sed -i "s|stdout_logfile=|stdout_logfile=$deploy_directory/current/storage/logs/reverb.log|" "$reverb_conf_file"
      sudo supervisorctl reread
      sudo supervisorctl update
      status "Created: $reverb_conf_file"
  else
      status "Already exists: $reverb_conf_file"
  fi
else
    status "Reverb is disabled in config.yml. Skipping Supervisor conf for Reverb."
fi

cd $initial_working_directory || exit
