#! /bin/bash
# Bind an unbound BATS variable that fails all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'

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
  export PLUGIN_STORE="$(mktemp -d)"
  export PLUGIN_DIRECTORY="a/path/to/a/better/world"
  mktemp -p "${PLUGIN_STORE}"

  run checkDeprecatedPluginDir

  assert_success
  assert_line --partial "WARNING: Found plugins in the deprecated plugin directory"
}

@test "checkDeprecatedPluginDir() should not print a warning if no directories exist in the deprecated plugin directory" {
  source /workspace/resources/startup.sh
  export PLUGIN_STORE="$(mktemp -d)"
  ls -lha $PLUGIN_STORE

  run checkDeprecatedPluginDir

  assert_success
  refute_output
}
