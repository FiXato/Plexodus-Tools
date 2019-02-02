#!/usr/bin/env bash
# encoding: utf-8
URL="https://www.googleapis.com/blogger/v3/blogs/byurl?url=$1&key=$BLOGGER_APIKEY"
curl -s "$URL"|jq -r '.id'
