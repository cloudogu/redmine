#!/bin/bash
#set -o errexit
#set -o nounset
#set -o pipefail

echo "setting redmine environment variables..."
RAILS_ENV=production
REDMINE_LANG=en

#function log_debug(){
#  local MSG="${1}"
#  if [ "${REDMINE_LOGLEVEL}" = ":debug" ]; then
#    echo "${MSG}"
#  fi
#}

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

echo "get data for database connection"
DATABASE_USER=$(doguctl config -e sa-postgresql/username)
DATABASE_USER_PASSWORD=$(doguctl config -e sa-postgresql/password)
DATABASE_DB=$(doguctl config -e sa-postgresql/database)

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

function create_temporary_admin() {
  echo "Creating temporary admin..."
  TMP_ADMIN_NAME="$(doguctl random)"
  TMP_ADMIN_PASSWORD="$(doguctl random)"

  # In case we are in restart loop to prevent infinite admin users...
  remove_last_temporary_admin

  source "/create-admin.sh" "${TMP_ADMIN_NAME}" "${TMP_ADMIN_PASSWORD}"
}

function remove_last_temporary_admin() {
  # Empty string is not possible with doguctl command
  local DEFAULT="<empty>"
  local LAST_TMP_ADMIN
  LAST_TMP_ADMIN="$(doguctl config --default "${DEFAULT}" last_tmp_admin)"

  if [ "${LAST_TMP_ADMIN}" != "${DEFAULT}" ]
  then
    echo "Removing last temporary admin..."
    source "/remove-user.sh" "${LAST_TMP_ADMIN}"
    doguctl config --rm last_tmp_admin
  fi
}

function curl_extended_api(){
  local BASE_URL="http://127.0.0.1:3000/redmine/extended_api/v1"
  local API="${1}"
  local METHOD="${2}"
  local PAYLOAD
  # Make sure the json is a oneliner for better overview in output
  PAYLOAD="$(echo "${3}" |jq -c)"

  echo "Execute curl to extended_api..."


  URL="${BASE_URL}/${API}"

  local CURL_COMMAND="curl -L -H 'accept: */*' -H 'Content-Type: application/json' -X ${METHOD} -u ${TMP_ADMIN_NAME}:${TMP_ADMIN_PASSWORD} --silent --write-out 'HTTPSTATUS:%{http_code}' -d '${PAYLOAD}' ${URL}"
  echo "${CURL_COMMAND}"
  HTTP_RESPONSE=$(bash -c "${CURL_COMMAND}")
  # shellcheck disable=SC2001 => Doesn't work
  HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')
  if [ -z "${HTTP_BODY}" ]
  then
    HTTP_BODY="{}"
  fi
  HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')


  RESPONSE="{\"body\": ${HTTP_BODY}, \"status\": ${HTTP_STATUS}}"
  echo "${RESPONSE}" >> /file.txt


#  echo "Execute curl to extended_api..."
#  echo "curl command is: "
#  local CURL_COMMAND="curl --fail -X '${METHOD}' -L -H 'accept: */*' -H 'Content-Type: application/json' -u ${TMP_ADMIN_NAME}:${TMP_ADMIN_PASSWORD} ${BASE_URL}/${API} -d '${PAYLOAD}'"
#  echo "${CURL_COMMAND}"
#  bash -c "${CURL_COMMAND}"
}

function add_settings(){
  echo "Apply settings..."
  local JSON="${1}"
  echo "Found settings config: ${JSON}"
  curl_extended_api "settings" "PUT" "${JSON}" || echo "Failed to apply settings: '${JSON}'"
}

function add_trackers(){
  echo "add trackers..."
  local JSON="${1}"
  echo "Found tracker config: ${JSON}"
  echo "${JSON}" |jq -c -r .[] | while IFS= read -r TRACKER ;
  do
    curl_extended_api "trackers" "POST" "${TRACKER}" || echo "Failed to apply tracker: '${TRACKER}'"
  done
}

function validate_default_config(){
  echo "Validate configuration..."
  echo "${DEFAULT_CONFIGURATION}" |jq
}

function start_redmine_in_background(){
  echo "Starting redmine in background..."
  rails server --daemon
}

function stop_redmine(){
  echo "Stopping redmine..."
  kill "$(cat /usr/share/webapps/redmine/tmp/pids/server.pid)"
}
