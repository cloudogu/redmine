#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

echo "Executing Redmine post-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
  echo "FROM and TO versions are the same; Exiting..."
  exit 0
fi

function exec_rake() {
  RAILS_ENV="production" REDMINE_LANG="en" rake --trace -f "${WORKDIR}"/Rakefile "$*"
}

echo "Making sure config/secrets.yml exists..."
if [ ! -f "${WORKDIR}/config/secrets.yml" ]; then
  if [[ $(doguctl config -e secret_key_base > /dev/null; echo $?) -ne 0 ]]; then
    # secret_key_base has not been initialized yet
    echo "Generating secret token..."
    exec_rake generate_secret_token
    SECRETKEYBASE=$(grep secret_key_base "${WORKDIR}"/config/initializers/secret_token.rb | awk -F \' '{print $2}' )
    doguctl config -e secret_key_base "${SECRETKEYBASE}"
    rm "${WORKDIR}/config/initializers/secret_token.rb"
  fi
  # secret_key_base is stored in registry, but secrets.yml is missing
    echo "Rendering config/secrets.yml..."
  doguctl template "${WORKDIR}/config/secrets.yml.tpl" "${WORKDIR}/config/secrets.yml"
fi

echo "Rendering config.ru template..."
doguctl template "${WORKDIR}/config.ru.tpl" "${WORKDIR}/config.ru"

echo "Rendering database.yml template..."
doguctl template "${WORKDIR}/config/database.yml.tpl" "${WORKDIR}/config/database.yml"

echo "Generating configuration.yml from template..."
doguctl template "${WORKDIR}/config/configuration.yml.tpl" "${WORKDIR}/config/configuration.yml"

echo "Migrating database..."
exec_rake db:migrate

echo "Migrating plugins..."
exec_rake redmine:plugins:migrate

echo "Clearing cache..."
exec_rake tmp:cache:clear

echo "Set etcd flag so startup script can start afterwards..."
# Note: This flag has been set to "true" in pre-upgrade.sh
doguctl config post_upgrade_running "false"

echo "Redmine post-upgrade done"
