#!/usr/bin/env bash
# encoding: utf-8
DATADIR="./data/gplus/activities/"
mkdir -p "$DATADIR"

function activity_file() {
  echo "$DATADIR/$1.json"
}
function comments_file() {
  mkdir -p "$DATADIR/$1"
  echo "$DATADIR/$1/comments.json"
}

stdin=$(cat)
while IFS= read -r activity_id
do  
  get_activity_api_url="https://www.googleapis.com/plus/v1/activities/$activity_id?key=$GPLUS_APIKEY"
  list_comments_api_url="https://www.googleapis.com/plus/v1/activities/$activity_id/comments?key=$GPLUS_APIKEY&maxResults=500&sortOrder=ascending"
  #echo "$api_url"
  response_file="$(activity_file $activity_id)"
  if [ ! -f "$response_file" ]; then
    $(curl "$get_activity_api_url" > "$response_file")
  fi
  
  
  
  #response=$(cat "$response_file")
  #puts response
  # cat "$response_file"
  title=$(jq -r ' .title' "$response_file")
  displayName=$(jq -r ' .actor | .displayName' "$response_file")
  authorPicture=$(jq -r ' .actor | .image | .url' "$response_file")
  permaLink=$(jq -r ' .url' "$response_file")
  published=$(jq -r ' .published' "$response_file")
  updated=$(jq -r ' .updated' "$response_file")
  content=$(jq -r ' .object | .content' "$response_file")
  plusOnesCount=$(jq -r ' .object | .plusoners | .totalItems ' "$response_file")
  plusOnesLink=$(jq -r ' .object | .plusoners | .selfLink ' "$response_file")
  resharesCount=$(jq -r ' .object | .resharers | .totalItems ' "$response_file")
  resharesLink=$(jq -r ' .object | .resharers | .selfLink ' "$response_file")
  commentsCount=$(jq -r ' .object | .replies | .totalItems ' "$response_file")
  commensLink=$(jq -r ' .object | .replies | .selfLink ' "$response_file")

  html="<!doctype html>\n"
  html="$html"'<html class="no-js" lang=""><head><meta charset="utf-8"><meta http-equiv="x-ua-compatible" content="ie=edge">'"<title>Comments for ${activity_id}</title>"'<meta name="description" content=""><meta name="viewport" content="width=device-width, initial-scale=1"></head><body>'
  html="${html}<article>"
  if [ -z "$title" -o "$title" == "" ]; then
    html="${html}<h1>No Google+ Comments Available for ${activity_id}</h1></article></body></html>"
    echo -e "$html"
    continue
  fi
  html="${html}<h1>$title</h1>\n"
  html="${html}<small class='authored'>Published by <span class='authorName'>$displayName</span><img class='authorPicture' src='$authorPicture' /> on <a href="$permaLink" class='publishedAt'>$published</a>\n"
  html="${html} and updated on: <span class='updatedAt'>$updated</span></small><br />\n"
  html="${html}<p>$content</p>\n"
  html="${html}<div class='interaction'>"
  html="${html}<span class='plusones'>+$plusOnesCount</span> <a href='$plusOnesLink'>plus-ones</a>"
  html="${html}<div class='reshares'>"
  html="${html}<span class='reshareCount'>+$resharesCount</span> <a href='$resharesLink'>reshares</a>"
  html="${html}</div>"
  html="${html}<div class='comments'>"
  html="${html}<span class='commentsCount'>$commentsCount</span> <a href='$commentsLink'>comments</a>"
  if [ -n "$commentsCount" -a "$commentsCount" == "0"  ]; then
    if [ ! -f "$(comments_file $activity_id)" ]; then
      $(curl "$list_comments_api_url" > "$(comments_file $activity_id)")
    fi
    for row in $(cat "$(comments_file $activity_id)" | jq -r '.items[] | @base64'); do
      _jq() {
        echo ${row} | base64 --decode | jq -r "$@"
      }
      html="${html}<div class='comment'>\n"
      commentTitle=$(_jq '.title')
      if [ -n "$commentTitle" -a "$commentTitle" == "" ]; then
        html="${html}<h3>$commentTitle</h3>\n"
      fi
      html="${html}<small class='authored'>Published by <span class='authorName'>$(_jq '.actor .displayName')</span><img class='authorPicture' src='$(_jq ' .actor | .image | .url')' /> on <a href="$(_jq '.url')" class='publishedAt'>$(_jq '.published')</a>\n"
      html="${html} and updated on: <span class='updatedAt'>$(_jq '.updated')</span></small><br />\n"
      html="${html}<p>$(_jq '.object | .content')</p>\n"
      html="${html}<div class='interaction'>"
      html="${html}<span class='plusones'>$(_jq '.plusoners | .totalItems ')</span> <a href='$(_jq '.object | .plusoners | .selfLink ')'>plus-ones</a>"
      
      html="${html}</div>\n"
      html="${html}</div>\n"
    done
  fi
  html="${html}</div>"
  html="${html}</div>"
  html="${html}</article></body></html>\n"
  echo -e "$html"
done <<< $stdin

