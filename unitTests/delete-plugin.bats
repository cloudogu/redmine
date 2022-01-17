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
  bundle="$(mock_create)"
  export bundle
  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${bundle}" "${BATS_TMPDIR}/bundle"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/bundle"
}

@test "script should print a backup warnings, remove plugins and migrate DB" {
  local plugin_name=myPlugin
  mock_set_status "${bundle}" 0
  mkdir -p /usr/share/webapps/redmine/plugins/${plugin_name}

  run /workspace/resources/delete-plugin.sh "myPlugin" "--force"

  assert_success
  # first line
  assert_line "Delete plugin myPlugin"
  # last line
  assert_line "To complete the deletion of the plugin, the Redmine dogu must be restarted once."
  assert_dir_not_exist /usr/share/webapps/redmine/plugins/${plugin_name}
  assert_equal "$(mock_get_call_num "${bundle}")" "1"
  assert_equal "$(mock_get_call_args "${bundle}" "1")" "exec rake redmine:plugins:migrate NAME=myPlugin VERSION=0 RAILS_ENV=production"
}

@test "script should print help page on zero arguments" {
  local plugin_name=myPlugin
  mock_set_status "${bundle}" 0
  mkdir -p /usr/share/webapps/redmine/plugins/${plugin_name}

  run /workspace/resources/delete-plugin.sh

  assert_failure
  # first line
  assert_line --partial "Wrong number of arguments"
  # help text start
  assert_line "usage: delete-plugin[.sh] <plugin-name> --force"
  # help text end
  assert_line --partial "To execute the deletion of the plugin add --force"
  refute_line --partial "Delete plugin"
  refute_line "To complete the deletion of the plugin, the Redmine dogu must be restarted once."
  assert_dir_exist /usr/share/webapps/redmine/plugins/${plugin_name}
  assert_equal "$(mock_get_call_num "${bundle}")" "0"
}

@test "script should print help page on one argument instead of two" {
  local plugin_name=myPlugin
  mock_set_status "${bundle}" 0
  mkdir -p /usr/share/webapps/redmine/plugins/${plugin_name}

  run /workspace/resources/delete-plugin.sh ${plugin_name}

  assert_failure
  # first line
  assert_line --partial "As the removal of the plugin may also result in changes to the database"
  assert_line --partial "Insert the flag --force at the end of the command to definitely uninstall"
  # help text start
  assert_line "usage: delete-plugin[.sh] <plugin-name> --force"
  # help text end
  assert_line --partial "To execute the deletion of the plugin add --force"
  refute_line --partial "Delete plugin"
  refute_line "To complete the deletion of the plugin, the Redmine dogu must be restarted once."
  assert_dir_exist /usr/share/webapps/redmine/plugins/${plugin_name}
  assert_equal "$(mock_get_call_num "${bundle}")" "0"
}
