#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

# FIXME: add usage example
usage="Usage: $0 \$blog_comments_widget_file"

if [ -z "$1" ]; then
  echo "Please supply the path to the GPlus Comments Widgets file as \$blog_comments_widget_file" 1>&2
  exit 255
elif [ "$1" == '--help' -o "$1" == '-h' ]; then
  echo -e $usage
  exit 255
fi
blog_comments_widget_file="$1"

# Look for an ActivityID in the Google+ Comments widget file, trim the trailing double quote, and apply a unique sort
if hash pup 2>/dev/null; then #If `pup` is installed, use that, else fall back to gsed
  # results="$(cat "$blog_comments_widget_file" | pup 'script[nonce]:contains("cw.gfr") text{}'| gnused 's/^AF_initDataCallback\(.+data://' | gnused 's/^}\);$//' | jq -r --slurp '[.[0]? | .[]? | .[]? | .[]? | .[]? | .[]?] | _nwise(3)[1]' | unsorted_uniques)"
  results="$(cat "$blog_comments_widget_file" | pup 'script[nonce]:contains("cw.gfr") text{}'| gnused 's/^AF_initDataCallback\(.+data://' | gnused 's/^}\);$//' | jq -r --slurp '[.[0]? | .[]? | .[]? | .[]? | .[]? | .[]?] | .[ range(1;length;3) ] | select(length > 23)' | unsorted_uniques)"
else
  results="$(gnugrep -oP '^,"\K([a-z0-9]{22,})"' "$blog_comments_widget_file" | tr -d '"' | unsorted_uniques)"
fi 
debug "Found the following ActivityIDs in $blog_comments_widget_file: $results"

echo -e "$results"