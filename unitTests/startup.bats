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

@test "checkDeprecatedPluginDir() should print a warning if directories exist in the deprecated plugin directory" {
  source /workspace/resources/startup.sh
  export DEPRECATED_PLUGIN_STORE="$(mktemp -d)"
  export PLUGIN_DIRECTORY="a/path/to/a/better/world"
  mktemp -p "${DEPRECATED_PLUGIN_STORE}"

  run checkDeprecatedPluginDir

  assert_success
  assert_line --partial "WARNING: Found plugins in the deprecated plugin directory"
}

@test "checkDeprecatedPluginDir() should not print a warning if no directories exist in the deprecated plugin directory" {
  source /workspace/resources/startup.sh
  export DEPRECATED_PLUGIN_STORE="$(mktemp -d)"

  run checkDeprecatedPluginDir

  assert_success
  refute_output
}

@test "install_plugin() should print an error but continue if a plugin directory turns out as regular file" {
  source /workspace/resources/startup.sh
  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  export PLUGIN_DIRECTORY="a/path/to/a/better/world"
  pluginName="$(mktemp -p ${DEFAULT_PLUGIN_DIRECTORY})"

  run install_plugin "${pluginName}"

  assert_success
  assert_line --partial "ERROR"
  assert_line --partial "is not a directory"
}

@test "install_plugin() should print an log line if a bundled plugin is already installed" {
  source /workspace/resources/startup.sh
  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  aPluginDirectory="$(mktemp -d -p ${DEFAULT_PLUGIN_DIRECTORY})"
  pluginName="$(basename "${aPluginDirectory}")"
  export PLUGIN_DIRECTORY="$(mktemp -d)"
  mkdir -p "${PLUGIN_DIRECTORY}/${pluginName}"

  run install_plugin "${pluginName}"

  assert_success
  assert_line --partial "already exists. Skip restoring the plugin"
}

@test "install_plugin() should install a bundled plugin that is absent" {
  source /workspace/resources/startup.sh
  export DEFAULT_PLUGIN_DIRECTORY="$(mktemp -d)"
  aPluginDirectory="$(mktemp -d -p "${DEFAULT_PLUGIN_DIRECTORY}")"
  aPluginFile="$(mktemp -p "${aPluginDirectory}")"
  pluginName="$(basename "${aPluginDirectory}")"
  aPluginFileName="$(basename "${aPluginFile}")"
  export PLUGIN_DIRECTORY="$(mktemp -d)"

  run install_plugin "${pluginName}"

  assert_success
  assert_line "install plugin ${pluginName}"
  assert_dir_exist "${PLUGIN_DIRECTORY}/${pluginName}"
  assert_file_exist "${PLUGIN_DIRECTORY}/${pluginName}/${aPluginFileName}"
}

