#!/bin/bash

common_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
root_path="$common_path/.."

source $common_path/helpers.sh

source $common_path/parse_yaml.sh
eval $(parse_yaml $root_path/config.yml)

IFS=","
read -ra servers <<< "$servers"

source $common_path/app_config.sh