#!/usr/bin/env bash
# encoding: utf-8
source "_functions.sh"
usage="usage: $(basename "$0") https://your.blogger.blog.example"
check_help "$1" "$usage" || exit 255
ensure_blogger_api||exit 255

if [ -z "$1" -o "$1" == "" ]; then
  echo -e "$usage" 1>&2
  exit 255
else
  blog_url="$1"
fi


api_url="https://www.googleapis.com/blogger/v3/blogs/byurl?url=${blog_url}&key=${BLOGGER_APIKEY}"
domain=$(domain_from_url "$blog_url" | sanitise_filename)
path=$(ensure_path "data/blog_ids" "${domain}.txt")

if [ ! -f "$path" ]; then
  curl -s "$api_url" | jq -r '.id' > "$path"
fi
cat "$path"
