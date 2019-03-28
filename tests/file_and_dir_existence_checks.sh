#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

if [ "$TMPDIR" == "" ]; then
  echo "\$TMPDIR is empty. Cannot run tests" 1>&2
  exit 255
else
  TMPDIR="$TMPDIR/tmp-pid-${$}"
  mkdir "$TMPDIR" || exit 255
fi

unset _PLEXODUS_TEST_ENV_VAR

test_path="${TMPDIR}/nonexistent"
rm -f "$test_path"
result="$(file_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[1] File ${TP_BOLD}Should not exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -f "$test_path"
unset _PLEXODUS_TEST_ENV_VAR

test_path="${TMPDIR}/existent"
touch "$test_path"
result="$(file_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[2] File ${TP_BOLD}Should exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "$test_path" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -f "$test_path"
unset _PLEXODUS_TEST_ENV_VAR

test_path="${TMPDIR}/nonexistent-dir/"
rm -rf "$test_path"
result="$(dir_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[3] Dir with trailing slash ${TP_BOLD}Should not exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -rf "$test_path"
unset _PLEXODUS_TEST_ENV_VAR

test_path="${TMPDIR}/existent-dir/"
mkdir "$test_path"
result="$(dir_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[4] Dir with trailing slash ${TP_BOLD}Should exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "$test_path" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -rf "$test_path"
unset _PLEXODUS_TEST_ENV_VAR


test_path="${TMPDIR}/nonexistent-dir"
rm -rf "$test_path"
result="$(dir_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[5] Dir without trailing slash ${TP_BOLD}Should not exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -rf "$test_path"
unset _PLEXODUS_TEST_ENV_VAR

test_path="${TMPDIR}/existent-dir"
mkdir "$test_path"
result="$(dir_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[6] Dir without trailing slash ${TP_BOLD}Should exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "$test_path" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -rf "$test_path"
unset _PLEXODUS_TEST_ENV_VAR

test_path="${TMPDIR}/existent dir with spaces/"
mkdir "$test_path"
result="$(dir_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[7] Dir with spaces ${TP_BOLD}Should exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "$test_path" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi

test_msg="[8] Dir with spaces ${TP_BOLD}Should have spaces${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$(basename "$_PLEXODUS_TEST_ENV_VAR")" == "existent dir with spaces" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -rf "$test_path"
unset _PLEXODUS_TEST_ENV_VAR

test_path="${TMPDIR}/existent file with spaces"
touch "$test_path"
result="$(file_exists "$test_path")" && _PLEXODUS_TEST_ENV_VAR="${test_path}"
exit_code="$?"
test_msg="[9] File with spaces ${TP_BOLD}Should exist${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "$_PLEXODUS_TEST_ENV_VAR" == "$test_path" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi

test_msg="[10] File with spaces ${TP_BOLD}Should have spaces${TP_RESET}: '$test_path' (\$?=$exit_code; \$result=$result; \$_PLEXODUS_TEST_ENV_VAR=$_PLEXODUS_TEST_ENV_VAR)"
if [ "${_PLEXODUS_TEST_ENV_VAR##*/}" == "existent file with spaces" ]; then
  echo_pass_msg "$test_msg"
else
  echo_fail_msg "$test_msg"
fi
rm -rf "$test_path"
unset _PLEXODUS_TEST_ENV_VAR
#cleanup:
rm -r "$TMPDIR"