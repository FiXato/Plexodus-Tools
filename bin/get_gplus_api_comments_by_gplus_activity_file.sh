#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"
ensure_jq || exit 255
LOG_DIR="${LOG_DIR:-"./logs"}"
ACTIVITIES_WITHOUT_COMMENTS_LOG="gplus-api-activities-without-comments.txt"

usage="usage: $(basename "$0") \$activity_file"
if [ -z "$1" ]; then
  echo "Please supply the Google Plus API Activity JSON response file as \$activity_file" 1>&2
  exit 255
fi
check_help "$1" "$usage" || exit 255

activity_file="$1"

if [ -z "$activity_file" -o "$activity_file" == "" ]; then
  debug "Missing activity_file argument: $activity_file"
  exit 255
fi

if [ ! -f "$activity_file" ]; then
  debug "File defined as \$activity_file does not exist: $activity_file"
  exit 255
fi

activity_id=$(jq -r '.id' "$activity_file")
# Only request comments from the API when the Activity actually has replies.
commentsCount=$(jq -r ' .object | .replies | .totalItems ' "$activity_file")
if [ -n "$commentsCount" -a "$commentsCount" != "0"  ]; then
  debug "Activity with ID $activity_id stored at $activity_file has $commentsCount comments:"
  echo $("$PT_PATH/bin/get_gplus_api_comments_by_gplus_activity_id.sh" "$activity_id")
else
  debug "Activity with ID $activity_id stored at $activity_file has no comments."
  echo "'$activity_id' -> '$activity_file'" >> $(ensure_path "$LOG_DIR" "$ACTIVITIES_WITHOUT_COMMENTS_LOG")
fi
