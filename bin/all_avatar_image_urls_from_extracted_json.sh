#!/usr/bin/env bash
# encoding: utf-8

caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

declare -a sed_rules=()
sed_rules+=('s/\\u003ds[0-9]{2,}-[a-zA-Z]//') # strip =s64-c and similar attributes from the URL
sed_rules+=('s/\/s[0-9]{2,}-[a-zA-Z]\//\//g') # strip /s64-c/ and similar (re-)size paths from the URL
sed_rules+=($'s/^\/\//https:\/\//') # Replace protocol-agnostic URLs with https:// URLs.
search_path="${1:-$PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH}/"
avatars_output_path="$(output_path "all_avatar_image_urls-without_size${2:-""}")"
find "$search_path" -iname '*.json' -exec "$(gnugrep_cmdstring)" -oP '"avatarImageUrl":\s{0,}"\K([^" ]{1,})' "{}" \; | gnused -E "$(printf '%s' "${sed_rules[@]/%/;}")" | sort -u | tee "$avatars_output_path"
echo "${TP_MAGENTA}$avatars_output_path${TP_RESET}" 1>&2