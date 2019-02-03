#!/usr/bin/env bash
# encoding: utf-8
source _functions.sh

stdin=$(cat)
while IFS= read -r blog_comments_widget_file
do
  # Look for an ActivityID in the Google+ Comments widget file, trim the trailing double quote, and apply a unique sort
  results="$(gnugrep -oP '^,"\K([a-z0-9]{22,})"' "$blog_comments_widget_file" | tr -d '"' | sort -u)"
  debug "Found the following ActivityIDs in $blog_comments_widget_file: $results"
  echo -e "$results"
done <<< "$stdin"
# < "${1:-/dev/stdin}"