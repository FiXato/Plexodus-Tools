#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

counter=0
filename="1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456.ext" #200 characters
default_max_length="${#filename}"

test_case="limit_filename_length should return exit code 0"
input="$filename"
result="$(limit_filename_length "$input")"
exit_code="$?"
if [ "$exit_code" != "0" ]; then
  echo_fail_msg "[$((counter+=1))] ${TP_SOON}$test_case${TP_SOOFF} (\$?=$exit_code; \$input=$input; \$result=$result)"
fi

test_case="limit_filename_length should return filename unchanged if of equal length as default max length of $default_max_length characters"
[ "$result" == "$input" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "[$((counter+=1))] ${TP_SOON}$test_case${TP_SOOFF} (\$?=$exit_code; \$input=$input; \$result=$result; length=${#input})"

test_case="limit_filename_length should return filename unchanged if shorter than max length of $default_max_length characters"
length=$(($default_max_length - 1))
input="${filename:0:$length}"
result="$(limit_filename_length "$input")"
[ "$result" == "$input" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "[$((counter+=1))] ${TP_SOON}$test_case${TP_SOOFF} (\$?=$exit_code; \$filename=$filename; \$result=$result; length=${#input})"

test_case="limit_filename_length should return filename shortened to $default_max_length characters if longer than max length of $default_max_length characters"
length=$((${#filename} + 1))
result="$(limit_filename_length "1${filename}")"
[ "${#result}" == "$default_max_length" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "[$((counter+=1))] ${TP_SOON}$test_case${TP_SOOFF} (\$?=$exit_code; \$filename=$filename; \$result=$result; length=${#result})"

test_case="limit_filename_length should return filename shortened, while retaining file-extension"
length=$((${#filename} + 1))
result="$(limit_filename_length "1${filename}")"
[ "$result" == "1123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345.ext" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "[$((counter+=1))] ${TP_SOON}$test_case${TP_SOOFF} (\$?=$exit_code; \$filename=$filename; \$result=$result; length=${#result})"


max_filename_length=190
test_case="limit_filename_length should return filename shortened to \$MAX_FILELENGTH=$max_filename_length characters if longer than max length of \$MAX_FILELENGTH characters"
length=$MAX_FILELENGTH
result="$(MAX_FILELENGTH=$max_filename_length limit_filename_length "${filename}")"
[ "${#result}" == "$max_filename_length" ] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "[$((counter+=1))] ${TP_SOON}$test_case${TP_SOOFF} (\$?=$exit_code; \$filename=$filename; \$result=$result; length=${#result})"

filename="12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890" #200 characters
default_max_length="${#filename}"
test_case="limit_filename_length should return filename shortened, while not adding a file-extension, when none was present"
length=$((${#filename} + 1))
result="$(limit_filename_length "1${filename}")"
[[ "$result" != *"."* ]] && test_result="pass" || test_result="fail"
"echo_${test_result}_msg" "[$((counter+=1))] ${TP_SOON}$test_case${TP_SOOFF} (\$?=$exit_code; \$filename=$filename; \$result=$result; length=${#result})"
