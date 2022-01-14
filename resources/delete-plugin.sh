#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

num_min_required_params=1
num_max_required_params=2
num_params=$#

function print_usage() {
    echo "usage: delete-plugin[.sh] <plugin-name> --force"
    echo "1st parameter: name of the plugin"
    echo "2nd parameter: '--force' flag to start the actual execution of the deletion process"
    echo
    echo "Deletes the plugin passed as 1st parameter."
    echo
    print_backup_info
    echo
    echo "To execute the deletion of the plugin add --force flag as 2nd parameter"
}

function print_backup_info() {
    echo "As the removal of the plugin may also result in changes to the database,"
    echo "it is recommended to make a backup of the database before removing the plugin."
}

if [[ $# -lt $num_min_required_params  || $# -gt $num_max_required_params ]]; then
    echo "Wrong number of arguments - Plugin name must be given as the first argument."
    echo
    print_usage
    exit 1
fi

plugin_name=$1

if [[ $num_params -eq 1 ]]; then
    print_backup_info
    echo
    echo "Insert the flag --force at the end of the command to definitely uninstall the selected plugin $plugin_name"
    echo
    print_usage
    exit 1
fi


force_param=$2
if [[ $force_param == "--force" ]]; then
  # Automate uninstall steps from official Redmine guide -
  # https://www.redmine.org/projects/redmine/wiki/plugins#Uninstalling-a-plugin
  echo "Delete plugin ${plugin_name}"
  bundle exec rake redmine:plugins:migrate NAME=${plugin_name} VERSION=0 RAILS_ENV=production
  rm -rf /usr/share/webapps/redmine/plugins/${plugin_name}

  echo "---"
  echo "To complete the deletion of the plugin, the Redmine dogu must be restarted once."
else
  print_usage
fi