#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
ensure_gplus_api||exit 255
LOG_DIR="./logs"
FAILED_FILES_LOGFILE="failed-gplus-api-activity-retrievals.txt"

usage="usage: $(basename "$0") \$activity_id\nMultiple Activity IDs example: echo -e \$activity_id1\n\$activity_id2\n\$activity_idn | xargs -L 1 $(basename "$0")"
if [ -z "$1" ]; then
  echo "Please supply the Google Plus API Activity ID as \$activity_id" 1>&2
  exit 255
fi
check_help "$1" "$usage" || exit 255

activity_id="$1"

if [ -z "$activity_id" -o "$activity_id" == "" ]; then
  debug "Missing activity id: $activity_id"
fi

debug "Looking up activities and comments for Activity with ID: $activity_id"
get_activity_api_base_url="https://www.googleapis.com/plus/v1/activities/$activity_id"
get_activity_api_url="${get_activity_api_base_url}?key=$GPLUS_APIKEY"
debug "Activity.get API URL: $get_activity_api_url"

log_file=$(ensure_path "$LOG_DIR" "$FAILED_FILES_LOGFILE")
activity_response_file="$(activity_file $activity_id)"
if [ ! -f "$activity_response_file" ]; then
  debug "Storing activities for $get_activity_api_url to $activity_response_file"
  filename=$(cache_remote_document_to_file "$get_activity_api_url" "$activity_response_file" "" "$log_file")
  exit_code="$?"
  setxattr "activity_id" "$activity_id" "$activity_response_file" 1>&2
  setxattr "source" "${get_activity_api_base_url}?key=REDACTED" "$activity_response_file" 1>&2

  if (( $exit_code >= 1 )); then
    read -p "Error while retrieving $get_activity_api_url - Retry? (y/n)" retry < /dev/tty
    if [ "$retry" == "y" ]; then
      debug "Retrying $get_activity_api_url"
      rm "$activity_response_file"
      filename=$(cache_remote_document_to_file "$get_activity_api_url" "$activity_response_file" "" "$log_file")
      exit_code="$?"
      setxattr "activity_id" "$activity_id" "$activity_response_file" 1>&2
      setxattr "source" "${get_activity_api_base_url}?key=REDACTED" "$activity_response_file" 1>&2
      if (( $exit_code >= 1 )); then
        debug "Failed again."
        exit 255
      fi
    else
      exit 255
    fi
  fi

  #FIXME: make sure the file actually contains results.
else
  debug "Cache hit: Google Plus API Activity has already been retrieved from $get_activity_api_url: to $activity_response_file"
fi

echo "$activity_response_file"