#!/usr/bin/env bash
# encoding: utf-8

PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

avatar_files_output_path="$(output_path "all_retrieved_avatar_image_paths${2:-""}")"
"$PT_PATH/bin/all_avatar_image_urls_from_extracted_json.sh" "$1" "$2" | MAX_RETRIEVAL_RETRIES=1 xargs -I@@ "$PT_PATH/bin/retrieve_url.sh" "@@" --ignore-errors | tee "$avatar_files_output_path" 1>&2 && echo "$avatar_files_output_path"
