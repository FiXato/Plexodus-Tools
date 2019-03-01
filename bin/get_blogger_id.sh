#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
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
domain=$(domain_from_url "$blog_url")
path=$(ensure_path "data/blog_ids" "$(echo "$domain" | sanitise_filename).txt")

#FIXME: catch 404s
if [ ! -f "$path" ]; then
  debug "Retrieving Blogger ID for domain '$domain' from '$api_url' and storing it at '$path'"
  curl -s "$api_url" | jq -r '.id' > "$path"
else
  debug "$path already exists"
fi
cat "$path"
