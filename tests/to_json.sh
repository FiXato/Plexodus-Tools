#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

counter=0
declare -A test_hash
test_hash["first"]="1"
test_hash["second"]="2"
test_hash["third"]="3"
declare -A empty_hash

declare -a test_array=("first" "second" "third" "last")
declare -a empty_array=()

input="$(declare -p test_hash)"
result="$(hash_to_json test_hash | jq -r 'keys | sort | join(",")')"
exit_code="$?"
test_case="hash_to_json() should return exit code 0"
[ "$exit_code" == "0" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
"

test_case="hash_to_json() should return a JSON hash with all keys"
expected="first,second,third"
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"

result="$(hash_to_json test_hash | jq -r 'map(.) | sort | join(",")')"
expected="1,2,3"
test_case="hash_to_json() should return a JSON hash with all values"
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"

input="$(declare -p empty_hash)"
result="$(hash_to_json empty_hash)"
test_case="hash_to_json() should handle empty hashes"
expected='{}'
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"

input="$(declare -p test_array)"
result="$(array_to_json test_array)"
exit_code="$?"
test_case="array_to_json() should return exit code 0"
[ "$exit_code" == "0" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
"

test_case="array_to_json() should return a compact JSON array string with all values"
expected='["first", "second", "third", "last"]'
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"

result="$(array_to_json test_array | jq -r 'sort|join(",")')"
expected='first,last,second,third'
test_case="array_to_json() should return a compact JSON array string parsable by jq"
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"

input="$(declare -p empty_array)"
result="$(array_to_json empty_array)"
test_case="array_to_json() should handle empty arrays"
expected='[]'
[ "$result" == "$expected" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "${TP_BOLD}[$((counter+=1))] $test_case${TP_RESET}
    → \$?=$exit_code
    → \$input=$input
    → \$result=$result
    → \$expected=$expected
"
