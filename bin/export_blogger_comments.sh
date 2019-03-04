#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
source "$caller_path/../lib/functions.sh"
domain="$(domain_from_url "$1")"
echo "Exporting Blogger blog at $domain"

blog_id=$("$caller_path/get_blogger_id.sh" "$1")
complete_blog_data_file="$(ensure_path "data/output" "$domain.json")"
debug "Storing initial data into: $complete_blog_data_file"
echo '{"blog": {"id": "'$blog_id'", "posts": [], "post_urls": []}}' > "$complete_blog_data_file"

blogger_posts_json_files=$("$caller_path/get_blogger_api_post_data_files.sh" "$blog_id")
while read -r blogger_posts_json_file; do
  debug "\n==================================="
  debug "Processing $blogger_posts_json_file"
  data=$(jq '.items' "$blogger_posts_json_file")
  "$caller_path/add_items_to_complete_blog_data_file.sh" "$data" "$complete_blog_data_file" "blog,posts" "$blogger_posts_json_file"

  # Call the script just to make sure the actual URLs files are also saved; a bit redundant perhaps?
  # post_urls=$("$caller_path/get_blogger_post_urls_from_api_post_data_file.sh" "$blogger_posts_json_file")

  last_index="$(echo "$data" | jq 'length - 1')"
  # last_index="1"
  for i in $(seq 0 $last_index); do
    debug "\n--------------------------------"
    debug "Processing blogger post item [$i/$last_index]"
    post_url="$(echo "$data" | jq -r --arg i "$i" '.[$i|tonumber] | .url')"
    exit_code="$?"
    if (( "$exit_code" >= 1 )); then
      input="$(abort_if "a" "Cannot find URL item in data from '${blogger_post_json_file}'. (a)bort, (n)ext item? [a/N]")" && exit 255 || continue
    fi
    debug "Logging post url to .blog .post_urls: $post_url"
    "$caller_path/add_items_to_complete_blog_data_file.sh" "[\"$post_url\"]" "$complete_blog_data_file" "blog,post_urls" "$blogger_posts_json_file"
    
    debug "-"
    debug "Requesting GPlus Comments Widget for: $post_url"
    gplus_widget=$("$caller_path/request_gplus_comments_widget_for_url.sh" "$post_url")
    exit_code="$?"
    if (( "$exit_code" >= 1 )); then
      input="$(abort_if "a" "Error while requesting GPlus Comments Widget for '$post_url' while processing '${blogger_post_json_file}'. (a)bort, (n)ext item? [a/N]")"  && exit 255 || continue
    fi
    "$caller_path/add_items_to_complete_blog_data_file.sh" "\"$gplus_widget\"" "$complete_blog_data_file" "blog,posts,$i,google_plus_comments_widget_file" "$blogger_posts_json_file"
    
    debug "-"
    debug "Retrieving GPlus API Activity IDs from GPlus Comments Widget stored at: $gplus_widget"
    gplus_activity_ids="$("$caller_path/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh" "$gplus_widget")"
    debug "Activity IDs: $gplus_activity_ids"
    activity_ids_data="$(printf "$gplus_activity_ids" | jq -nR '[inputs | select(length>0)]')"
    "$caller_path/add_items_to_complete_blog_data_file.sh" "$activity_ids_data" "$complete_blog_data_file" "blog,posts,$i,activity_ids" "$gplus_widget"
    
    while read -r gplus_activity_id; do
      debug "\n---"
      if [ -z "$gplus_activity_id" -o "$gplus_activity_id" == "" ]; then
        debug "=!= No activity IDs found in GPlus Comments Widget ('$gplus_widget'); maybe comments were made using Blogger's native comments?"
        echo "'$post_url' -> '$gplus_widget'" >> "./logs/blogger-gplus-comments-widgets-without-gplus-api-activity-ids.txt"
        continue
      fi
      debug "Requesting JSON from GPlus Activity API for $gplus_activity_id:"
      gplus_activity_file="$("$caller_path/get_gplus_api_activity_by_gplus_activity_id.sh" "$gplus_activity_id")"
      exit_code="$?"
      if (( "$exit_code" >= 1 )); then
        input=$(abort_if "a" "Error while requesting JSON from GPlus Activity API for Activity with id '$gplus_activity_id' while processing '${blogger_post_json_file}'. (a)bort, (r)etry, (n)ext Activity item? [a/r/N]") && exit 255
        if [ "$input" == 'r' -o "$input" == "R" ]; then
          if [ -f "$gplus_activity_file" ]; then
            rm "$gplus_activity_file"
          fi
          gplus_activity_file="$("$caller_path/get_gplus_api_activity_by_gplus_activity_id.sh" "$gplus_activity_id")"
          if (( "$?" >= 1 )); then
            debug "=!= Failed again; continuing with next item."
            continue
          fi
        else
          continue
        fi
      fi
      setxattr "activity_id" "$gplus_activity_id" "$gplus_activity_file" 1>&2
      setxattr "widget_file" "$gplus_widget" "$gplus_activity_file" 1>&2
      activity_data="$(cat "$gplus_activity_file" | jq -s)"
      "$caller_path/add_items_to_complete_blog_data_file.sh" "$activity_data" "$complete_blog_data_file" "blog,posts,$i,activities" "$gplus_activity_file"
      
      debug "-"
      debug "Checking if we need to request JSON from the GPlus Comments API for Activity '$gplus_activity_file' with ID $gplus_activity_id"
      gplus_comments_file="$("$caller_path/get_gplus_api_comments_by_gplus_activity_file.sh" "$gplus_activity_file")"
      exit_code="$?"
      if (( "$exit_code" >= 1 )); then
        input=$(abort_if "a" "Error while requesting JSON from GPlus Comments API for Activity with id '$gplus_activity_id' while processing '${gplus_activity_file}'. (a)bort, (r)etry, (n)ext Activity item? [a/r/N]") && exit 255
        if [ "$input" == 'r' -o "$input" == "R" ]; then
          if [ -f "$gplus_comments_file" ]; then
            rm "$gplus_comments_file"
          fi
          gplus_comments_file="$("$caller_path/get_gplus_api_comments_by_gplus_activity_file.sh" "$gplus_activity_file")"
          if (( "$?" >= 1 )); then
            debug "=!= Failed again; continuing with next item."
            continue
          fi
        else
          continue
        fi
      fi
      
      if [ -z "$gplus_comments_file" -o "$gplus_comments_file" == "" -o ! -f "$gplus_comments_file" ]; then
        debug "=*= No GPlus Comments File: '$gplus_comments_file'"
        continue
      fi
      setxattr "activity_id" "$gplus_activity_id" "$gplus_comments_file" 1>&2
      setxattr "widget_file" "$gplus_widget" "$gplus_comments_file" 1>&2
      setxattr "activity_file" "$gplus_activity_file" "$gplus_comments_file" 1>&2
      comments_data="$(cat "$gplus_comments_file" | jq -s)"

      # Add to the complete blog data file manually, since we require a target filter
      tmp_file="${complete_blog_data_file}.$(timestamp "iso-8601-seconds")"
      cp "$complete_blog_data_file" "$tmp_file" &&\
        cat "$complete_blog_data_file" | jq --argjson newItems "$comments_data" --arg postsIndex "$i" --arg activityId "$gplus_activity_id" '. as $input | $input | .blog .posts[$postsIndex|tonumber] .activities | map(.id == $activityId)|index(true) as $index | $input | .blog .posts[$postsIndex|tonumber] .activities[$index] .object .replies .comments += $newItems' > "${tmp_file}" &&\
        mv "$tmp_file" "$complete_blog_data_file" || \
        echo "'.blog .posts[$i] .activities[] | select(.id == $gplus_activity_id) | .object .replies .comments ' -> '$gplus_comments_file'" >> "./logs/failed-complete-blog-posts-adds.log" 
      exit_code="$?"
      if (( "$exit_code" >= 1 )); then
        debug "=!= [$exit_code] Error while adding comments to complete blog data file."
      fi
      
      #TODO: retrieve plusoners/resharers
      # Get all self-links: $(cat "$complete_blog_data_file"|jq '. as $source | $source | [.blog .posts[0] .activities[]|path(..)|[.[]|tostring]|select(any(. == "selfLink"))|join(",")]|unique | .[] | [split(",")] as $selflinks | $source .blog .posts[0] .activities[] | [getpath($selflinks[])] | unique | add')
      #TODO: retrieve attachments
      #TODO: cache actors
      #TODO: cache user avatars
      # $(cat "$complete_blog_data_file" | jq '. as $source | $source | [.blog .posts[0] .activities[]|path(..)|[.[]|tostring]|select(.[-1] == "actor")|join(",")]|unique | .[] | [split(",")] as $selflinks | $source .blog .posts[0] .activities[] | [getpath($selflinks[])]')
    done <<< "$gplus_activity_ids"
  done
done <<< "$blogger_posts_json_files"
echo "$complete_blog_data_file"

# Elaborate piping example; will probably gradually be replaced with the stage-wise above approach, so the final results will be in a neat, complete JSON file.
# "$caller_path/get_blogger_post_urls.sh" "$("$caller_path/get_blogger_id.sh" "$1")" | xargs -L 1 "$caller_path/request_gplus_comments_widget_for_url.sh" | xargs -L 1 "$caller_path/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh" | xargs -L 1 "$caller_path/get_gplus_api_activity_by_gplus_activity_id.sh" | xargs -L 1 "$caller_path/get_gplus_api_comments_by_gplus_activity_file.sh"




# #FIXME: make sure the script does this
# mkdir -p "./data/output/$domain/html"
#
#
# #FIXME: Make it so that you aren't basically repeating all these lookups, even though they are cached...
# for filename in $(find "data/comments_frames/$domain/"* )
# do
#   #FIXME: keep track of where you are, so you can abort, and continue again at a later time without having to restart.
#   echo "$filename"
#   echo $(basename "$filename")
#   echo "$filename" | "$caller_path/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh" | "$caller_path/get_comments_from_google_plus_api_by_activity_id.sh" > "data/output/$domain/html/$(basename "$filename")"
# done