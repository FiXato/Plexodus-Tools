#!/usr/bin/env bash
# encoding: utf-8

caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

avatar_files_output_path="$(output_path "all_retrieved_avatar_image_paths${2:-""}")"
"$caller_path/all_avatar_image_urls_from_extracted_json.sh" "$1" "$2" | MAX_RETRIEVAL_RETRIES=1 xargs -I@@ "$caller_path/retrieve_url.sh" "@@" --ignore-errors | tee "$avatar_files_output_path" 1>&2 && echo "$avatar_files_output_path"
