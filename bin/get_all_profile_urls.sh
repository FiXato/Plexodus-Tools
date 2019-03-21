#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

if hash gxargs 2>/dev/null; then
  xargs_cmd="gxargs"
else
  xargs_cmd="xargs"
fi

output_dir="data/output/urls/profile_urls"
extracted_takeout_directory="extracted/Takeout"

output_profile_urls_from_takeout_stream_posts_posters="$(ensure_path "$output_dir" "from_takeout_stream_posts_posters.txt")"
output_profile_urls_from_takeout_stream_posts_resharers="$(ensure_path "$output_dir" "from_takeout_stream_posts_resharers.txt")"
output_profile_urls_from_takeout_stream_posts_commenters="$(ensure_path "$output_dir" "from_takeout_stream_posts_commenters.txt")"
output_profile_urls_from_takeout_stream_posts_plusoners="$(ensure_path "$output_dir" "from_takeout_stream_posts_plusoners.txt")"

output_profile_urls_from_takeout_community_posts_posters="$(ensure_path "$output_dir" "from_takeout_community_posts_posters.txt")"
output_profile_urls_from_takeout_community_posts_resharers="$(ensure_path "$output_dir" "from_takeout_community_posts_resharers.txt")"
output_profile_urls_from_takeout_community_posts_commenters="$(ensure_path "$output_dir" "from_takeout_community_posts_commenters.txt")"
output_profile_urls_from_takeout_community_posts_plusoners="$(ensure_path "$output_dir" "from_takeout_community_posts_plusoners.txt")"

# output_post_urls_from_activitylog_comments="$(ensure_path "$output_dir" "from_activitylog_comments.txt")"
# output_post_urls_from_activitylog_poll_votes="$(ensure_path "$output_dir" "from_activitylog_poll_votes.txt")"
# output_post_urls_from_activitylog_plusones_on_comments="$(ensure_path "$output_dir" "from_activitylog_plusones_on_comments.txt")"
# output_post_urls_from_activitylog_plusones_on_posts="$(ensure_path "$output_dir" "from_activitylog_plusones_on_posts.txt")"
output_all_unique_profile_urls="$(ensure_path "$output_dir" "all_unique_profile_urls.txt")"

find "$extracted_takeout_directory/Google+ Stream/Posts" -type f -print0 -iname '*.json' | $xargs_cmd -0 jq -r '.author .profilePageUrl' | exclude_empty_lines | tee "$output_profile_urls_from_takeout_stream_posts_posters" && sort -uo "$output_profile_urls_from_takeout_stream_posts_posters" "$output_profile_urls_from_takeout_stream_posts_posters"
find "$extracted_takeout_directory/Google+ Stream/Posts" -type f -print0 -iname '*.json' | $xargs_cmd -0 jq -r '.resharedPost .author .profilePageUrl//""' | exclude_empty_lines | tee "$output_profile_urls_from_takeout_stream_posts_resharers" && sort -uo "$output_profile_urls_from_takeout_stream_posts_resharers" "$output_profile_urls_from_takeout_stream_posts_resharers"
find "$extracted_takeout_directory/Google+ Stream/Posts" -type f -print0 -iname '*.json' | $xargs_cmd -0 jq -r '.comments//[]|map(.author .profilePageUrl)|unique|join("\n")' | exclude_empty_lines | tee "$output_profile_urls_from_takeout_stream_posts_commenters" && sort -uo "$output_profile_urls_from_takeout_stream_posts_commenters" "$output_profile_urls_from_takeout_stream_posts_commenters"
find "$extracted_takeout_directory/Google+ Stream/Posts" -type f -print0 -iname '*.json' | $xargs_cmd -0 jq -r '.plusOnes//[]|map(.plusOner .profilePageUrl)|unique|join("\n")' | exclude_empty_lines | tee "$output_profile_urls_from_takeout_stream_posts_plusoners" && sort -uo "$output_profile_urls_from_takeout_stream_posts_plusoners" "$output_profile_urls_from_takeout_stream_posts_plusoners"


#TODO: Extra "users" and plusMentions too?

# For some reason I can't use -print0 with -path as it then seems to ignore the -path argument
# I unfortunately also had issues with macOS's BSD version of xargs when not using null-byte delimited filenames, so I had to resort to GNU xargs when available.
find "$extracted_takeout_directory/Google+ Communities" -type f -path '*/Posts/*.json' | $xargs_cmd -I@@ jq -r '.author .profilePageUrl' "@@" | exclude_empty_lines | tee "$output_profile_urls_from_takeout_community_posts_posters" && sort -uo "$output_profile_urls_from_takeout_community_posts_posters" "$output_profile_urls_from_takeout_community_posts_posters"
find "$extracted_takeout_directory/Google+ Communities" -type f -path '*/Posts/*.json' | $xargs_cmd -I@@ jq -r '.resharedPost .author .profilePageUrl//""' "@@" | exclude_empty_lines | tee "$output_profile_urls_from_takeout_community_posts_resharers" && sort -uo "$output_profile_urls_from_takeout_community_posts_resharers" "$output_profile_urls_from_takeout_community_posts_resharers"

# These two are currently not available, but hopefully these keys will get added to the Takeout; can't hurt to already have them
find "$extracted_takeout_directory/Google+ Communities" -type f -path '*/Posts/*.json' | $xargs_cmd -I@@ jq -r '.comments//[]|map(.author .profilePageUrl)|unique|join("\n")' "@@" | exclude_empty_lines | tee "$output_profile_urls_from_takeout_community_posts_commenters" && sort -uo "$output_profile_urls_from_takeout_community_posts_commenters" "$output_profile_urls_from_takeout_community_posts_commenters"
find "$extracted_takeout_directory/Google+ Communities" -type f -path '*/Posts/*.json' | $xargs_cmd -I@@ jq -r '.plusOnes//[]|map(.plusOner .profilePageUrl)|unique|join("\n")' "@@" | exclude_empty_lines | tee "$output_profile_urls_from_takeout_community_posts_plusoners" && sort -uo "$output_profile_urls_from_takeout_community_posts_plusoners" "$output_profile_urls_from_takeout_community_posts_plusoners"
#
# jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.commentCreatedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/Comments.json" | tee "$output_post_urls_from_activitylog_comments"
#
# jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.commentPlusOneAddedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/+1s on comments.json" | tee "$output_post_urls_from_activitylog_plusones_on_comments"
#
# jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.postPlusOneAddedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/+1s on posts.json" | tee "$output_post_urls_from_activitylog_plusones_on_posts"
#
# jq -r '[.items[]|select(.visibility == "PUBLIC")]|map(.pollVoteAddedItem .postPermalink)|join("\n")' "$extracted_takeout_directory/Google+ Stream/ActivityLog/Poll Votes.json" | tee "$output_post_urls_from_activitylog_poll_votes"

sort -u $(find "$output_dir" -iname 'from_takeout_*.txt' -type f | xargs) | exclude_empty_lines > "$output_all_unique_profile_urls"