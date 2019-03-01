#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
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
api_url="https://www.googleapis.com/blogger/v3/blogs/${blog_id}/posts?key=${BLOGGER_APIKEY}&fetchBodies=false&fetchImages=false&status=live&maxResults=${PER_PAGE}"

function buildResponseFilename {
  blog_id="$1"
  pathSuffix="$2"
  timestamp="$3"
  extension="$4"
  echo "${blog_id}${pathSuffix}-${timestamp}.${extension}"
}

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
  path="$(ensure_path "data/blog_post_urls" "$filename")"
  if [ ! -f "$path" ]; then
    debug "Retrieving $url and caching the JSON at $path"
    curl "$url" > "$path"
  else
    debug "Local cached copy already present: $path"
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

while :
do
  # Check if there is another page; if you crawled the last page previously, then there won't be an .items item.
  items=$(cat "$responsePath" | jq -rc '.items')
  if [ -z "$items" -o "$items" == null -o "$items" == "" ]; then
    break
  fi
  
  debug "Found the following URLs:"
  cat "$responsePath" | jq -rc '.items[] | .url' || (echo "${0}: Error while retrieving urls for $responsePath" 1>&2 && exit 255)

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
aggregatePath="data/blog_post_urls/$(buildResponseFilename "$blog_id" "-${PER_PAGE}" "$(timestamp_date)" "txt")"
cat "data/blog_post_urls/${blog_id}-${PER_PAGE}"*"-$(timestamp_date).json" | jq -rc '.items[] | .url' > "$aggregatePath" || (echo "${0}: Error while saving all post urls for $aggregatePath for blog with id ${blog_id} with ${PER_PAGE} items per page, cached on $(timestamp_date)" 1>&2 && exit 255)
debug "Saved all post urls to: $aggregatePath"