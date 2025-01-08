#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

function update_password_policy_setting(){
  echo "Updating password policy in redmine start"

  echo "Retrieving config values start"
  local MIN_LENGTH=$(get_password_policy_key "min_length")
  local UPPERCASE_FLAG=$(get_password_policy_key "must_contain_capital_letter")
  local LOWERCASE_FLAG=$(get_password_policy_key "must_contain_lower_case_letter")
  local DIGITS_FLAG=$(get_password_policy_key "must_contain_digit")
  local SPECIAL_FLAG=$(get_password_policy_key "must_contain_special_character")
  echo "Retrieving config values end"

  if [[ -z "$MIN_LENGTH" && -z "$UPPERCASE_FLAG" && -z "$LOWERCASE_FLAG" && -z "$DIGITS_FLAG" && -z "$SPECIAL_FLAG" ]]; then
    echo "INFO: no password policy configuration found."
    local SETTINGS_JSON=$(build_json "8" "" "" "" "")
    # clean up json in case any of the array vals are not filled
    safe_extended_api_call "settings" "PUT" "${SETTINGS_JSON}" "204"
    return 0;
  fi

  if  [[ -z "$MIN_LENGTH" ]]; then
     MIN_LENGTH = 8; # reset to standard
  fi

  local UPPERCASE=""
  if [[ "$UPPERCASE_FLAG" == "true" ]]; then
    UPPERCASE="uppercase"
  fi

  local LOWERCASE=""
  if [[ "$LOWERCASE_FLAG" == "true" ]]; then
    LOWERCASE="lowercase"
  fi

  local DIGITS=""
  if [[ "$DIGITS_FLAG" == "true" ]]; then
    DIGITS="digits"
  fi

  local SPECIAL=""
  if [[ "$SPECIAL_FLAG" == "true" ]]; then
    SPECIAL="special_chars"
  fi

  local SETTINGS_JSON=$(build_json "${MIN_LENGTH}" "${UPPERCASE}" "${LOWERCASE}" "${DIGITS}" "${SPECIAL}")
  echo "Calling extended rest api start"

  # clean up json in case any of the array vals are not filled
  safe_extended_api_call "settings" "PUT" "${SETTINGS_JSON}" "204"
  echo "Calling extended rest api end"
  echo "Updating password policy in redmine end"
}

function get_password_policy_key(){
  local configKey=${1}
  local configValue=$(doguctl config -g -d " " password-policy/${configKey})
  echo "${configValue}"
}

function build_password_policy_settings_json(){
    local SETTINGS_JSON='{"password_min_length":"%s","password_required_char_classes":["%s","%s","%s","%s"]}'

    local MIN_LENGTH="${1}"
    local UPPERCASE="${2}"
    local LOWERCASE="${3}"
    local DIGITS="${4}"
    local SPECIAL="${5}"

    SETTINGS_JSON=$(printf "${SETTINGS_JSON}" "${MIN_LENGTH}" "${UPPERCASE}" "${LOWERCASE}" "${DIGITS}" "${SPECIAL}")
    echo "${SETTINGS_JSON}"
}