#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

output_dir="$PLEXODUS_OUTPUT_DIR_ALL_FROM_TAKEOUT"
extracted_takeout_directory="$PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH/Takeout"

gnugrep -hoPR 'https://plus.google.com/(\+[^/\s"<]+|[0-9]+)/posts/([^/\s;<")\\\x{FEFF}]+)+' "$extracted_takeout_directory" | sort -u | tee "$(ensure_path "$output_dir" "all_unique_post_urls_from_takeout.txt")"
gnugrep -hoPR 'https://plus.google.com/(\+[^/\s"<]+|[0-9]+)' "$extracted_takeout_directory" | sort -u | tee "$(ensure_path "$output_dir" "all_unique_profile_urls_from_takeout.txt")"
gnugrep -hoPR 'https://plus.google.com/communities/[0-9]+(/[^/\s;<")\\\x{FEFF}]+)*' "$extracted_takeout_directory" | sort -u | tee "$(ensure_path "$output_dir" "all_unique_community_urls_from_takeout.txt")"
gnugrep -hoPR 'https://plus.google.com/collections?/[-_a-zA-Z0-9]+(/[^/\s;<")\\\x{FEFF}]+)*' "$extracted_takeout_directory" | sort -u | tee "$(ensure_path "$output_dir" "all_unique_collection_urls_from_takeout.txt")"
gnugrep -hoPR 'https://plus.google.com/events/[-_a-zA-Z0-9]+(/[^/\s;<")\\\x{FEFF}]+)*' "$extracted_takeout_directory" | sort -u | tee "$(ensure_path "$output_dir" "all_unique_event_urls_from_takeout.txt")"
