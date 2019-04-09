#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
LINK_FILES=${LINK_FILES:-"hard"} #hard, soft, skip
source "${PT_PATH}/lib/functions.sh"
IFS='' read -r -d '' usage <<EOSTRING
# ${TP_BOLD}${TP_UON}Get all media files that have a URL but no local filepath, or where the local file could not be found.${TP_RESET}
# ${TP_BOLD}usage:${TP_RESET} bin/$(basename "$0") [[/path/to/first/extracted/takeout/parent/directory] [/path/to/second/extracted/takeout/parent/directory] [/path/to/nth/extracted/takeout/parent/directory]]
#
# Paths support globbing, for instance if you've extracted multiple archives in a structure like 'extracted/\$profileName/\$date/', you can use:
# ${TP_BOLD} bin/$(basename "$0") extracted/*/* ${TP_RESET}
EOSTRING
check_help "$1" "$usage" || exit $?

declare -a takeout_parent_paths=()
if [ "$1" != "" ]; then
  takeout_posts_paths+=("${@}")
else
  takeout_posts_paths+=("${PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH}")
fi

#   find "${takeout_posts_paths[@]/%/\/Takeout\/Google+ Stream\/Posts\/}" -iname '*.json' -type f -exec jq -r '.album .media//[] | .[] .localFilePath//"" | gsub("/[^/]+$"; "")' '{}' \; | grep -v '^$'
#
# exit

link_file() {
  debug "LINK_FILES: '$LINK_FILES'"
  [ "$LINK_FILES" == "skip" -o "$LINK_FILES" == "" ] && return 1
  [ "$1" == "" ] && error "You need to specify a file to link from" && return 1
  [ "$2" == "" ] && error "You need to specify a path to link to" && return 1
  [ ! -f "$1" ] && error "Source file doesn't exist" && return 1
  [ -f "$2" ] && error "Target file already exists" && return 1
  target_dirname="$(dirname "$2")"
  [ "$target_dirname" != "" -a ! -d "$target_dirname/" ] && mkdir -p "$target_dirname" && debug "created $target_dirname" 
  if [ "$LINK_FILES" == "hard" ] && on_same_device "$1" "$target_dirname"; then
    debug "Trying to hardlink"
    ln "$1" "$2"
  else
    debug "trying to symlink"
    ln -s "$1" "$2"
  fi
}

declare -a items=()
total_results="$(find "${takeout_posts_paths[@]/%/\/Takeout\/Google+ Stream\/Posts\/}" -iname '*.json' -type f -print0 2> /dev/null | "$GREP_CMD" -cz '^')"
while IFS= read -r -d '' json_source_fp || [ -n "$json_source_fp" -a "$json_source_fp" != "" ]; do
  debug "JSON [$((counter+=1))/$total_results]: $json_source_fp"
  total_media_items="$(jq -r '.album .media | length' "$json_source_fp")"
  media_counter=0
  while IFS= read -r -d '' line || [ -n "$line" -a "${line//$'\n'/}" != "" ]; do
    items=()
    split "$line" items $'\u001F' > /dev/null 2>&1
    remote_url="${items[0]}"
    local_filepath="${items[1]}"
    debug "[$((media_counter+=1))/$total_media_items]${FG_MAGENTA}Remote: '$remote_url'
${FG_MAGENTA}Local: '$local_filepath'${TP_RESET}"

    if [ "$local_filepath" != "" ]; then
      if [ -f "$local_filepath" ]; then
        debug "\$local_filepath '$local_filepath' already exists"
        echo "$local_filepath"
      else
        debug "${FG_MAGENTA}Local file '$local_filepath' does not exist"
        downloaded_fps="$("$PT_PATH/bin/retrieve_googleusercontent_url.sh" "$remote_url")"
        exit_code="$?"
        if (( $exit_code == 0 )); then
          downloaded_fp="$(realpath "${downloaded_fps//*$'\n'}")"
          setxattr "json_source" "$json_source_fp" "$downloaded_fp" 1>&2

          [ -f "$local_filepath" ] && debug "file '$local_filepath' exists"
          link_file "$downloaded_fp" "$local_filepath"
          exit_code="$?"
          if (( $exit_code == 0 ));then
            debug "linking succeeded: $downloaded_fp -> $local_filepath"
            realpath --no-symlinks "$local_filepath"
          else
            debug "linking exited with $exit_code"
            echo "$downloaded_fp"
          fi
        else
          error "[\$?=$exit_code] Error while retrieving $remote_url"
          echo "$remote_url"
        fi
      fi
      continue
    fi
    #TODO: also download this, and perhaps add the reference to the local file path to the source JSON
    debug "No local filepath specified. Returning \$remote_url"
    echo "$remote_url"
    # printf 'remote: "%s"\nlocal: %s\n\n' "$remote_url" "$local_filepath"
  done < <(jq -L "${PT_PATH}" -r --arg source_file "$json_source_fp" 'include "plexodus-tools"; get_all_resource_urls_and_local_filepaths | map(.[0] as $remote| .[1] as $local| [$remote, (if $local|length > 0 then ($source_file|gsub("/[^/]+$"; "") + $local) else "" end)]|join("\u001F")) | join("\u0000")' "$json_source_fp")
done < <(find "${takeout_posts_paths[@]/%/\/Takeout\/Google+ Stream\/Posts\/}" -iname '*.json' -type f -print0)

#gnugrep -v '^$' | gnused 's/^\/\//https:\/\//' | sort -u | "${XARGS_CMD}" -I@@ "${PT_PATH}/bin/retrieve_googleusercontent_url.sh" "@@"
