#!/usr/bin/env bash
# encoding: utf-8
DATADIR="./data/output"
BASE_URL="https://apis.google.com/u/0/_/widget/render/comments?first_party_property=BLOGGER&query="
mkdir -p $DATADIR
stdin=$(cat)
while read -r post_url
do
  domain=$(echo "$post_url"| sed -r 's/https?:\/\/([^/]+)\/.+/\1/gi' -| sed 's/[^-a-z0-9_.]/-/ig' -)
  #echo "$domain"
  url="$BASE_URL$post_url"
  #echo "$post_url"
  filename=$(echo "$post_url" | sed 's/[^-a-z0-9_.]/-/ig' -)
  #echo $filename
  mkdir -p "$DATADIR/$domain"
  path="$DATADIR/$domain/$filename"
  echo "Storing comments for $post_url to $path"
  curl "$url" > "$path"
done <<< $stdin
