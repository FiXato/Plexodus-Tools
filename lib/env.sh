#!/usr/bin/env bash
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
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

test_path="${PT_PATH}/${PLEXODUS_ENV_FILENAME}"
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
PLEXODUS_DATA_PATH="${PLEXODUS_DATA_PATH:-"./data"}"
PLEXODUS_DATA_CACHE_PATH="${PLEXODUS_DATA_CACHE_PATH:-"${PLEXODUS_DATA_PATH}/cache"}"
PLEXODUS_DATA_CACHE_DIRECT_PATH="${PLEXODUS_DATA_CACHE_DIRECT_PATH:-"${PLEXODUS_DATA_CACHE_PATH}/direct"}"

PLEXODUS_DATA_OUTPUT_PATH="${PLEXODUS_DATA_OUTPUT_PATH:-"${PLEXODUS_DATA_PATH}/output"}"
PLEXODUS_DATA_URLS_OUTPUT_PATH="${PLEXODUS_DATA_URLS_OUTPUT_PATH:-"${PLEXODUS_DATA_OUTPUT_PATH}/urls"}"
PLEXODUS_DATA_GOOGLEUSERCONTENT_URLS_OUTPUT_PATH="${PLEXODUS_DATA_GOOGLEUSERCONTENT_URLS_OUTPUT_PATH:-"${PLEXODUS_DATA_URLS_OUTPUT_PATH}/googleusercontent"}"

PLEXODUS_DATA_RESULT_LISTS_OUTPUT_PATH="${PLEXODUS_DATA_RESULT_LISTS_OUTPUT_PATH:-"${PLEXODUS_DATA_OUTPUT_PATH}/result-lists"}"
PLEXODUS_DATA_GOOGLEUSERCONTENT_FILEPATHS_OUTPUT_PATH="${PLEXODUS_DATA_GOOGLEUSERCONTENT_FILEPATHS_OUTPUT_PATH:-"${PLEXODUS_DATA_RESULT_LISTS_OUTPUT_PATH}/googleusercontent"}"

MAX_RETRIEVAL_RETRIES=${MAX_RETRIEVAL_RETRIES:-3}
PLEXODUS_ON_URL_RETRIEVAL_FAILURE="${PLEXODUS_ON_URL_RETRIEVAL_FAILURE:-"DELETE_DOWNLOAD"}"
#PLEXODUS_ON_URL_RETRIEVAL_FAILURE="${PLEXODUS_ON_URL_RETRIEVAL_FAILURE:-"DELETE_DOWNLOAD:DELETE_METADATA"}"

PLEXODUS_FIND_MAX_DEPTH=${PLEXODUS_FIND_MAX_DEPTH:-5}

function output_path() {
  [[ "$1" == "all_avatar_image_urls-without_size"* ]] && printf '%s' "$(ensure_path "${PLEXODUS_DATA_GOOGLEUSERCONTENT_URLS_OUTPUT_PATH}" "$1.txt")" && return 0
  [[ "$1" == "all_retrieved_avatar_image_paths"* ]] && printf '%s' "$(ensure_path "${PLEXODUS_DATA_GOOGLEUSERCONTENT_FILEPATHS_OUTPUT_PATH}" "$1.txt")" && return 0

  error "Missing output path for '$1'"
  printf '%s' ''
  return 255
}

XARGS_CMD="${XARGS_CMD:-"$(hash gxargs 2>/dev/null && echo 'gxargs' || echo 'xargs')"}"
SED_CMD="${SED_CMD:-"$(hash gsed 2>/dev/null && echo 'gsed' || echo 'sed')"}"
GREP_CMD="${GREP_CMD:-"$(hash ggrep 2>/dev/null && echo 'ggrep' || echo 'grep')"}"
AWK_CMD="${AWK_CMD:-"$(hash gawk 2>/dev/null && echo 'gawk' || echo 'awk')"}"
FIND_CMD="${FIND_CMD:-"$(hash gfind 2>/dev/null && echo 'gfind' || echo 'find')"}"
DATE_CMD="${DATE_CMD:-"$(hash gdate 2>/dev/null && echo 'gdate' || echo 'date')"}"
STAT_CMD="${STAT_CMD:-"$(hash gstat 2>/dev/null && echo 'gstat' || echo 'stat')"}"