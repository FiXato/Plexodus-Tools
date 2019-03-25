#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

output_dir="data/output/urls/all_from_takeout"
extracted_takeout_directory="extracted/Takeout"

gnugrep -hoPR 'https://plus.google.com/(\+[^/\s"<]+|[0-9]+)/posts/([^/\s;<")\\\x{FEFF}]+)+' extracted |sort -u | tee "$(ensure_path "$output_dir" "all_unique_post_urls_from_takeout.sh")"
gnugrep -hoPR 'https://plus.google.com/(\+[^/\s"<]+|[0-9]+)' extracted |sort -u | tee "$(ensure_path "$output_dir" "all_unique_profile_urls_from_takeout.sh")"
gnugrep -hoPR 'https://plus.google.com/communities/[0-9]+(/[^/\s;<")\\\x{FEFF}]+)*' extracted |sort -u | tee "$(ensure_path "$output_dir" "all_unique_community_urls_from_takeout.sh")"
gnugrep -hoPR 'https://plus.google.com/collections?/[-_a-zA-Z0-9]+(/[^/\s;<")\\\x{FEFF}]+)*' extracted |sort -u | tee "$(ensure_path "$output_dir" "all_unique_collection_urls_from_takeout.sh")"
gnugrep -hoPR 'https://plus.google.com/events/[-_a-zA-Z0-9]+(/[^/\s;<")\\\x{FEFF}]+)*' extracted |sort -u | tee "$(ensure_path "$output_dir" "all_unique_event_urls_from_takeout.sh")"
