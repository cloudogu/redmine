#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ $# -ne 1 ]]; then
    echo "Wrong number of arguments - Plugin name must be given as the first argument."
    exit 1
fi

plugin_name=$1

# Automate uninstall steps from official Redmine guide -
# https://www.redmine.org/projects/redmine/wiki/plugins#Uninstalling-a-plugin
echo "Delete plugin ${plugin_name}"
bundle exec rake redmine:plugins:migrate NAME=${plugin_name} VERSION=0 RAILS_ENV=production
rm -rf /usr/share/webapps/redmine/plugins/${plugin_name}

echo "---"
echo "To complete the deletion of the plugin, the Redmine dogu must be restarted once."
