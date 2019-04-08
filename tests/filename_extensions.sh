#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

first_extension="extfirst"
second_extension="ext2"
last_extension="extlast"
filename="filename.$first_extension.$second_extension.$last_extension"

result="$(strip_all_extensions "$filename")"
exit_code="$?"
if [ "$result" == "filename" ]; then
  echo_pass_msg "[$((counter+=1))] Strip all extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] Strip all extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi

result="$(strip_last_extension "$filename")"
exit_code="$?"
if [ "$result" == "filename.$first_extension.$second_extension" ]; then
  echo_pass_msg "[$((counter+=1))] Strip last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] Strip last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi

result="$(all_extensions "$filename")"
exit_code="$?"
if [ "$result" == "$first_extension.$second_extension.$last_extension" ]; then
  echo_pass_msg "[$((counter+=1))] All extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] All extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi

result="$(last_extension "$filename")"
exit_code="$?"
if [ "$result" == "$last_extension" ]; then
  echo_pass_msg "[$((counter+=1))] Last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] Last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi

############

filename="noextension"
echo "Testing filename without extension: $filename"
result="$(strip_all_extensions "$filename")"
exit_code="$?"
if [ "$result" == "$filename" ]; then
  echo_pass_msg "[$((counter+=1))] Strip all extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] Strip all extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi

result="$(strip_last_extension "$filename")"
exit_code="$?"
if [ "$result" == "$filename" ]; then
  echo_pass_msg "[$((counter+=1))] Strip last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] Strip last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi

result="$(all_extensions "$filename")"
exit_code="$?"
if [ "$result" == "" ]; then
  echo_pass_msg "[$((counter+=1))] All extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] All extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi

result="$(last_extension "$filename")"
exit_code="$?"
if [ "$result" == "" ]; then
  echo_pass_msg "[$((counter+=1))] Last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
else
  echo_fail_msg "[$((counter+=1))] Last extensions (\$?=$exit_code; \$filename=$filename; \$result=$result)"
fi