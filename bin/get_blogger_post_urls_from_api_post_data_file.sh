#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
usage="usage: $(basename "$0") \$blogger_post_api_data_file\nExample: $(basename "$0") data/posts/\$blog_id-500-2019-03-02.json"
check_help "$1" "$usage" || exit 255
LOG_DIR="${LOG_DIR:-./logs}"
FAILED_FILES_LOGFILE="failed-blogger-post-urls-extractions.txt"

if [ -z "$1" -o "$1" == "" ]; then
  echo -e "$usage" 1>&2
  exit 255
else
  blogger_post_api_data_file="$1"
fi

items=$(cat "$blogger_post_api_data_file" | jq -rc '.items')
if [ -z "$items" -o "$items" == null -o "$items" == "" ]; then
  echo "Blogger blog post API response file $blogger_post_api_data_file has no items." 1>&2 && exit
fi
  
urls=$(cat "$blogger_post_api_data_file" | jq -rc '.items[] | .url')
exit_code="$?"

debug "Found $(echo -e "$urls" | wc -l) URLs."
if (( $exit_code >= 1 )); then
  echo "${0}: Error ($exit_code) while retrieving urls for $blogger_post_api_data_file" 1>&2 && exit 255
  echo "$blogger_post_api_data_file #${0}" >> $(ensure_path "$LOG_DIR" "$FAILED_FILES_LOGFILE")
fi
echo -e "$urls"

blog_id=$(cat "$blogger_post_api_data_file" | jq -rc '.items[0] .blog .id')
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "${0}: Error ($exit_code) while extracting blog id from $blogger_post_api_data_file" 1>&2 && exit
fi

if [ -z "$blog_id" -o "$blog_id" == "" ]; then
  debug "Extracted \$blog_id is empty"
  exit
fi

aggregatePath="data/blog_post_urls/$(buildResponseFilename "$blog_id" "" "$(timestamp_date)" "txt")"
echo -e "$urls" >> "$aggregatePath"
debug "Added post urls to: $aggregatePath"