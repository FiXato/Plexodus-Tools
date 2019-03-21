#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

function echo_fail_msg() {
  echo -e "[❌ ${FG_RED}${TP_BOLD}FAIL${TP_RESET}] $@"
}

function echo_pass_msg() {
  echo "[✅ ${FG_GREEN}${TP_BOLD}PASS${TP_RESET}] $@"
}

declare -A test_cases
test_cases['https://plus.google.com/+PeggyKTC/posts/i2KiCNbMwC4']='+PeggyKTC'
test_cases['https://plus.google.com/+PeggyKTC']='+PeggyKTC'
test_cases['https://plus.google.com/112064652966583500522']='112064652966583500522'
test_cases['https://plus.google.com/112064652966583500522/posts/jfnSz1YrxWS']='112064652966583500522'
test_cases['https://plus.google.com/+NguyễnSỹBằng/posts/TUNMVAa6Sm6']='+NguyễnSỹBằng'
nr_of_test_cases="${#test_cases[@]}"
echo "${TP_BOLD}Found $nr_of_test_cases test cases that should succeed:${TP_RESET}"
counter=0
for input in "${!test_cases[@]}"
do
  counter=$((counter+1))
  target_uid="${test_cases[$input]}"
  result="$(get_user_id "$input")"
  exit_code="$?"
  if [ "$result" != "$target_uid" ]; then
    echo "Input '$input' does not match target UID '$target_uid'. Exited with $exit_code" 1>&2
    echo_fail_msg "[$counter/$nr_of_test_cases] '$input' (\$?=$exit_code)"
  else
    echo_pass_msg "[$counter/$nr_of_test_cases] '$input' (\$?=$exit_code)"
  fi
done
echo

declare -A fail_test_cases
fail_test_cases['https://plus.google.com/']=255
fail_test_cases['https://plus.google.com/communities/112164273001338979772']=255
nr_of_test_cases="${#fail_test_cases[@]}"
echo "${TP_BOLD}Found $nr_of_test_cases test cases that should return an exit code:${TP_RESET}"
counter=0
for input in "${!fail_test_cases[@]}"
do
  counter=$((counter+1))
  target_exit_code="${fail_test_cases[$input]}"
  result="$(get_user_id "$input")"
  exit_code="$?"
  if [ "$result" == "" ]; then
    if (( $exit_code == $target_exit_code )); then
      echo_pass_msg "[$counter/$nr_of_test_cases] '$input' (\$?=$exit_code)"
    else
      echo "Input '$input' has incorrect exit code. (Expected: $target_exit_code / Received: $exit_code)" 1>&2
      echo_fail_msg "[$counter/$nr_of_test_cases] '$input' (\$?=$exit_code)"
    fi
  else
    echo_fail_msg "[$counter/$nr_of_test_cases] '$input' (\$?=$exit_code; \$result=$result)"
  fi
done