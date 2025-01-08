#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}"/default-config.sh
# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}"/update-password-policy.sh

echo "setting redmine environment variables..."
RAILS_ENV=production
REDMINE_LANG=en
DATABASE_USER=
DATABASE_USER_PASSWORD=
DATABASE_DB=

# DEFAULT_PLUGIN_DIRECTORY contains plugins that come bundled with the dogu. They must be re-installed if a user deletes
# them from the plugin directory
DEFAULT_PLUGIN_DIRECTORY="${WORKDIR}/defaultPlugins"
PLUGIN_STORE="/var/tmp/redmine/plugins"
PLUGIN_DIRECTORY="${WORKDIR}/plugins"

RAILS_SCRIPTS_DIR=/rails_scripts

function install_plugins(){
  echo "installing plugins..."

  installBundledPlugins

  installCustomPlugins

  # Installing Gems needs either an internet connection for pulling Gem dependencies or
  # all required Gems in the Gem path.
  runPluginMigration
}

function runPluginMigration() {
  # run migrations always, because core plugins need also a db migration
  echo "running plugin migrations..."
  exec_rake redmine:plugins:migrate
  echo "plugin migrations... done"
}

function installMissingGems() {
  # Install missing gems if new plugins are going to be installed.
  # Otherwise bundle will detect that there are no changes and thus no new gems are needed
  echo "install missing gems ..."

  rakeExitCode=0
  RAILS_ENV="${RAILS_ENV}" REDMINE_LANG="${REDMINE_LANG}" bundle install --quiet || rakeExitCode=$?
  if [[ ${rakeExitCode} -ne 0 ]]; then
    echo "ERROR: bundle install returned with an error during the gem installation"
    sleep 300
    exit 1
  fi

  echo "missing gems ... installed"
}

# installs or upgrades the given plugin
function install_plugin(){
  SOURCE_DIRECTORY="${1}"
  NAME="${2}"
  SOURCE="${SOURCE_DIRECTORY}/${NAME}"
  TARGET="${PLUGIN_DIRECTORY}/${NAME}"

  if [ ! -d "${SOURCE}" ]; then
    echo "ERROR: ${SOURCE} is not a directory. Skipping this plugin..."
    return
  fi

  echo "remove plugin ${NAME}"
  rm -rf "${TARGET}"

  echo "install plugin ${NAME}"
  cp -rf "${SOURCE}" "${TARGET}"
}

function installBundledPlugins() {
  echo "install default plugins ..."

  PLUGINS=$(ls "${DEFAULT_PLUGIN_DIRECTORY}")
  for PLUGIN_PACKAGE in ${PLUGINS}; do
    install_plugin "${DEFAULT_PLUGIN_DIRECTORY}" "${PLUGIN_PACKAGE}"
  done
}

function installCustomPlugins() {
  echo "install custom plugins ..."

  PLUGINS=$(ls "${PLUGIN_STORE}")
  for PLUGIN_PACKAGE in ${PLUGINS}; do
    install_plugin "${PLUGIN_STORE}" "${PLUGIN_PACKAGE}"
  done
}

function exec_rake() {
  # Installing Gems needs either an internet connection for pulling Gem dependencies or
  # all required Gems in the Gem path.
  # Installing missing Gems is necessary at this point. The following rake task execution works only if the
  # dependencies required by plugins and the core modules are present.
  installMissingGems
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
  local stmt="${1}"
  PGPASSWORD="${DATABASE_USER_PASSWORD}" psql --host "postgresql" --username "${DATABASE_USER}" --dbname "${DATABASE_DB}" -1 -c "${stmt}"
}

function sqlForSelect(){
  local stmt="${1}"
  local returnOnlyTheSelectedValue="-tA"
  PGPASSWORD="${DATABASE_USER_PASSWORD}" psql "${returnOnlyTheSelectedValue}" --host "postgresql" --username "${DATABASE_USER}" --dbname "${DATABASE_DB}" -1 -c "${stmt}"
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

# Creates an admin user by using the create_admin.rb script
function create_temporary_admin() {
  echo "Creating temporary admin..."
  # The Password must contain a special character, a lowercase letter, a capital letter and a number...
  local TMP_ADMIN_PASSWORD_SUFFIX="aB&5"
  TMP_ADMIN_NAME="$(doguctl random)"
  local TMP_ADMIN_RANDOMIZED_STR
  TMP_ADMIN_RANDOMIZED_STR="$(doguctl random -l 60)"
  TMP_ADMIN_PASSWORD="${TMP_ADMIN_RANDOMIZED_STR}${TMP_ADMIN_PASSWORD_SUFFIX}"

  # In case we are in restart loop to prevent infinite admin users...
  remove_last_temporary_admin

  railsConsole "/rails_scripts/create_admin.rb" --username "${TMP_ADMIN_NAME}" --password "${TMP_ADMIN_PASSWORD}" || exit 1
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
    railsConsole "/rails_scripts/remove_user.rb" --username "${LAST_TMP_ADMIN}" || exit 1
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

function background_configuration_tasks() {
  echo "Start background configuration tasks"
  # setup
  local ALLOW_LOCAL_USERS
  ALLOW_LOCAL_USERS="$(railsConsole "${RAILS_SCRIPTS_DIR}/get_setting.rb" --key "local_users_enabled" | grep "{\"result\":" | jq -r ".result")"

  if [[ "${ALLOW_LOCAL_USERS}" == "null" ]]; then
    ALLOW_LOCAL_USERS=0
  fi

  railsConsole "${RAILS_SCRIPTS_DIR}/update_settings.rb" --allow_local_users "1"
  create_temporary_admin
  start_redmine_in_background

  # tasks
  trigger_imports || true
  update_password_policy_setting


  # cleanup
  stop_redmine_daemon
  remove_last_temporary_admin
  railsConsole "${RAILS_SCRIPTS_DIR}/update_settings.rb" --allow_local_users "${ALLOW_LOCAL_USERS}"
  echo "Finished background configuration tasks"
}

function trigger_imports(){
    local EMPTY="<empty>"
    DEFAULT_DATA=$(doguctl config --default "${EMPTY}" "${DEFAULT_DATA_KEY}")+
    if [ "$(default_data_imports_exist)" == "true" ]; then
      echo "IMPORT-INFO: starting default data import"
      apply_default_data "${DEFAULT_DATA}"
    else
      echo "IMPORT-INFO: no default data to import"
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

function fetchDatabaseConnection() {
  echo "get data for database connection"
  DATABASE_USER="$(doguctl config -e sa-postgresql/username)"
  DATABASE_USER_PASSWORD="$(doguctl config -e sa-postgresql/password)"
  DATABASE_DB="$(doguctl config -e sa-postgresql/database)"
}

function railsConsole() {
  rails r -e production "$@"
}

# make the script only run when executed, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetchDatabaseConnection
fi

