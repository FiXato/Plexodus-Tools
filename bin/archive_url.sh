#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

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
wbm_save_url="$wbm_save_base_url/$clean_source_url?hl=en"
if [ "$FORCED_GOOGLE_LOCALE" != "" ];then
  if [[ "$domain" == *.google.com || "$domain" == google.com ]]; then
    wbm_save_url="$wbm_save_url?hl=$FORCED_GOOGLE_LOCALE"
  fi
fi
target_filepath="$(wbm_archive_filepath "$source_url")"
filename="$(cache_remote_document_to_file "$wbm_save_url" "$target_filepath" "" "./logs/archive_url-errors-$domain.log")"
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "${FG_RED}${TP_BOLD}=!= cache_remote_document_to_file('$wbm_save_url' '$target_filepath') exited with $exit_code and returned '$filename'${TO_RESET}" 1>&2
  setxattr "exit_code" "$exit_code" "$target_filepath"
  if [ "$ignore_errors" != true ]; then
    exit 255
  fi
fi
setxattr "source_url" "$source_url" "$target_filepath"
setxattr "wbm_save_url" "$wbm_save_url" "$target_filepath"

echo "$filename"