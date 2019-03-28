#!/usr/bin/env bash
caller_path="$(dirname "$(realpath "$0")")"
PLEXODUS_ENV_PATH=${PLEXODUS_ENV_PATH:-""}
PLEXODUS_ENV_FILENAME="${PLEXODUS_ENV_FILENAME:-"plexodus-tools.env"}"

# Maybe use find -name "$1" -maxdepth 0 for this instead?
file_exists() {
  ls -- "$1" > /dev/null 2>&1
}

dir_exists() {
  file_exists "$1/"
}

test_path="./${PLEXODUS_ENV_FILENAME}"
[ "$PLEXODUS_ENV_PATH" == "" ] && file_exists "$test_path" && PLEXODUS_ENV_PATH="${test_path}"

test_path="${caller_path}/../${PLEXODUS_ENV_FILENAME}"
[ "$PLEXODUS_ENV_PATH" == "" ] && file_exists "$test_path" && PLEXODUS_ENV_PATH="${test_path}"

test_path="${HOME}/.config"
[ "$PLEXODUS_ENV_PATH" == "" ] && dir_exists "$test_path" && PLEXODUS_ENV_PATH="${test_path}/${PLEXODUS_ENV_FILENAME}"

test_path="${HOME}/.configs"
[ "$PLEXODUS_ENV_PATH" == "" ] && dir_exists "$test_path" && PLEXODUS_ENV_PATH="${test_path}/${PLEXODUS_ENV_FILENAME}"

test_path="${HOME}/.${PLEXODUS_ENV_FILENAME}"
[ "$PLEXODUS_ENV_PATH" == "" ] && file_exists "$test_path" && PLEXODUS_ENV_PATH="${test_path}"

test_path="${HOME}/${PLEXODUS_ENV_FILENAME}"
[ "$PLEXODUS_ENV_PATH" == "" ] && file_exists "$test_path" && PLEXODUS_ENV_PATH="${test_path}"

[ "$PLEXODUS_ENV_PATH" == "" ] && PLEXODUS_ENV_PATH="./${PLEXODUS_ENV_FILENAME}"

[ ! -f "$PLEXODUS_ENV_PATH" ] && touch "$PLEXODUS_ENV_PATH"

reload_env() {
  . "$PLEXODUS_ENV_PATH"
}

reload_env

append_to_env_file() {
  declare -n env_var="${1}"
  env_var="$2"
  echo "${1}=\${$1:-$env_var}" >> "$PLEXODUS_ENV_PATH"
}
replace_in_env_file() {
  declare -n env_var="${1}"
  env_var="${2}"
  $(gnused_cmdstring) -Ee "s/${1}=.{1,}/${1}=\${${1}:-$(printf '%s' "$env_var" | $(gnused_cmdstring) -e 's/[\/&]/\\&/g')}/" -i"" "$PLEXODUS_ENV_PATH"
}
update_env_file() {
  local variable="$1"
  local default="$2"
    
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

declare -a PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES=("." "~/storage/downloads")
PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH="${PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH:-"./.plexodus-takeout-search-dirs.txt"}"
PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH="${PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH:-"./extracted"}"
PLEXODUS_OUTPUT_DIR_ALL_FROM_TAKEOUT="${PLEXODUS_OUTPUT_DIR_ALL_FROM_TAKEOUT:-"./data/output/urls/all_from_takeout"}"
LAST_COMMAND_OUTPUT_LOGPATH="./last_command_output.log"
