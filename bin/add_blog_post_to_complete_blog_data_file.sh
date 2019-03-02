#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
blog_post_data_file="$1"
complete_blog_data_file="$2"
tmp_file="${complete_blog_data_file}.$(timestamp "iso-8601-seconds")"
cp "$complete_blog_data_file" "$tmp_file" &&\
jq --argjson newItems "$(jq -s '.[0] .items' "$blog_post_data_file")" '.blog .posts += $newItems' "$tmp_file" > "${complete_blog_data_file}" &&\
rm "$tmp_file"
