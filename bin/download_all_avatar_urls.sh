#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
source "${PT_PATH}/lib/functions.sh"
IFS='' read -r -d '' usage <<EOSTRING
# ${TP_BOLD}${TP_UON}Get all avatar URLs from extracted Takeout Google+ Stream Posts, and download them in their original form, as well as with any size URL parameters stripped${TP_RESET}
# ${TP_BOLD}usage:${TP_RESET} bin/$(basename "$0") [[/path/to/first/extracted/takeout/parent/directory] [/path/to/second/extracted/takeout/parent/directory] [/path/to/nth/extracted/takeout/parent/directory]]
#
# Paths support globbing, for instance if you've extracted multiple archives in a structure like 'extracted/\$profileName/\$date/', you can use:
# ${TP_BOLD} bin/$(basename "$0") extracted/*/* ${TP_RESET}
EOSTRING
check_help "$1" "$usage" || exit $?

declare -a takeout_parent_paths=()
if [ "$1" != "" ]; then
  takeout_posts_paths+=("${@}")
else
  takeout_posts_paths+=("${PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH}")
fi
find "${takeout_posts_paths[@]/%/\/Takeout\/Google+ Stream\/Posts\/}" -iname '*.json' -type f -exec jq -L "${PT_PATH}" -r 'include "plexodus-tools"; avatar_urls | join("\n")' '{}' \; | gnugrep -v '^$' | gnused 's/^\/\//https:\/\//' | sort -u | "${XARGS_CMD}" -I@@ "${PT_PATH}/bin/retrieve_googleusercontent_url.sh" "@@"
