#!/usr/bin/env bash
# encoding: utf-8
BASE_URL="https://apis.google.com/u/0/_/widget/render/comments?first_party_property=BLOGGER&query="
stdin=$(cat)

source ./_functions.sh

while IFS= read -r post_url
do
  domain=$(echo "$post_url" | gnused 's/https?:\/\/([^/]+)\/.+/\1/g' | sanitise_filename)
  #echo "$domain"
  url="$BASE_URL$post_url"
  #echo "$post_url"
  filename=$(echo "$post_url" | gnused 's/https?:\/\/([^/]+)\/(.+)$/\2/g' | sanitise_filename)
  #echo $filename
  mkdir -p "data/comments_frames/$domain"
  mkdir -p "./logs/$domain"
  path="data/comments_frames/$domain/$filename"
  if [ ! -f "$path" ]; then
    echo "Storing comments for $post_url to $path" >> "./logs/$domain/$(date +"%y-%m-%d").log"
    curl "$url" > "$path"
  fi
  echo "$path"
done <<< $stdin
