#!/usr/bin/env bash
# encoding: utf-8
#
# Retrieves People API data from the Google+ People API for given Google+ profile id/URL.
#
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
ensure_gplus_api||exit 255
ensure_gnutools||exit 255
LOG_DIR="./logs"
FAILED_FILES_LOGFILE="failed-profile-retrievals.txt"

usage="Usage: $0 \$profile [--delete-target]\nThe optional --delete-target flag will delete the JSON output file for the given Profile if an error occurs; without it, it will log the filepath to '$LOG_DIR/$FAILED_FILES_LOGFILE' and leave the JSON output file intact instead.\n\$profile can be a numeric profile ID, a +PrefixedCustomURLName, or full plus.google.com profile URL."

if [ -z "$1" ]; then
  echo "Please supply a user id, custom URL profile handle (e.g. +PrefixedCustomURLName), or full profile URL as \$1" 1>&2
  exit 255
elif [ "$1" == '--help' -o "$1" == '-h' ]; then
  echo -e $usage
  exit 255
fi
user_id="$(get_user_id "$1")"
if (( $? >= 1 )); then
  echo "Please supply the user id (\$1) in their numeric, +PrefixedCustomURLName form, or profile URL form." 1>&2 && exit 255
fi

function handle_failure() {
  echo "$json_output_file" >> $(ensure_path "$LOG_DIR" "$FAILED_FILES_LOGFILE")
  debug "handle_failure(): \$1: '$1'"
  if [ -n "$1" -a "$1" == '--delete-target' ]; then
    debug "removing output file"
    rm "$json_output_file"
  fi
}

json_output_file="$(user_profile_file "$user_id" "day")" || exit 255
profile_api_url="$(api_url "gplus" "people" "get" "$user_id")" || exit 255

#filename=$(cache_remote_document_to_file "$profile_api_url" "$json_output_file") && cat "$filename" || handle_failure
filename=$(cache_remote_document_to_file "$profile_api_url" "$json_output_file")
if (( $? >= 1 )); then
  # FIXME: find out why I can't exit with an error code, as it seems to make xargs running in parallel mode stop working when it encounters an error on one of its processes.
  handle_failure "$2" # && exit 255
fi

echo "$filename"