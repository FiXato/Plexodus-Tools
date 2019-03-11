#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
template="$1"
author_template="$2"
takeout_activity_comment_json_filename="$3"
if [ "$(wc -c < "$takeout_activity_comment_json_filename" | gnused 's/\s+//g')" == "0" ]; then
  echo "    <div class='col-md'><p>No comments on this activity post</p></div>"
  exit
fi

declare -A author_template_variables
declare -A comment_template_variables

author_template_variables["actorDisplayName"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.author .displayName')"
author_template_variables["actorProfileUrl"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.author .profilePageUrl')"
author_template_variables["actorImageUrl"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.author .avatarImageUrl')"
# printarr author_template_variables

#comment_template_variables["authorDisplayName"]="$(cat "$takeout_activity_comment_json_filename" | jq -r '.author .displayName')"
comment_template_variables["actorTemplate"]="$(parse_template "$author_template" "author_template_variables")"
comment_template_variables["commentId"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.resourceName | gsub("^./comments/"; "")')"
comment_template_variables["commentContentBody"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.content')"
comment_template_variables["commentContentSummary"]="$(echo "${comment_template_variables["commentContentBody"]}" | text_summary_from_html )"
comment_template_variables["commentPublishedDateTime"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.creationTime')"
comment_template_variables["commentPublishedFormatted"]=$(timestamp "rss" --date="${comment_template_variables[commentPublishedDateTime]}")
comment_template_variables["commentUpdatedDateTime"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.updateTime//""')"
if [ "${comment_template_variables["commentUpdatedDateTime"]}" != "" ]; then
  comment_template_variables["commentUpdatedFormatted"]=$(timestamp "rss" --date="${comment_template_variables[commentUpdatedDateTime]}")
else
  comment_template_variables["commentUpdatedFormatted"]=""
fi
comment_template_variables["entryUrl"]="$(cat "$takeout_activity_comment_json_filename" | jq -Cr '.postUrl')"
comment_template_variables["commentUrl"]="${comment_template_variables[entryUrl]}#${comment_template_variables["commentId"]}"
comment_template_variables["entryTitle"]=""

parse_template "$template" "comment_template_variables"

# printarr template_variables

# comment_template_variables[""]="$(cat "$takeout_activity_comment_json_filename" | jq -r '')"
# #TODO: store authorPictures locally (permanently)
# permaLink=$(jq -r ' .url' "$response_file")
# published=$(jq -r ' .published' "$response_file")
# updated=$(jq -r ' .updated' "$response_file")
# content=$(jq -r ' .object | .content' "$response_file")
# plusOnesCount=$(jq -r ' .object | .plusoners | .totalItems ' "$response_file")
# plusOnesLink=$(jq -r ' .object | .plusoners | .selfLink ' "$response_file")
# resharesCount=$(jq -r ' .object | .resharers | .totalItems ' "$response_file")
# resharesLink=$(jq -r ' .object | .resharers | .selfLink ' "$response_file")
# commentsCount=$(jq -r ' .object | .replies | .totalItems ' "$response_file")
# commentsLink=$(jq -r ' .object | .replies | .selfLink ' "$response_file")

