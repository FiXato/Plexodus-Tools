#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

template="$1"
actor_template="$2"
comment_json="$3"
comment_json="$(printf "$comment_json" | gbase64 -d -)"

declare -A actor_template_variables
declare -A comment_template_variables

actor_template_variables["actorDisplayName"]="$(echo "$comment_json" | jq -Cr '.actor .displayName')"
actor_template_variables["actorProfileUrl"]="$(echo "$comment_json" | jq -Cr '.actor .url')"
actor_template_variables["actorImageUrl"]="$(echo "$comment_json" | jq -Cr '.actor .image .url')"
# printarr actor_template_variables

#comment_template_variables["actorDisplayName"]="$(echo "$comment_json" | jq -r '.actor .displayName')"
comment_template_variables["actorTemplate"]="$(parse_template "$actor_template" "actor_template_variables")"
comment_template_variables["commentId"]="$(echo "$comment_json" | jq -Cr '.id')"
comment_template_variables["commentContentBody"]="$(echo "$comment_json" | jq -Cr '.object .content')"
comment_template_variables["commentContentSummary"]=""
comment_template_variables["commentPublishedDateTime"]="$(echo "$comment_json" | jq -Cr '.published')"
comment_template_variables["commentPublishedFormatted"]=$(timestamp "rss" --date="${comment_template_variables[commentPublishedDateTime]}")
comment_template_variables["commentUpdatedDateTime"]="$(echo "$comment_json" | jq -Cr '.updated')"
comment_template_variables["commentUpdatedFormatted"]=$(timestamp "rss" --date="${comment_template_variables[commentUpdatedDateTime]}")
comment_template_variables["entryUrl"]="$(echo "$comment_json" | jq -Cr '.inReplyTo[0] .url')"
comment_template_variables["commentUrl"]="${comment_template_variables[entryUrl]}#$(echo "$comment_json" | jq -Cr '.id')"
comment_template_variables["entryTitle"]=""

parse_template "$template" "comment_template_variables"

# printarr template_variables

# comment_template_variables[""]="$(echo "$comment_json" | jq -r '')"
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

