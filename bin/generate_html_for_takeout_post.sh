#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"
OVERWRITE_LINKS="${OVERWRITE_LINKS:-false}"

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
activity_title_summary="$(jq -r '.content//"UNTITLED by " + .author .displayName' "$input_filepath" | title_from_html "" -1 | strip_html | shorten "" 100)"
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
      directory=$(directory_for_output_html_for_activity "$activity_user_id" "$acl_key" "$privacy" "circle_and_userless")
      if (( "$?" >= 1 )); then exit 255; fi
      filename="$(filename_for_output_html_for_activity "$activity_id" "$activity_published_date" "$activity_title_summary")"
      if (( "$?" >= 1 )); then exit 255; fi
      target_output_filepath+=("$(ensure_path "$directory" "$filename")")
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
    if [ "$acl_key" == "communityAcl" ]; then
      debug "Community ACL"
      acl_path="postAcl,communityAcl,community"
      resource_name_prefix="communities"
      default_display_name="NAMELESS_OR_DELETED_COMMUNITY"
    elif [ "$acl_key" == "collectionAcl" ]; then
      debug "Collection ACL"
      acl_path="postAcl,collectionAcl,collection"
      resource_name_prefix="collections"
      default_display_name="NAMELESS_OR_DELETED_COLLECTION"
    elif [ "$acl_key" == "eventAcl" ]; then
      debug "Event ACL"
      acl_path="postAcl,eventAcl,event"
      resource_name_prefix="events"
      default_display_name="NAMELESS_OR_DELETED_EVENT"
    elif [ "$acl_key" == "isLegacyAcl" ]; then
      debug "Legacy ACL"
      continue
    else
      echo "Unrecognised .postAcl[key]: '$acl_key'" 1>&2 && exit 255
    fi
    activity_acl_name="$(jq -r --arg aclPath "$acl_path" --arg resourceNamePrefix "$resource_name_prefix" --arg defaultDisplayName "$default_display_name" 'getpath($aclPath|split(",")) | [(.resourceName | gsub("^$resourceNamePrefix/"; "")), (.displayName//"$defaultDisplayName" | gsub("\n"; "") | gsub("(?<g>G(oogle)?)\\+"; .g+"Plus"))] | join("-")' "$input_filepath")"

    directory=$(directory_for_output_html_for_activity "$activity_user_id" "$acl_key" "$privacy" "$activity_acl_name")
    if (( "$?" >= 1 )); then exit 255; fi
    filename="$(filename_for_output_html_for_activity "$activity_id" "$activity_published_date" "$activity_title_summary")"
    if (( "$?" >= 1 )); then exit 255; fi
    target_output_filepath+=("$(ensure_path "$directory" "$filename")")
  fi
done <<< "$activity_post_acl_keys"

debug "Found filepaths:\n$(printarr target_output_filepath)"
primary_filepath="${target_output_filepath[0]}"
comment_template_script="$PT_PATH/bin/generate-comment-template-from-takeout-activity-json-file.sh"
activity_template_script="$PT_PATH/bin/generate-activity-template-from-takeout-activity-json-file.sh"
layout_template_script="$PT_PATH/bin/generate-html-template-layout.sh"
activity_template="$PT_PATH/templates/h-entry-microformat.template.html"
comment_template="$PT_PATH/templates/h-entry-p-comment-microformat.template.html"
author_template="$PT_PATH/templates/h-entry-author.template.html"
intermediate_activity_file="${primary_filepath}.activity.$(timestamp "%Y%m%d-%H%M%S")"
intermediate_comments_file="${primary_filepath}.comments.$(timestamp "%Y%m%d-%H%M%S")"
asset_directory="$(realpath "${PT_PATH}/assets/")"

comments="$(cat "$input_filepath" | jq -cr '.comments//[] | .[] | @base64')"
counter=0
touch "$intermediate_comments_file"
while IFS= read -r comment || [ -n "$comment" ]; do # Loop through $comments
  if ((${#input} == 0)); then
    debug "comment #${counter} is empty"
    ((counter+=1))
    continue
  fi
  
    
  tmp_filename="${intermediate_comments_file}.${counter}.json"
  debug "Parsing comment '$tmp_filename'"
  debug "Comment: '$comment'"
  printf "$comment" | gbase64 -d - > "$tmp_filename" && "$comment_template_script" "$comment_template" "$author_template" "$tmp_filename" >> "$intermediate_comments_file" && rm "$tmp_filename"
  ((counter+=1))
done <<< "$comments"
unset counter

# Generate Intermediate Activity Output File
touch "$intermediate_activity_file"
debug "\"$activity_template_script\" \"$activity_template\" \"$author_template\" \"$input_filepath\" \"$intermediate_comments_file\""
filename="$("$activity_template_script" "$activity_template" "$author_template" "$input_filepath" "$intermediate_comments_file" > "$intermediate_activity_file" && debug "Intermediate Activity File: $intermediate_activity_file")"
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "Template generation exited with '$exit_code' Remember to clean up '$intermediate_comments_file'." 1>&2
  exit $exit_code
else
  rm "$intermediate_comments_file"
fi

#TODO: Optimise by splitting templates in header and footer files, so we can output straight to the end-result file for intermediate results

# Generate Final Layout Output File
filename="$("$layout_template_script" "default" "$intermediate_activity_file" "$asset_directory/css" > "$primary_filepath" && echo "$primary_filepath")"
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "Template generation exited with '$exit_code'. Remember to clean up '$intermediate_activity_file'." 1>&2
  exit $exit_code
else
  rm "$intermediate_activity_file"
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