#!/usr/bin/env bash
# encoding: utf-8

PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

ignore_errors=false
if [ "$1" == '--ignore-errors' ]; then
  ignore_errors=true
  shift
fi

usage="# Archive a remote document locally\n# usage: $(basename "$0") \$source_url"
check_help "$1" "$usage" || exit 255
source_url="$1"
if [ "$source_url" == "" ]; then
  error "Please supply the source page URL as \$source_url"
  exit 255
fi

declare -a urls=("$source_url")
url_without_size=$(printf '%s' "$source_url" | "$SED_CMD" -E 's/\/w[0-9]{1,}(-h[0-9]{1,})?\//\//')
[ "$url_without_size" != "" -a "$url_without_size" != "$source_url" ] && urls+=("$url_without_size")
url_without_size=''

url_without_size=$(printf '%s' "$source_url" | "$SED_CMD" -E 's/=s[0-9]{1,}-c$//')
[ "$url_without_size" != "" -a "$url_without_size" != "$source_url" ] && urls+=("$url_without_size")
url_without_size=''

url_without_size=$(printf '%s' "$source_url" | "$SED_CMD" -E 's/-s[0-9]{1,}-c-/-/')
[ "$url_without_size" != "" -a "$url_without_size" != "$source_url" ] && urls+=("$url_without_size")
url_without_size=''

for url in "${urls[@]}"
do
  "$PT_PATH/bin/retrieve_url.sh" $([ "$ignore_errors" == true ] && echo '--ignore-errors ')"$url"
done