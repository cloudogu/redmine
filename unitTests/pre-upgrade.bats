#! /bin/bash
# Bind an unbound BATS variable that fails all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'

setup() {
  doguctl="$(mock_create)"
  export doguctl
  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
}

teardown() {
  rm "${BATS_TMPDIR}/doguctl"
}

@test "versionXLessOrEqualThanY() should return true for versions less than or equal to another" {
  source /workspace/resources/pre-upgrade.sh

  run versionXLessOrEqualThanY "1.0.0" "1.0.0"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.1.0"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.0.1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.1.1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.0.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.1.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.0.1-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "1.1.1-1"
  assert_success

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

  run versionXLessOrEqualThanY "1.0.0" "2.0.0"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "2.1.0"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "2.0.1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "2.1.1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "2.0.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "2.1.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "2.0.1-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0" "2.1.1-1"
  assert_success

  run versionXLessOrEqualThanY "1.0.0-1" "2.0.0"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.1.0"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.0.1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.1.1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.0.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.1.0-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.0.1-1"
  assert_success
  run versionXLessOrEqualThanY "1.0.0-1" "2.1.1-1"
  assert_success
}

@test "versionXLessOrEqualThanY() should return false for versions greater than another" {
  source /workspace/resources/pre-upgrade.sh

  run versionXLessOrEqualThanY "1.0.0" "0.0.9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.9.0"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.9.9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.0.0"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-0" "0.0.0"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0-1" "0.0.0"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.0.0-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.1.9-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.0.9-9"
  assert_failure
  run versionXLessOrEqualThanY "1.0.0" "0.1.9-9"
  assert_failure

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

  run versionXLessOrEqualThanY "2.0.0" "1.0.0"
  assert_failure
  run versionXLessOrEqualThanY "2.1.0" "1.0.0"
  assert_failure
  run versionXLessOrEqualThanY "2.0.1" "1.0.0"
  assert_failure
  run versionXLessOrEqualThanY "2.1.1" "1.0.0"
  assert_failure
  run versionXLessOrEqualThanY "2.0.0-1" "1.0.0"
  assert_failure
  run versionXLessOrEqualThanY "2.1.0-1" "1.0.0"
  assert_failure
  run versionXLessOrEqualThanY "2.0.1-1" "1.0.0"
  assert_failure
  run versionXLessOrEqualThanY "2.1.1-1" "1.0.0"
  assert_failure

  run versionXLessOrEqualThanY "2.0.0" "1.0.0-1"
  assert_failure
  run versionXLessOrEqualThanY "2.1.0" "1.0.0-1"
  assert_failure
  run versionXLessOrEqualThanY "2.0.1" "1.0.0-1"
  assert_failure
  run versionXLessOrEqualThanY "2.1.1" "1.0.0-1"
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

  run versionXLessThanY "1.0.0" "1.1.0"
  assert_success
  run versionXLessThanY "1.0.0" "1.0.1"
  assert_success
  run versionXLessThanY "1.0.0" "1.1.1"
  assert_success
  run versionXLessThanY "1.0.0" "1.0.0-1"
  assert_success
  run versionXLessThanY "1.0.0" "1.1.0-1"
  assert_success
  run versionXLessThanY "1.0.0" "1.0.1-1"
  assert_success
  run versionXLessThanY "1.0.0" "1.1.1-1"
  assert_success

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

  run versionXLessThanY "1.0.0" "2.0.0"
  assert_success
  run versionXLessThanY "1.0.0" "2.1.0"
  assert_success
  run versionXLessThanY "1.0.0" "2.0.1"
  assert_success
  run versionXLessThanY "1.0.0" "2.1.1"
  assert_success
  run versionXLessThanY "1.0.0" "2.0.0-1"
  assert_success
  run versionXLessThanY "1.0.0" "2.1.0-1"
  assert_success
  run versionXLessThanY "1.0.0" "2.0.1-1"
  assert_success
  run versionXLessThanY "1.0.0" "2.1.1-1"
  assert_success

  run versionXLessThanY "1.0.0-1" "2.0.0"
  assert_success
  run versionXLessThanY "1.0.0-1" "2.1.0"
  assert_success
  run versionXLessThanY "1.0.0-1" "2.0.1"
  assert_success
  run versionXLessThanY "1.0.0-1" "2.1.1"
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

  run versionXLessThanY "1.0.0" "1.0.0"
  assert_failure
  run versionXLessThanY "1.0.0" "0.0.9"
  assert_failure
  run versionXLessThanY "1.0.0" "0.9.0"
  assert_failure
  run versionXLessThanY "1.0.0" "0.9.9"
  assert_failure
  run versionXLessThanY "1.0.0" "0.0.0"
  assert_failure
  run versionXLessThanY "1.0.0-0" "0.0.0"
  assert_failure
  run versionXLessThanY "1.0.0-1" "0.0.0"
  assert_failure
  run versionXLessThanY "1.0.0" "0.0.0-9"
  assert_failure
  run versionXLessThanY "1.0.0" "0.1.9-9"
  assert_failure
  run versionXLessThanY "1.0.0" "0.0.9-9"
  assert_failure
  run versionXLessThanY "1.0.0" "0.1.9-9"
  assert_failure

  run versionXLessThanY "1.0.0" "1.0.0"
  assert_failure
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

  assert_failure
  run versionXLessThanY "1.2.3-4" "0.1.2-3"
  assert_failure
  run versionXLessThanY "1.2.3-5" "0.1.2-3"
  assert_failure

  run versionXLessThanY "2.0.0" "1.0.0"
  assert_failure
  run versionXLessThanY "2.1.0" "1.0.0"
  assert_failure
  run versionXLessThanY "2.0.1" "1.0.0"
  assert_failure
  run versionXLessThanY "2.1.1" "1.0.0"
  assert_failure
  run versionXLessThanY "2.0.0-1" "1.0.0"
  assert_failure
  run versionXLessThanY "2.1.0-1" "1.0.0"
  assert_failure
  run versionXLessThanY "2.0.1-1" "1.0.0"
  assert_failure
  run versionXLessThanY "2.1.1-1" "1.0.0"
  assert_failure

  run versionXLessThanY "2.0.0" "1.0.0-1"
  assert_failure
  run versionXLessThanY "2.1.0" "1.0.0-1"
  assert_failure
  run versionXLessThanY "2.0.1" "1.0.0-1"
  assert_failure
  run versionXLessThanY "2.1.1" "1.0.0-1"
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