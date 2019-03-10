#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"

declare -A template_variables
template_variables["title"]="Template Title"
template_variables["description"]="Metadata description"
template_variables["body"]="$(cat "$2")"
template_variables["author"]="Filip H.F. &quot;FiXato&quot; Slagter"
template_variables["css_path"]="$3"
parse_template "$caller_path/../templates/layout_$1.html" "template_variables"
