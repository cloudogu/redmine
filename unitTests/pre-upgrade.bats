#! /bin/bash

@test "setSemanticVersionVars() should do a thing" {
  mock_set_output "${mock1}" "alias1\n" 1
  mock_set_side_effect "${mock2}" "echo hallo > welt"

  source /workspace/script.sh

  run setSemanticVersionVars

  assert_success
  assert_equal "$(mock_get_call_num "${mock1}")" "1"
  assert_equal "$(mock_get_call_args "${mock1}" "1")" "some call params"
}

@test "getMajorVersion() should do a thing" {
  mock_set_output "${mock1}" "alias1\n" 1
  mock_set_side_effect "${mock2}" "echo hallo > welt"

  source /workspace/script.sh

  run getMajorVersion

  assert_success
  assert_equal "$(mock_get_call_num "${mock1}")" "1"
  assert_equal "$(mock_get_call_args "${mock1}" "1")" "some call params"
}

@test "getMinorVersion() should do a thing" {
  mock_set_output "${mock1}" "alias1\n" 1
  mock_set_side_effect "${mock2}" "echo hallo > welt"

  source /workspace/script.sh

  run getMinorVersion

  assert_success
  assert_equal "$(mock_get_call_num "${mock1}")" "1"
  assert_equal "$(mock_get_call_args "${mock1}" "1")" "some call params"
}

@test "getBugfixVersion() should do a thing" {
  mock_set_output "${mock1}" "alias1\n" 1
  mock_set_side_effect "${mock2}" "echo hallo > welt"

  source /workspace/script.sh

  run getBugfixVersion

  assert_success
  assert_equal "$(mock_get_call_num "${mock1}")" "1"
  assert_equal "$(mock_get_call_args "${mock1}" "1")" "some call params"
}

@test "getDoguVersion() should do a thing" {
  mock_set_output "${mock1}" "alias1\n" 1
  mock_set_side_effect "${mock2}" "echo hallo > welt"

  source /workspace/script.sh

  run getDoguVersion

  assert_success
  assert_equal "$(mock_get_call_num "${mock1}")" "1"
  assert_equal "$(mock_get_call_args "${mock1}" "1")" "some call params"
}