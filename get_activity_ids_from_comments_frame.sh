#!/usr/bin/env bash
# encoding: utf-8
source _functions.sh
stdin=$(cat)
while IFS= read -r blog_comments_frame_file
do
  gnugrep -oP '^,"\K([a-z0-9]{22,})"' "$blog_comments_frame_file" | tr -d '"' | sort -u
done <<< "$stdin"
# < "${1:-/dev/stdin}"