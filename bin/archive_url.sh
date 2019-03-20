#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

ignore_errors=false
if [ "$1" == '--ignore-errors' ]; then
  ignore_errors=true
  shift
fi

usage="# Archive a webpage through the WayBackMachine and cache it locally\n# usage: $(basename "$0") \$source_url"
check_help "$1" "$usage" || exit 255
source_url="$1"
domain="$(domain_from_url "$source_url" | sanitise_filename )"
if [ "$source_url" == "" ]; then
  echo "Please supply the source page URL as \$source_url" && exit 255 1>&2
else
  clean_source_url="$(urlsafe_plus_profile_url "$source_url")"
fi

wbm_save_base_url="https://web.archive.org/save"
wbm_save_url="$wbm_save_base_url/$clean_source_url"
target_filepath="$(wbm_archive_filepath "$source_url")"
filename="$(cache_remote_document_to_file "$wbm_save_url" "$target_filepath" "" "./logs/archive_url-errors-$domain.log")"
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "=!= cache_remote_document_to_file('$wbm_save_url' '$target_filepath') exited with $exit_code and returned '$filename'" 1>&2
  setxattr "exit_code" "$exit_code" "$filename"
  if [ "$ignore_errors" != true ]; then
    exit 255
  fi
fi
setxattr "source_url" "$source_url" "$filename"
setxattr "wbm_save_url" "$wbm_save_url" "$filename"

echo "$filename"