#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

counter=0
first_item="first"
second_item="second"
third_item="third"
last_item="last"
default_delimiter=","
default_input="${first_item}${default_delimiter}${second_item}${default_delimiter}${third_item}${default_delimiter}${last_item}"
declare -a items=()
declare -a default_items=("$first_item" "$second_item" "$third_item" "$last_item")
declare -a input_starts_with_delimiter_items=("" "$second_item" "$third_item" "$last_item")
declare -a input_ends_with_delimiter_items=("$first_item" "$second_item" "$third_item" "")
input_starts_with_delimiter="$(printf "%s$default_delimiter" "${input_starts_with_delimiter_items[@]}")" #join array items with delimiter
input_starts_with_delimiter="${input_starts_with_delimiter/%$default_delimiter}" #Strip trailing delimiter
input_ends_with_delimiter="$(printf "%s$default_delimiter" "${input_ends_with_delimiter_items[@]}")" #join array items with delimiter
input_ends_with_delimiter="${input_ends_with_delimiter/%$default_delimiter}" #Strip trailing delimiter
input_with_unicode_delimiter="$(printf $'%s\u001F' "${default_items[@]}")" #join array items with delimiter
input_with_unicode_delimiter="${input_with_unicode_delimiter/%$'\u001F'}" #Strip trailing delimiter

test_case="split() should return exit code 0"
input="$default_input"
split "$input" items
exit_code="$?"
[ "$exit_code" == "0" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
"

result="$(all_after_first_delimiter "$(declare -p items)" '=')"
expected="$(all_after_first_delimiter "$(declare -p default_items)" '=')"
test_case="split() should fill \$items with all items"
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"
items=()

input="$input_starts_with_delimiter"
split "$input" items
exit_code="$?"
result="$(all_after_first_delimiter "$(declare -p items)" '=')"
expected="$(all_after_first_delimiter "$(declare -p input_starts_with_delimiter_items)" '=')"
test_case="split() should fill \$items with all items, even when input starts with delimiter"
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"
items=()

input="$input_ends_with_delimiter"
split "$input" items
exit_code="$?"
result="$(all_after_first_delimiter "$(declare -p items)" '=')"
expected="$(all_after_first_delimiter "$(declare -p input_ends_with_delimiter_items)" '=')"
test_case="split() should fill \$items with all items, even when input ends with delimiter"
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"
items=()

input="$input_with_unicode_delimiter"
split "$input" items $'\u001F'
result="$(all_after_first_delimiter "$(declare -p items)" '=')"
expected="$(all_after_first_delimiter "$(declare -p default_items)" '=')"
test_case="split() should support non-default delimiter"
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"
items=()