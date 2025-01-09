#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

function update_password_policy_setting(){
  echo "Updating password policy in Redmine start"
  echo "Retrieving config values start"
  local MIN_LENGTH UPPERCASE_FLAG LOWERCASE_FLAG DIGITS_FLAG SPECIAL_FLAG

  MIN_LENGTH=$(get_password_policy_key "min_length")
  UPPERCASE_FLAG=$(get_password_policy_key "must_contain_capital_letter")
  LOWERCASE_FLAG=$(get_password_policy_key "must_contain_lower_case_letter")
  DIGITS_FLAG=$(get_password_policy_key "must_contain_digit")
  SPECIAL_FLAG=$(get_password_policy_key "must_contain_special_character")
  echo "Retrieving config values end"

  if  [[ -z "${MIN_LENGTH// }" ]]; then
     MIN_LENGTH=8; # reset to standard
  fi

  local UPPERCASE=""
  if [[ "${UPPERCASE_FLAG}" == "true" ]]; then
    UPPERCASE="uppercase"
  fi

  local LOWERCASE=""
  if [[ "${LOWERCASE_FLAG}" == "true" ]]; then
    LOWERCASE="lowercase"
  fi

  local DIGITS=""
  if [[ "${DIGITS_FLAG}" == "true" ]]; then
    DIGITS="digits"
  fi

  local SPECIAL=""
  if [[ "${SPECIAL_FLAG}" == "true" ]]; then
    SPECIAL="special_chars"
  fi

  local SETTINGS_JSON
  SETTINGS_JSON=$(build_password_policy_settings_json "${MIN_LENGTH}" "${UPPERCASE}" "${LOWERCASE}" "${DIGITS}" "${SPECIAL}")
  echo "Calling extended rest api start"

  # clean up json in case any of the array vals are not filled
  safe_extended_api_call "settings" "PUT" "${SETTINGS_JSON}" "204"
  echo "Calling extended rest api end"
  echo "Updating password policy in Redmine end"
}

function get_password_policy_key(){
  local configKey=${1}
  local configValue
  configValue=$(doguctl config -g -d " " password-policy/"${configKey}")
  echo "${configValue}"
}

function build_password_policy_settings_json(){
    local SETTINGS_JSON
    SETTINGS_JSON='{"password_min_length":"%s","password_required_char_classes":["%s","%s","%s","%s"]}'

    local MIN_LENGTH="${1}"
    local UPPERCASE="${2}"
    local LOWERCASE="${3}"
    local DIGITS="${4}"
    local SPECIAL="${5}"

    # shellcheck disable=SC2059
    SETTINGS_JSON=$(printf "${SETTINGS_JSON}" "${MIN_LENGTH}" "${UPPERCASE}" "${LOWERCASE}" "${DIGITS}" "${SPECIAL}")
    echo "${SETTINGS_JSON}"
}