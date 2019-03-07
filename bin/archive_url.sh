#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

usage="# Archive a webpage through the WayBackMachine and cache it locally\n# usage: $(basename "$0") \$source_url"
check_help "$1" "$usage" || exit 255
source_url="$1"
if [ "$source_url" == "" ]; then
  echo "Please supply the source page URL as \$source_url" && exit 255 1>&2
fi

wbm_save_base_url="https://web.archive.org/save"
wbm_save_url="$wbm_save_base_url/$source_url"
target_filepath="$(wbm_archive_filepath "$source_url")"
filename="$(cache_remote_document_to_file "$wbm_save_url" "$target_filepath")"
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "=!= cache_remote_document_to_file('$wbm_save_url' '$target_filepath') exited with $exit_code and returned '$filename'" 1>&2
  exit $exit_code
fi

cat "$filename"