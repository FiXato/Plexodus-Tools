#!/usr/bin/env bash
caller_path="$(dirname "$(realpath "$0")")"
PLEXODUS_ENV_PATH=${PLEXODUS_ENV_PATH:-""}

test_path="./plexodus-tools.env"
ls "${test_path}" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}"
fi

test_path="${caller_path}/../plexodus-tools.env"
ls "${test_path}" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}"
fi

test_path="~/.config"
ls "${test_path}/" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}/plexodus-tools.env"
fi

test_path="~/.configs"
ls "${test_path}/" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}/plexodus-tools.env"
fi

test_path="~/.plexodus-tools.env"
ls "${test_path}" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}"
fi

if [ "$PLEXODUS_ENV_PATH" == "" ]; then
  PLEXODUS_ENV_PATH="./plexodus-tools.env"
fi

if [ ! -f "$PLEXODUS_ENV_PATH" ]; then
  touch "$PLEXODUS_ENV_PATH"
fi

reload_env() {
  . "$PLEXODUS_ENV_PATH"
}

reload_env

append_to_env_file() {
  echo "${1}=\${$1:-$2}" >> "$PLEXODUS_ENV_PATH"
}
replace_in_env_file() {
  sed -Ee "s/${1}=.{1,}/${1}=${2}/" -i "" "$PLEXODUS_ENV_PATH"
}
update_env_file() {
  variable="$1"
  default="$2"
    
  if [ ! -f "$PLEXODUS_ENV_PATH" ]; then
    append_to_env_file "$variable" "$default"
  else
    grep -q -- "^${variable}=" "$PLEXODUS_ENV_PATH"
    if [ "$?" == "0" ]; then
      replace_in_env_file "$variable" "$default"
    else 
      append_to_env_file "$variable" "$default"
    fi
  fi
}

PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH="${PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH:-"./extracted"}"
PLEXODUS_OUTPUT_DIR_ALL_FROM_TAKEOUT="${PLEXODUS_OUTPUT_DIR_ALL_FROM_TAKEOUT:-"./data/output/urls/all_from_takeout"}"

