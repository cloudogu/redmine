#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}"/default-config.sh

echo "setting redmine environment variables..."
RAILS_ENV=production
REDMINE_LANG=en
DATABASE_USER=
DATABASE_USER_PASSWORD=
DATABASE_DB=

# DEFAULT_PLUGIN_DIRECTORY contains plugins that come bundled with the dogu. They must be re-installed if a user deletes
# them from the plugin directory
DEFAULT_PLUGIN_DIRECTORY="${WORKDIR}/defaultPlugins"
DEPRECATED_PLUGIN_STORE="/var/tmp/redmine/plugins"
PLUGIN_DIRECTORY="${WORKDIR}/plugins"

function install_plugins(){
  echo "installing plugins..."

  checkDeprecatedPluginDir

  forceInstallBundledPlugins

  # Installing Gems needs either an internet connection for pulling Gem dependencies or
  # all required Gems in the Gem path.
  installPluginGems

  runPluginMigration
}

function runPluginMigration() {
  # run migrations always, because core plugins need also a db migration
  echo "running plugin migrations..."
  exec_rake redmine:plugins:migrate
  echo "plugin migrations... done"
}

function installPluginGems() {
  # Install missing gems if new plugins are going to be installed.
  # Otherwise bundle will detect that there are no changes and thus no new gems are needed
  echo "install missing gems ..."

  rakeExitCode=0
  RAILS_ENV="${RAILS_ENV}" REDMINE_LANG="${REDMINE_LANG}" bundle install || rakeExitCode=$?
  if [[ ${rakeExitCode} -ne 0 ]]; then
    echo "ERROR: Rake bund installed returned with an error during the gem installation for new plugins"
    sleep 300
    exit 1
  fi

  echo "missing gems ... installed"
}

# installs or upgrades the given plugin
function install_plugin(){
  NAME="${1}"
  SOURCE="${DEFAULT_PLUGIN_DIRECTORY}/${NAME}"
  TARGET="${PLUGIN_DIRECTORY}/${NAME}"

  if [ ! -d "${SOURCE}" ]; then
    echo "ERROR: ${SOURCE} is not a directory. Skipping this plugin..."
    return
  fi

  echo "deinstall bundled plugin ${NAME}"
  rm -rf "${TARGET}"

  echo "install bundled plugin ${NAME}"
  cp -rf "${SOURCE}" "${TARGET}"
}

function checkDeprecatedPluginDir() {
  if [[ -n "$(ls -A "${DEPRECATED_PLUGIN_STORE}")" ]]; then
     echo "WARNING: Found plugins in the deprecated plugin directory ${DEPRECATED_PLUGIN_STORE}. Please use the plugin volume which maps to ${PLUGIN_DIRECTORY} instead."
  fi
}

function forceInstallBundledPlugins() {
  PLUGINS=$(ls "${DEFAULT_PLUGIN_DIRECTORY}")

  for PLUGIN_PACKAGE in ${PLUGINS}; do
    install_plugin "${PLUGIN_PACKAGE}"
  done
}

function exec_rake() {
  RAILS_ENV="${RAILS_ENV}" REDMINE_LANG="${REDMINE_LANG}" rake --trace -f "${WORKDIR}"/Rakefile "$*"
}

function create_secrets_yml() {
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
  # this happens after a restore of the dogu, because the config folder is not backed up
  echo "Rendering config/secrets.yml..."
  doguctl template "${WORKDIR}/config/secrets.yml.tpl" "${WORKDIR}/config/secrets.yml"
fi
}

function render_config_ru_template() {
    doguctl template "${WORKDIR}/config.ru.tpl" "${WORKDIR}/config.ru"
}

function render_database_yml_template() {
    doguctl template "${WORKDIR}/config/database.yml.tpl" "${WORKDIR}/config/database.yml"
}

function render_configuration_yml_template() {
    doguctl template "${WORKDIR}/config/configuration.yml.tpl" "${WORKDIR}/config/configuration.yml"
}

function sql(){
  PGPASSWORD="${DATABASE_USER_PASSWORD}" psql --host "postgresql" --username "${DATABASE_USER}" --dbname "${DATABASE_DB}" -1 -c "${1}"
}

function get_setting_value() {
  SETTING_NAME=$1
  PGPASSWORD="${DATABASE_USER_PASSWORD}" psql -t \
    --host "postgresql" \
    --username "${DATABASE_USER}" \
    --dbname "${DATABASE_DB}" \
    -1 -c "SELECT value FROM settings WHERE name='${SETTING_NAME}';"
}

function stop_redmine_daemon(){
  kill "${PID}"
}

# Starts redmine as daemon and waits until it is available.
function start_redmine_in_background(){
  echo "Starting redmine in background..."
  exec su - redmine -c "FQDN=${FQDN} ADMIN_GROUP=${ADMIN_GROUP} puma -e ${RAILS_ENV} -p 3000" >> /dev/null &
  PID=$!
  wait_for_redmine_to_get_healthy 300
}

# Creates an admin user by using the create-admin.sh script
function create_temporary_admin() {
  echo "Creating temporary admin..."
  TMP_ADMIN_NAME="$(doguctl random)"
  TMP_ADMIN_PASSWORD="$(doguctl random)"

  # In case we are in restart loop to prevent infinite admin users...
  remove_last_temporary_admin

  # shellcheck disable=SC1091
  source "/create-admin.sh" "${TMP_ADMIN_NAME}" "${TMP_ADMIN_PASSWORD}"
  doguctl config -e "last_tmp_admin" "${TMP_ADMIN_NAME}"
}

# Removes the temporary admin created by 'create_temporary_admin' function.
# Uses etcd key 'last_tmp_admin' to get the name of the last temporary admin.
# After successfully removing the admin, the key 'last_tmp_admin' is also removed.
function remove_last_temporary_admin() {
  # Empty string is not possible with doguctl command
  local DEFAULT="<empty>"
  local LAST_TMP_ADMIN
  LAST_TMP_ADMIN="$(doguctl config -e --default "${DEFAULT}" last_tmp_admin)"

  if [ "${LAST_TMP_ADMIN}" != "${DEFAULT}" ]
  then
    echo "Removing last temporary admin..."
    # shellcheck disable=SC1091
    source "/remove-user.sh" "${LAST_TMP_ADMIN}"
    doguctl config --rm last_tmp_admin
  fi
}

function default_data_imports_exist() {
  if [ "${DEFAULT_DATA}" != "${EMPTY}" ]; then
    echo "true"
  else
    echo "false"
  fi
}

function trigger_imports(){
    local EMPTY="<empty>"
    DEFAULT_DATA=$(doguctl config --default "${EMPTY}" "${DEFAULT_DATA_KEY}")

    if [ "$(default_data_imports_exist)" == "true" ]; then
      create_temporary_admin
      start_redmine_in_background

      if [ "$(default_data_imports_exist)" == "true" ]; then
        echo "IMPORT-INFO: starting default data import"
        apply_default_data "${DEFAULT_DATA}"
      else
        echo "IMPORT-INFO: no default data to import"
      fi

      stop_redmine_daemon
      remove_last_temporary_admin
    else
      echo "IMPORT-INFO: Startup without any import. No temporary admin will be created."
    fi
}

function wait_for_redmine_to_get_healthy() {
  WAIT_TIMEOUT=${1}
  echo "Waiting up to ${WAIT_TIMEOUT} seconds for Redmine endpoint to get ready..."
  if ! doguctl wait-for-http -u "${TMP_ADMIN_NAME}" -p "${TMP_ADMIN_PASSWORD}" --timeout "${WAIT_TIMEOUT}" --method GET "http://127.0.0.1:3000/redmine/extended_api/v1/settings"; then
    echo "timeout reached while waiting for Redmine endpoint to be available"
    exit 1
  else
    echo "Redmine endpoint is available"
  fi
}

function runUtil() {
  echo "get data for database connection"
  DATABASE_USER="$(doguctl config -e sa-postgresql/username)"
  DATABASE_USER_PASSWORD="$(doguctl config -e sa-postgresql/password)"
  DATABASE_DB="$(doguctl config -e sa-postgresql/database)"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runUtil
fi
