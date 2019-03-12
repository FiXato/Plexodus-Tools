#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
template="$1"
author_template="$2"
takeout_activity_json_filename="$3"
generated_comments_template_filename="$4"
if [ "$(wc -c < "$takeout_activity_json_filename" | gnused 's/\s+//g')" == "0" ]; then
  echo "    <div class='col-md'><p>No comments on this activity post</p></div>"
  exit
fi

debug "Parsing '$takeout_activity_json_filename'"

declare -A author_template_variables
declare -A activity_template_variables

author_template_variables["actorDisplayName"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.author .displayName')"
author_template_variables["actorProfileUrl"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.author .profilePageUrl')"
author_template_variables["actorImageUrl"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.author .avatarImageUrl')"
# printarr author_template_variables

activity_template_variables["actorTemplate"]="$(parse_template "$author_template" "author_template_variables")"
activity_template_variables["activityId"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.activityId')"
activity_template_variables["entryContentBody"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.content//""')"
activity_template_variables["entryContentSummary"]="$(echo "${activity_template_variables["entryContentBody"]}" | title_from_html $'\U2026' 200 )"
activity_template_variables["entryTitle"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.title//""')"
activity_template_variables["entryPublishedFormatted"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.creationTime')"
activity_template_variables["entryPublishedFormatted"]=$(timestamp "rss" --date="${activity_template_variables[entryPublishedDateTime]}")
activity_template_variables["entryUpdatedDateTime"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.updateTime//""')"
if [ "${activity_template_variables["entryUpdatedDateTime"]}" != "" ]; then
  activity_template_variables["entryUpdatedFormatted"]=$(timestamp "rss" --date="${activity_template_variables[entryUpdatedDateTime]}")
  activity_template_variables["entryUpdatedPrefixData"]="updated on "
else
  activity_template_variables["entryUpdatedFormatted"]=""
  activity_template_variables["entryUpdatedPrefixData"]=""
fi
activity_template_variables["entryUrl"]="$(cat "$takeout_activity_json_filename" | jq -Cr '.url')"
activity_template_variables["entryCollectionUrl"]="$(cat "$takeout_activity_json_filename" | jq '.postAcl .collectionAcl .collection .resourceName//"" | gsub("^collections/"; "https://plus.google.com/collections/")')"
activity_template_variables["entryCollectionName"]="$(cat "$takeout_activity_json_filename" | jq '.postAcl .collectionAcl .collection .displayName//""')"
activity_template_variables["entryCommentsTemplate"]="$(cat "$generated_comments_template_filename")"


parse_template "$template" "activity_template_variables"

# printarr template_variables

# activity_template_variables[""]="$(cat "$takeout_activity_json_filename" | jq -r '')"
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

