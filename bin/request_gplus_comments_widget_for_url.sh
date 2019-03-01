#!/usr/bin/env bash
# encoding: utf-8
DATA_WIDGETS_PATH="data/gplus_comments_widgets"
LOG_DIR="./logs"
FAILED_FILES_LOGFILE="failed-gplus-comments-widgets-retrievals.txt"
REQUEST_THROTTLE="${REQUEST_THROTTLE:-0}"
api_url="https://apis.google.com/u/0/_/widget/render/comments?first_party_property=BLOGGER&query="

caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

usage="Usage: $0 \$blog_post_url\nIf you have a file with URLs, where every URL is on its own line, you can pass each line to this script with xargs: cat urls_list.txt | xargs -L 1 $0"

if [ -z "$1" ]; then
  echo -e $usage
  echo "Please supply a (blog post) URL \$blog_post_url" 1>&2
  exit 255
elif [ "$1" == '--help' -o "$1" == '-h' ]; then
  echo -e $usage
  exit 255
fi
post_url="$1"

domain=$(domain_from_url "$post_url" | sanitise_filename)
widget_url="${api_url}${post_url}"
debug "Looking for G+ Comments for $post_url"
filename="$(path_from_url "$post_url" | add_file_extension ".html" | sanitise_filename)"
debug "Filename: $filename"
widget_output_path="$(ensure_path "$DATA_WIDGETS_PATH/$domain" "$filename")"
if [ ! -f "$widget_output_path" ]; then
  debug "Storing comments for $widget_url to $widget_output_path and sleeping for $REQUEST_THROTTLE seconds."
  sleep $REQUEST_THROTTLE
  filename=$(cache_remote_document_to_file "$widget_url" "$widget_output_path")
  if (( $? >= 1 )); then
    # FIXME: find out why I can't exit with an error code, as it seems to make xargs running in parallel mode stop working when it encounters an error on one of its processes.
    echo "$widget_output_path" >> $(ensure_path "$LOG_DIR" "$FAILED_FILES_LOGFILE")
  fi

  #FIXME: make sure the file actually contains results.
else
  debug "Cache hit: G+ Comments Widget has already been retrieved from $widget_url: to $widget_output_path"
fi
echo "$widget_output_path"
