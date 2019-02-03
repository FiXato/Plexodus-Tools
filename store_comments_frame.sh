#!/usr/bin/env bash
# encoding: utf-8
api_url="https://apis.google.com/u/0/_/widget/render/comments?first_party_property=BLOGGER&query="
stdin=$(cat)

source ./_functions.sh

while IFS= read -r post_url
do
  domain=$(domain_from_url "$post_url" | sanitise_filename)
  url="${api_url}${post_url}"
  debug "Looking for G+ Comments for $post_url"
  filename=$(path_from_url "$post_url" | sanitise_filename)
  path="$(ensure_path "data/comments_frames/$domain" "$filename")"
  if [ ! -f "$path" ]; then
    debug "Storing comments for $post_url to $path and sleeping for $REQUEST_THROTTLE seconds."
    sleep $REQUEST_THROTTLE
    curl "$url" > "$path"
  else
    debug "Cache hit: G+ Comments Widget has already been retrieved from $url: to $path"
  fi
  echo "$path"
done <<< $stdin
