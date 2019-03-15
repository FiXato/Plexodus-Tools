#!/usr/bin/env bash
# encoding: utf-8
activity_log_filepath="$1"
if [ "$activity_log_filepath" == "" ]; then
  printf "Please specify the path to activity log file. e.g.:\n$0 \"extracted/Takeout/Google+ Stream/ActivityLog/Comments.json\"\n" 1>&2
  exit 255
fi

data_dir=${2:-"data/output/html/exported_comments"}
mkdir -p "$data_dir"
while IFS= read -r -d '' comment; do
  newline=$'
'
  comment="$(printf '%s' "$comment" | tr -d '\0' )"
  filename="${comment%% *}"
  filename="${filename#*$newline}"
  echo "Exporting to ${data_dir}/${filename}" 1>&2
  comment_text="${comment#* }"
  # echo "Filename: $filename"
  # echo "Comment: $comment_text"
  printf '%s' "$comment_text" > "${data_dir}/${filename}"
done < <(jq -r '.items | sort_by(.primaryText|length) | reverse[] | (.primaryText|length|tostring) + "-" + .timestampMs + "-" + (.primaryText|gsub("[^a-zA-Z0-9]+"; "_")[0:50]|gsub("_+$"; "")) + ".txt " + (.primaryText|gsub("  "; "\n")) + "\u0000"' "$activity_log_filepath")

if hash gsort 2>/dev/null; then
  find "$data_dir" | gsort -V
else
  find "$data_dir" | sort -V  
fi