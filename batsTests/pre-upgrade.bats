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

@test "versionXLessOrEqualThanY() should return true for versions less than or equal to another" {
  source /workspace/resources/pre-upgrade.sh

  run versionXLessOrEqualThanY "1.0.0-1" "1.0.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "1.0.0-2"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "1.1.0-2"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "1.0.2-2"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "1.0.0-2"
  assert_success
  run versionXLessOrEqualThanY "1.1.0-1" "1.1.0-2"
  assert_success
  run versionXLessOrEqualThanY "1.0.2-1" "1.0.2-2"
  assert_success
  run versionXLessOrEqualThanY "1.2.3-4" "1.2.3-4"
  assert_success
  run versionXLessOrEqualThanY "1.2.3-4" "1.2.3-5"
  assert_success

  run versionXLessOrEqualThanY "1.0.0-1" "2.0.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.1.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.0.1-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.1.1-1"
  assert_success
  run versionXLessOrEqualThanY "5.1.3-1" "5.1.3-1"
  assert_success
}

@test "versionXLessOrEqualThanY() should return false for versions greater than another" {
  source /workspace/resources/pre-upgrade.sh

  run versionXLessOrEqualThanY "0.0.0-10" "0.0.0-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-1" "0.0.0-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-1" "0.0.9-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-1" "0.9.9-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-0" "0.9.9-9"
  assert_failure
  run versionXLessOrEqualThanY "1.1.0-1" "0.0.0-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-1" "0.0.9-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-1" "0.9.9-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-0" "0.9.9-9"
  assert_failure

  run versionXLessOrEqualThanY "1.2.3-4" "0.1.2-3"
  assert_failure
  run versionXLessOrEqualThanY "1.2.3-5" "0.1.2-3"
  assert_failure

  run versionXLessOrEqualThanY "2.0.0-1" "1.0.0-1"
  assert_failure
  run versionXLessOrEqualThanY "2.1.0-1" "1.0.0-1"
  assert_failure
  run versionXLessOrEqualThanY "2.0.1-1" "1.0.0-1"
  assert_failure
  run versionXLessOrEqualThanY "2.1.1-1" "1.0.0-1"
  assert_failure
}

@test "versionXLessThanY() should return true for versions less than another" {
  source /workspace/resources/pre-upgrade.sh

  run versionXLessThanY "1.0.0-1" "1.0.0-2"
  assert_success
  run versionXLessThanY "1.0.0-1" "1.1.0-2"
  assert_success
  run versionXLessThanY "1.0.0-1" "1.0.2-2"
  assert_success
  run versionXLessThanY "1.0.0-1" "1.0.0-2"
  assert_success
  run versionXLessThanY "1.1.0-1" "1.1.0-2"
  assert_success
  run versionXLessThanY "1.0.2-1" "1.0.2-2"
  assert_success
  run versionXLessThanY "1.2.3-4" "1.2.3-5"
  assert_success

  run versionXLessThanY "1.0.0-1" "2.0.0-1"
  assert_success
  run versionXLessThanY "1.0.0-1" "2.1.0-1"
  assert_success
  run versionXLessThanY "1.0.0-1" "2.0.1-1"
  assert_success
  run versionXLessThanY "1.0.0-1" "2.1.1-1"
  assert_success
}

@test "versionXLessThanY() should return false for versions greater than another" {
  source /workspace/resources/pre-upgrade.sh

  run versionXLessThanY "1.0.0-1" "1.0.0-1"
  assert_failure
  run versionXLessThanY "0.0.0-10" "0.0.0-9"
  assert_failure
  run versionXLessThanY "1.0.0-1" "0.0.0-9"
  assert_failure
  run versionXLessThanY "1.0.0-1" "0.0.9-9"
  assert_failure
  run versionXLessThanY "1.0.0-1" "0.9.9-9"
  assert_failure
  run versionXLessThanY "1.0.0-0" "0.9.9-9"
  assert_failure
  run versionXLessThanY "1.1.0-1" "0.0.0-9"
  assert_failure
  run versionXLessThanY "1.0.0-1" "0.0.9-9"
  assert_failure
  run versionXLessThanY "1.0.0-1" "0.9.9-9"
  assert_failure
  run versionXLessThanY "1.0.0-0" "0.9.9-9"

  run versionXLessThanY "1.2.3-4" "0.1.2-3"
  assert_failure
  run versionXLessThanY "1.2.3-5" "0.1.2-3"
  assert_failure

  run versionXLessThanY "2.0.0-1" "1.0.0-1"
  assert_failure
  run versionXLessThanY "2.1.0-1" "1.0.0-1"
  assert_failure
  run versionXLessThanY "2.0.1-1" "1.0.0-1"
  assert_failure
  run versionXLessThanY "2.1.1-1" "1.0.0-1"
  assert_failure
}

@test "movePluginsToTempDirM4234() should move files back from the plugin temp volume" {
  source /workspace/resources/pre-upgrade.sh

  export REDMINE_WORK_DIR="$(mktemp -d)"
  productionPluginDir="${REDMINE_WORK_DIR}/plugins"
  mkdir -p "${productionPluginDir}"
  aPluginDirectory="$(mktemp -d -p "${productionPluginDir}")"
  aPluginFile="$(mktemp -p "${aPluginDirectory}")"
  pluginName="$(basename "${aPluginDirectory}")"
  aPluginFileName="$(basename "${aPluginFile}")"

  export MIGRATION_VERSION_4234_TMP_DIR="$(mktemp -d)"

  run movePluginsToTempDirM4234

  assert_success
  assert_line --partial "Move plugins to temporary directory"
  assert_line --partial "Moving plugins finished. The plugins will be moved back during the post-upgrade"
  assert_dir_exist "${MIGRATION_VERSION_4234_TMP_DIR}"
  assert_file_exist "${MIGRATION_VERSION_4234_TMP_DIR}/${pluginName}/${aPluginFileName}"
}
