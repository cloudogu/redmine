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
  rake="$(mock_create)"
  export rake
  bundle="$(mock_create)"
  export bundle
  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${rake}" "${BATS_TMPDIR}/rake"
  ln -s "${bundle}" "${BATS_TMPDIR}/bundle"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/rake"
  rm "${BATS_TMPDIR}/bundle"
}

@test "install_plugin() should print an error but continue if a plugin directory turns out as regular file" {
  source /workspace/resources/startup.sh
  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  export PLUGIN_DIRECTORY="a/path/to/a/better/world"
  pluginName="$(mktemp -p ${DEFAULT_PLUGIN_DIRECTORY})"

  run install_plugin "${PLUGIN_DIRECTORY}" "${pluginName}"

  assert_success
  assert_line --partial "ERROR"
  assert_line --partial "is not a directory"
}

@test "install_plugin() should install a bundled plugin that is absent" {
  source /workspace/resources/startup.sh
  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  aPluginDirectory="$(mktemp -d -p "${DEFAULT_PLUGIN_DIRECTORY}")"
  aPluginFile="$(mktemp -p "${aPluginDirectory}")"
  pluginName="$(basename "${aPluginDirectory}")"
  aPluginFileName="$(basename "${aPluginFile}")"
  export PLUGIN_DIRECTORY="$(mktemp -d)"

  run install_plugin "${DEFAULT_PLUGIN_DIRECTORY}" "${pluginName}"

  assert_success
  assert_line "remove plugin ${pluginName}"
  assert_line "install plugin ${pluginName}"
  assert_dir_exist "${PLUGIN_DIRECTORY}/${pluginName}"
  assert_file_exist "${PLUGIN_DIRECTORY}/${pluginName}/${aPluginFileName}"
}

@test "install_plugins() should install 1 plugin and call rake afterwards" {
  mock_set_status "${rake}" 0
  mock_set_status "${bundle}" 0

  source /workspace/resources/startup.sh

  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  aPluginDirectory="$(mktemp -d -p "${DEFAULT_PLUGIN_DIRECTORY}")"
  aPluginFile="$(mktemp -p "${aPluginDirectory}")"
  pluginName="$(basename "${aPluginDirectory}")"
  aPluginFileName="$(basename "${aPluginFile}")"
  export PLUGIN_DIRECTORY="$(mktemp -d)"

  run install_plugins

  assert_success
  assert_line "installing plugins..."
  assert_line "remove plugin ${pluginName}"
  assert_line "install plugin ${pluginName}"
  assert_line "running plugin migrations..."
  assert_line "plugin migrations... done"
  assert_dir_exist "${PLUGIN_DIRECTORY}/${pluginName}"
  assert_file_exist "${PLUGIN_DIRECTORY}/${pluginName}/${aPluginFileName}"
  assert_equal "$(mock_get_call_num "${rake}")" "1"
  assert_equal "$(mock_get_call_args "${rake}" "1")" "--trace -f /workspace/Rakefile redmine:plugins:migrate"
  assert_equal "$(mock_get_call_num "${bundle}")" "1"
  assert_equal "$(mock_get_call_args "${bundle}" "1")" "install --quiet"
}
