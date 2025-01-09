#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'

setup() {
  export STARTUP_DIR=/workspace/resources
  export BASEDIR=/workspace/app/usr/share/webapps
  export RAILS_DIR="${BASEDIR}/easyredmine"
  export SCRIPTS_DIR=/workspace/scripts
  export RAILS_ENV=production
  doguctl="$(mock_create)"
  export doguctl
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
  mysql="$(mock_create)"
  export mysql
  ln -s "${mysql}" "${BATS_TMPDIR}/mysql"
  rake="$(mock_create)"
  export rake
  ln -s "${rake}" "${BATS_TMPDIR}/rake"
  bundle="$(mock_create)"
  export bundle
  ln -s "${bundle}" "${BATS_TMPDIR}/bundle"
  export PATH="${PATH}:${BATS_TMPDIR}"
  curl="$(mock_create)"
  export curl
  ln -s "${curl}" "${BATS_TMPDIR}/curl"
  jq="$(mock_create)"
  export jq
  ln -s "${jq}" "${BATS_TMPDIR}/jq"
  export TMP_ADMIN_NAME="adminAdmin"
  export TMP_ADMIN_PASSWORD="adminPW"
}

teardown() {
  unset STARTUP_DIR
  unset BASEDIR
  unset RAILS_DIR
  unset SCRIPTS_DIR
  unset RAILS_ENV
  unset curl
  unset jq
  unset TMP_ADMIN_NAME
  unset TMP_ADMIN_PASSWORD
  rm "${BATS_TMPDIR}/doguctl"
  rm "${BATS_TMPDIR}/mysql"
  rm "${BATS_TMPDIR}/rake"
  rm "${BATS_TMPDIR}/bundle"
  rm "${BATS_TMPDIR}/curl"
  rm "${BATS_TMPDIR}/jq"
}

@test "upgrade password policy generates proper json" {
  source /workspace/resources/update-password-policy.sh

  MIN_LENGTH="14"
  UPPERCASE="uppercase"
  LOWERCASE="lowercase"
  DIGITS="digits"
  SPECIAL="special_char"

  run build_password_policy_settings_json "${MIN_LENGTH}" "${UPPERCASE}" "${LOWERCASE}" "${DIGITS}" "${SPECIAL}"
  assert assert_output '{"password_min_length":"14","password_required_char_classes":["uppercase","lowercase","digits","special_char"]}'
  assert assert_success

  MIN_LENGTH="8"
  UPPERCASE=" "
  LOWERCASE=" "
  DIGITS=" "
  SPECIAL=" "

  run build_password_policy_settings_json "${MIN_LENGTH}" "${UPPERCASE}" "${LOWERCASE}" "${DIGITS}" "${SPECIAL}"
  assert assert_output '{"password_min_length":"8","password_required_char_classes":[" "," "," "," "]}'
  assert assert_success
}

@test "update_password_policy is successful" {
  source /workspace/resources/update-password-policy.sh
  source /workspace/resources/default-config.sh

  mock_set_status "${doguctl}" 0 1
  mock_set_output "${doguctl}" "14" 1

  mock_set_status "${doguctl}" 0 2
  mock_set_output "${doguctl}" "true" 2

  mock_set_status "${doguctl}" 0 3
  mock_set_output "${doguctl}" "true" 3

  mock_set_status "${doguctl}" 0 4
  mock_set_output "${doguctl}" "true" 4

  mock_set_status "${doguctl}" 0 5
  mock_set_output "${doguctl}" "true" 5

  mock_set_status "${curl}" 0 1
  mock_set_output "${curl}" "HTTPSTATUS:204" 1

  SETTINGS_JSON='{"password_min_length":"14","password_required_char_classes":["uppercase","lowercase","digits","special_chars"]}'
  run update_password_policy_setting
  assert assert_output --partial "Updating password policy in Redmine start"
  assert assert_output --partial "Retrieving config values start"
  assert assert_output --partial "Retrieving config values end"
  assert assert_output --partial "Calling extended rest api start"
  assert assert_output --partial "Call to 'settings' successful with content: '${SETTINGS_JSON}'"
  assert assert_output --partial "Calling extended rest api end"
  assert assert_output --partial "Updating password policy in Redmine end"
}