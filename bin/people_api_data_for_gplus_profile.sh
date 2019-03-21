#!/usr/bin/env bash
# encoding: utf-8
#
# Retrieves People API data from the Google+ People API for given Google+ profile id/URL.
#
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
ensure_gplus_api||exit 255
#ensure_gnutools||exit 255
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
  echo "'$profile_api_url' -> '$json_output_file'" >> $(ensure_path "$LOG_DIR" "$FAILED_FILES_LOGFILE")
  debug "handle_failure(): \$1: '$1'"
  if [ -n "$1" -a "$1" == '--delete-target' ]; then
    debug "removing output file"
    rm "$json_output_file"
  fi
}

# FIXME: # REFACTORME Replace this with the logic used in archive_gplus_url.sh
# Get the numeric UserID from the profile page if the given $user_id is in the +CustomHandle format.
if [ "${user_id:0:1}" == "+" ]; then
  user_id_custom_to_numeric_map_filepath="$(ensure_path "${caller_path}/../data/gplus/custom_to_numeric_user_id_mappings" "${user_id:1}.txt")"
  if [ -f "$user_id_custom_to_numeric_map_filepath" ]; then
    numeric_user_id="$(cat "$user_id_custom_to_numeric_map_filepath")"
    debug "Retrieved numeric user_id '$numeric_user_id' for '$user_id' from '$user_id_custom_to_numeric_map_filepath'."
  else
    archived_profile_page="$("$caller_path/archive_url.sh" "https://plus.google.com/${user_id}")"
    exit_code="$?"
    if (( $exit_code > 0 )); then
      echo "Error while archiving G+ profile page for ${user_id}. Exited with error code $exit_code" 1>&2
      exit $exit_code
    fi
    
    if hash pup 2>/dev/null; then
      numeric_user_id="$(cat "$archived_profile_page" | pup 'link[itemprop] attr{href}')"
      numeric_user_id="${numeric_user_id#"https://plus.google.com/"}"
    else
      numeric_user_id="$(cat "$archived_profile_page" | gnugrep -oP '<link itemprop="url" href="\K([^"]+)')"
    fi
  fi
else
  numeric_user_id="$user_id"
fi

json_output_file="$(user_profile_file "$numeric_user_id" "day")" || exit 255
profile_api_url="$(api_url "gplus" "people" "get" "$numeric_user_id")" || exit 255

#filename=$(cache_remote_document_to_file "$profile_api_url" "$json_output_file") && cat "$filename" || handle_failure
filename=$(cache_remote_document_to_file "$profile_api_url" "$json_output_file")
if (( $? >= 1 )); then
  # FIXME: find out why I can't exit with an error code, as it seems to make xargs running in parallel mode stop working when it encounters an error on one of its processes.
  handle_failure "$2" # && exit 255
elif [ "$user_id" != "$numeric_user_id" ];then
  json_output_file="$(user_profile_file "$user_id" "day")"
  if [ ! -f "$json_output_file" ]; then
    ln "$filename" "$json_output_file" 1>&2
  fi
fi

echo "$filename"