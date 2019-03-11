#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
data="$1"
complete_blog_data_file="$2"
new_items_jq_path="$3"
input_file="$4"
tmp_file="${complete_blog_data_file}.$(timestamp "%Y%m%d-%H%M%S")"
# debug "data: '$data'\nblog data file: '$complete_blog_data_file'\ntmp path: '$tmp_file'\njq path: '$new_items_jq_path'"
cp "$complete_blog_data_file" "$tmp_file" &&\
  cat "$tmp_file" | jq --argjson newItems "$data" --arg newItemsPath "$new_items_jq_path" 'def is_numeric: . as $raw | try tonumber catch $raw; def getpathFromArg(arg): getpath(arg|split(",")|map(is_numeric)); getpathFromArg($newItemsPath) += $newItems' > "${complete_blog_data_file}" || echo "'$new_items_jq_path' -> '$input_file'" >> "./logs/failed-complete-blog-posts-adds.log" &&\
  rm "$tmp_file"