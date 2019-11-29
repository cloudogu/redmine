#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# import util functions:
# - create_secrets_yml
# - render_config_ru_template
# - render_database_yml_template
# - render_configuration_yml_template
# - exec_rake
#
# import util variables:
# - RAILS_ENV
# - REDMINE_LANG
#
# shellcheck disable=SC1091
source /util.sh

FROM_VERSION="${1}"
TO_VERSION="${2}"

echo "Executing Redmine post-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
  echo "FROM and TO versions are the same; Exiting..."
  exit 0
fi

echo "Making sure config/secrets.yml exists..."
create_secrets_yml

echo "Rendering config.ru template..."
render_config_ru_template

echo "Rendering database.yml template..."
render_database_yml_template

echo "Generating configuration.yml from template..."
render_configuration_yml_template

echo "Migrating database..."
exec_rake db:migrate

echo "Migrating plugins..."
exec_rake redmine:plugins:migrate

echo "Clearing cache..."
exec_rake tmp:cache:clear

echo "Set etcd flag so startup script can start afterwards..."
# Note: This flag has been set to "true" in pre-upgrade.sh
doguctl state "upgrade done"

echo "Redmine post-upgrade done"
