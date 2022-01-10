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
  export WORKDIR=/workspace
  doguctl="$(mock_create)"
  export doguctl
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
  psql="$(mock_create)"
  export psql
  ln -s "${psql}" "${BATS_TMPDIR}/psql"
  rake="$(mock_create)"
  export rake
  ln -s "${rake}" "${BATS_TMPDIR}/rake"
  bundle="$(mock_create)"
  export bundle
  ln -s "${bundle}" "${BATS_TMPDIR}/bundle"
  export PATH="${PATH}:${BATS_TMPDIR}"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/doguctl"
  rm "${BATS_TMPDIR}/psql"
  rm "${BATS_TMPDIR}/rake"
  rm "${BATS_TMPDIR}/bundle"
}

@test "versionXLessOrEqualThanY() was properly sourced from pre-upgrade.sh" {
  source /workspace/resources/post-upgrade.sh

  run versionXLessOrEqualThanY "1.0.0" "1.0.0"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.1.1-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "0.0.9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.9.0"
  assert_failure
}

@test "versionXLessThanY() was properly sourced from pre-upgrade.sh" {
  source /workspace/resources/post-upgrade.sh

  run versionXLessThanY "1.0.0" "1.1.0"
  assert_success
  run versionXLessThanY "1.0.0" "1.1.1-1"
  assert_success
  run versionXLessThanY "1.0.0" "1.0.0"
  assert_failure
  run versionXLessThanY "1.2.3-4" "0.1.2-3"
  assert_failure
}

@test "migratePluginsBackToNewPluginsVolume() should move files back from the plugin temp volume" {
  source /workspace/resources/post-upgrade.sh

  export REDMINE_WORK_DIR="$(mktemp -d)"
  productionPluginDir="${REDMINE_WORK_DIR}/plugins"
  mkdir -p "${productionPluginDir}"

  export MIGRATION_TMP_DIR="$(mktemp -d)"
  aPluginDirectory="$(mktemp -d -p "${MIGRATION_TMP_DIR}")"
  aPluginFile="$(mktemp -p "${aPluginDirectory}")"
  pluginName="$(basename "${aPluginDirectory}")"
  aPluginFileName="$(basename "${aPluginFile}")"

  run migratePluginsBackToNewPluginsVolume

  assert_success
  assert_line --partial "Move plugins back to new plugin volume"
  assert_line --partial "Migrating plugins finished successfully"
  assert_dir_exist "${productionPluginDir}"
  assert_file_exist "${productionPluginDir}/${pluginName}/${aPluginFileName}"
}

@test "run_postupgrade should provide PostgresSQL credentials" {
  export PGPASSWORD="unset!"
  source /workspace/resources/post-upgrade.sh

  mock_set_output "${doguctl}" "theUser" 1
  mock_set_output "${doguctl}" "thePassword" 2
  mock_set_output "${doguctl}" "theDatabase" 3
  mock_set_status "${psql}" 0
  mock_set_side_effect "${psql}" 'export IS_PSQL_PASSWORD_REALLY_SET="${PGPASSWORD}"'
  mock_set_status "${rake}" 0
  # overwrite plugin env vars for implicit call of install_plugins
  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  aPluginDirectory="$(mktemp -d -p "${DEFAULT_PLUGIN_DIRECTORY}")"
  aPluginFile="$(mktemp -p "${aPluginDirectory}")"
  pluginName="$(basename "${aPluginDirectory}")"
  aPluginFileName="$(basename "${aPluginFile}")"
  export PLUGIN_DIRECTORY="$(mktemp -d)"

  run run_postupgrade "4.1.0-3" "4.2.0-1"

  assert_success
  assert_line "Redmine post-upgrade done"
  assert_equal "$(mock_get_call_args "${doguctl}")" "1" "config -e sa-postgresql/user"
  assert_equal "$(mock_get_call_args "${doguctl}")" "2" "config -e sa-postgresql/password"
  assert_equal "$(mock_get_call_args "${doguctl}")" "3" "config -e sa-postgresql/database"

  assert_equal "$(mock_get_call_num "${psql}")" "1"
  assert_equal "$(mock_get_call_args "${psql}" "1")" "--host postgresql --username theUser --dbname theDatabase -1 -c DELETE FROM settings WHERE"

  assert_equal "${IS_PSQL_PASSWORD_REALLY_SET}" "thePassword"
}
