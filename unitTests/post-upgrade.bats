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

@test "run_postupgrade should provide PostgresSQL credentials (while note being exported)" {
  source /workspace/resources/post-upgrade.sh

  mock_set_status "${doguctl}" 0
  mock_set_output "${doguctl}" "theUser" 1
  mock_set_output "${doguctl}" "thePassword" 2
  mock_set_output "${doguctl}" "theDatabase" 3
  mock_set_output "${doguctl}" "somethingElse" 4
  mock_set_status "${psql}" 0
  mock_set_status "${rake}" 0
  # overwrite plugin env vars for implicit call of install_plugins
  overwritePluginDirsWithTmpDirs

  run run_postupgrade "4.1.0-3" "4.2.0-1"

  assert_success
  assert_line "get data for database connection"
  assert_equal "$(mock_get_call_num "${doguctl}")" "9"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config -e sa-postgresql/username"
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "config -e sa-postgresql/password"
  assert_equal "$(mock_get_call_args "${doguctl}" "3")" "config -e sa-postgresql/database"

  assert_equal "$(mock_get_call_num "${psql}")" "1"
  assert_equal "$(mock_get_call_args "${psql}" "1")" "--host postgresql --username theUser --dbname theDatabase -1 -c DELETE FROM settings WHERE id IN (SELECT id FROM settings WHERE NOT id IN (SELECT max(id) FROM settings GROUP BY name HAVING count(*) > 1) AND name IN (SELECT name FROM settings GROUP BY name HAVING count(name) > 1))"

  assert_line "Redmine post-upgrade done"

  refute isVarExported "DATABASE_USER"
  refute isVarExported "DATABASE_USER_PASSWORD"
  refute isVarExported "DATABASE_DB"
}

@test "run_postupgrade should delete duplicate database settings during upgrade from source versions [3.3.2-4 to 4.1.0-3] to target version 4.2.0-1" {
  source /workspace/resources/post-upgrade.sh
  sourceVersions=("3.3.2-4" "3.4.10-1" "3.4.10-2" "3.4.11-1" "3.4.2-2" "3.4.2-3" "3.4.2-4" "3.4.2-5" "3.4.2-6" "3.4.8-1" "3.4.8-2" "4.0.5-1" "4.1.0-1" "4.1.0-2" "4.1.0-3")

  for sourceVersion in "${sourceVersions[@]}"; do
    echo "TEST: Running: run_postupgrade ${sourceVersion}" "4.2.0-1"

    mock_set_status "${doguctl}" 0
    mock_set_output "${doguctl}" "theUser" 1
    mock_set_output "${doguctl}" "thePassword" 2
    mock_set_output "${doguctl}" "theDatabase" 3
    mock_set_output "${doguctl}" "somethingElse" 4
    mock_set_status "${psql}" 0
    mock_set_status "${rake}" 0
    # overwrite plugin env vars for implicit call of install_plugins
    overwritePluginDirsWithTmpDirs

    run run_postupgrade "${sourceVersion}" "4.2.0-1"

    assert_success
    assert_line "post-upgrade: Deleting duplicate settings in database..."
    assert_line "Redmine post-upgrade done"

    echo "TEST: Success: run_postupgrade ${sourceVersion}" "4.2.0-1"
  done
}

@test "run_postupgrade should not delete duplicate database settings during upgrade from source versions higher than 4.1.0-3" {
  source /workspace/resources/post-upgrade.sh
  sourceVersions=("4.1.1-1" "4.1.1-2" "4.2.0-1" "4.2.0-2" "4.2.1-1" "4.2.1-2" "4.2.1-3" "4.2.2-1" "4.2.2-2" "4.2.2-3" "4.2.2-4" "4.2.3-1")

  for sourceVersion in "${sourceVersions[@]}"; do
    echo "TEST: run_postupgrade ${sourceVersion}" "4.2.3-4"

    mock_set_status "${doguctl}" 0
    mock_set_output "${doguctl}" "theUser" 1
    mock_set_output "${doguctl}" "thePassword" 2
    mock_set_output "${doguctl}" "theDatabase" 3
    mock_set_output "${doguctl}" "somethingElse" 4
    mock_set_status "${psql}" 0
    mock_set_status "${rake}" 0
    # overwrite plugin env vars for implicit call of install_plugins
    overwritePluginDirsWithTmpDirs

    run run_postupgrade "${sourceVersion}" "4.2.3-4"

    assert_success
    refute_line "post-upgrade: Deleting duplicate settings in database..."
    assert_line "Redmine post-upgrade done"
  done
}

@test "isVarExported() return true or false if a variable is exported or not" {
  local localEnvVar=hidden
  export exportEnvVar=HELLO

  run isVarExported "localEnvVar"
  assert_failure

  run isVarExported "exportEnvVar"
  assert_success
}

function overwritePluginDirsWithTmpDirs() {
  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  aPluginDirectory="$(mktemp -d -p "${DEFAULT_PLUGIN_DIRECTORY}")"
  aPluginFile="$(mktemp -p "${aPluginDirectory}")"
  pluginName="$(basename "${aPluginDirectory}")"
  aPluginFileName="$(basename "${aPluginFile}")"
  export PLUGIN_DIRECTORY="$(mktemp -d)"
  export DEPRECATED_PLUGIN_STORE="$(mktemp -d)"
  export MIGRATION_TMP_DIR="$(mktemp -d)"
}

function isVarExported() {
    local name="${1}"
    if [[ "${!name@a}" == *x* ]]; then
        return 0
    fi

    return 1
}