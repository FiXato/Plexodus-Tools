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

while IFS= read -r -d '' line; do
  remote_url="${line%%$'\u001F'*}"
  local_filepath="${line//*$'\u001F'}"
  if [ "$local_filepath" != "" ]; then
    if [ -f "$local_filepath" ]; then
      echo "$local_filepath"
    else
      debug "${FG_MAGENTA}Local file '$local_filepath' does not exist"
      downloaded_fps="$("$PT_PATH/bin/retrieve_googleusercontent_url.sh" "$remote_url")"
      exit_code="$?"
      if (( $exit_code == 0 )); then
        downloaded_fp="$(realpath "${downloaded_fps//*$'\n'}")"
        debug "downloaded filepath: '$downloaded_fp'"
        debug "target filepath: '$local_filepath'"
        [ -f "$local_filepath" ] && debug "file '$local_filepath' exists"
        link_file "$downloaded_fp" "$local_filepath"
        exit_code="$?"
        debug "exit_code: $exit_code"
        if (( $exit_code == 0 ));then
          debug "linking succeeded"
          realpath --no-symlinks "$local_filepath"
        else
          debug "linking exited with $exit_code"
          echo "$downloaded_fp"
        fi
      else
        error "Error while retrieving $remote_url"
        echo "$remote_url"
      fi
    fi
    continue
  fi
  echo "$remote_url"
  # printf 'remote: "%s"\nlocal: %s\n\n' "$remote_url" "$local_filepath"
done < <(find "${takeout_posts_paths[@]/%/\/Takeout\/Google+ Stream\/Posts\/}" -iname '*.json' -type f -exec jq -L "${PT_PATH}" -r --arg source_file "{}" 'include "plexodus-tools"; get_all_resource_urls_and_local_filepaths | map(.[0] as $remote| .[1] as $local| [$remote, (if $local|length > 0 then ($source_file|gsub("/[^/]+$"; "") + $local) else "" end)]|join("\u001F")) | join("\u0000")' '{}' \;)

#gnugrep -v '^$' | gnused 's/^\/\//https:\/\//' | sort -u | "${XARGS_CMD}" -I@@ "${PT_PATH}/bin/retrieve_googleusercontent_url.sh" "@@"
