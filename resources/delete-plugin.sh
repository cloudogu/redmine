#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ $# -ne 1 ]]; then
    echo "Illegal number of arguments - plugin_name must be given as first argument"
    exit 1
fi

plugin_name=$1
echo "delete plugin ${plugin_name}"
bundle exec rake redmine:plugins:migrate NAME=${plugin_name} VERSION=0 RAILS_ENV=production
rm -rf /usr/share/webapps/redmine/plugins/${plugin_name}
echo "---"
echo "In order to save the changes you have made, you must restart the system"
