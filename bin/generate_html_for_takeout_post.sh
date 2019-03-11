#!/usr/bin/env bash
# encoding: utf-8
OVERWRITE_LINKS="${OVERWRITE_LINKS:-false}"
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

# FIXME: add usage example
usage="Usage: $0 \$takeout_gstream_post_json_filepath"

if [ -z "$1" ]; then
  echo "Please supply the path to the Google Data Takeout Post JSON file as \$takeout_gstream_post_json_filepath" 1>&2
  exit 255
elif [ "$1" == '--help' -o "$1" == '-h' ]; then
  echo -e $usage 1>&2
  exit 255
fi
input_filepath="$1"
debug "Input file path: $input_filepath"
privacy="limited" # Default privacy
declare -a target_output_filepath
target_output_filepath=()

activity_id="$(jq -r '.activityId' "$1")"
debug "activity_id: $activity_id"
activity_user_id="$(jq -r '.author .resourceName | gsub("^users/"; "")' "$input_filepath")"
debug "user_id: $activity_user_id"
activity_published_date="$(timestamp "day" --date="$(jq -r '.creationTime' "$input_filepath")")"
debug "published on: $activity_published_date"
activity_title_summary="$(jq -r '.content//"UNTITLED by " + .author .displayName' "$input_filepath" | text_summary_from_html)"
debug "title summary: $activity_title_summary"
activity_post_acl_keys="$(jq -r '.postAcl//{}|keys|join("\n")' "$input_filepath")"
debug "post acl keys:\n$activity_post_acl_keys"


while IFS= read -r acl_key || [ -n "$acl_key" ]; do # Loop through activity_post_acl_keys
  if [ "$acl_key" == "isPublic" ]; then
    privacy="public"
    continue
  elif [ "$acl_key" == "visibleToStandardAcl" ]; then
    circles="$(cat "$input_filepath" | jq -r '.postAcl .visibleToStandardAcl .circles//[] | .[] | [(.type | gsub("\u0001"; "")), (.displayName//"" | gsub("(?<g>G(oogle)?)\\+"; .g+"Plus") | gsub(" "; "_") | gsub("\u0001"; ""))] | join("\u0001")')"
      users="$(cat "$input_filepath" | jq -r '.postAcl .visibleToStandardAcl .users//[]   | .[] | [(.resourceName | gsub("^users/"; "") | gsub("\u0001"; "")), (.displayName//"NAMELESS_USER" | gsub("(?<g>G(oogle)?)\\+"; .g+"Plus") | gsub(" "; "_") | gsub("\u0001"; ""))] | join("\u0001")')"
    delimiter=$'\U0001'

    if [ "$circles" == "" -a "$users" == "" ]; then
      debug "No circles nor circles"
      continue
    fi

    if [ "$circles" != "" ];then 
      debug "Circles:\n$circles"
      while IFS= read -r circle || [ -n "$circle" ]; do # Loop through $circles
        circle_type="${circle%%$delimiter*}"
        circle_name="${circle#*$delimiter}"
      
        directory=$(directory_for_output_html_for_activity "$activity_user_id" "$acl_key" "$privacy" "$circle_type" "$circle_name")
        if (( "$?" >= 1 )); then exit 255; fi
        filename="$(filename_for_output_html_for_activity "$activity_id" "$activity_published_date" "$activity_title_summary")"
        if (( "$?" >= 1 )); then exit 255; fi
        target_output_filepath+=("$(ensure_path "$directory" "$filename")")
      done <<< "$circles"
    fi

    if [ "$privacy" != "public" -a "$users" != "" ];then 
      debug "Users:\n$users"
      while IFS= read -r user || [ -n "$user" ]; do # Loop through $users
        user_id="${user%%$delimiter*}"
        user_display_name="${user#*$delimiter}"
      
        directory=$(directory_for_output_html_for_activity "$activity_user_id" "$acl_key" "$privacy" "private" "${user_id}-${user_display_name}")
        if (( "$?" >= 1 )); then exit 255; fi
        filename="$(filename_for_output_html_for_activity "$activity_id" "$activity_published_date" "$activity_title_summary")"
        if (( "$?" >= 1 )); then exit 255; fi
        target_output_filepath+=("$(ensure_path "$directory" "$filename")")
      done <<< "$users"
    fi
  else # not a visibleToStandardAcl
    # TODO: Simplify this (--arg)
    if [ "$acl_key" == "communityAcl" ]; then
      debug "Community ACL"
      activity_acl_name="$(jq -r '.postAcl .communityAcl .community | [(.resourceName | gsub("^communities/"; "")), (.displayName//"NAMELESS_OR_DELETED_COMMUNITY" | gsub("\n"; "") | gsub("(?<g>G(oogle)?)\\+"; .g+"Plus"))] | join("-")' "$input_filepath")"
      echo "ACL Name: $activity_acl_name"
    elif [ "$acl_key" == "collectionAcl" ]; then
      debug "Collection ACL"
      activity_acl_name="$(jq -r '.postAcl .collectionAcl .collection | [(.resourceName | gsub("^collections/"; "")), (.displayName//"NAMELESS_OR_DELETED_COLLECTION" | gsub("\n"; "") | gsub("(?<g>G(oogle)?)\\+"; .g+"Plus"))] | join("-")' "$input_filepath")"
    elif [ "$acl_key" == "eventAcl" ]; then
      debug "Event ACL"
      activity_acl_name="$(jq -r '.postAcl .eventAcl .event | [(.resourceName | gsub("^events/"; "")), (.displayName//"NAMELESS_OR_EVENT" | gsub("\n"; "") | gsub("(?<g>G(oogle)?)\\+"; .g+"Plus"))] | join("-")' "$input_filepath")"
    elif [ "$acl_key" == "isLegacyAcl" ]; then
      debug "Legacy ACL"
      continue
    else
      echo "Unrecognised .postAcl[key]: '$acl_key'" 1>&2 && exit 255
    fi

    directory=$(directory_for_output_html_for_activity "$activity_user_id" "$acl_key" "$privacy" "$activity_acl_name")
    if (( "$?" >= 1 )); then exit 255; fi
    filename="$(filename_for_output_html_for_activity "$activity_id" "$activity_published_date" "$activity_title_summary")"
    if (( "$?" >= 1 )); then exit 255; fi
    target_output_filepath+=("$(ensure_path "$directory" "$filename")")
  fi
done <<< "$activity_post_acl_keys"

debug "Found filepaths:\n$(printarr target_output_filepath)"
primary_filepath="${target_output_filepath[0]}"
comment_template_script="$caller_path/generate-comment-template-from-takeout-activity-json-in-base64.sh"
layout_template_script="$caller_path/generate-html-template-layout.sh"
comment_template="$caller_path/../templates/h-entry-p-comment-microformat.template.html"
author_template="$caller_path/../templates/h-entry-author.template.html"
intermediate_file="${primary_filepath}.comments.$(timestamp "%Y%m%d-%H%M%S")"
debug "Intermediate filename: $intermediate_file"
asset_directory="$(dirname "$(realpath "${caller_path}/")")"

comments="$(cat "$input_filepath" | jq -cr '.comments//[] | .[] | @base64')"
counter=0
while IFS= read -r comment || [ -n "$comment" ]; do # Loop through $comments
  tmp_filename="${intermediate_file}.${counter}.json"
  printf "$comment" | gbase64 -d - > "$tmp_filename" && "$comment_template_script" "$comment_template" "$author_template" "$tmp_filename" >> "$intermediate_file" && rm "$tmp_filename"
  ((counter+=1))
done <<< "$comments"
unset counter

filename="$("$layout_template_script" "default" "$intermediate_file" "$asset_directory" > "$primary_filepath" && echo "$primary_filepath")"
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "Template generation exited with '$exit_code'" 1>&2
  exit $exit_code
else
  rm "$intermediate_file"
fi
  
echo "$filename"
target_output_filepath=("${target_output_filepath[@]:1}")
for filepath in "${target_output_filepath[@]}"; do
  if [ ! -f "$filepath" -o "$OVERWRITE_LINKS" == true ]; then
    flags=''
    if [ "$OVERWRITE_LINKS" == true ]; then
      flags+='-f '
    fi
    ln $flags"$primary_filepath" "$filepath"
  fi
  echo "$filepath"
done