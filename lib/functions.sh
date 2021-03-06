#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/formatting.sh"
. "${PT_PATH}/lib/env.sh"

#FIXME: Make sure all functions use *local* variables.

#FIXME: move this to an variables.env file
REQUEST_THROTTLE="${REQUEST_THROTTLE:-0}"
USER_AGENT="${USER_AGENT:-PlexodusToolsBot/0.9.0}" #Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3724.8 Safari/537.36
MAX_RETRIEVAL_RETRIES=${MAX_RETRIEVAL_RETRIES:-3}
USER_ID_CUSTOM_TO_NUMERIC_MAP_DIRECTORY="${PT_PATH}/data/gplus/custom_to_numeric_user_id_mappings"


#TODO: Implement LOG_LEVEL
function debug() {
  if [ "$DEBUG" == "1" -o "$DEBUG" == "true" -o "$DEBUG" == "TRUE" ]; then
    echo -e "${FG_YELLOW}${TP_BOLD}[$(basename "$0")] $@${TP_RESET}" 1>&2
  fi
}

function error() {
  echo -e "${FG_RED}!E! [$(basename "$0")] ${TP_BOLD}$@${TP_RESET}" 1>&2
}

# By @ilkkachu from https://unix.stackexchange.com/a/366655
function printarr() {
  declare -n __p="$1"
  for k in "${!__p[@]}"
    do printf "%s=%s\n" "$k" "${__p[$k]}"
  done
}

function echo_fail_msg() {
  echo -e "[❌ ${FG_RED}${TP_BOLD}FAIL${TP_RESET}] $@"
}

function echo_pass_msg() {
  echo "[✅ ${FG_GREEN}${TP_BOLD}PASS${TP_RESET}] $@"
}

# https://stackoverflow.com/a/17841619 by @gniourf_gniourf and @nicholas-sushkin with edits from @lynn
# function join_by() { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

# https://stackoverflow.com/a/23673883 by @gniourf_gniourf
function join_by() {
  # $1 is sep
  # $2... are the elements to join
  local sep="$1" IFS=
  local join_ret=$2
  shift 2 || shift $(($#))
  join_ret+="${*/#/$sep}"
  echo "$join_ret"
}

function curl_urlencode() {
  curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | cut -c 3- | sed 's/%00$//g'
}

#FIXME: this can probably be simplified with get_user_id
function urlsafe_plus_profile_url() {
  local clean_source_url="$1"
  local plus_url_custom_handle_base="https://plus.google.com/+"
  local escaped_plus_url_custom_handle_base="^$(printf "$plus_url_custom_handle_base" | sed 's/\./\\./g;s/\+/\\+/g')"
  if [[ "$source_url" == $plus_url_custom_handle_base* ]]; then
    local urlencoded_username="$(echo "$clean_source_url" | gnugrep -oP "$escaped_plus_url_custom_handle_base"'\K([^/]+)' | curl_urlencode | sed 's/%0A$//' )"
    local url_path_suffix="$(echo "$clean_source_url" | gnugrep -oP "$escaped_plus_url_custom_handle_base"'[^/]+\K(/.+)')"
    clean_source_url="${plus_url_custom_handle_base}${urlencoded_username}${url_path_suffix}"
  fi
  echo "$clean_source_url"
}

function custom_to_numeric_user_id_map_filepath() {
  ensure_path "$(realpath "$USER_ID_CUSTOM_TO_NUMERIC_MAP_DIRECTORY")" "${1}.txt"
}

function get_numeric_user_id_for_custom_user_id() {
  local user_id="$1"
  local user_id_map_filepath="$(custom_to_numeric_user_id_map_filepath "$user_id")"
  if [ -f "$user_id_map_filepath" -a "$IGNORE_CACHE" != 'true' ]; then
    debug "Retrieved numeric user_id for '$user_id' from '${user_id_map_filepath/#$PWD/.}'."
    cat "$user_id_map_filepath"
    return 0
  fi

  local archived_profile_page="$("${PT_PATH}/bin/archive_url.sh" "https://plus.google.com/+${user_id}")"
  local exit_code="$?"
  if (( $exit_code > 0 )); then
    echo "Error while archiving G+ profile page for ${user_id}. Exited with error code $exit_code" 1>&2
    return $exit_code
  fi

  if hash pup 2>/dev/null; then
    debug "archived profile page: $archived_profile_page"
    cat "$archived_profile_page" | pup 'link[itemprop] attr{href}' | gnused 's/^https:\/\/plus\.google\.com\///' | tee "$user_id_map_filepath"
  else
    cat "$archived_profile_page" | gnugrep -oP '<link itemprop="url" href="\K([^"]+)' | tee "$user_id_map_filepath"
  fi
}

function set_user_id_array_from_gplus_url() {
  #FIXME: this nameref isn't actually used?
  declare -n ___="$1" # $1 = name of the target array variable
  debug "Source url: $2"
  user_ids['unparsed']="$(get_user_id "$2")" # $2 is the plus.google.com profile/post URL
  if [ "${user_ids['unparsed']:0:1}" == "+" ]; then
    user_ids['custom']="${user_ids['unparsed']:1}"
  else
    user_ids['numeric']="${user_ids['unparsed']}"
  fi
}

function parse_template() {
  # Usage: parse_template "/path/to/template.html" "name_of_variable"
  declare -n _template_variables="$2"
  _template_variables="${!_template_variables[@]}"

  # The || section is needed to read the last line if no trailing newline is present in the file at EOF
  while IFS= read -r line || [ -n "$line" ]; do
    processed_line="$line"
    while [ suffix != "" -a processed_line != "" ]; do
      variable_name_regex='\$[a-zA-Z_][a-zA-Z0-9_]*'
      literal_variable_name="$(expr "$processed_line" : '[^$]*\('$variable_name_regex'\)')"

      if (( $? > 0 )); then
        echo "$processed_line"
        break
      fi
      if [ "$literal_variable_name" == "" ]; then
        echo "$processed_line"
        break
      fi

      variable_name="${literal_variable_name:1}"
      prefix="$(expr "$processed_line" : '^\([^\$]\{0,\}\)'$variable_name_regex || echo "")"
      if [ "$prefix" != "" ]; then
        processed_line="${processed_line#$prefix}"
      fi
      processed_line="${processed_line#$literal_variable_name}"
      [ ${_template_variables[$variable_name]+test} ] && variable="${_template_variables[$variable_name]}" || variable="$literal_variable_name"
      printf "%s%s" "$prefix" "$variable"

    done
  done < "$1"
}

function machine_type() { #function provided by paxdiablo at https://stackoverflow.com/a/3466183
  unameOut="$(uname -s)"
  case "${unameOut}" in
      Linux*)     machine=Linux;;
      Darwin*)    machine=macOS;;
      CYGWIN*)    machine=Cygwin;;
      MINGW*)     machine=MinGw;;
      *)          machine="UNKNOWN:${unameOut}"
  esac
  echo "${machine}"
}

#FIXME: Should probably make this tool-independent and just run it once in an initial setup step. 
function ensure_gnutools() {
  gnu_utils=()
  missing_gnu_utils=()
  install_suggestion=""
  if [ "$(machine_type)" == "macOS" ]; then
    install_suggestion="$(machine_type)"' comes with the BSD versions of many of the CLI utilities this script uses. Unfortunately these are often limited in their usage options. I would suggest installing the GNU versions through Homebrew (https://brew.sh), which the script should automatically detect as Homebrew prefixes them with "g". E.g.: `brew install gawk findutils gnu-sed grep coreutils moreutils`'
  fi
  if [[ $(gnufind "--version") == *"GNU findutils"* ]]; then
    gnu_utils+=('find')
  elif [[ $(man $(gnufind_string) | head -2 | grep BSD) == *"BSD General Commands Manual"* ]]; then
    debug 'You have the BSD version of `find` installed. This script relies on the GNU version. Please install it with `brew install findutils`'
    missing_gnu_utils+=('find')
  else
    missing_gnu_utils+=('find')
  fi

  if [[ $(gnused "--version") == *"GNU sed"* ]]; then
    gnu_utils+=('sed')
  elif [[ $(man $(gnused_string) | head -2 | grep BSD) == *"BSD General Commands Manual"* ]]; then
    debug 'You have the BSD version of `sed` installed. This script relies on the GNU version. Please install it with `brew install sed`'
    missing_gnu_utils+=('sed')
  else
    missing_gnu_utils+=('sed')
  fi

  if [[ $(gnugrep "--version") == *"GNU grep"* ]]; then
    gnu_utils+=('grep')
  elif [[ $(gnugrep "--version") == *"BSD grep"* ]]; then
    debug 'You have the BSD version of `grep` installed. This script relies on the GNU version. Please install it with `brew install grep`'
    missing_gnu_utils+=('grep')
  else
    missing_gnu_utils+=('grep')
  fi

  if [[ $(gnudate "--version") == *"GNU coreutils"* ]]; then
    gnu_utils+=('date')
  elif [[ $(man $(gnudate_string) | head -2 | grep BSD) == *"BSD General Commands Manual"* ]]; then
    debug 'You have the BSD version of `date` installed. This script relies on the GNU version. Please install it with `brew install coreutils`'
    missing_gnu_utils+=('date')
  else
    missing_gnu_utils+=('date')
  fi

  if [ "${gnu_utils[*]}" != "" ]; then
    debug "We've found GNU versions of the following utils: $( IFS=$', '; echo "${gnu_utils[*]}" )"
  fi

  if [ "${missing_gnu_utils[*]}" != "" ]; then
    echo -e "You are missing the GNU versions of the following utils: $( IFS=$', '; echo "${missing_gnu_utils[*]}" )\n$install_suggestion" 1>&2
    exit 255
  fi
}

function gnused_string() {
  printf '%s -E' "${SED_CMD}"
}

function gnused_cmdstring() {
  printf '%s' "${SED_CMD}"
}

function gnudate_string() {
  printf 'LC_ALL=en_GB %s' "${DATE_CMD}"
}

function gnugrep_string() {
  printf '%s -E' "${GREP_CMD}"
}

function gnugrep_cmdstring() {
  printf '%s' "${GREP_CMD}"
}

function gnufind_string() {
  printf '%s' "${FIND_CMD}"
}

function gnuawk_string() {
  printf '%s' "${AWK_CMD}"
}

function gnused() {
  "${SED_CMD}" -E "$@"
}

function gnugrep() {
  "${GREP_CMD}" "$@"
}

# Inspired by https://stackoverflow.com/a/3557165 by @drAlberT
function unique_append() {
  string="$1"
  filepath="$2"
  
  append=false
  if [ ! -f "$filepath" ];then
    append=true
  fi
  
  [ $append == false ] && grep -qxF -- "$string" "$filepath" || echo "$string" >> "$filepath"
}

function xattr_metadata_filepath() {
  #TODO: Add support for putting the metadata files in a separate directory instead
  local filepath="$1"
  if [ "$XATTR_METADATA_SUFFIX" == "" ]; then
    echo "xattr_metadata_filepath(): XATTR_METADATA_SUFFIX not set!" 1>&2
    return 255
  fi
  echo "${filepath}${XATTR_METADATA_SUFFIX}"
}

function xattr_metadata_list_keys() {
  local filepath="$1"
  if [ "$filepath" == "" ]; then
    echo "xattr_metadata_list_keys(): You need to specify a xattr metadata filepath as \$1" 1>&2
    return 255
  elif [ ! -f "$filepath" ]; then
    echo "xattr_metadata_list_keys(): File '$filepath' does not exist." 1>&2
    return 255
  fi

  gnuawk 'BEGIN { FS="\31"; RS="\0"; exit_code=1} $1 !~ "^###$" { print $1; exit_code=0 }; END { exit exit_code }' "$1"
}

function xattr_metadata_get_key() {
  local key="$1"
  if [ "$key" == "" ]; then
    echo "xattr_metadata_get_key(): You need to specify a xattr metadata key as \$1" 1>&2
    return 255
  elif [ "$key" == "###" ]; then
    echo "xattr_metadata_get_key(): The key '$key' is a restricted key meant as a header and cannot be retrieved" 1>&2
    return 255
  fi

  local filepath="$2"
  if [ "$filepath" == "" ]; then
    echo "xattr_metadata_get_key(): You need to specify a xattr metadata filepath as \$2" 1>&2
    return 255
  elif [ ! -f "$filepath" ]; then
    echo "xattr_metadata_get_key(): File '$filepath' does not exist." 1>&2
    return 255
  fi

  gnuawk -v key="^$1$" 'BEGIN { FS="\31"; RS="\0"; exit_code=1} $1 ~ key { print $2; exit_code=0 }; END { exit exit_code }' "$2"
}

function xattr_metadata_test_key() {
  local key="$1"
  if [ "$key" == "" ]; then
    echo "xattr_metadata_test_key(): You need to specify a xattr metadata key as \$1" 1>&2
    return 255
  fi

  local filepath="$2"
  if [ "$filepath" == "" ]; then
    echo "xattr_metadata_test_key(): You need to specify a xattr metadata filepath as \$2" 1>&2
    return 255
  elif [ ! -f "$filepath" ]; then
    echo "xattr_metadata_test_key(): File '$filepath' does not exist." 1>&2
    return 255
  fi

  gnuawk -v key="^$1$" 'BEGIN { FS="\31"; RS="\0"; exit_code=1} $1 ~ key { exit_code=0 }; END { exit exit_code }' "$2"
}

function xattr_metadata_unset_key() {
  local key="$1"
  if [ "$key" == "" ]; then
    echo "You need to specify a xattr metadata key as \$1" 1>&2
    return 255
  elif [ "$key" == "###" ]; then
    echo "xattr_metadata_unset_key(): The key '$key' is a restricted key meant as a header and cannot be unset" 1>&2
  fi

  local filepath="$2"
  if [ "$filepath" == "" ]; then
    echo "xattr_metadata_unset_key(): You need to specify a xattr metadata filepath as \$2" 1>&2
    return 255
  elif [ ! -f "$filepath" ]; then
    echo "xattr_metadata_unset_key(): File '$filepath' does not exist." 1>&2
    return 255
  fi

  if hash sponge 2>/dev/null; then
    gnuawk -v key="^$1$" 'BEGIN { OFS=FS="\31"; ORS=RS="\0"; exit_code=1} $1 !~ key { print $1,$2; exit_code=0 }; END { exit exit_code }' "$2" | sponge "$2"
  else
    echo 'xattr_metadata_unset_key() relies on `sponge`. Please install it from the `moreutils` package via your package manager (e.g. `brew install moreutils` or `sudo apt-get install moreutils`) or from https://joeyh.name/code/moreutils/' 1>&2
    return 255
  fi
}

function xattr_metadata_set_key() {
  local key="$1"
  if [ "$key" == "" ]; then
    echo "xattr_metadata_set_key(): You need to specify a xattr metadata key as \$1" 1>&2
    return 255
  elif [ "$key" == "###" ]; then
    echo "xattr_metadata_set_key(): The key '$key' is a restricted key meant as a header and cannot be set." 1>&2
  fi

  local value="$2"
  if [ "$value" == "" ]; then
    echo "xattr_metadata_set_key(): You need to specify a xattr metadata value as \$2" 1>&2
    return 255
  fi

  local filepath="$3"
  if [ "$filepath" == "" ]; then
    echo "xattr_metadata_set_key(): You need to specify a xattr metadata filepath as \$3" 1>&2
    return 255
  fi

  if [ ! -f "$filepath" ]; then
    printf '###\31%s\0' 'Simplified xattr alternative metadata file. Format: $key1\31$data1\0$key2\31$data2\0' >> "$filepath"
  else
    # TODO: Could more strictly test for header value too, but I think this will suffice.
    xattr_metadata_test_key '###' "$filepath" || (echo "xattr_metadata_set_key(): File '$filepath' exists and does not contain '###\31' header and thus is not recognised as xattr metadata file." 1>&2 && return 255)
  fi

  xattr_metadata_test_key "$key" "$filepath" && (xattr_metadata_unset_key "$key" "$filepath" || return 255)
  printf '%s\31%s\0' "$key" "$value" >> "$filepath"
}

function setxattr() {
  if [ "$XATTR_DISABLED" == true ]; then
    return
  fi
  
  if [ -f "$3" ]; then
    if [ "$XATTR_METADATA_SUFFIX" != "" ]; then
      xattr_metadata_set_key "$1" "$2" "$(xattr_metadata_filepath "$3")"
    elif hash xattr 2>/dev/null; then
      xattr -w "$1" "$2" "$3" 1>&2
    elif hash attr 2>/dev/null; then
      attr -s "$1" -V "$2" "$3" 1>&2
    fi
  else
    error "setxattr('$1' '$2' '$3') File '$3' does not exist."
  fi
}

function gnudate() { # Taken from https://stackoverflow.com/a/677212 by @lhunath and @Cory-Klein
  #FIXME: find out how I can prevent the loss of the quotes around the format in the debug output
  # debug "gnudate(): $(gnudate_string) $@"
  LC_ALL=en_GB "${DATE_CMD}" "$@"
}

function gnufind() {
  # debug "gnufind(): $(gnufind_string) $@"
  "${FIND_CMD}" "$@"
}

function gnuawk() {
  # debug "gnuawk(): $(gnuawk_string) $@"
  "${AWK_CMD}" "$@"
}

function unsorted_uniques() {
  "${AWK_CMD}" '!uniques[$0]++'
}

function sanitise_filename() {
  # debug "sanitising filename $@"
  additional_rules=$''
  if [ "$1" == '--underscore-whitespace' ]; then
    additional_rules+=$'s/\s{1,}/_/g;'
  fi
  gnused "$additional_rules"$'s/[^-a-zA-Z0-9_.]/-/g'
}

function lesser_sanitise_filename() {
  # debug "sanitising filename $@"
  rules=$''
  rules+=$'s/\+/ /g;'
  rules+=$'s/\s/_/g;'
  rules+=$'s/\\u00/%/g;'
  rules+=$'s/\$/%2A/g;'
  rules+=$'s/[*\\/:"><|]/-/g'
  gnused "$rules"
}

function add_file_extension() {
  # debug "adding file extension: $@"
  extension="$1"
  filepath=$(cat - )
  filepath+="$extension"
  pattern="$extension$extension"
  # Make sure the file didn't already have the same file extension.
  echo ${filepath/%$pattern/$extension}
}

function domain_from_url() {
  # debug "Retrieving domain from URL $1: echo \"$1\" | $(gnused_string) 's/https?:\/\/([^/]+)\/?.*/\1/g'"
  domain="$(echo "$1" | gnused 's/https?:\/\/([^/]+)\/?.*/\1/g')"
  # debug "Domain: $domain"
  echo "$domain"
}

function path_from_url() {
  # debug "Retrieving path from URL $1: echo \"$1\" | $(gnused_string) 's/https?:\/\/([^/]+)\/(.+)$/\2/g')"
  path="$(echo "$1" | gnused 's/https?:\/\/([^/]+)\/(.+)$/\2/g')"
  # debug "Path: $path"
  echo "$path"
}

function ensure_path() {
  # debug "ensure_path called with: $@ "
  if [ -z "$1" -o "$1" == "" ]; then
    echo "ensure_path called with an undefined path \$1" 1>&2
    exit 255
  elif [ -z "$2" -o "$2" == "" ]; then
    echo "ensure_path called with an undefined filename \$2" 1>&2
    exit 255
  else
    mkdir -p -- "$1"
    echo "$1/$2"
  fi
}

function ensure_jq() {
  if ! hash jq 2>/dev/null; then
    echo 'This command requires the `jq` commandline utility, but unfortunately we could not find it installed on your system. Please get it through your system package manager, or from https://github.com/stedolan/jq/' 1>&2 && return 255
  fi
}

function ensure_blogger_api() {
  if [ -z "$BLOGGER_APIKEY" -o "$BLOGGER_APIKEY" == "" ]; then
    echo "This command requires access to the Blogger API, but ENVironment variable BLOGGER_APIKEY is not set. Please set it to your Blogger API v3 API key." 1>&2
    exit 255
  fi
}

function ensure_gplus_api() {
  if [ "$GPLUS_APIKEY" == "" -a "$GOOGLE_OAUTH_ACCESS_TOKEN" == "" -a "$GOOGLE_OAUTH_ACCESS_TOKEN_FILE" == "" ]; then
    echo "This command requires access to the Google+ API via an API key, or OAuth2 token, but ENVironment variables GPLUS_APIKEY, GOOGLE_OAUTH_ACCESS_TOKEN, or GOOGLE_OAUTH_ACCESS_TOKEN_FILE are not set." 1>&2
    exit 255
  fi
}

function check_help() {
  if [ -n "$1" -a "$1" == "--help" ]; then
    if [ -z "$2" -o "$2" == "" ]; then
      echo -e "Usage: $(basename "$0")\nUsage definition undefined" 1>&2
      exit 255
    fi
    echo -e "$2"
    exit 0
  fi
  return 0
}

function timestamp() {
  function_usage=("Usage: timestamp(\"\$format\" \"\$additional_date_arguments\")")
  function_usage+=("Supports a number of format shorthands, as well as custom format.")
  function_usage+=("Examples:")
  function_usage+=("timestamp \"day\" # $(DEBUG=0 gnudate +"%Y-%m-%d")")
  function_usage+=("timestamp \"week\" # $(DEBUG=0 gnudate +"%Y-%W")")
  function_usage+=("timestamp \"month\" # $(DEBUG=0 gnudate +"%Y-%m")")
  function_usage+=("timestamp \"year\" # $(DEBUG=0 gnudate +"%Y")")
  function_usage+=("timestamp \"iso-8601\" # $(DEBUG=0 gnudate --iso-8601)")
  function_usage+=("timestamp \"iso-8601=seconds\" # $(DEBUG=0 gnudate --iso-8601=seconds)")
  function_usage+=("timestamp \"rfc-3339\" # $(DEBUG=0 gnudate --rfc-3339=seconds)")
  function_usage+=("timestamp \"rfc-email\" # or \"rfc-5322\" # $(DEBUG=0 gnudate +"%a, %d %b %Y %H:%M:%S %z")")
  function_usage+=("timestamp \"rss\" # $(DEBUG=0 gnudate "+\"%a, %d %b %Y %H:%M:%S %z\"")")
  function_usage+=("timestamp \"%H:%M:%S, %a %d-%m-%y\" -u -d '2019-02-03 18:23:01' # $(DEBUG=0 gnudate +"%H:%M:%S, %a %d-%m-%y" -u -d '2019-02-03 18:23:01')")
  function_usage=$( IFS=$'\n'; echo "${function_usage[*]}" )

  date_arguments=()
  if [ -z "$1" ]; then
    echo -e "timestamp() called without arguments.\n$function_usage" 1>&2 && return 255
  elif [ "$1" == "day" ]; then
    ts_format="%Y-%m-%d"
  elif [ "$1" == "week" ]; then
    ts_format="%Y-%W"
  elif [ "$1" == "month" ]; then
    ts_format="%Y-%m"
  elif [ "$1" == "year" ]; then
    ts_format="%Y"
  elif [ "$1" == "iso-8601" ]; then
    date_arguments+=("--$1")
    ts_format=""
  elif [ "$1" == "iso-8601-seconds" -o "$1" == "iso-8601=seconds" ]; then
    date_arguments=("--iso-8601=seconds")
    ts_format=""
  elif [ "$1" == "rfc-3339" ]; then
    date_arguments=("--$1=seconds")
    ts_format=""
  elif [ "$1" == "rfc-5322" -o "$1" == "rfc-email" -o "$1" == "--rfc-email" ]; then
    ts_format="%a, %d %b %Y %H:%M:%S %z"
  elif [ "$1" == "rss" -o "$1" == "rfc-822" ]; then # per https://groups.yahoo.com/neo/groups/rss-public/conversations/topics/536
    ts_format="%a, %d %b %Y %H:%M:%S %z"
  else
    ts_format="$1"
  fi

  shift 1
  # echo "ts_format: '$ts_format'"
  # echo "date_arguments: '$date_arguments'"
  if [ "$ts_format" == "" ]; then
    gnudate "$date_arguments$@"
  else
    # debug "gnudate(): $(gnudate_string) $date_arguments$@" +"\"$ts_format\""
    DEBUG=0 gnudate "$date_arguments$@" +"$ts_format"
  fi
}

# FIXME: replace calls to this with the more generic version
function timestamp_date() { 
  if [ -z "$CACHE_TIMESTAMP" -o "$CACHE_TIMESTAMP" == "" ]; then
    timestamp "day"
  else
    timestamp "day" --date="$CACHE_TIMESTAMP"
  fi
}

function activity_file() {
  activity_id="$1"
  if [ "$activity_id" == "" ]; then
    echo "activity_file() called with an undefined activity_id \$1" 1>&2
    exit 255
  else
    # FIXME: also allow for date-based caching of this?
    activity_filepath="$(ensure_path "./data/gplus/activities" "$activity_id.json")"
    debug "Filepath for Activity Resource $activity_id: $activity_filepath"
    echo "$activity_filepath"
  fi
}

function get_user_id() {
  uid_regex="^([0-9]+|\+[^/]+)$"
  user_id="$1"
  if [[ "$user_id" =~ $uid_regex ]]; then
    echo "$user_id"
    return
  fi
  user_id="${user_id/#https:\/\/plus.google.com\/u\/?\//}"
  user_id="${user_id/#https:\/\/plus.google.com\//}"
  user_id="${user_id/%\/*/}"
  if [[ "$user_id" =~ $uid_regex ]]; then
    echo "$user_id"
    return
  else
    echo "Unrecognised user id $user_id ($1)" 1>&2
    return 255
  fi
}

function user_profile_file() {
  debug "user_profile_file() called with: '$1' '$2' '$3' "

  user_id="$1"
  timestamp_format="$2"
  shift 2
  timestamp_args=("$@")

  if [ -z "$timestamp_format" -o "$timestamp_format" == "" ]; then
    suffix=""
  else
    if [ -n "$timestamp_args" ]; then
      debug "timestamp_args: ${timestamp_args[@]}"
    else
      timestamp_args=('-u')
    fi
    # debug "timestamp_args: ${timestamp_args[@]}"
    suffix=".$(timestamp "$timestamp_format" ${timestamp_args[@]})"
  fi

  if [ "$user_id" == "" ]; then
    echo "user_profile_filepath() called with an undefined user_id \$1" 1>&2
    return 255
  elif [[ "$user_id" == '*' || "$user_id" == 'all_users' ]]; then
    echo "$(ensure_path "./data/gplus/users" "${user_id}${suffix}.json")"
    return
  fi

  user_id="$(get_user_id "$user_id")"
  return_code=$?
  if (( $return_code >= 1 )); then
    echo "Please supply the user id (\$1) in their numeric, +PrefixedCustomURLName form, or profile URL form." 1>&2 && exit 255
  fi

  if [ -n "$user_id" ]; then
    user_profile_filepath="$(ensure_path "./data/gplus/users" "${user_id}${suffix}.json")"
    debug "Filepath for GPlus People resource with ID $user_id: $user_profile_filepath"
    echo "$user_profile_filepath"
  else
    echo "user_profile_filepath(): Please supply the user id (\$1) in their numeric form, or the +PrefixedCustomURLName form." 1>&2
    exit 255
  fi
}

function wbm_archive_filepath() {
  url="$1"
  if [ "$url" == "" ]; then
    echo "wbm_archive_filepath() called with an undefined url \$1" 1>&2
    exit 255
  else
    #FIXME: also allow for date-based caching of this?
    sanitised_domain="$(domain_from_url "$url" | sanitise_filename )"
    sanitised_filename="$(path_from_url "$url" | add_file_extension ".html" | sanitise_filename )"
    local filepath="$(ensure_path "./data/wbm/$sanitised_domain" "$sanitised_filename")"
    # debug "wbm_archive_filepath('$url') #=> '$filepath'"
    echo "$filepath"
  fi
}

function comments_file() {
  activity_id="$1"
  if [ "$activity_id" == "" ]; then
    echo "comments_file() called with an undefined activity_id \$1" 1>&2
    exit 255
  else
    #FIXME: also allow for date-based caching of this?
    comments_filepath="$(ensure_path "./data/gplus/activities/$activity_id" "comments_for_$activity_id.json")"
    debug "Filepath for Comments Resource List for Activity with id $activity_id: $comments_filepath"
    echo "$comments_filepath"
  fi
}

# # Source: https://www.rosettacode.org/wiki/Find_common_directory_path#UNIX_Shell
# function longest_common_directory() {
#   i=2
#   while [ $i -lt 100 ]
#   do
#     path=`echo -e "$1" | cut -f1-$i -d/ | uniq -d`
#     if [ -z "$path" ]
#     then
#        echo $prev_path
#        break
#     else
#        prev_path=$path
#     fi
#     i=`expr $i + 1`
#   done
# }

function filename_for_output_html_for_activity() {
  fn_name="filename_for_output_html_for_activity"
  activity_id="$(echo "$1" | sanitise_filename)"
  activity_published_date="$(echo "$2" | sanitise_filename)"
  title_summary="$(echo "$3" | sanitise_filename | gnused 's/-{2,}/-/g')"
  
  if [ "$activity_id" == "" ]; then
    echo "$fn_name() called without an activity ID \$1" 1>&2 && return 255
  elif [ "$activity_published_date" == "" ]; then
    echo "$fn_name() called without an activity published date \$2" 1>&2 && return 255
  elif [ "$title_summary" == "" ]; then
    title_summary="UNTITLED"
    echo "$fn_name() called without an activity user ID \$4 - defaulting to $title_summary" 1>&2
  fi
  echo "${activity_published_date}-${activity_id}-${title_summary}" | add_file_extension ".html"
}

function directory_for_output_html_for_activity() {
  fn_name="directory_for_output_html_for_activity"
  activity_user_id="$1"
  activity_post_acl="$2"
  activity_post_acl_privacy="$3"
  activity_post_acl_name="$4"
  activity_post_acl_audience="$5"
  declare -a directories=()
  
  if [ "$activity_user_id" == "" ]; then
    echo "$fn_name() called without an activity user ID \$1" 1>&2 && return 255
  elif [ "$activity_post_acl" == "" ]; then
    echo "$fn_name() called without an activity post Access Control List \$2" 1>&2 && return 255
  elif [ "$activity_post_acl_privacy" == "" ]; then
    echo "$fn_name() called without an activity post Access Control List privacy level \$3" 1>&2 && return 255
  elif [ "$activity_post_acl_name" == "" ]; then
    echo "$fn_name() called without an activity type name (i.e., the name of the Community or Collection) \$4" 1>&2 && return 255
  fi
  
  activity_user_id="$(echo "$activity_user_id" | sanitise_filename)"
  activity_post_acl="$(echo "$activity_post_acl" | sanitise_filename)"
  
  if [ "$activity_post_acl_privacy" == 'public' -o "$activity_post_acl_privacy" == 'limited' ]; then
    directories+=("$activity_post_acl_privacy")
  else
    echo "$fn_name() called with an unsupported activity post Access Control List privacy level \$3: '$activity_post_acl_privacy'" 1>&2 && return 255
  fi
  
  if [ "$activity_post_acl" == "communityAcl" ]; then
    directories+=("communities" "${activity_post_acl_name}" "${activity_user_id}")
  elif [ "$activity_post_acl" == "collectionAcl" ]; then
    directories+=("posts" "${activity_user_id}" "collections" "$activity_post_acl_name")
  elif [ "$activity_post_acl" == "eventAcl" ]; then
    directories+=("events" "${activity_post_acl_name}" "${activity_user_id}")
  elif [ "$activity_post_acl" == "visibleToStandardAcl" ]; then
    if [ "$activity_post_acl_name" == "CIRCLE_TYPE_PUBLIC" ]; then
      activity_post_acl_name="public"
    elif [ "$activity_post_acl_name" == "CIRCLE_TYPE_EXTENDED_CIRCLES" ]; then
      activity_post_acl_name="extended-circles"
    elif [ "$activity_post_acl_name" == "CIRCLE_TYPE_YOUR_CIRCLES" ]; then
      activity_post_acl_name="followers"
    elif [ "$activity_post_acl_name" == "CIRCLE_TYPE_USER_CIRCLE" ]; then
      activity_post_acl_name="circles"
    elif [ "$activity_post_acl_name" == "private" ]; then
      activity_post_acl_name="users"
    elif [ "$activity_post_acl_name" == "circle_and_userless" ]; then
      activity_post_acl_name="$activity_post_acl_name"
    else
      debug "Unknown acl: $activity_post_acl_name"
    fi
  
    directories+=("posts" "${activity_user_id}" "${activity_post_acl_name}")
    if [ "$activity_post_acl_audience" != "" ]; then
      directories+=("${activity_post_acl_audience}")
    fi
  else
    echo "$fn_name() Unknown Activity Type '$activity_post_acl' ('$2')" 1>&2 && return 255
  fi
  directories=("data" "output" "html" "exported_activities" "${directories[@]}")
  # Array#Map the directories through filename sanitisation
  for i in "${!directories[@]}"; do
    directories[$i]=$(echo "${directories[$i]}" | sanitise_filename)
  done
  join_by "/" "${directories[@]}"
}

function api_url() {
  api_url_usage="Usage: api_url(\"\$api_name\" \"\$api_endpoint\" \"\$api_endpoint_action\" \$api_arguments)\nExamples:\n"
  api_url_usage="${api_url_usage}api_url(\"gplus\" \"people\" \"get\" \$user_id)\n"
  if [ -z "$1" ]; then
    echo -e "api_url() called without arguments.\n$api_url_usage" 1>&2 && return 255
  elif [ "$1" == "gplus" ]; then #https://developers.google.com/+/web/api/rest/index
    gplus_api_url="https://www.googleapis.com/plus/v1"

    if [ -z "$2" ]; then
      echo -e "api_url(\"$1\") needs more arguments.\n$api_url_usage" 1>&2 && return 255
    elif [ "$2" == "people" ]; then #https://developers.google.com/+/web/api/rest/latest/people
      gplus_api_url="https://people.googleapis.com/v1/people"
      if [ -z "$3" ]; then
        echo -e "api_url(\"$1\" \"$3\") needs more arguments.\n$api_url_usage" 1>&2 && return 255
      elif [ "$3" == "get" ]; then #https://developers.google.com/+/web/api/rest/latest/people/get
        if [ -z "$4" ]; then
          echo -e "api_url(\"$1\" \"$3\" \"\$user_id\") is missing its \$user_id.\n$api_url_usage" 1>&2 && return 255
        elif [[ "$4" =~ ^([0-9]+$|^\+[a-zA-Z0-9_-]+)$ ]]; then
          echo "$gplus_api_url/$4?personFields=addresses%2CageRanges%2Cbiographies%2Cbirthdays%2CbraggingRights%2CcoverPhotos%2CemailAddresses%2Cevents%2Cgenders%2CimClients%2Cinterests%2Clocales%2Cmemberships%2Cmetadata%2Cnames%2Cnicknames%2Coccupations%2Corganizations%2CphoneNumbers%2Cphotos%2Crelations%2CrelationshipInterests%2CrelationshipStatuses%2Cresidences%2CsipAddresses%2Cskills%2Ctaglines%2Curls%2CuserDefined&key=$GPLUS_APIKEY"
        else
          echo -e "api_url(\"$1\" \"$3\" \"\$user_id\") \$user_id needs to be a numeric id, or the +PrefixedCustomURLName; '$4' was given.\n$api_url_usage" 1>&2 && return 255
        fi
      else
        echo -e "api_url(\"$1\" \"$2\" \"$api_endpoint_action\") called with an unknown API endpoint action '$3'. $api_url_usage" 1>&2 && return 255
      fi
    else
      echo -e "api_url(\"$1\" \"$api_endpoint\") called with an unknown API endpoint '$2'. $api_url_usage" 1>&2 && return 255
    fi
  else
    echo -e "api_url(\"\$api_name\") called with an unknown API name '$1'. $api_url_usage" 1>&2 && return 255
  fi
}

function append_log_msg() {
  local msg="$1"
  local log_file="$2"
  if [ "$log_file" != "" ]; then
    echo -e "[$(timestamp "%H:%M:%S")] $msg" >> "$log_file"
  fi
}

function append_log_message() {
  append_log_msg "$1" "$2"
}

function append_log_file() {
  append_log_msg "$1" "$2"
}

function cache_remote_document_to_file() { # $1=url, $2=local_file, $3=curl_args $4=log_file
  function_usage="Usage: cache_remote_document_to_file(\"\$url\" \"\$local_filepath\" [\"\$curl_args\" [\"\$log_file\"]])\n"
  debug "cache_remote_document_to_file(): \"$1\" \"$2\" \"$3\" \"$4\""

  
  document_url="$1"
  target_file_path="$2"
  curl_args=""
  if [ "$3" != "" ]; then
    curl_args="$3 "
  fi
  curl_headers=("Accept-Charset: utf-8, iso-8859-1;q=0.5, *;q=0.1")
  curl_headers+=("Accept-Language: en-GB;q=0.9, en;q=0.8, en-US;q=0.7, *;q=0.5")
  log_file="$4"

  if [ "$document_url" == "" ]; then
    echo -e "=!!!= cache_external_document_to_file() needs a target URL at \$1.\n$api_url_usage" 1>&2 && return 255
  elif [[ "$document_url" =~ (^https?|ftps?):// ]]; then # Supported protocols
    if [ "$target_file_path" == "" ]; then
      echo -e "=!!!= cache_external_document_to_file() needs a target file path.\n$function_usage" 1>&2 && return 255
    elif [ ! -f "$target_file_path" -o "$IGNORE_CACHE" == 'true' ]; then
      local retries=$MAX_RETRIEVAL_RETRIES
      local count=0
      while [ $count -lt $retries ]; do
        if (( $count > 0 )); then  # Don't sleep on the first try
          sleep $count
        fi
        count=$[$count+1]

        debug "  =!= [Try #$count/$retries]: ⬇️  Storing ${TP_UON}'$document_url'${TP_UOFF} to ${TP_UON}'$target_file_path'${TP_UOFF}"
        # TODO: add support for extracting more metadata such as returned charset and content-type, and storing it via setxattr
        if [[ $document_url == https://*.googleapis.com/* || $document_url == https://googleapis.com/* ]]; then
          if [ "$GOOGLE_OAUTH_ACCESS_TOKEN_FILE" != "" ]; then
            export GOOGLE_OAUTH_ACCESS_TOKEN="$(cat "$GOOGLE_OAUTH_ACCESS_TOKEN_FILE")"
          fi
          if [ "$GOOGLE_OAUTH_ACCESS_TOKEN" != "" ]; then
            if hash oauth2l 2>/dev/null; then
              #debug "${FG_MAGENTA}Testing ACCESS Token${FG_YELLOW}"
              oauth2l_response="$(oauth2l test "$GOOGLE_OAUTH_ACCESS_TOKEN")"
              if (( $? > 0 || "$oauth2l_response" > 0 )); then
                read -p "oauth2l test says Google Oauth2 token is invalid. Please enter new token:" new_token < /dev/tty
                export GOOGLE_OAUTH_ACCESS_TOKEN="$new_token"
              fi
            fi
            document_url="$(printf '%s' "$document_url" | gnused 's/\?key=[^=&?]+&/?/;s/\?key=[^=&?]+//;s/&key=[^=&?]+//')"
            #debug "Google OAuth2 Access Token set, so removed key parameter from document_url: '${document_url}'"
            curl_headers+=("Authorization: Bearer $GOOGLE_OAUTH_ACCESS_TOKEN")
          fi
        fi
        debug "    curl Headers: '${curl_headers[@]/##/-H }'"
        debug "curl -A "$USER_AGENT" "${curl_headers[@]/#/-H}" --write-out %{http_code} --silent ${curl_args}--output "$target_file_path" "$document_url""
        status_code="$(curl -A "$USER_AGENT" "${curl_headers[@]/#/-H}" --write-out %{http_code} --silent ${curl_args}--output "$target_file_path" "$document_url")"; exit_code="$?"
        setxattr "status_code" "$status_code" "$target_file_path" 1>&2
        setxattr "tries" "$count/$retries" "$target_file_path" 1>&2

        if (( $exit_code >= 1 )); then

          errormsg="[\$?=$exit_code]'$document_url' -> '$target_file_path' # curl exited with code $exit_code"
          debug "    =!= $errormsg"

          if (( $exit_code == 23 )); then #CURL_WRITE_ERROR
            printf "%s\n" "${TP_BOLD}${FG_RED}It looks like cURL could not write to the file. Are you perhaps running out of disk space / inodes?${TP_RESET}" 1>&2
            df -h 1>&2
            read -p $'# Please check the cause of the error and press enter to continue, or ctrl-c to abort' input < /dev/tty
          fi

          append_log_msg "$errormsg" "$log_file"

          # FIXME: abstract this hardcoded log path:
          status_log_path="$(ensure_path "logs/cache/$(timestamp_date)" "exit_code.${exit_code}.error${status_code}.log")"
          append_log_msg "'$document_url' -> '$target_file_path'" "$status_log_path"

          setxattr "exit_code" "$exit_code" "$target_file_path" 1>&2
          continue
        fi

        if [ "$status_code" -eq 200 ]; then
          debug "    ${FG_GREEN}${TP_BOLD}✅  [${status_code}] Success ${TP_RESET}"
          echo "$target_file_path"
          # TODO: check for empty "items": or "error":
          return 0
        else
          # FIXME: abstract this hardcoded log path:
          status_log_path="$(ensure_path "logs/cache/$(timestamp_date)" "error.${status_code}.log")"
          append_log_msg "$document_url" "$status_log_path"
          
          error "    crdf(): =!!= [$status_code] Error while retrieving remote document."

          if [ "$status_code" -eq 403 ]; then # Forbidden. Possibly the result of Exceeded Quota Usage. Preferably don't retry immediately
            error "    ${FG_RED}${TP_BOLD}❌ [${status_code}] FORBIDDEN${TP_RESET} Error while retrieving '$document_url' -> '$target_file_path'.\nRequest returned:\n\n---\n$(cat "$target_file_path")\n---\n"
            input=""
            if [ "$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION" == "" ];then
              read -p $'=!!!= (a)bort, (r)etry or (c)ontinue with next item? [a/r/C]\n' input < /dev/tty
            fi

            if [ "$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION" == "retry" -o "$(echo "$input" | tr '[:upper:]' '[:lower:]')" == "r" ]; then
              retrymsg="'$document_url' -> '$target_file_path' # User requested retry (input: '$input'; MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION=$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION)"
              debug "  =!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              continue
            elif [ "$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION" == "abort" -o "$(echo "$input" | tr '[:upper:]' '[:lower:]')" == "a" ]; then
              retrymsg="'$document_url' -> '$target_file_path' # User requested ABORT (input: '$input'; MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION=$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION)"
              debug "  =!!!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              exit 255
            elif [ "$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION" == "continue" -o "$(echo "$input" | tr '[:upper:]' '[:lower:]')" == "c" ]; then
              retrymsg="'$document_url' -> '$target_file_path' # User requested to continue with next item (input: '$input'; MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION=$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION)"
              debug "  =!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              break
            else
              retrymsg="'$document_url' -> '$target_file_path' # Unrecognised user input; continuing with next item (input: '$input'; MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION=$MAX_RETRIEVAL_RETRIES_EXCEEDED_ACTION)"
              debug "  =!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              break
            fi
          elif [ "$status_code" -eq 204 -o "$status_code" -eq 404 ]; then # Known problematic HTTP Status codes that should be okay to retry automatically
            retrymsg="[$status_code]'$document_url' -> '$target_file_path' # FAIL with 'safe' HTTP Status Code [$count/$retries]"
            debug "    ${FG_RED}${TP_BOLD}❌ [${status_code}] ${TP_RESET}    crdf(): =!= $retrymsg"
            append_log_msg "$retrymsg"
            continue
          else # The rest is probably also okay
            retrymsg="[$status_code]'$document_url' -> '$target_file_path' # FAIL with potentially 'non-safe' HTTP Status Code; retrying regardless [$count/$retries]"
            debug "    ${FG_RED}${TP_BOLD}❌ [${status_code}] ${TP_RESET}    crdf(): =!= $retrymsg"
            append_log_msg "$retrymsg"
            continue
          fi
        fi
      done
      return 255
    else
      debug "Cache hit for ${1}: $target_file_path"
      echo "$target_file_path"
    fi
  else
    error "cache_external_document_to_file(): unsupported protocol for \$document_url ('$document_url'); only http(s) and ftp(s) are currently supported.\n$function_usage" && return 255
  fi
}

function crdf() {
  cache_remote_document_to_file "$1" "$2" "$3" "$4"
}

function merge_json_files() {
  debug "merge_json_files(): Looking in '$1' for files matching case-insensitive filemask '$2'"
  gnufind "$1" -iname "$2" -exec cat {} + | jq -s '.' > "$3"
}


function buildResponseFilename {
  blog_id="$1"
  pathSuffix="$2"
  timestamp="$3"
  extension="$4"
  echo "${blog_id}${pathSuffix}-${timestamp}.${extension}"
}

function abort_if() {
  confirmation_input="$1"
  prompt="$2"
  read -p "$prompt" input < /dev/tty
  echo "$input"
  if [ "$(echo "$input" | tr '[:upper:]' '[:lower:]')" == "$confirmation_input" ]; then
    debug "=!= Aborting by user request!"
    exit 0
  else
    exit 255
  fi
}

function strip_html() {
  gnused 's/<[^>]{1,}>//g'
}

function shorten() {
  local input="$(cat -)"
  local cut_indicator=${1:-$'\U2026'} #Horizontal Ellipsis
  local max_length=${2:-100}
  if ((${#input} > $max_length)); then
    echo "$(echo "$input" | first_x_characters $max_length)$cut_indicator"
  else
    echo "$input"
  fi
}

function first_x_characters() {
  cut -c-${1:-100}
}

function title_from_html() {
  # First look for *header* / _header_ / *_header_* / _*header*_ or similar
  # Only include contents: '((?<=<b><i>).*(?=</i></b>)|(?<=<i><b>).*(?=</b></i>)|(?<=<b>).*(?=</b>)|(?<=<i>).*(?=</i>))'
  input=$(cat -)
  first_line="$(echo "$input" | head -1)"
  title="$( echo "$first_line" | gnugrep -oP '^(<i><b>|<b><i>|<b>|<i>).*(</b></i>|</i></b>|</b>)')"
  exit_code="$?"
  
  # If there was no match
  if (( $exit_code > 0 )); then
    title="$(echo "$first_line" | strip_html )"
  fi
  if (( $2 > -1 )); then
    echo "$title" | shorten $1 $2
  else
    echo "$title"
  fi
}

function exclude_empty_lines() {
  grep -v "^$"
}

ohash_name() {
  printf "%s" "ohash_${1}"
}

ohash_order_name() {
  printf "%s" "order_ohash_${1}"
}

printf_ohash() {
  declare -n ohash="$(ohash_name "$1")"
  declare -n ohash_order="$(ohash_order_name "$1")"
  local format="${2:-'%s\n'}"

  for key in "${ohash_order[@]}"
  do
    printf "$format" "$key" "${ohash["$key"]}"
  done
}

printf_ohash_keys() {
  declare -n ohash_order="$(ohash_order_name "$1")"
  local format="${2:-"%s, "}"

  for key in "${ohash_order[@]}"
  do
    printf "$format" "$key"
  done
}

ohash_clear() {
  local hash_name="$(ohash_name "$1")"
  local hash_name_order="$(ohash_order_name "$1")"
  declare -A new_hash
  declare -a new_array
  declare -gA "${hash_name}"
  declare -ga "${hash_name_order}"
  declare -n ohash="${hash_name}"
  declare -n ohash_order="${hash_name_order}"
  ohash_order=()
  ohash="${new_hash[@]}"
}
ohash_add() {
  local hash_name="$(ohash_name "$1")"
  local hash_name_order="$(ohash_order_name "$1")"
  declare -n ohash="${hash_name}"
  declare -n ohash_order="${hash_name_order}"
  
  ohash_order+=("$2")
  ohash["$2"]="$3"
}



default_takeout_archives_dir_mask() {
  if [ -f "$PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH" ]; then
    dirmask_from_list_file "$PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH" || dirmask_from_array_reference "PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES"
  else
    dirmask_from_array_reference "PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES"
  fi
}

dirmask_from_array_reference() {
  declare -n __dirs="${1}"
  printf "{%s}" "$(join_by ',' "${__dirs[@]}")"
}

initialise_default_takeout_archives_list_file() {
  touch "$PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH"
  for dir in "${PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES[@]}"
  do
    add_directory_to_default_takeout_archives_list_file "$dir" "$PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH" || continue
  done
}

add_directory_to_default_takeout_archives_list_file() {
  local dir
  if [ ! -f "$PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH" ];then
    initialise_default_takeout_archives_list_file
  fi

  find "$1/" -maxdepth 0 > /dev/null 2>&1
  if (( $? > 0 )); then
    error "Directory '$1' does not seem accessible."
    return 255
  else
    unique_append "$1" "$PLEXODUS_DEFAULT_TAKEOUT_ARCHIVES_SEARCH_DIRECTORIES_LIST_FILEPATH"
  fi
  return 0
}

dirmask_from_list_file() {
  local line
  if [ "$1" == "" ]; then
    error "You need to specify a file to read the list of directories from."
    return 255
  elif [ ! -f "$1" ]; then
    error "The specified list to read the list of directories from, does not exist."
    return 255
  fi

  declare -a directories
  while IFS= read -r line || [ -n "$line" ]; do
    find "$line/" -maxdepth 0 > /dev/null 2>&1
    if (( $? > 0 )); then
      error "Directory '$line' does not seem accessible; ignoring it"
    else
      directories+=("$line")
    fi
  done < "$1"

  dirmask_from_array_reference directories
  return 0
}

extract_data_from_takeout_archives() {
  local directory_mask="${1:-}"
  local filemask=${2:-'takeout-*.zip'}
  gnufind "$directory_mask" -maxdepth 1 -iname "$filemask" -exec 7z x "{}" '*.json' '*.html' '*.csv' '*.vcf' '*.ics' -r -o${PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH}/ \; 2>/dev/null
}

dir_exists_or_is_created() {
  local response
  if ! dir_exists "$1"; then
    echo "${FG_RED}'$1' is not an accessible directory." 1>&2
    read -p "Want to create it? [y/n]" response
    if [ "$response" == 'y' -o "$response" == "Y" -o "$response" == "yes" ]; then
      mkdir -p "$1"
    else
      return 255
    fi
  fi
}

strip_last_by_delimiter() {
  printf '%s' "${1%${2}*}"
}
strip_last_extension() {
  strip_last_by_delimiter "$1" '.'
}

strip_all_by_delimiter() {
  printf '%s' "${1%%${2}*}"
}
strip_all_extensions() {
  strip_all_by_delimiter "$1" '.'
}

all_after_first_delimiter() {
  [[ $1 == *${2}* ]] && printf '%s' "${1#*${2}}" || printf ''
}
all_extensions() {
  all_after_first_delimiter "$1" '.'
}

last_after_delimiter() {
  [[ $1 == *${2}* ]] && printf '%s' "${1##*${2}}" || printf ''
}
last_extension() {
  last_after_delimiter "$1" '.'
}

split(){
  local input="$1"
  declare -n _items="$2"
  local delimiter="${3:-,}"
  local first_input="$(all_after_first_delimiter "$input" "$delimiter")"
  local first=$(strip_all_by_delimiter "$input" "$delimiter")
  _items+=("$first")
  while [ "$first" != "$input" ]; do
    input="$(all_after_first_delimiter "$input" "$delimiter")"
    first=$(strip_all_by_delimiter "$input" "$delimiter")
    _items+=("$first")
  done
  return 0
}


#FIXME: this function should perhaps limit to bytes, rather than characters
limit_filename_length() {
  MAX_FILELENGTH="${MAX_FILELENGTH:-200}"
  MAX_EXTENSIONSLENGTH="${MAX_EXTENSIONSLENGTH:-50}"
  filename="$1"
  [ "$filename" == "" ] && echo "You need to specify a filename as \$1" && return 255

  if (( "${#filename}" <= $MAX_FILELENGTH )); then
    printf '%s' "$filename"
    return 0
  fi

  debug "${FG_MAGENTA}Filename is too long. ${#filename} > ${MAX_FILELENGTH}: ${filename}${TP_RESET}"

  extensions=".$(all_extensions "$filename")"
  [ "$extensions" == '.' ] && extensions=""
  if (( "${#extensions}" > $MAX_EXTENSIONSLENGTH )); then
    debug "${FG_MAGENTA}File extension is too long. ${#filename} > ${MAX_EXTENSIONSLENGTH}: ${extensions}${TP_RESET}"
    #FIXME: Actually handle this exception
  fi

  filename_without_extension="$(strip_all_extensions "$filename")"

  target_filename_length=$(($MAX_FILELENGTH - ${#extensions}))
  printf '%s%s' "${filename_without_extension:0:$target_filename_length}" "$extensions"
}


non_existing_filename() {
  local directory_path="$1"
  local source_filename="$2"
  local filename="$(limit_filename_length "$source_filename")" || return $?
  local max_tries="${3:-3}"
  local count=0
  debug "non_existing_filename() '${directory_path}/${source_filename}'"

  if ! dir_exists "$directory_path"; then
    local exit_code="$?"
    error "non_existing_filename(): directory '$directory_path' does not exist"
    return $exit_code
  fi

  while [ -f "${directory_path}/${filename}" ]; do
    count=$[$count+1]
    if [ $count -gt $max_tries ]; then
      error "non_existing_filename(): exceeded maximum number of attempts ($count) to find a unique, non-existing filename."
      return $count
    fi
    local filename="$(limit_filename_length "$source_filename").${count}"
    debug "count: $count/$max_tries; filename: $filename"
  done
  printf '%s' "$filename"
  return 0
}

unique_characters_in_document() {
  $(hash god 2>/dev/null && printf '%s' "god" || printf '%s' "od" ) -cvAnone -w1 | sort -bu
}


on_same_device() {
  man ${STAT_CMD} | grep -- '--format'
  if (($? > 0)); then
    file_a_device="$(${STAT_CMD} --format="%d" "$1")"
    file_b_device="$(${STAT_CMD} --format="%d" "$2")"
  else
    file_a_device="$(${STAT_CMD} -f "%Sdr" "$1")"
    file_b_device="$(${STAT_CMD} -f "%Sdr" "$2")"
  fi
  [ "$file_a_device" == "$file_b_device" ] # && return 0 || return 1
}

hash_to_json() {
  local _h
  declare -n _h="$1"
  [ "${#_h[@]}" == "0" ] && echo '{}' && return 0

  local _output=""
  #FIXME: handle escaping in keys and values
  for key in "${!_h[@]}"; do
    _output+="\"$key\": \"${_h["$key"]}\","
  done
  echo "{${_output::-1}}"
  return 0
}

array_to_json() {
  local _a
  declare -n _a="$1"

  [ "${#_a[@]}" == "0" ] && echo '[]' && return 0

  local _output=""
  #FIXME: handle escaping in values
  for value in "${_a[@]}"; do
    _output+="\"${value}\", "
  done
  echo "[${_output::-2}]"
  return 0
}

download_to_local_filepath() {
  remote_url="$1"
  local_filepath="$2"
  json_source_fp="$3"
  downloaded_fps="$("$PT_PATH/bin/retrieve_googleusercontent_url.sh" "$remote_url")"
  exit_code="$?"
  if (( $exit_code == 0 )); then
    if [ "$downloaded_fps" == "" -o "${downloaded_fps//*$'\n'}" == "" ]; then
      error "[\$?=$exit_code] Error while retrieving $remote_url"
      echo "$remote_url"
      return 255
    fi

    downloaded_fp="$(realpath "${downloaded_fps//*$'\n'}")"
    [ -f "$downloaded_fp" ] && setxattr "json_source" "$json_source_fp" "$downloaded_fp" 1>&2 && setxattr "remote_url" "$remote_url" "$downloaded_fp" 1>&2

    if [ "$local_filepath" == "" ]; then
      echo "$downloaded_fp"
      return 0
    fi

    if [ -f "$local_filepath" ]; then
      debug "file '$local_filepath' already exists"
      echo "$local_filepath"
      return 0
    fi

    link_file "$downloaded_fp" "$local_filepath"
    exit_code="$?"
    if (( $exit_code == 0 ));then
      debug "linking succeeded: $downloaded_fp -> $local_filepath"
      realpath --no-symlinks "$local_filepath" || printf '%s\n' "$downloaded_fp"
    else
      error "linking exited with $exit_code"
      echo "$downloaded_fp"
    fi
    return 0
  else
    error "[\$?=$exit_code] Error while retrieving $remote_url"
    echo "$remote_url"
    return $exit_code
  fi
}