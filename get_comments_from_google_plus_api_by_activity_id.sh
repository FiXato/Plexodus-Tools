#!/usr/bin/env bash
# encoding: utf-8
source "_functions.sh"
usage="usage: echo -e \$activity_id1\n\$activity_id2\n\$activity_idn | $(basename "$0")\nExample: TODO (get_activity_ids_from_comments_frame.sh)"
check_help "$1" "$usage" || exit 255

stdin=$(cat)
while IFS= read -r activity_id
do
  # TODO: Add an activity counter; combined with size messages in other scripts that could give a rough estimate of how many items still left to go
  if [ -z "$activity_id" -o "$activity_id" == "" ]; then
    debug "Missing activity id: $activity_id"
    continue
  fi
  
  debug "\nLooking up activities and comments for Activity with ID: $activity_id"
  get_activity_api_url="https://www.googleapis.com/plus/v1/activities/$activity_id?key=$GPLUS_APIKEY"
  debug "Activity.get API URL: $get_activity_api_url"
  # TODO: make comments per-page count also configurable via ENV var. Not sure if the same one should be recycled.
  # FIXME: comments should be ordered by published dates...
  list_comments_api_url="https://www.googleapis.com/plus/v1/activities/$activity_id/comments?key=$GPLUS_APIKEY&maxResults=500&sortOrder=ascending"
  debug "Comments.list API URL: $list_comments_api_url"

  response_file="$(activity_file $activity_id)"
  if [ ! -f "$response_file" ]; then
    debug "Retrieving JSON from $get_activity_api_url and storing it at $response_file"
    $(curl "$get_activity_api_url" > "$response_file")
  else
    debug "Cache hit for ${get_activity_api_url}: $response_file"
  fi

  #FIXME: HTML generation should probably be split off to a separate file, and possibly be done in a more suitable language. 

  title=$(jq -r ' .title' "$response_file")
  displayName=$(jq -r ' .actor | .displayName' "$response_file")
  authorPicture=$(jq -r ' .actor | .image | .url' "$response_file")
  #TODO: store authorPictures locally (permanently)
  permaLink=$(jq -r ' .url' "$response_file")
  published=$(jq -r ' .published' "$response_file")
  updated=$(jq -r ' .updated' "$response_file")
  content=$(jq -r ' .object | .content' "$response_file")
  plusOnesCount=$(jq -r ' .object | .plusoners | .totalItems ' "$response_file")
  plusOnesLink=$(jq -r ' .object | .plusoners | .selfLink ' "$response_file")
  resharesCount=$(jq -r ' .object | .resharers | .totalItems ' "$response_file")
  resharesLink=$(jq -r ' .object | .resharers | .selfLink ' "$response_file")
  commentsCount=$(jq -r ' .object | .replies | .totalItems ' "$response_file")
  commentsLink=$(jq -r ' .object | .replies | .selfLink ' "$response_file")
  
  #TODO: add Attachment data and also store that locally if possible

  html="<!doctype html>\n"
  html="$html"'<html class="no-js" lang=""><head><meta charset="utf-8"><meta http-equiv="x-ua-compatible" content="ie=edge">'"<title>Comments for ${activity_id}</title>"'<meta name="description" content=""><meta name="viewport" content="width=device-width, initial-scale=1"></head><body>'
  html="${html}<article>"
  if [ -z "$title" -o "$title" == "" -o "$title" == null ]; then
    debug "Could not find .title item"
    html="${html}<h1>No Google+ Comments Available for ${activity_id}</h1></article></body></html>"
    echo -e "$html"
    continue
  else
    debug "Found title: $title"
  fi
  html="${html}<h1>$title</h1>\n"
  html="${html}<small class='authored'>Published by <span class='authorName'>$displayName</span><img class='authorPicture' src='$authorPicture' /> on <a href="$permaLink" class='publishedAt'>$published</a>\n"
  html="${html} and updated on: <span class='updatedAt'>$updated</span></small><br />\n"
  html="${html}<p>$content</p>\n"
  html="${html}<div class='interaction'>"
  html="${html}<span class='plusones'>+$plusOnesCount</span> <a href='$plusOnesLink'>plus-ones</a>"
  #TODO: expand the list of plusoners
  html="${html}<div class='reshares'>"
  html="${html}<span class='reshareCount'>+$resharesCount</span> <a href='$resharesLink'>reshares</a>"
  #TODO: expand the list of resharers
  html="${html}</div>"
  html="${html}<div class='comments'>"
  html="${html}<span class='commentsCount'>$commentsCount</span> <a href='$commentsLink'>comments</a>"
  if [ -n "$commentsCount" -a "$commentsCount" != "0"  ]; then
    debug "Activity with id $activity_id has $commentsCount comments:"
    comments_file_path="$(comments_file $activity_id)"
    if [ ! -f "$comments_file_path" ]; then
      debug "Querying Comments.list API for Activity with ID $activity_id at $list_comments_api_url and storing to $comments_file_path"
      $(curl "$list_comments_api_url" > "$comments_file_path")
    else
      debug "Cache hit for Comments.list for Activity with ID $activity_id: $comments_file_path"
    fi
    for row in $(cat "$(comments_file $activity_id)" | jq -r '.items[] | @base64'); do
      # TODO: Add a counter: "Processing comment [1/xx]"
      _jq() {
        echo ${row} | base64 --decode | jq -r "$@"
      }
      html="${html}<div class='comment'>\n"
      commentTitle=$(_jq '.title')
      if [ -n "$commentTitle" -a "$commentTitle" == "" ]; then
        debug "Found comment title: $commentTitle"
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
  else
    debug "Activity with id $activity_id has no (${commentsCount}) comments."
  fi
  html="${html}</div>"
  html="${html}</div>"
  html="${html}</article></body></html>\n"
  echo -e "$html"
done <<< $stdin

