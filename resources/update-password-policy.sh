#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

function update_password_policy_setting(){
  echo "updating password policy in redmine start"

  echo "retrieving config values start"
  local MIN_LENGTH=$(get_password_policy_key "min_length")
  local UPPERCASE_BOL=$(get_password_policy_key "must_contain_capital_letter")
  local LOWERCASE_BOL=$(get_password_policy_key "must_contain_lower_case_letter")
  local DIGITS_BOL=$(get_password_policy_key "must_contain_digit")
  local SPECIAL_BOL=$(get_password_policy_key "must_contain_special_character")
  echo "retrieving config values end"

  if [[ -z "$MIN_LENGTH" && -z "$UPPERCASE_BOL" && -z "$LOWERCASE_BOL" && -z "$DIGITS_BOL" && -z "$SPECIAL_BOL" ]]; then
    echo "no password policy configuration found"
    return 1;
  fi

  local UPPERCASE=""
  if [[ "$UPPERCASE_BOL" == "true" ]]; then
    UPPERCASE="uppercase"
  fi

  local LOWERCASE=""
  if [[ "$LOWERCASE_BOL" == "true" ]]; then
    LOWERCASE="lowercase"
  fi

  local DIGITS=""
  if [[ "$DIGITS_BOL" == "true" ]]; then
    DIGITS="digits"
  fi

  local SPECIAL=""
  if [[ "$SPECIAL_BOL" == "true" ]]; then
    SPECIAL="special_chars"
  fi

  echo "calling extended rest api start"
  local SETTINGS_JSON='
  {
    "password_min_length": "%s",
    "password_required_char_classes": ["%s", "%s", "%s", "%s"]
  }
  '
  SETTINGS_JSON=$(printf "$SETTINGS_JSON" "$MIN_LENGTH" "$UPPERCASE" "$LOWERCASE" "$DIGITS" "$SPECIAL")
  echo "Settings: ${SETTINGS_JSON}"

  # clean up json in case any of the array vals are not filled
  safe_extended_api_call "settings" "PUT" "${SETTINGS_JSON}" "204"
  echo "calling extended rest api end"
  echo "updating password policy in redmine end"
}

function get_password_policy_key() {
  local key=$(doguctl config -g -d " " password-policy/${1})
  echo "${key}"
}