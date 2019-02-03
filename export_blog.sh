#!/usr/bin/env bash
# encoding: utf-8
source _functions.sh
domain=$(echo "$1" | gnused 's/https?:\/\/([^/]+)\/?.*/\1/g' | sanitise_filename )
echo "Exporting Blogger blog at $domain"
mkdir -p "./data/output/$domain/html"

./getposturls.sh `sh ./getblogid.sh "$1"` | ./store_comments_frame.sh | ./get_activity_ids_from_comments_frame.sh | ./get_comments_from_google_plus_api_by_activity_id.sh > "./data/output/$domain/html/all-activities.html"

#FIXME: Make it so that you aren't basically repeating all these lookups, even though they are cached...
for filename in $(find "data/comments_frames/$domain/"* )
do
  echo "$filename"
  echo $(basename "$filename")
  echo "$filename" | ./get_activity_ids_from_comments_frame.sh | ./get_comments_from_google_plus_api_by_activity_id.sh > "data/output/$domain/html/$(basename "$filename")"
done