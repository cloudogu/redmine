#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'
export output=""
export parameter=""
export status=0


setup() {
  export STARTUP_DIR=/workspace/resources
  export RAILS_DIR=/workspace
  export RAILS_ENV=production
  doguctl="$(mock_create)"
  jq="$(mock_create)"
  curl="$(mock_create)"
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
  ln -s "${jq}" "${BATS_TMPDIR}/jq"
  ln -s "${curl}" "${BATS_TMPDIR}/curl"
  export doguctl
  export jq
  export curl
  export PATH="${PATH}:${BATS_TMPDIR}"
  exportDefaultData
}

teardown() {
  unset STARTUP_DIR
  unset RAILS_DIR
  unset RAILS_ENV
  rm "${BATS_TMPDIR}/doguctl"
  rm "${BATS_TMPDIR}/jq"
  rm "${BATS_TMPDIR}/curl"
}

@test "apply_default_data_if_new() should return early on config key with empty string" {
  # given
  export TMP_ADMIN_NAME="admin"
  export TMP_ADMIN_PASSWORD="Password1!"
  mock_set_status "${doguctl}" 0

  mock_set_output "${curl}" 'HTTPSTATUS:200'
  mock_set_status "${curl}" 0

  source /workspace/resources/default-config.sh
  export DEFAULT_DATA_KEY_ARCHIVED="/fake/config/key"
  export CURRENT_TIMESTAMP="2025-04-03-020100"

  # when
  run apply_default_data_if_new ""

  # then
  assert_success
  assert_line "Found empty default data configuration"
  assert_equal "$(mock_get_call_num "${doguctl}")" "0"
  assert_equal "$(mock_get_call_num "${curl}")" "0"
}

@test "apply_default_data_if_new() should import default-data on empty archive config key" {
  # given
  export TMP_ADMIN_NAME="admin"
  export TMP_ADMIN_PASSWORD="Password1!"
  mock_set_status "${doguctl}" 0
  mock_set_output "${doguctl}" 'no-data' 1
  mock_set_output "${doguctl}" '' 2

  mock_set_output "${curl}" 'HTTPSTATUS:200'
  mock_set_status "${curl}" 0

  source /workspace/resources/default-config.sh
  export CURRENT_TIMESTAMP="2025-04-03-020100"
  export DEFAULT_DATA_KEY_ARCHIVED="default_data/archived/${CURRENT_TIMESTAMP}"

  # when
  run apply_default_data_if_new "${defaultData}"

  # then
  assert_success
  assert_line "found configured default data to import."
  assert_equal "$(mock_get_call_num "${curl}")" "3"
  assert_equal "$(mock_get_call_num "${doguctl}")" "3"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config --default no-data default_data/archived/last_timestamp"
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "config ${DEFAULT_DATA_KEY_ARCHIVED} ${defaultData}"
  assert_equal "$(mock_get_call_args "${doguctl}" "3")" "config default_data/archived/last_timestamp 2025-04-03-020100"
}

@test "apply_default_data_if_new() should import default-data on config key with valid JSON" {
  # given
  export TMP_ADMIN_NAME="admin"
  export TMP_ADMIN_PASSWORD="Password1!"
  mock_set_status "${doguctl}" 0
  mock_set_output "${doguctl}" '2025-01-01-010100' 1
  mock_set_output "${doguctl}" 'totally different json than the input json' 2
  mock_set_output "${doguctl}" '' 3

  mock_set_output "${curl}" 'HTTPSTATUS:200'
  mock_set_status "${curl}" 0

  source /workspace/resources/default-config.sh
  export CURRENT_TIMESTAMP="2025-04-03-020100"
  export DEFAULT_DATA_KEY_ARCHIVED="default_data/archived/${CURRENT_TIMESTAMP}"

  # when
  run apply_default_data_if_new "${defaultData}"

  # then
  assert_success
  assert_line "found configured default data to import."
  assert_equal "$(mock_get_call_num "${curl}")" "3"
  assert_equal "$(mock_get_call_num "${doguctl}")" "4"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config --default no-data default_data/archived/last_timestamp"
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "config default_data/archived/2025-01-01-010100"
  assert_equal "$(mock_get_call_args "${doguctl}" "3")" "config ${DEFAULT_DATA_KEY_ARCHIVED} ${defaultData}"
  assert_equal "$(mock_get_call_args "${doguctl}" "4")" "config default_data/archived/last_timestamp 2025-04-03-020100"
}


exportDefaultData() {
  export defaultData=""

  # end with true because read exits with code 1 on EOF
  read -d '' -r defaultData </workspace/batsTests/small-default-data.json || true
}
