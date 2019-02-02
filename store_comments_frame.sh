#!/usr/bin/env bash
# encoding: utf-8
DATADIR="./data/output"
mkdir -p $DATADIR
BASE_URL="https://apis.google.com/u/0/_/widget/render/comments?first_party_property=BLOGGER&query="
stdin=$(cat)


function gnused() {
  if hash gsed 2>/dev/null; then
      gsed -E "$@"
  else
      sed -E "$@"
  fi
}

while read -r post_url
do
  domain=$(echo "$post_url" | gnused 's/https?:\/\/([^/]+)\/.+/\1/g' | gnused 's/[^-a-zA-Z0-9_.]/-/g')
  #echo "$domain"
  url="$BASE_URL$post_url"
  #echo "$post_url"
  filename=$(echo "$post_url" | gnused 's/[^-a-zA-Z0-9_.]/-/g')
  #echo $filename
  mkdir -p "$DATADIR/$domain"
  path="$DATADIR/$domain/$filename"
  echo "Storing comments for $post_url to $path"
  curl "$url" > "$path"
done <<< $stdin
