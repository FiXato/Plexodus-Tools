#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

output_dir="data/output/urls/public_post_urls"
extracted_takeout_directory="extracted/Takeout"

output_public_post_urls_from_takeout_stream_posts="$(ensure_path "$output_dir" "from_takeout_stream_posts.txt")"
output_public_post_urls_from_takeout_community_posts="$(ensure_path "$output_dir" "from_takeout_community_posts.txt")"
output_post_urls_from_activitylog_comments="$(ensure_path "$output_dir" "from_activitylog_comments.txt")"
output_post_urls_from_activitylog_poll_votes="$(ensure_path "$output_dir" "from_activitylog_poll_votes.txt")"
output_post_urls_from_activitylog_plusones_on_comments="$(ensure_path "$output_dir" "from_activitylog_plusones_on_comments.txt")"
output_post_urls_from_activitylog_plusones_on_posts="$(ensure_path "$output_dir" "from_activitylog_plusones_on_posts.txt")"
output_all_unique_public_post_urls="$(ensure_path "$output_dir" "all_unique_public_post_urls.txt")"

find "$extracted_takeout_directory/Google+ Stream/Posts" -type f -print0 -iname '*.json' | $XARGS_CMD -0 jq -r 'select(.postAcl .isPublic == true)| [.]|map(.url)|[.]|flatten|add|[.]|unique|join("\n")' | tee "$output_public_post_urls_from_takeout_stream_posts" && sort -uo "$output_public_post_urls_from_takeout_stream_posts" "$output_public_post_urls_from_takeout_stream_posts"

# For some reason I can't use -print0 with -path as it then seems to ignore the -path argument
# I unfortunately also had issues with macOS's BSD version of xargs when not using null-byte delimited filenames, so I had to resort to GNU xargs when available.
find "$extracted_takeout_directory/Google+ Communities" -type f -path '*/Posts/*.json' | $XARGS_CMD -I@@ jq -r 'select(.postAcl .isPublic == true)| [.]|map(.url)|[.]|flatten|add|[.]|unique|join("\n")' "@@" | tee "$output_public_post_urls_from_takeout_community_posts" && sort -uo "$output_public_post_urls_from_takeout_community_posts" "$output_public_post_urls_from_takeout_community_posts"

jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.commentCreatedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/Comments.json" | tee "$output_post_urls_from_activitylog_comments" && sort -uo "$output_post_urls_from_activitylog_comments" "$output_post_urls_from_activitylog_comments"

jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.commentPlusOneAddedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/+1s on comments.json" | tee "$output_post_urls_from_activitylog_plusones_on_comments" && sort -uo "$output_post_urls_from_activitylog_plusones_on_comments" "$output_post_urls_from_activitylog_plusones_on_comments"

jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.postPlusOneAddedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/+1s on posts.json" | tee "$output_post_urls_from_activitylog_plusones_on_posts" && sort -uo "$output_post_urls_from_activitylog_plusones_on_posts" "$output_post_urls_from_activitylog_plusones_on_posts"

jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.pollVoteAddedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/Poll Votes.json" | tee "$output_post_urls_from_activitylog_poll_votes" && sort -uo "$output_post_urls_from_activitylog_poll_votes" "$output_post_urls_from_activitylog_poll_votes"

# echo "$output_public_post_urls_from_takeout_stream_posts"
# echo "$output_public_post_urls_from_takeout_community_posts"
# echo "$output_post_urls_from_activitylog_comments"
# echo "$output_post_urls_from_activitylog_plusones_on_comments"
# echo "$output_post_urls_from_activitylog_plusones_on_posts"
# echo "$output_post_urls_from_activitylog_poll_votes"

sort -u $(find "$output_dir" -iname 'from_*.txt' -type f | $XARGS_CMD) | exclude_empty_lines > "$output_all_unique_public_post_urls"