#!/usr/bin/env bash
# encoding: utf-8
PT_PATH="${PT_PATH:-"$(realpath "$(dirname "$0")/..")"}"
. "${PT_PATH}/lib/functions.sh"
usage="usage: $(basename "$0") \$blog_id\nExample: $(basename "$0") 12345\nOr: $(basename "$0") \"\$(bin/get_blogger_id.sh https://your.blogger.blog.example)\""
check_help "$1" "$usage" || exit 255
ensure_blogger_api||exit 255

if [ -z "$1" -o "$1" == "" ]; then
  echo -e "$usage" 1>&2
  exit 255
else
  blog_id="$1"
fi

REQUEST_THROTTLE="${REQUEST_THROTTLE:-0}"
PER_PAGE="${PER_PAGE:-500}"
LOG_DIR="${LOG_DIR:-./logs}"
FAILED_FILES_LOGFILE="failed-blogger-post-retrievals.txt"
#TODO: optionally allow fetching bodies too?
api_url="https://www.googleapis.com/blogger/v3/blogs/${blog_id}/posts?key=${BLOGGER_APIKEY}&fetchBodies=false&fetchImages=false&status=live&maxResults=${PER_PAGE}"

function getResponsePath {
  pageToken="$1"
  debug "\$pageToken=${pageToken}"
  pageTokenParam=""
  pathSuffix="-${PER_PAGE}"
  if [ -n "$pageToken" -a "$pageToken" != "" ]; then
    pageTokenParam="&pageToken=$1"
    pathSuffix="${pathSuffix}-${pageToken}"
  fi

  url="$api_url$pageTokenParam"
  debug "API url to call: $url"
  filename="$(buildResponseFilename "$blog_id" "$pathSuffix" "$(timestamp_date)" "json")"
  path="$(ensure_path "data/blog_posts" "$filename")"

  #TODO: Refactor this into a more generic function
  if [ ! -f "$path" ]; then
    debug "Storing Blogger blog post from API $url to $path and sleeping for $REQUEST_THROTTLE seconds."
    sleep $REQUEST_THROTTLE
    filename=$(cache_remote_document_to_file "$url" "$path" "" "$FAILED_FILES_LOGFILE")
    exit_code="$?"
    setxattr "blog_id" "$blog_id" "$path" 1>&2

    if (( $exit_code >= 1 )); then
      debug "=!= getResponsePath: '$url' -> '$path'"
      read -p "Error while retrieving $url - Retry? (y/n)" retry < /dev/tty
      if [ "$retry" == "y" ]; then
        debug "Retrying $url"
        rm "$path"
        filename=$(cache_remote_document_to_file "$url" "$path" "" "$FAILED_FILES_LOGFILE")
        exit_code="$?"
        setxattr "blog_id" "$blog_id" "$path" 1>&2
        if (( $exit_code >= 1 )); then
          debug "=!= getResponsePath failed again: '$url' -> '$path'"
          exit 255
        fi
      else
        exit 255
      fi
    fi

    #FIXME: make sure the file actually contains results.
  else
    debug "Cache hit: Blog posts with page token $pageToken and $PER_PAGE per page, have already been retrieved from $url: to $path"
  fi
  echo "$path"
}

function getPageToken {
  reponsePath="$1"
  if [ -f "$responsePath" ]; then
    debug "Looking for next pageToken: getPageToken(\$responsePath=${reponsePath}) { cat "$responsePath" | jq -r '.nextPageToken' }"
    cat "$responsePath" | jq -r '.nextPageToken'
  fi
}

# Requesting initial page:
responsePath=$(getResponsePath)

aggregatePath="data/blog_posts/$(buildResponseFilename "$blog_id" "" "$(timestamp_date)" "json")"
echo '{}' > "$aggregatePath"
while :
do
  echo "$responsePath"

  # Need to use an intermediate file, or else I'm getting escaping issues for some reason.
  backup_file="${aggregatePath}.$(timestamp "%Y%m%d-%H%M%S")"
  cp "$aggregatePath" "$backup_file" && \
  debug "Merging $responsePath into $backup_file" && \
  jq --argjson newItems "$(jq -s '.[].items' "$responsePath")" '.items += $newItems' "$backup_file" > "$aggregatePath"
  exit_code="$?"
  if (( $exit_code >= 1 )); then
    debug "[$0] Exit code $exit_code trying to merge"
    #leave the intermediate file for manual debugging.
    break
  else
    rm "$backup_file" 1>&2
  fi
  debug "Merged"

  # Check if there is another page; if you crawled the last page previously, then there won't be an .items item.
  items=$(cat "$responsePath" | jq -rc '.items')
  exit_code="$?"
  if (( $exit_code >= 1 )); then
    echo "[$0] Exit code $exit_code while looking for an .items item in $responsePath"
    break
  fi

  if [ -z "$items" -o "$items" == null -o "$items" == "" ]; then
    break
  fi
  

  # Look up the next pageToken from the JSON result
  pageToken=$(getPageToken "$responsePath")
  debug "Next pageToken: $pageToken"
  if [ -z "$pageToken" -o "$pageToken" == null -o "$pageToken" == "" ]; then
    break
  fi

  # Retrieve the next page of JSON results
  responsePath=$(getResponsePath "$pageToken")

  # Optional throttling in seconds
  sleep $REQUEST_THROTTLE
done
debug "Saved all post JSON data files to: $aggregatePath"