#!/bin/bash

initial_working_directory=$(pwd)
my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

source $my_path/../common/helpers.sh

title "Create New Application Form"

read -p "Enter the deployment username (e.g., demo_1):" username

while [ -z "$username" ] || [ $(getent passwd "$username") ]; do
  echo "The username '$username' already exists."
  read -p "Enter another deployment username:" username
done

read -s -p "Deployment user password: " password
echo

read -s -p "Confirm deployment user password: " confirm_password
echo
if [[ "$password" != "$confirm_password" ]]; then
  echo "Passwords do not match."
  exit 1
fi

read -p "Database name (e.g., ale_db): " db_database
read -p "Database username: " db_username
read -p "Database password (e.g., hardPassword): " db_password

read -p "Application port number (e.g., 8000): " application_port

read -p "Git repo url: " git_repo_url

read -p "Laravel Reverb (y or n): " has_reverb
read -p "Laravel Horizon (y or n): " has_horizon
read -p "Laravel Pulse (y or n): " has_pulse
read -p "Laravel Queue (y or n): " has_queue

app_type="laravel"

read -p "Public SSH Key for Remote Access As Deployment User: " public_ssh_key

if [[ ! -d $my_path/../apps ]]; then
  mkdir $my_path/../apps
fi

cd $my_path/../apps

sudo cp $my_path/_app.sh $my_path/../apps/$username.sh
sudo sed -i "s|username=UNAME|username=$username|" $my_path/../apps/$username.sh
sudo sed -i "s|password=PWORD|password=$password|" $my_path/../apps/$username.sh
sudo sed -i "s|db_database=DB_DBASE|db_database=$db_database|" $my_path/../apps/$username.sh
sudo sed -i "s|db_username=DB_UNAME|db_username=$db_username|" $my_path/../apps/$username.sh
sudo sed -i "s|db_password=DB_PWORD|db_password=$db_password|" $my_path/../apps/$username.sh
sudo sed -i "s|app_type=APP_TYPE|app_type=$app_type|" $my_path/../apps/$username.sh
sudo sed -i "s|app_port=PORT|app_port=$application_port|" $my_path/../apps/$username.sh
sudo sed -i "s|repo=REPO_URL|repo=$git_repo_url|" $my_path/../apps/$username.sh
sudo sed -i "s|public_ssh_key=PUB_SSH_KEY|public_ssh_key=\"$public_ssh_key\"|" $my_path/../apps/$username.sh
sudo sed -i "s|has_reverb=HAS_REVERB|has_reverb=$has_reverb|" $my_path/../apps/$username.sh
sudo sed -i "s|has_horizon=HAS_HORIZON|has_horizon=$has_horizon|" $my_path/../apps/$username.sh
sudo sed -i "s|has_pulse=HAS_PULSE|has_pulse=$has_pulse|" $my_path/../apps/$username.sh
sudo sed -i "s|has_queue=HAS_QUEUE|has_queue=$has_queue|" $my_path/../apps/$username.sh

title "Status"
if [ -f $my_path/../apps/$username.sh ]; then
  echo "A new application config file has been created at:"
  status "$my_path/../apps/$username.sh"
  echo ""
  echo ""
  echo "Next Steps:"
  status "1. Review the config file"
  status "2. Create the application by executing: appCreate $username"
else
  error "Failed to create a new application config file."
fi

cd $initial_working_directory || exit
