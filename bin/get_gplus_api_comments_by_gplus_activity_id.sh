#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"
ensure_gplus_api||exit 255
LOG_DIR="${LOG_DIR:-"./logs"}"
FAILED_FILES_LOGFILE="failed-gplus-api-comments-retrievals.txt"
FAILED_FILES_LOGPATH="$(ensure_path "$LOG_DIR" "$FAILED_FILES_LOGFILE")"

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

# TODO: make comments per-page count also configurable via ENV var. Not sure if the same one should be recycled.
# TODO: should add pagination, though since the max of comments per post is 500, a maxResults of 500 should already get all the available comments(?)
list_comments_api_base_url="https://www.googleapis.com/plus/v1/activities/$activity_id/comments?maxResults=500&sortOrder=ascending"
list_comments_api_url="${list_comments_api_base_url}&key=${GPLUS_APIKEY}"
debug "Comments.list API URL: $list_comments_api_url"

comments_response_file="$(comments_file $activity_id)"
if [ ! -f "$comments_response_file" ]; then
  debug "Storing activities for $list_comments_api_url to $comments_response_file"
  filename=$(cache_remote_document_to_file "$list_comments_api_url" "$comments_response_file" "" "$FAILED_FILES_LOGPATH")
  if (( $? >= 1 )); then
    # FIXME: find out why I can't exit with an error code, as it seems to make xargs running in parallel mode stop working when it encounters an error on one of its processes.
    append_log_msg "'$list_comments_api_url' -> '$comments_response_file'" "$FAILED_FILES_LOGPATH"
  else
    comments_count="$(cat "$filename" | jq -r '.items | length')"
    if (( $comments_count == 0 )); then
      append_log_msg "'$list_comments_api_url' -> '$comments_response_file' #EMPTY! comments list. RETRYING" "$FAILED_FILES_LOGPATH"

      if [ -f "$comments_response_file" ]; then
        rm "$comments_response_file"
      fi
      sleep 2
      filename=$(cache_remote_document_to_file "$list_comments_api_url" "$comments_response_file" "" "$FAILED_FILES_LOGPATH"); exit_code="$?"
      if (( $exit_code >= 1 )); then
        # FIXME: find out why I can't exit with an error code, as it seems to make xargs running in parallel mode stop working when it encounters an error on one of its processes.
        append_log_msg "'$list_comments_api_url' -> '$comments_response_file' #ERROR WHILE RETRYING" "$FAILED_FILES_LOGPATH"
      else
        comments_count="$(cat "$filename" | jq -r '.items | length')"
        if (( $comments_count == 0 )); then
          append_log_msg "'$list_comments_api_url' -> '$comments_response_file' #EMPTY AGAIN" "$FAILED_FILES_LOGPATH"
        fi
      fi
    fi
  fi
  setxattr "activity_id" "$activity_id" "$filename"
  setxattr "api_url" "$list_comments_api_base_url" "$filename"
else
  debug "Cache hit: Google Plus API Activity has already been retrieved from $list_comments_api_url: to $comments_response_file"
fi

echo "$comments_response_file"