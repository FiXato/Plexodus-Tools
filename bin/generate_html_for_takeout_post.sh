#!/usr/bin/env bash
# encoding: utf-8
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
activity_title_summary="$(jq -r 'if .content then .content else "UNTITLED by " + .author .displayName end' "$input_filepath" | text_summary_from_html)"
debug "title summary: $activity_title_summary"
activity_post_acl_keys="$(jq -r 'if .postAcl then (.postAcl|keys|join("\n")) else "" end' "$input_filepath")"
debug "post acl keys: $activity_post_acl_keys"


while IFS= read -r acl_key || [ -n "$acl_key" ]; do # Loop through activity_post_acl_keys
  debug '---'
  if [ "$acl_key" == "isPublic" ]; then
    privacy="public"
    continue
  elif [ "$acl_key" == "visibleToStandardAcl" ]; then

    circles="$(cat "$input_filepath" | jq -r 'if .postAcl .visibleToStandardAcl .circles != null then (.postAcl .visibleToStandardAcl .circles[] | [.type, (if .displayName then (.displayName | gsub("\u0001"; "") | gsub("G(?<g1>oogle)?\\+"; "G\(if .g1 then .g1 else "" end)Plus") | gsub(" "; "_")) else "" end)] | join("\u0001")) else "" end')"
    users="$(cat "$input_filepath" | jq -r 'if .postAcl .visibleToStandardAcl .users then (.postAcl .visibleToStandardAcl .users[] | [(.resourceName | gsub("^users/"; "") | gsub("\u0001"; "")), .displayName | gsub("\u0001"; "") | gsub(" "; "_")] | join("\u0001")) else "" end')"
    delimiter=$'\U0001'

    if [ "$circles" == "" -a "$users" == "" ]; then
      debug "No circles nor circles"
      continue
    fi

    if [ "$circles" != "" ];then 
      debug "Circles: $circles"
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

    if [ "$users" != "" ];then 
      debug "Users: $users"
      while IFS= read -r user || [ -n "$user" ]; do # Loop through $users
        user_id="${user%%$delimiter*}"
        user_display_name="${user#*$delimiter}"
      
        directory=$(directory_for_output_html_for_activity "$activity_user_id" "$acl_key" "$privacy" "private" "$circle_name")
        if (( "$?" >= 1 )); then exit 255; fi
        filename="$(filename_for_output_html_for_activity "$activity_id" "$activity_published_date" "$activity_title_summary")"
        if (( "$?" >= 1 )); then exit 255; fi
        target_output_filepath+=("$(ensure_path "$directory" "$filename")")
      done <<< "$user"
    fi
  else # not a visibleToStandardAcl
    if [ "$acl_key" == "communityAcl" ]; then
      debug "Community ACL"
      activity_acl_name="$(jq -r '.postAcl .communityAcl .community | [(.resourceName | gsub("^communities/"; "")), (.displayName | gsub("\n"; "") | gsub("G(?<g1>oogle)?\\+"; "G\(if .g1 then .g1 else "" end)Plus"))] | join("-")' "$input_filepath")"
    elif [ "$acl_key" == "collectionAcl" ]; then
      debug "Collection ACL"
      activity_acl_name="$(jq -r '.postAcl .collectionAcl .collection | [(.resourceName | gsub("^collections/"; "")), (.displayName | gsub("\n"; "") | gsub("G(?<g1>oogle)?\\+"; "G\(if .g1 then .g1 else "" end)Plus"))] | join("-")' "$input_filepath")"
    elif [ "$acl_key" == "eventAcl" ]; then
      debug "Event ACL"
      activity_acl_name="$(jq -r '.postAcl .eventAcl .event | [(.resourceName | gsub("^events/"; "")), (.displayName | gsub("\n"; "") | gsub("G(?<g1>oogle)?\\+"; "G\(if .g1 then .g1 else "" end)Plus"))] | join("-")' "$input_filepath")"
    elif [ "$acl_key" == "isLegacyAcl" ]; then
      debug "Legacy ACL"
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

debug "Found filepaths:\n==="
primary_filepath="${target_output_filepath[0]}"
filename="$(cat "$input_filepath" | jq -cr 'if .comments then .comments[] else null end|@base64' | gxargs -I @@ bin/generate-comment-template-from-takeout-activity-json-in-base64.sh templates/h-entry-p-comment-microformat.template.html templates/h-entry-author.template.html "@@" > "${primary_filepath}.comments" && bin/generate-html-template-layout.sh "default" "${primary_filepath}.comments" "$(dirname "$(realpath "${caller_path}/")")" > "$primary_filepath" && echo "$primary_filepath")"
exit_code="$?"
if (( $exit_code >= 1 )); then
  echo "Template generation exited with '$exit_code'"
  exit $exit_code
else
 rm "${primary_filepath}.comments"
fi
  
echo "$filename"
target_output_filepath=("${target_output_filepath[@]:1}")
for filepath in "${target_output_filepath[@]}"; do
   ln "$primary_filepath" "$filepath"
   echo "$filepath"
done