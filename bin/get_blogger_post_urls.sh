#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"
usage="usage: $(basename "$0") \$blog_id\nExample: $(basename "$0") 12345\nOr: $(basename "$0") \"\$(bin/get_blogger_id.sh https://your.blogger.blog.example)\""
check_help "$1" "$usage" || exit 255

if [ -z "$1" -o "$1" == "" ]; then
  echo -e "$usage" 1>&2
  exit 255
else
  blog_id="$1"
fi
aggregatePostUrlsPath="data/blog_post_urls/$(buildResponseFilename "$blog_id" "" "$(timestamp_date)" "txt")"
# Clear/reset the file with collected post urls for this blog.
printf '' > "$aggregatePostUrlsPath"
"$PT_PATH/bin/get_blogger_api_post_data_files.sh" "$blog_id" | xargs -L 1 "$PT_PATH/bin/get_blogger_post_urls_from_api_post_data_file.sh"
