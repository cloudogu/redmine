#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CURRENT_TIMESTAMP="$(date "+%Y%m%d-%H%M%S")"
DEFAULT_DATA_PREFIX="default_data"
DEFAULT_DATA_KEY="${DEFAULT_DATA_PREFIX}/new_configuration"
DEFAULT_DATA_KEY_ARCHIVED="${DEFAULT_DATA_PREFIX}/archived/${CURRENT_TIMESTAMP}"
API_RESPONSE_IDS="{}"

# Calls the the api provided by the extended_rest_api plugin.
# ${1} The api to call (settings, workflows, issue_statuses, custom_fields, trackers)
# ${2} HTTP Method to call (POST, GET, ...)
# ${3} The body of the call. Must be valid json.
# ${4} The expected response code from that api. If nothing else provided, response code 200 is expected.
#
# Uses TMP_ADMIN_NAME and TMP_ADMIN_PASSWORD global variables. Must be set before calling this function!
#
# Prints out a json with the body, the response code and the expected response code.
# Exits with 1 if expected and actual response code are not equal.
function curl_extended_api(){
  local BASE_URL="http://127.0.0.1:3000/redmine/extended_api/v1"
  local API="${1}"
  local METHOD="${2}"
  local PAYLOAD
  # Make sure the json is a oneliner for better overview in output
  PAYLOAD="$(echo "${3}" | jq -c)"
  local EXPECTED_RESPONSE_CODE="${4}"

  URL="${BASE_URL}/${API}"

  local CURL_COMMAND="curl -L -H 'accept: */*' -H 'Content-Type: application/json' -X ${METHOD} -u ${TMP_ADMIN_NAME}:${TMP_ADMIN_PASSWORD} --silent --write-out 'HTTPSTATUS:%{http_code}' -d '${PAYLOAD}' ${URL}"
  HTTP_RESPONSE=$(bash -c "${CURL_COMMAND}")
  # shellcheck disable=SC2001 ### Doesn't work
  HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')
  if [ -z "${HTTP_BODY}" ]
  then
    HTTP_BODY="{}"
  fi
  HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')


  RESPONSE="{\"body\": ${HTTP_BODY}, \"status\": ${HTTP_STATUS}, \"expectedStatus\": ${EXPECTED_RESPONSE_CODE}, \"command\": \"${CURL_COMMAND//\"/\\\"}\"}"
  echo "${RESPONSE}" | jq

  if [ ! "${HTTP_STATUS}" -eq "${EXPECTED_RESPONSE_CODE}"  ]; then
    exit 1
  fi
}

# Calls the the api provided by the extended_rest_api plugin. The response is printed out. Even on error, the script will not be exited.
# If $5 and $6 are provided, an attribute of the response will be saved in the $API_RESPONSE_IDS variable.
# ${1} The api to call (settings, workflows, issue_statuses, custom_fields, trackers)
# ${2} HTTP Method to call (POST, GET, ...)
# ${3} The body of the call. Must be valid json.
# ${4} The expected response code from that api. If nothing else provided, response code 200 is expected.
# ${5} The value of the successful response which is saved in $API_RESPONSE_IDS. Provide in jq syntax (e.g. '.myattribute')
# ${6} The key of the successful response which is saved in $API_RESPONSE_IDS. Provide in jq syntax (e.g. '.myattribute')
#
# Example for $5 & $6:
# Response {"someattribute": "1", "someotherattribute": "my value"}
# $5: '.someattribute'
# $6: '.someotherattribute'
# $API_RESPONSE_IDS will be: {"my value": "1"}
#
function safe_extended_api_call() {
  local none="<none>"
  local API="${1}"
  local METHOD="${2}"
  local PAYLOAD="${3}"
  local EXPECTED_RESPONSE_CODE="${4:-"200"}"
  local SAVE_ATTRIBUTE="${5:-"${none}"}"
  local WITH_IDENTIFIER="${6:-"${none}"}"

  local ERROR=""
  RESPONSE="$(curl_extended_api "${API}" "${METHOD}" "${PAYLOAD}" "${EXPECTED_RESPONSE_CODE}")" || ERROR="error"

  if [ "${ERROR}" != "" ]
  then
    echo "Call to extended api '${API}' failed. Output:"
    echo "${RESPONSE}"
  else
    if [ "${SAVE_ATTRIBUTE}" != "${none}" ] && [ "${WITH_IDENTIFIER}" != "${none}" ]; then
      if [ "${METHOD}" == "GET" ]
      then
        while read -r ELEMENT
        do
          ATTRIBUTE_TO_SAVE="$(echo "${ELEMENT}" | jq "${SAVE_ATTRIBUTE}")"
          IDENTIFIER="$(echo "${ELEMENT}" | jq "${WITH_IDENTIFIER}")"
          JQ=".${API}.${IDENTIFIER}=${ATTRIBUTE_TO_SAVE}"
          API_RESPONSE_IDS="$(echo "${API_RESPONSE_IDS}" | jq "${JQ}")"
        done < <(echo "${RESPONSE}" | jq -c -r .body[])
      else
      ATTRIBUTE_TO_SAVE="$(echo "${RESPONSE}" | jq "${SAVE_ATTRIBUTE}")"
      IDENTIFIER="$(echo "${RESPONSE}" | jq "${WITH_IDENTIFIER}")"
      JQ=".${API}.${IDENTIFIER}=${ATTRIBUTE_TO_SAVE}"
      API_RESPONSE_IDS="$(echo "${API_RESPONSE_IDS}" | jq "${JQ}")"
      fi
    fi
    echo "Call to '${API}' successful with content: '${PAYLOAD}'"
  fi
}

function fetch_remote_creation_ids() {
  safe_extended_api_call "issue_statuses" "GET" "" "" ".id" ".name"
  safe_extended_api_call "trackers" "GET" "" "" ".id" ".name"
  safe_extended_api_call "roles" "GET" "" "" ".id" ".name"
}

# Adds settings by using the extended_rest_api plugin. The settings must be provided in arg ${1} as json-array.
function add_settings(){
  local SETTINGS_JSON="${1}"
  if [ -z "${SETTINGS_JSON}" ] || [ "${SETTINGS_JSON}" = "null" ];
  then
    echo "No settings provided...";
    return;
  fi

  echo "Apply configured settings..."
  echo "Found settings data: ${SETTINGS_JSON}"
  safe_extended_api_call "settings" "PUT" "${SETTINGS_JSON}" "204"
}

# Adds roles by using the extended_rest_api plugin. The roles must be provided in arg ${1} as json-array.
function add_roles() {
  local ROLES_JSON="${1}"
  if [ -z "${ROLES_JSON}" ] || [ "${ROLES_JSON}" = "null" ];
  then
    echo "No roles provided...";
    return;
  fi

  echo "Apply configured roles..."
  echo "Found roles data: ${ROLES_JSON}"
  while read -r ROLE
  do
    ROLE_NAME="$(echo "${ROLE}" | jq ".name")"
    REAL_ID="$(echo "${API_RESPONSE_IDS}" | jq ".roles.${ROLE_NAME}")"
    if [ -z "${REAL_ID}" ] || [ "${REAL_ID}" = "null" ];
    then
      safe_extended_api_call "roles" "POST" "${ROLE}" "201" ".body.id" ".body.name"
    elif [[ -n "${REAL_ID}" ]]; then
      ROLE="$(echo "${ROLE}" | jq ".id=${REAL_ID}")"
      safe_extended_api_call "roles" "PATCH" "${ROLE}" "200" ".body.id" ".body.name"
    fi
  done < <(echo "${ROLES_JSON}" | jq -c -r .[])
}

# Adds trackers by using the extended_rest_api plugin. The trackers must be provided in arg ${1} as json-array.
function add_trackers(){
  local TRACKERS_JSON="${1}"
  if [ -z "${TRACKERS_JSON}" ] || [ "${TRACKERS_JSON}" = "null" ];
  then
    echo "No trackers provided...";
    return;
  fi

  echo "Apply configured trackers..."
  echo "Found tracker data: ${TRACKERS_JSON}"
  while read -r TRACKER
  do
    PREPARED_TRACKER="$(prepare_tracker "${TRACKER}")"
    safe_extended_api_call "trackers" "POST" "${PREPARED_TRACKER}" "201" ".body.id" ".body.name"
  done < <(echo "${TRACKERS_JSON}" | jq -c -r .[])
}

# Replaces names in a trackers-json-object with the ids. Prints out the modified trackers-json-object
function prepare_tracker(){
  TRACKER="${1}"
  RESULT="$(echo "${TRACKER}" | jq "del( .default_status_name )")"
  ISSUE_STATUS_NAME="$(echo "${TRACKER}" | jq ".default_status_name")"

  if [ "${ISSUE_STATUS_NAME}" != "null" ]; then
    REAL_ID="$(echo "${API_RESPONSE_IDS}" | jq ".issue_statuses.${ISSUE_STATUS_NAME}")"
    FORMATTED_TRACKER="$(echo "${RESULT}" | jq ".default_status_id=${REAL_ID}")"
    TRACKER="${FORMATTED_TRACKER}"
  fi

  echo "${TRACKER}"
}

# Adds issue_statuses by using the extended_rest_api plugin. The issue_statuses must be provided in arg ${1} as json-array.
function add_issue_statuses(){
  local ISSUE_STATUSES_JSON="${1}"
  if [ -z "${ISSUE_STATUSES_JSON}" ] || [ "${ISSUE_STATUSES_JSON}" = "null" ];
  then
    echo "No issue statuses provided...";
    return;
  fi

  echo "Apply configured issue statuses..."
  echo "Found issue status data: ${ISSUE_STATUSES_JSON}"
  while read -r ISSUE_STATUS
  do
    safe_extended_api_call "issue_statuses" "POST" "${ISSUE_STATUS}" "201" ".body.id" ".body.name"
  done < <(echo "${ISSUE_STATUSES_JSON}" | jq -c -r .[])
}

# Adds custom_fields by using the extended_rest_api plugin. The custom_fields must be provided in arg ${1} as json-array.
function add_custom_fields(){
  local CUSTOM_FIELDS_JSON="${1}"
  if [ -z "${CUSTOM_FIELDS_JSON}" ] || [ "${CUSTOM_FIELDS_JSON}" = "null" ];
  then
    echo "No custom fields provided...";
    return;
  fi

  echo "Apply configured custom fields..."
  echo "Found custom field data: ${CUSTOM_FIELDS_JSON}"
  while read -r CUSTOM_FIELD
  do
    PREPARED_CUSTOM_FIELD="$(prepare_custom_field "${CUSTOM_FIELD}")"
    safe_extended_api_call "custom_fields" "POST" "${PREPARED_CUSTOM_FIELD}" "201" ".body.id" ".body.name"
  done < <(echo "${CUSTOM_FIELDS_JSON}" | jq -c -r .[])
}

# Replaces names in a custom-field-json-object with the ids. Prints out the modified custom-field-json-object
function prepare_custom_field(){
  CUSTOM_FIELD="${1}"
  RESULT="$(echo "${CUSTOM_FIELD}" | jq "del( .tracker_names )" | jq "del( .role_names )")"
  TRACKER_NAMES="$(echo "${CUSTOM_FIELD}" | jq ".tracker_names")"
  ROLE_NAMES="$(echo "${CUSTOM_FIELD}" | jq ".role_names")"

  if [ "${TRACKER_NAMES}" != "null" ]; then
  while read -r TRACKER_NAME
  do
    REAL_ID="\"$(jq_get_or_default "${API_RESPONSE_IDS}" ".trackers.${TRACKER_NAME}" "${TRACKER_NAME}")\""
    TRANSFORMED="$(echo "${RESULT}" | jq ".tracker_ids += [ ${REAL_ID} ]")"
    RESULT="${TRANSFORMED}"
  done < <(echo "${TRACKER_NAMES}" | jq ".[]")
  fi

  if [ "${ROLE_NAMES}" != "null" ]; then
  while read -r ROLE_NAME
  do
    REAL_ID="\"$(jq_get_or_default "${API_RESPONSE_IDS}" ".roles.${ROLE_NAME}" "${ROLE_NAME}")\""
    TRANSFORMED="$(echo "${RESULT}" | jq ".role_ids += [ ${REAL_ID} ]")"
    RESULT="${TRANSFORMED}"
  done < <(echo "${ROLE_NAMES}" | jq ".[]")
  fi

  echo "${RESULT}"
}

# Adds workflows by using the extended_rest_api plugin. The workflows must be provided in arg ${1} as json-array.
function add_workflows(){
  local WORKFLOWS_JSON="${1}"
  if [ -z "${WORKFLOWS_JSON}" ] || [ "${WORKFLOWS_JSON}" = "null" ];
  then
    echo "No workflows provided...";
    return;
  fi

  echo "Apply configured workflows..."
  echo "Found workflows data: ${WORKFLOWS_JSON}"
  while read -r WORKFLOW
  do
    PREPARED_WORKFLOW="$(prepare_workflow "${WORKFLOW}")"
    safe_extended_api_call "workflows" "PATCH" "${PREPARED_WORKFLOW}" "200"
  done < <(echo "${WORKFLOWS_JSON}" | jq -c -r .[])
}

# Replaces names in a workflows-json-object with the ids. Prints out the modified workflows-json-object
function prepare_workflow() {
  WORKFLOW="${1}"
  RESULT="$(echo "${WORKFLOW}" | jq "del( .transitions )" | jq "del( .tracker_names )" | jq "del( .role_names )")"
  TRANSITIONS="$(echo "${WORKFLOW}" | jq ".transitions")"
  TRACKER_NAMES="$(echo "${WORKFLOW}" | jq ".tracker_names")"
  ROLE_NAMES="$(echo "${WORKFLOW}" | jq ".role_names")"

  if [ "${TRANSITIONS}" != "null" ]; then
    while read -r TRANSITION_OLD_KEY
    do
      TRANSITION_OLD_VALUE="$(echo "${TRANSITIONS}" | jq ".${TRANSITION_OLD_KEY}")"
      while read -r TRANSITION_NEW_KEY
      do
        REAL_ID_OLD="\"$(jq_get_or_default "${API_RESPONSE_IDS}" ".issue_statuses.${TRANSITION_OLD_KEY}" "${TRANSITION_OLD_KEY}")\""
        REAL_ID_NEW="\"$(jq_get_or_default "${API_RESPONSE_IDS}" ".issue_statuses.${TRANSITION_NEW_KEY}" "${TRANSITION_NEW_KEY}")\""
        VALUE="$(echo "${TRANSITIONS}" | jq -c ".${TRANSITION_OLD_KEY}.${TRANSITION_NEW_KEY}")"
        TRANSFORMED="$(echo "${RESULT}" | jq ".transitions.${REAL_ID_OLD}.${REAL_ID_NEW}=${VALUE}")"
        RESULT="${TRANSFORMED}"
      done < <(echo "${TRANSITION_OLD_VALUE}" | jq "keys[]")
    done < <(echo "${TRANSITIONS}" | jq "keys[]")
  fi

  if [ "${TRACKER_NAMES}" != "null" ]; then
    while read -r TRACKER_NAME
    do
      REAL_ID="\"$(jq_get_or_default "${API_RESPONSE_IDS}" ".trackers.${TRACKER_NAME}" "${TRACKER_NAME}")\""
      TRANSFORMED="$(echo "${RESULT}" | jq ".tracker_id += [ ${REAL_ID} ]")"
      RESULT="${TRANSFORMED}"
    done < <(echo "${TRACKER_NAMES}" | jq -c ".[]")
  fi

  if [ "${ROLE_NAMES}" != "null" ]; then
    while read -r ROLE_NAME
    do
      REAL_ID="\"$(jq_get_or_default "${API_RESPONSE_IDS}" ".roles.${ROLE_NAME}" "${ROLE_NAME}")\""
      TRANSFORMED="$(echo "${RESULT}" | jq ".role_id += [ ${REAL_ID} ]")"
      RESULT="${TRANSFORMED}"
    done < <(echo "${ROLE_NAMES}" | jq -c ".[]")
  fi

  echo "${RESULT}"
}

# Adds enumerations by using the extended_rest_api plugin. The enumerations must be provided in arg ${1} as json-array.
function add_enumerations(){
  local ENUMERATIONS_JSON="${1}"
  if [ -z "${ENUMERATIONS_JSON}" ] || [ "${ENUMERATIONS_JSON}" = "null" ];
  then
    echo "No enumerations provided...";
    return;
  fi

  echo "Apply configured enumerations..."
  echo "Found custom field data: ${ENUMERATIONS_JSON}"
  while read -r ENUMERATION
  do
    PREPARED_ENUMERATION="$(prepare_enumeration "${ENUMERATION}")"
    safe_extended_api_call "enumerations" "POST" "${PREPARED_ENUMERATION}" "200"
  done < <(echo "${ENUMERATIONS_JSON}" | jq -c -r .[])
}

# Replaces names in a enumerations-json-object with the ids. Prints out the modified enumerations-json-object
function prepare_enumeration(){
  ENUMERATION="${1}"
  RESULT="$(echo "${ENUMERATION}" | jq "del( .custom_field_values )")"
  CUSTOM_FIELD_VALUES="$(jq_get_or_default "${ENUMERATION}" ".custom_field_values" "{}" "true")"

  while read -r KEY
  do
    REAL_ID="\"$(jq_get_or_default "${API_RESPONSE_IDS}" ".custom_fields.${KEY}" "${KEY}")\""
    VALUE="$(echo "${CUSTOM_FIELD_VALUES}" | jq ".${KEY}")"
    TRANSFORMED="$(echo "${RESULT}" | jq ".custom_field_values.${REAL_ID}=${VALUE}")"
    RESULT="${TRANSFORMED}"
  done < <(echo "${CUSTOM_FIELD_VALUES}" | jq "keys[]")

  echo "${RESULT}"
}

# Applies the default configuration which must be provided in arg ${1} as json.
function apply_default_data(){
  local DEFAULT_CONFIG="${1}"
  fetch_remote_creation_ids

  echo "Validating default data configuration..."
  # Check if it is possible to parse json
  echo "${DEFAULT_DATA}" | jq >> /dev/null

  echo "Archiving etcd key for default data..."
  doguctl config "${DEFAULT_DATA_KEY_ARCHIVED}" "${DEFAULT_CONFIG}"
  echo "Removing etcd key for default data..."
  doguctl config --rm "${DEFAULT_DATA_KEY}"

  echo "============================================================================"
  echo "Reading settings default data..."
  SETTINGS="$(echo "${DEFAULT_CONFIG}" | jq -c ".settings")"
  add_settings "${SETTINGS//\'/}"

  echo "============================================================================"
  echo "Reading roles default data..."
  ROLES="$(echo "${DEFAULT_CONFIG}" | jq -c ".roles")"
  add_roles "${ROLES//\'/}"

  echo "============================================================================"

  echo "Reading issue statuses default data..."
  ISSUE_STATUSES="$(echo "${DEFAULT_CONFIG}" | jq -c ".issueStatuses")"
  add_issue_statuses "${ISSUE_STATUSES//\'/}"

  echo "============================================================================"

  echo "Reading trackers default data..."
  TRACKERS="$(echo "${DEFAULT_CONFIG}" | jq -c ".trackers")"
  add_trackers "${TRACKERS//\'/}"

  echo "============================================================================"

  echo "Reading custom fields default data..."
  CUSTOM_FIELDS="$(echo "${DEFAULT_CONFIG}" | jq -c ".customFields")"
  add_custom_fields "${CUSTOM_FIELDS//\'/}"

  echo "============================================================================"

  echo "Reading enumerations default data..."
  ENUMERATIONS="$(echo "${DEFAULT_CONFIG}" | jq -c ".enumerations")"
  add_enumerations "${ENUMERATIONS//\'/}"

  echo "============================================================================"

  echo "Reading workflows default data..."
  WORKFLOWS="$(echo "${DEFAULT_CONFIG}" | jq -c ".workflows")"
  add_workflows "${WORKFLOWS//\'/}"

  echo "============================================================================"
}

function jq_get_or_default(){
  JSON="${1}"
  KEY="${2}"
  DEFAULT="${3}"
  KEEP_QUOTES="${4:-"false"}"
  RESPONSE="$(echo "${JSON}" | jq "${KEY}")"
  local RESULT
  if [ "${RESPONSE}" != "null" ]; then
    RESULT="${RESPONSE}"
  else
    RESULT="${DEFAULT}"
  fi

  if [ "${KEEP_QUOTES}" != "false" ]; then
    echo "${RESULT}"
  else
    echo "${RESULT//\"/}"
  fi
}