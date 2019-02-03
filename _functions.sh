#!/usr/bin/env bash
# encoding: utf-8

#FIXME: move this to an variables.env file
REQUEST_THROTTLE="${REQUEST_THROTTLE:-0}"

function gnused() {
  if hash gsed 2>/dev/null; then
      gsed -E "$@"
  else
      sed -E "$@"
  fi
}
#export -f gnused

function gnugrep() {
  if hash ggrep 2>/dev/null; then
      ggrep "$@"
  else
      grep "$@"
  fi
}
#export -f gnugrep

function sanitise_filename() {
  gnused 's/[^-a-zA-Z0-9_.]/-/g'
}


function domain_from_url() {
  echo "$1" | gnused 's/https?:\/\/([^/]+)\/.+/\1/g'
}

function path_from_url() {
  echo "$1" | gnused 's/https?:\/\/([^/]+)\/(.+)$/\2/g'
}

function ensure_path() {
  if [ -z "$1" -o "$1" == "" ]; then
    echo "ensure_path called with an undefined path \$1" 1>&2
    exit 255
  elif [ -z "$2" -o "$2" == "" ]; then
    echo "ensure_path called with an undefined filename \$2" 1>&2
    exit 255
  else
    mkdir -p "$1"
    echo "$1/$2"
  fi
}

function ensure_blogger_api() {
  if [ -z "$BLOGGER_APIKEY" -o "$BLOGGER_APIKEY" == "" ]; then
    echo "This command requires access to the Blogger API, but ENVironment variable BLOGGER_APIKEY is not set. Please set it to your Blogger API v3 API key." 1>&2
    exit 255
  fi
}

function check_help() {
  if [ -n "$1" -a "$1" == "--help" ]; then
    if [ -z "$2" -o "$2" == "" ]; then
      echo -e "Usage: $(basename "$0")\nUsage definition undefined" 1>&2
      exit 255
    fi
    echo -e "$2"
    exit 0
  fi
}

function timestamp_date() {
  date +"%y-%m-%d"
}

function debug() {
  if [ "$DEBUG" == "1" -o "$DEBUG" == "true" -o "$DEBUG" == "TRUE" ]; then
    echo -e "$1" 1>&2
  fi
}

function activity_file() {
  activity_id="$1"
  if [ "$activity_id" == "" ]; then
    echo "activity_file() called with an undefined activity_id \$1" 1>&2
    exit 255
  else
    activity_filepath="$(ensure_path "./data/gplus/activities" "$activity_id.json")"
    debug "Filepath for Activity Resource $activity_id: $activity_filepath"
    echo "$activity_filepath"
  fi
}


function comments_file() {
  activity_id="$1"
  if [ "$activity_id" == "" ]; then
    echo "comments_file() called with an undefined activity_id \$1" 1>&2
    exit 255
  else
    comments_filepath="$(ensure_path "./data/gplus/activities/$activity_id" "comments.json")"
    debug "Filepath for Comments Resource List for Activity with id $activity_id: $comments_filepath"
    echo "$comments_filepath"
  fi
}



