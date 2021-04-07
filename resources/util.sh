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
  local PAYLOAD="${3}"
  local EXPECTED_RESPONSE_CODE="${4}"

  echo "Execute curl to extended_api..."

  URL="${BASE_URL}/${API}"

  local CURL_COMMAND="curl -L -H 'accept: */*' -H 'Content-Type: application/json' -X ${METHOD} -u ${TMP_ADMIN_NAME}:${TMP_ADMIN_PASSWORD} --silent --write-out 'HTTPSTATUS:%{http_code}' -d '${PAYLOAD}' ${URL}"
  echo "${CURL_COMMAND}"
  HTTP_RESPONSE=$(bash -c "${CURL_COMMAND}")
  # shellcheck disable=SC2001 ### Doesn't work
  HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')
  if [ -z "${HTTP_BODY}" ]
  then
    HTTP_BODY="{}"
  fi
  HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')


  RESPONSE="{\"body\": ${HTTP_BODY}, \"status\": ${HTTP_STATUS}, \"expectedStatus\": ${EXPECTED_RESPONSE_CODE}}"
  echo "${RESPONSE}" |jq

  if [ ! "${HTTP_STATUS}" -eq "${EXPECTED_RESPONSE_CODE}"  ]; then
    exit 1
  fi
}

function safe_extended_api_call() {
  local API="${1}"
  local METHOD="${2}"
  local PAYLOAD
  # Make sure the json is a oneliner for better overview in output
  PAYLOAD="$(echo "${3}" |jq -c)"
  local EXPECTED_RESPONSE_CODE="${4:-"200"}"

  local ERROR=""
  RESPONSE="$(curl_extended_api "${API}" "${METHOD}" "${PAYLOAD}" "${EXPECTED_RESPONSE_CODE}")" || ERROR="error"

  if [ "${ERROR}" != "" ]
  then
    echo "======================================"
    echo "Call to extended api '${API}' failed. Output:"
    echo "${RESPONSE}"
    echo "======================================"
  else
    echo "Call to '${API}' successful with content: '${PAYLOAD}'"
  fi
}

function add_settings(){
  local JSON="${1}"
  if [ -z "${JSON}" ] || [ "${JSON}" = "null" ];
  then
    echo "No settings provided...";
    return;
  fi

  echo "============> Apply default config for settings..."
  echo "Found settings config: ${JSON}"
  safe_extended_api_call "settings" "PUT" "${JSON}" "204"
}

function add_trackers(){
  local JSON="${1}"
  if [ -z "${JSON}" ] || [ "${JSON}" = "null" ];
  then
    echo "No trackers provided...";
    return;
  fi

  echo "============> Apply default config for trackers..."
  echo "Found tracker config: ${JSON}"
  echo "${JSON}" |jq -c -r .[] | while IFS= read -r TRACKER ;
  do
    safe_extended_api_call "trackers" "POST" "${TRACKER}" "201"
  done
}

function add_issue_statuses(){
  local JSON="${1}"
  if [ -z "${JSON}" ] || [ "${JSON}" = "null" ];
  then
    echo "No issue statuses provided...";
    return;
  fi

  echo "============> Apply default config for issue statuses..."
  echo "Found issue status config: ${JSON}"
  echo "${JSON}" |jq -c -r .[] | while IFS= read -r ISSUE_STATUS ;
  do
    safe_extended_api_call "issue_statuses" "POST" "${ISSUE_STATUS}" "201"
  done
}

function add_custom_fields(){
  local JSON="${1}"
  if [ -z "${JSON}" ] || [ "${JSON}" = "null" ];
  then
    echo "No custom fields provided...";
    return;
  fi

  echo "============> Apply default config for custom fields..."
  echo "Found custom field config: ${JSON}"
  echo "${JSON}" |jq -c -r .[] | while IFS= read -r CUSTOM_FIELD ;
  do
    safe_extended_api_call "custom_fields" "POST" "${CUSTOM_FIELD}" "201"
  done
}

function add_workflows(){
  local JSON="${1}"
  if [ -z "${JSON}" ] || [ "${JSON}" = "null" ];
  then
    echo "No workflows provided...";
    return;
  fi

  echo "============> Apply default config for workflows..."
  echo "Found workflows config: ${JSON}"
  echo "${JSON}" |jq -c -r .[] | while IFS= read -r WORKFLOW ;
  do
    safe_extended_api_call "workflows" "PATCH" "${WORKFLOW}" "200"
  done
}

function add_enumerations(){
  local JSON="${1}"
  if [ -z "${JSON}" ] || [ "${JSON}" = "null" ];
  then
    echo "No enumerations provided...";
    return;
  fi

  echo "============> Apply default config for enumerations..."
  echo "Found custom field config: ${JSON}"
  echo "${JSON}" |jq -c -r .[] | while IFS= read -r ENUMERATION ;
  do
    safe_extended_api_call "enumerations" "POST" "${ENUMERATION}" "200"
  done
}

function validate_default_config(){
  echo "Validate configuration..."

  # Check if it is possible to parse json
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

function apply_default_configuration(){
  local DEFAULT_CONFIG="${1}"
  echo "Archiving etcd key for default configuration..."
  doguctl config etcd_redmine_config_archived "${DEFAULT_CONFIG}"
  echo "Removing etcd key for default configuration..."
  doguctl config --rm etcd_redmine_config

  echo "Reading settings default config..."
  SETTINGS="$(echo "${DEFAULT_CONFIG}" |jq -c ".settings")"
  add_settings "${SETTINGS}"

  echo "Reading trackers default config..."
  TRACKERS="$(echo "${DEFAULT_CONFIG}" |jq -c ".trackers")"
  add_trackers "${TRACKERS}"

  echo "Reading issue statuses default config..."
  ISSUE_STATUSES="$(echo "${DEFAULT_CONFIG}" |jq -c ".issueStatuses")"
  add_issue_statuses "${ISSUE_STATUSES}"

  echo "Reading custom fields default config..."
  CUSTOM_FIELDS="$(echo "${DEFAULT_CONFIG}" |jq -c ".customFields")"
  add_custom_fields "${CUSTOM_FIELDS}"

  echo "Reading workflows default config..."
  WORKFLOWS="$(echo "${DEFAULT_CONFIG}" |jq -c ".workflows")"
  add_workflows "${WORKFLOWS}"

  echo "Reading enumerations default config..."
  ENUMERATIONS="$(echo "${DEFAULT_CONFIG}" |jq -c ".enumerations")"
  add_enumerations "${ENUMERATIONS}"
}
