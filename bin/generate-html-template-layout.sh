#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"

declare -A template_variables
template_variables["title"]="Template Title"
template_variables["description"]="Metadata description"
template_variables["body"]="$(cat "$2")"
template_variables["author"]="Filip H.F. &quot;FiXato&quot; Slagter"
template_variables["css_path"]="$3"
parse_template "$PT_PATH/templates/layout_$1.html" "template_variables"
