#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
ensure_gplus_api||exit 255
LOG_DIR="./logs"
FAILED_FILES_LOGFILE="failed-gplus-api-comments-retrievals.txt"

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
list_comments_api_url="https://www.googleapis.com/plus/v1/activities/$activity_id/comments?key=$GPLUS_APIKEY&maxResults=500&sortOrder=ascending"
debug "Comments.list API URL: $list_comments_api_url"

comments_response_file="$(comments_file $activity_id)"
if [ ! -f "$comments_response_file" ]; then
  debug "Storing activities for $list_comments_api_url to $comments_response_file"
  filename=$(cache_remote_document_to_file "$list_comments_api_url" "$comments_response_file")
  if (( $? >= 1 )); then
    # FIXME: find out why I can't exit with an error code, as it seems to make xargs running in parallel mode stop working when it encounters an error on one of its processes.
    echo "'$list_comments_api_url' -> '$comments_response_file'" >> $(ensure_path "$LOG_DIR" "$FAILED_FILES_LOGFILE")
  fi

  #FIXME: make sure the file actually contains results.
else
  debug "Cache hit: Google Plus API Activity has already been retrieved from $list_comments_api_url: to $comments_response_file"
fi

echo "$comments_response_file"