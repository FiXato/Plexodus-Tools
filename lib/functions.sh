#!/usr/bin/env bash
# encoding: utf-8

#FIXME: move this to an variables.env file
REQUEST_THROTTLE="${REQUEST_THROTTLE:-0}"
USER_AGENT="${USER_AGENT:-PlexodusToolsBot/0.9.0}"
#Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3724.8 Safari/537.36

#TODO: Implement LOG_LEVEL
function debug() {
  if [ "$DEBUG" == "1" -o "$DEBUG" == "true" -o "$DEBUG" == "TRUE" ]; then
    echo -e "[$(basename "$0")] $@" 1>&2
  fi
}

function printarr() {
  declare -n __p="$1"
  for k in "${!__p[@]}"
    do printf "%s=%s\n" "$k" "${__p[$k]}"
  done
}

function curl_urlencode() {
  curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | cut -c 3- | sed 's/%00$//g'
}

function urlsafe_plus_profile_url() {
  clean_source_url="$1"
  plus_url_custom_handle_base="https://plus.google.com/+"
  escaped_plus_url_custom_handle_base="^$(printf "$plus_url_custom_handle_base" | sed 's/\./\\./g;s/\+/\\+/g')"
  if [[ "$source_url" == $plus_url_custom_handle_base* ]]; then
    urlencoded_username="$(echo "$clean_source_url" | gnugrep -zoP "$escaped_plus_url_custom_handle_base"'\K([^/]+)' | curl_urlencode)"
    url_path_suffix="$(echo "$clean_source_url" | gnugrep -oP "$escaped_plus_url_custom_handle_base"'[^/]+\K(/.+)')"
    clean_source_url="${plus_url_custom_handle_base}${urlencoded_username}${url_path_suffix}"
  fi
  echo "$clean_source_url"
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
    install_suggestion="$(machine_type)"' comes with the BSD versions of many of the CLI utilities this script uses. Unfortunately these are often limited in their usage options. I would suggest installing the GNU versions through Homebrew (https://brew.sh), which the script should automatically detect as Homebrew prefixes them with "g". E.g.: `brew install gawk findutils gnu-sed grep coreutils`'
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
  if hash gsed 2>/dev/null; then
    echo 'gsed -E'
  else
    echo 'sed -E'
  fi
}

function gnudate_string() {
  if hash gdate 2>/dev/null; then
    echo 'LC_ALL=en_GB gdate'
  else
    echo 'LC_ALL=en_GB date'
  fi
}

function gnugrep_string() {
  if hash ggrep 2>/dev/null; then
    echo 'ggrep -E'
  else
    echo 'grep -E'
  fi
}

function gnufind_string() {
  if hash gfind 2>/dev/null; then
    echo 'gfind'
  else
    echo 'find'
  fi
}

function gnuawk_string() {
  if hash gawk 2>/dev/null; then
    echo 'gawk'
  else
    echo 'awk'
  fi
}

function gnused() {
  if hash gsed 2>/dev/null; then
    # debug "gnused(): gsed -E \"$@\""
    gsed -E "$@"
  else
    # debug "gnused(): sed -E \"$@\""
    sed -E "$@"
  fi
}

function gnugrep() {
  if hash ggrep 2>/dev/null; then
    # debug "gnugrep(): ggrep -E \"$@\""
    ggrep "$@"
  else
    # debug "gnugrep(): grep -E \"$@\""
    grep "$@"
  fi
}

function setxattr() {
  if hash xattr 2>/dev/null; then
    if [ -f "$3" ]; then
      xattr -w "$1" "$2" "$3" 1>&2
    fi
  elif hash attr 2>/dev/null; then
    if [ -f "$3" ]; then
      attr -s "$1" -V "$2" "$3" 1>&2
    fi
  fi
}

function gnudate() { # Taken from https://stackoverflow.com/a/677212 by @lhunath and @Cory-Klein
  #FIXME: find out how I can prevent the loss of the quotes around the format in the debug output
  # debug "gnudate(): $(gnudate_string) $@"
  if hash gdate 2>/dev/null; then
    gdate "$@"
  else
    date "$@"
  fi
}

function gnufind() {
  # debug "gnufind(): $(gnufind_string) $@"
  if hash gfind 2>/dev/null; then
    gfind "$@"
  else
    find "$@"
  fi
}

function gnuawk() {
  # debug "gnuawk(): $(gnuawk_string) $@"
  if hash gawk 2>/dev/null; then
    gawk "$@"
  else
    awk "$@"
  fi
}

function unsorted_uniques() {
  gnuawk '!uniques[$0]++'
}

function sanitise_filename() {
  # debug "sanitising filename $@"
  gnused 's/[^-a-zA-Z0-9_.]/-/g'
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
    mkdir -p "$1"
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
  if [ -z "$GPLUS_APIKEY" -o "$GPLUS_APIKEY" == "" ]; then
    echo "This command requires access to the Google+ API via an API key, but ENVironment variable GPLUS_APIKEY is not set. Please set it to your Google Plus API key." 1>&2
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
  function_usage+=("timestamp \"rfc-email\" # or \"rfc-5322\" # $(DEBUG=0 gnudate --rfc-email)")
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
  elif [ "$1" == "rfc-5322" -o "$1" == "rfc-email" ]; then
    date_arguments=("--rfc-email")
    ts_format=""
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
  uid_regex="^([0-9]+|\+[a-zA-Z0-9_-]+)$"
  user_id="$1"
  if [[ "$user_id" =~ $uid_regex ]]; then
    echo "$user_id"
    return
  fi
  user_id="${user_id/#https:\/\/plus.google.com\/u\/?\//}"
  user_id="${user_id/#https:\/\/plus.google.com\//}"
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
  log_file="$4"

  if [ "$document_url" == "" ]; then
    echo -e "=!!!= cache_external_document_to_file() needs a target URL at \$1.\n$api_url_usage" 1>&2 && return 255
  elif [[ "$document_url" =~ (^https?|ftps?):// ]]; then # Supported protocols
    if [ "$target_file_path" == "" ]; then
      echo -e "=!!!= cache_external_document_to_file() needs a target file path.\n$function_usage" 1>&2 && return 255
    elif [ ! -f "$target_file_path" ]; then
      local retries=3
      local count=0
      while [ $count -lt $retries ]; do
        if (( $count > 0 )); then  # Don't sleep on the first try
          sleep $count
        fi
        count=$[$count+1]

        debug "  =!= [Try #$count/$retries]: Storing '$document_url' to '$target_file_path'"
        status_code="$(curl -A "$USER_AGENT" -H "Accept-Charset: utf-8, iso-8859-1;q=0.5, *;q=0.1" --write-out %{http_code} --silent ${curl_args}--output "$target_file_path" "$document_url")"; exit_code="$?"
        setxattr "status_code" "$status_code" "$2" 1>&2
        setxattr "tries" "$count/$retries" "$2" 1>&2

        if (( $exit_code >= 1 )); then
          errormsg="[\$?=$exit_code]'$document_url' -> '$target_file_path' # curl exited with code $exit_code"
          debug "    =!= $errormsg"
          append_log_msg "$errormsg" "$log_file"
          setxattr "exit_code" "$exit_code" "$target_file_path" 1>&2
          continue
        fi
      
        if [ "$status_code" -eq 200 ]; then
          echo "$target_file_path"
          # TODO: check for empty "items": or "error":
          return 0
        else
          echo -e "    crdf(): =!!= [$status_code] Error while retrieving remote document." 1>&2

          if [ "$status_code" -eq 403 ]; then # Forbidden. Possibly the result of Exceeded Quota Usage. Preferably don't retry immediately
            echo -e "404 FORBIDDEN Error while retrieving '$document_url' -> '$target_file_path'.\nCould be the result of Exceeded Quota Usage. Request returned:\n\n---\n$(cat "$target_file_path")\n---\n" 1>&2
            read -p $'=!!!= (a)bort, (r)etry or (c)ontinue with next item? [a/r/C]\n' input < /dev/tty

            if [ "$(echo "$input" | tr '[:upper:]' '[:lower:]')" == "r" ]; then
              retrymsg="'$document_url' -> '$target_file_path' # User requested retry (input: '$input')"
              debug "  =!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              continue
            elif [ "$(echo "$input" | tr '[:upper:]' '[:lower:]')" == "a" ]; then
              retrymsg="'$document_url' -> '$target_file_path' # User requested ABORT (input: '$input')"
              debug "  =!!!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              exit 255
            elif [ "$(echo "$input" | tr '[:upper:]' '[:lower:]')" == "c" ]; then
              retrymsg="'$document_url' -> '$target_file_path' # User requested to continue with next item (input: '$input')"
              debug "  =!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              break
            else
              retrymsg="'$document_url' -> '$target_file_path' # Unrecognised user input; continuing with next item (input: '$input')"
              debug "  =!= $retrymsg"
              append_log_msg "$retrymsg" "$log_file"
              break
            fi
          elif [ "$status_code" -eq 204 -o "$status_code" -eq 404 ]; then # Known problematic HTTP Status codes that should be okay to retry automatically
            retrymsg="[$status_code]'$document_url' -> '$target_file_path' # FAIL with 'safe' HTTP Status Code [$count/$retries]"
            debug "    crdf(): =!= $retrymsg"
            append_log_msg "$retrymsg"
            continue
          else # The rest is probably also okay
            retrymsg="[$status_code]'$document_url' -> '$target_file_path' # FAIL with potentially 'non-safe' HTTP Status Code; retrying regardless [$count/$retries]"
            debug "    crdf(): =!= $retrymsg"
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
    echo -e "cache_external_document_to_file(): unsupported protocol for \$document_url ('$document_url'); only http(s) and ftp(s) are currently supported.\n$function_usage" 1>&2 && return 255
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
