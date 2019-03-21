#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

ignore_errors=""
if [ "$1" == '--ignore-errors' ]; then
  ignore_errors="$1 "
  shift
fi

usage="# Archive a Google Plus webpage through the WayBackMachine and cache it locally\n# usage: $(basename "$0") \$source_url"
check_help "$1" "$usage" || exit 255
source_url="$1"
if [ "$source_url" == "" ]; then
  echo "Please supply the source page URL as \$source_url" 1>&2
  echo -e "$usage" 1>&2
  exit 255
fi

domain="$(domain_from_url "$source_url" | sanitise_filename )"
if [ $domain != 'plus.google.com' ]; then
  echo "This script is only meant for Google Plus pages on the plus.google.com domain" 1>&2
  exit 255
fi

debug "Calling archiver with source URL: $source_url"
"$caller_path/archive_url.sh" ${ignore_errors}"${source_url}"

declare -A user_ids
set_user_id_array_from_gplus_url user_ids "$source_url"

if [ "${user_ids['custom']}" != "" -a "${user_ids['numeric']}" == "" ]; then
  user_ids['numeric']="$(get_numeric_user_id_for_custom_user_id "${user_ids['custom']}")"
  # debug "unparsed: ${user_ids['unparsed']}"
  # debug "custom: ${user_ids['custom']}"
  # debug "numeric: ${user_ids['numeric']}"
  base_url="https://plus.google.com"
  pattern="${base_url}/${user_ids['unparsed']}"
  replacement="${base_url}/${user_ids['numeric']}"
  numeric_url="${source_url/#$pattern/$replacement}"
  debug "Calling archiver with numeric URL: $numeric_url"
  "$caller_path/archive_url.sh" ${ignore_errors}"$numeric_url"
fi

