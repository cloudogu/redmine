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
  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/doguctl"
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