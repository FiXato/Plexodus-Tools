#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
domain="$(domain_from_url "$1")"
echo "Exporting Blogger blog at $domain"

# #FIXME: make sure the script does this
# mkdir -p "./data/output/$domain/html"
#
"$caller_path/get_blogger_post_urls.sh" "$("$caller_path/get_blogger_id.sh" "$1")" | xargs -L 1 "$caller_path/request_gplus_comments_widget_for_url.sh" | xargs -L 1 "$caller_path/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh" | xargs -L 1 "$caller_path/get_gplus_api_activity_by_gplus_activity_id.sh" | xargs -L 1 "$caller_path/get_gplus_api_comments_by_gplus_activity_file.sh"
#
# #FIXME: Make it so that you aren't basically repeating all these lookups, even though they are cached...
# for filename in $(find "data/comments_frames/$domain/"* )
# do
#   #FIXME: keep track of where you are, so you can abort, and continue again at a later time without having to restart.
#   echo "$filename"
#   echo $(basename "$filename")
#   echo "$filename" | "$caller_path/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh" | "$caller_path/get_comments_from_google_plus_api_by_activity_id.sh" > "data/output/$domain/html/$(basename "$filename")"
# done