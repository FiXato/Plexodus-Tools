#!/usr/bin/env bash
# encoding: utf-8
PER_PAGE=500
BASE_URL="https://www.googleapis.com/blogger/v3/blogs/$1/posts?key=$BLOGGER_APIKEY&fetchBodies=false&fetchImages=false&status=live&maxResults=$PER_PAGE"
#echo $BASE_URL

function getResponse {
  [ -z "$1" ] && pageToken="" || pageToken="&pageToken=$1"
  url="$BASE_URL$pageToken"
  curl -s "$url" > ./last_curl.json && cat last_curl.json
}

function getPageToken {
  if [ -z "$1" ]
  then
    ""
  else
#    $(echo "$1" | jq -r '.nextPageToken')
    jq -r '.nextPageToken' ./last_curl.json
  fi
}

#echo "Requesting initial page:"
response=$(getResponse)
#echo "First response:"
#echo "$response"

while :
#[ pageToken=$(getPageToken $response) ]
do
  jq -rc '.items[]|.url' ./last_curl.json

  pageToken=$(getPageToken $response)
#  echo "Next Page token: $pageToken"
  if [ -z "$pageToken" -o "$pageToken" == null ]
  then
    break
  fi

  #echo "Looking up next page:"
  reponse=$(getResponse $pageToken)
#  sleep 1
done

