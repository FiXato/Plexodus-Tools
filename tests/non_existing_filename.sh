#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

if [ "$TMPDIR" == "" ]; then
  echo "\$TMPDIR is empty. Cannot run tests" 1>&2
  exit 255
else
  TMPDIR="$TMPDIR/tmp-pid-${$}"
  gnufind -- "$TMPDIR/" -maxdepth 0 2>/dev/null && error "Process-specific \$TMPDIR '$TMPDIR' already exists" && exit 255
  debug "TMPDIR: '$TMPDIR'"
  mkdir -- "$TMPDIR" || exit 255
fi

touch "${TMPDIR}/exists.png"
touch "${TMPDIR}/exists-for-one-attempt.png"{,.1}
touch "${TMPDIR}/exists-for-two-attempts.png"{,.1,.2}
touch "${TMPDIR}/exists-for-three-attempts.png"{,.1,.2,.3}

if [ "$DEBUG" != 1 ]; then
  error() {
    return 0
  }
fi

declare -A test_cases
test_cases['does_not_exist.png']='does_not_exist.png'
test_cases['exists.png']='exists.png.1'
test_cases['exists-for-one-attempt.png']='exists-for-one-attempt.png.2'
test_cases['exists-for-two-attempts.png']='exists-for-two-attempts.png.3'
nr_of_test_cases="${#test_cases[@]}"
echo "${TP_BOLD}Found $nr_of_test_cases test cases that should succeed:${TP_RESET}"
counter=0
for input in "${!test_cases[@]}"
do
  counter=$((counter+1))
  expected="${test_cases[$input]}"
  result="$(non_existing_filename "${TMPDIR}" "$input")"
  exit_code="$?"
  
  if (( $exit_code > 0 )); then
    echo_fail_msg "[$counter/$nr_of_test_cases] '$input' has unexpected non-zero exit code (\$?=$exit_code; \$result=$result; \$expected=$expected)"
    continue
  fi
  
  if [ "$result" != "$expected" ]; then
    echo "Input '$input' does not match \$expected output filename: '$expected'. Exited with: $exit_code" 1>&2
    echo_fail_msg "[$counter/$nr_of_test_cases] '$input' (\$?=$exit_code; \$result=$result; \$expected=$expected)"
  else
    echo_pass_msg "[$counter/$nr_of_test_cases] '$input' (\$?=$exit_code; \$result=$result)"
  fi
done
echo

echo "${TP_BOLD}Additional test cases:${TP_RESET}"
test_case_counter="1/4"
input='exists-for-three-attempts.png'
test_cases["$input"]=''
expected="${test_cases["$input"]}"
test_case_suffix=" (returns error, with max_tries=default(=3))"
result="$(non_existing_filename "${TMPDIR}" "$input")"
exit_code="$?"
if (( $exit_code == 0 )); then
  echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix has unexpected zero exit code (\$?=$exit_code; \$result=$result; \$expected=$expected)"
else
  if [ "$result" != "$expected" ]; then
    echo "Input '$input'$test_case_suffix does not match \$expected output filename: '$expected'. Exited with: $exit_code" 1>&2
    echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result; \$expected=$expected)"
  else
    echo_pass_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result)"
  fi
fi

test_case_counter="2/4"
input='exists-for-three-attempts.png'
test_cases["$input"]=''
expected="${test_cases["$input"]}"
test_max_tries=3
test_case_suffix=" (returns error, with non-default max_tries=$test_max_tries)"
result="$(non_existing_filename "${TMPDIR}" "$input" "$test_max_tries")"
exit_code="$?"
if (( $exit_code == 0 )); then
  echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix has unexpected zero exit code (\$?=$exit_code; \$result=$result; \$expected=$expected)"
else
  if [ "$result" != "$expected" ]; then
    echo "Input '$input'$test_case_suffix does not match \$expected output filename: '$expected'. Exited with: $exit_code" 1>&2
    echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result; \$expected=$expected)"
  else
    echo_pass_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result)"
  fi
fi

test_case_counter="3/4"
input='exists-for-three-attempts.png'
test_cases["$input"]='exists-for-three-attempts.png.4'
expected="${test_cases["$input"]}"
test_max_tries=4
test_case_suffix=" (with non-default max_tries=$test_max_tries)"
result="$(non_existing_filename "${TMPDIR}" "$input" $test_max_tries)"
exit_code="$?"
if (( $exit_code > 0 )); then
  echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix has unexpected non-zero exit code (\$?=$exit_code; \$result=$result; \$expected=$expected)"
else
  if [ "$result" != "$expected" ]; then
    echo "Input '$input'$test_case_suffix does not match \$expected output filename: '$expected'. Exited with: $exit_code" 1>&2
    echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result; \$expected=$expected)"
  else
    echo_pass_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result)"
  fi
fi

test_case_counter="4/4"
input='does-not-exist-with-0-tries.png'
test_cases["$input"]='does-not-exist-with-0-tries.png'
expected="${test_cases["$input"]}"
test_max_tries=0
test_case_suffix=" (with non-default max_tries=$test_max_tries)"
result="$(non_existing_filename "${TMPDIR}" "$input" $test_max_tries)"
exit_code="$?"
if (( $exit_code > 0 )); then
  echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix has unexpected non-zero exit code (\$?=$exit_code; \$result=$result; \$expected=$expected)"
else
  if [ "$result" != "$expected" ]; then
    echo "Input '$input'$test_case_suffix does not match \$expected output filename: '$expected'. Exited with: $exit_code" 1>&2
    echo_fail_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result; \$expected=$expected)"
  else
    echo_pass_msg "[$test_case_counter] '$input'$test_case_suffix (\$?=$exit_code; \$result=$result)"
  fi
fi