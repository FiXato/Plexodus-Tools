#!/usr/bin/env bash
# encoding: utf-8

caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

ignore_errors=false
if [ "$1" == '--ignore-errors' ]; then
  ignore_errors=true
  shift
fi

usage="# Archive a remote document locally\n# usage: $(basename "$0") \$source_url"
check_help "$1" "$usage" || exit 255
source_url="$1"
if [ "$source_url" == "" ]; then
  error "Please supply the source page URL as \$source_url"
  exit 255
fi

declare -a curl_headers
curl_headers=("Accept-Charset: utf-8, iso-8859-1;q=0.5, *;q=0.1")
curl_headers+=("Accept-Language: en-GB;q=0.9, en;q=0.8, en-US;q=0.7, *;q=0.5")

domain="$(domain_from_url "$source_url" | sanitise_filename )"
domain_cache_path="${PLEXODUS_DATA_CACHE_DIRECT_PATH}/$domain"
domain_cache_files_path="${domain_cache_path}/files"
mkdir -p -- "${domain_cache_files_path}"
domain_cache_metadata_path="${domain_cache_path}/metadata"
domain_cache_metadata_downloads_log_path="$(ensure_path "$domain_cache_metadata_path" "downloads.success.log")"
domain_cache_metadata_failed_downloads_log_path="$(ensure_path "$domain_cache_metadata_path" "downloads.failed.log")"

log_download(){
  local url="$1"
  if [ "$url" == "" ]; then
    error "log_download(): \$1 needs to be a URL"
    return 255
  fi

  local filepath="$2"
  if [ "$filepath" == "" ]; then
    error "log_download(): \$2 needs to be a local filepath"
    return 255
  fi

  if [ ! -f "$filepath" ]; then
    error "log_download(): \$2 (\$filepath) '$filepath' does not exist"
    return 255
  fi

  local log_path="$3"
  if [ "$log_path" == "" ]; then
    error "log_download(): \$3 needs to be the path to the log file"
    return 255
  fi

  # TODO: unit test this
  # printf '%s\31%s\n\0' "$url" "$filepath" >> "$log_path"
  xattr_metadata_set_key "$url" "$filepath" "$log_path"
}

# TODO: unit test this
local_path_for_downloaded_url() {
  xattr_metadata_get_key "$1" "$2"
  exit_code="$?"
  exit $exit_code
  # gnuawk -v key="^$1$" 'BEGIN { FS="\31"; RS="\n\0"; exit_code=1} $1 ~ key { print "\""$1"\": "$2; exit_code=0 }; END { exit exit_code }' "$2"
}

if [ -f "$domain_cache_metadata_downloads_log_path" ]; then
  local_path="$(local_path_for_downloaded_url "$source_url" "$domain_cache_metadata_downloads_log_path")"
  exit_code="$?"
  [ "$local_path" != "" ] && debug "local_path_for_downloaded_url(): \$?=$exit_code; \$local_path='$local_path'"
  if (( $exit_code == 0 )); then
  #TODO: allow for  "$IGNORE_CACHE" == 'true'
    debug "📁  URL '${source_url}' has already been downloaded: $local_path"
    printf '%s\n' "$local_path"
    exit 0
  fi
fi

sanitised_filename="$(path_from_url "$source_url" | lesser_sanitise_filename )"
filename="$( non_existing_filename "${domain_cache_files_path}" "$sanitised_filename" 2 )"; exit_code="$?"
if (( $exit_code > 0 )); then
  error "📁 '${filename}': '$source_url' already exists, and we exceeded the maximum amount of $exit_code tries"
  exit $exit_code
fi
# debug "\$filename='$filename'"

tries="${filename#$sanitised_filename.*}"
if [ "$tries" == "" ]; then
  debug "📁 '${filename}': '$source_url' already existed. It took ${tries} tries to get a unique filename."
fi
curl_output_filepath="${domain_cache_files_path}/${filename}"
# debug "\$curl_output_filepath='$curl_output_filepath'"
curl_output_stderr_filepath="${domain_cache_metadata_path}/${filename}.metadata"
curl_output_stderr_filepath="${domain_cache_metadata_path}/${filename}.metadata"

retries=$MAX_RETRIEVAL_RETRIES
count=0
while [ $count -lt $retries ]; do
  if (( $count > 0 )); then  # Don't sleep on the first try
    sleep $count
  fi
  count=$[$count+1]

  debug "[$count/$retries] ⬇️  ${TP_UON}'$source_url'${TP_UOFF}\n    -> ${TP_UON}'$curl_output_filepath'${TP_UOFF}\n    -> ${TP_UON}'$curl_output_stderr_filepath'${TP_UOFF}"
  status_code="$(curl -v -A "$USER_AGENT" "${curl_headers[@]/#/-H}" --write-out %{http_code} --silent --output "$curl_output_filepath" "$source_url" 2>> "$curl_output_stderr_filepath")"
  exit_code="$?"
  
  if (( $exit_code > 0 ));then
    error "❌ curl exited with a non-zero exit code: \$?=$exit_code"
    printf '%s\n' "$source_url" >> "${domain_cache_metadata_failed_downloads_log_path/%".failed.log"/".failed.exit.$exit_code.log"}"
    continue
  fi

  if (( $status_code > 200 ));then
    error "❌ curl returned a non-200 HTTP Status Code: \$status_code=$status_code"
    printf '%s\n' "$source_url" >> "${domain_cache_metadata_failed_downloads_log_path/%".failed.log"/".failed.status.$status_code.log"}"
    debug "\$PLEXODUS_ON_URL_RETRIEVAL_FAILURE: '$PLEXODUS_ON_URL_RETRIEVAL_FAILURE'"
    if [[ "$PLEXODUS_ON_URL_RETRIEVAL_FAILURE" == *"DELETE_DOWNLOAD"* ]]; then
      debug "\$PLEXODUS_ON_URL_RETRIEVAL_FAILURE='$PLEXODUS_ON_URL_RETRIEVAL_FAILURE' includes 'DELETE_DOWNLOAD'; deleting: '$curl_output_filepath'"
      rm -- "$curl_output_filepath"
    fi
    if [[ "$PLEXODUS_ON_URL_RETRIEVAL_FAILURE" == *"DELETE_METADATA"* ]]; then
      debug "\$PLEXODUS_ON_URL_RETRIEVAL_FAILURE='$PLEXODUS_ON_URL_RETRIEVAL_FAILURE' includes 'DELETE_METADATA'; deleting: '$curl_output_stderr_filepath'"
      rm -- "$curl_output_stderr_filepath"
    fi
    continue
  fi
  
  if ! log_download "$source_url" "$curl_output_filepath" "$domain_cache_metadata_downloads_log_path"; then
    exit_code="$?"
    error "log_downloaded exited with a non-zero exit code: \$?=$exit_code"
    continue
  else
    debug "Logged download to $domain_cache_metadata_downloads_log_path"
  fi
  
  debug "  ${FG_GREEN}${TP_BOLD}✅  Successful download!"
  printf "%s\n" "$curl_output_filepath"
  exit 0
done
if [ "$ignore_errors" == 'true' ]; then
  exit 0
else
  exit "${exit_code:-255}"
fi