#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}"/default-config.sh
# keys that are only modifiable from outside the dogu
DEFAULT_DATA_KEY="${DEFAULT_DATA_PREFIX}/new_configuration"
# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}"/update-password-policy.sh

echo "setting redmine environment variables..."
RAILS_ENV=production
REDMINE_LANG=en
DATABASE_USER=
DATABASE_USER_PASSWORD=
DATABASE_DB=
CONFIG_ADMIN_NAME="ces-config-admin"
CONFIG_ADMIN_PASSWORD="please-set-me"

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

# create_configuration_admin creates an admin user by using a ruby script to authenticate against the API.
# The configuration admin is volatile and might be deleted between dogu restarts.
function create_or_update_configuration_admin() {
  echo "Creating configuration admin..."

  local doesAdminAlreadyExist
  doesAdminAlreadyExist=$(sql "SELECT login FROM users WHERE login='${CONFIG_ADMIN_NAME}';" | grep -c "${CONFIG_ADMIN_NAME}"  || true) # always true: grep count returns an exitcode of 1 if not found but will still print the value "0"

  if [[ ${doesAdminAlreadyExist} != "0" ]]; then
    echo "Found already existing configuration admin."
    sql "update users set status = '1' where login = '${CONFIG_ADMIN_NAME}';" # enable config_admin
    update_configuration_admin_password
    return
  fi

  create_random_admin_password

  RAILS_TIMEOUT="$(doguctl config rails_script_timeout)"
  railsConsoleRetryOnce "${RAILS_TIMEOUT}"  "${RAILS_SCRIPTS_DIR}/create_admin.rb" --username "${CONFIG_ADMIN_NAME}" --password "${CONFIG_ADMIN_PASSWORD}" || exit 1
}

function create_random_admin_password() {
  # The Password must contain a special character, a lowercase letter, a capital letter and a number...
  local CONFIG_ADMIN_PASSWORD_SUFFIX="aB&5"
  local ADMIN_RANDOMIZED_STR
  ADMIN_RANDOMIZED_STR="$(doguctl random -l 60)"
  CONFIG_ADMIN_PASSWORD="${ADMIN_RANDOMIZED_STR}${CONFIG_ADMIN_PASSWORD_SUFFIX}"
}

function update_configuration_admin_password() {
  create_random_admin_password

  RAILS_TIMEOUT="$(doguctl config rails_script_timeout)"
  railsConsoleRetryOnce "${RAILS_TIMEOUT}" "${RAILS_SCRIPTS_DIR}/update_admin_pw.rb" --username "${CONFIG_ADMIN_NAME}" --password "${CONFIG_ADMIN_PASSWORD}"
  echo "Configuration admin received a new password."
}

function default_data_imports_exist() {
  local defaultData="${1}"
  if [ "${defaultData}" != "${EMPTY}" ]; then
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

  create_or_update_configuration_admin
  start_redmine_in_background

  # tasks
  trigger_imports || true
  update_password_policy_setting

  # cleanup
  stop_redmine_daemon
  sql "update users set status = '3' where login = '${CONFIG_ADMIN_NAME}';" # disable config_admin
  railsConsole "${RAILS_SCRIPTS_DIR}/update_settings.rb" --allow_local_users "${ALLOW_LOCAL_USERS}"
  echo "Finished background configuration tasks"
}

function trigger_imports(){
    local EMPTY="<empty>"
    DEFAULT_DATA=$(doguctl config --default "${EMPTY}" "${DEFAULT_DATA_KEY}")
    if [ "$(default_data_imports_exist "${DEFAULT_DATA}")" == "true" ]; then
      echo "IMPORT-INFO: found existing default data to apply"
      apply_default_data_if_new "${DEFAULT_DATA}"
    else
      echo "IMPORT-INFO: no default data to import"
    fi
}

function wait_for_redmine_to_get_healthy() {
  WAIT_TIMEOUT=${1}
  echo "Waiting up to ${WAIT_TIMEOUT} seconds for Redmine endpoint to get ready..."
  if ! doguctl wait-for-http -u "${CONFIG_ADMIN_NAME}" -p "${CONFIG_ADMIN_PASSWORD}" --timeout "${WAIT_TIMEOUT}" --method GET "http://127.0.0.1:3000/redmine/extended_api/v1/settings"; then
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

function railsConsoleRetryOnce() {
  local RETRY_AFTER=${1}
  local SCRIPT_NAME=${2}
  local SCRIPT_ARGS=("${@:3}")

  echo "Run rails script ${SCRIPT_NAME}"
  rails r -e production "${SCRIPT_NAME}" "${SCRIPT_ARGS[@]}" &

  echo "Waiting up to ${RETRY_AFTER} seconds for script ${SCRIPT_NAME} to finish."
  local PID=$!
  for _ in $(seq 1 "${RETRY_AFTER}"); do
    if [[ -d /proc/${PID} ]]; then
      sleep 1
    else
      # returns exit code of the background process
      wait $PID
      return $?
    fi
  done

  echo "Script ${SCRIPT_NAME} did not finish after ${RETRY_AFTER} seconds. Killing it and running it again..."
  kill -9 ${PID}
  rails r -e production "${SCRIPT_NAME}" "${SCRIPT_ARGS[@]}"
  return $?
}


# make the script only run when executed, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetchDatabaseConnection
fi

