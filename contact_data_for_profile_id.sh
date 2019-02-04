#!/usr/bin/env bash
# encoding: utf-8
source "_functions.sh"
ensure_blogger_api||exit 255

if [ -z "$1" ]; then
  echo "Please supply a user id as \$1"
  exit 255
elif [[ "$1" =~ [0-9]+$ ]]; then
  user_id="$1"
else
  echo "Please supply the user id (\$1) in their numeric form"
  exit 255
fi

json_output_file="$(user_profile_file "$user_id" "day")" || exit 255
profile_api_url="$(api_url "gplus" "people" "get" "$user_id")" || exit 255

#filename=$(cache_remote_document_to_file "$profile_api_url" "$json_output_file") && cat "$filename" || rm "$json_output_file"
filename=$(cache_remote_document_to_file "$profile_api_url" "$json_output_file") || echo "$json_output_file" >> "failed.txt"
