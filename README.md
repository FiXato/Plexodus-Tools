# Plexodus-Tools
A collection of tools to process the Google Plus-related data from Google Takeout.

Copyright (C) 2018 Filip H.F. "FiXato" Slagter

## Google+ Shutting down April 2019
With the [announcement of Google+ shutting its doors for consumers](https://www.blog.google/technology/safety-security/project-strobe/), and the [second announcement of Google+ expediting its shutdown](https://www.blog.google/technology/safety-security/expediting-changes-google-plus/), those of us who've accumulated a large collection of posts and other data over the lifetime of the platform, are in need of tools to process the data archives that Google are providing us through [Google Takeout](https://takeout.google.com), and possibly live data through the [Google+ API](https://developers.google.com/+/web/api/rest/).
With the shutdown originally being scheduled for August 2019, but following the second announcement, expedited to April 2nd, 2019, and the Google+ APIs being turned off even sooner, on Sunday March 7th, 2019 at the latest, time is quickly running out.

This repository will hopefully provide some of those tools.

## Extract files from a Zip/Zip64 archive
If your (Takeout) Zip-archive is greater than 2GB, and has to be extracted on a platform that doesn't support extracting zip64 files natively, I suggest you install [p7zip](http://p7zip.sourceforge.net/), a port of [7-Zip](https://www.7-zip.org/) for POSIX systems. On macOS the easiest would be to install it through [Homebrew](https://brew.sh) with `brew install p7zip`. Once (p)7-Zip has been installed, you can extract all files while retaining their directory structure with:
```bash
7z x takeout-20181025T124927Z-001.zip
```

If you want to just extract the JSON files, you can use this instead:
```bash
7z x takeout-20181025T124927Z-001.zip '*.json' -r
```

To extract them to a different directory (while retaining their directory structure):
```bash
7z x takeout-20181025T124927Z-001.zip '*.json' -r -o/path/to/output/dir/
```

To extract them to a different directory (without creating sub-directories):
```bash
7z e takeout-20181025T124927Z-001.zip '*.json' -r -o/path/to/output/dir/
```

Extract all `*.json`, `*.html`, `*.csv`, `*.vcf` and `*.ics` files from multi-part Zip-archives:

```bash
7z x -an -ai'!takeout-20181111T153533Z-00*.zip' '*.json' '*.html' '*.csv' '*.vcf' '*.ics' -r -oextracted/2018-11-11/
```

### Explanation of commonly used arguments and flags for `7z` command:

Argument          | Explanation
-----------------:|:-----------------
`e`               | Extract archive into current folder, *without* retaining folder structure.
`x`               | eXtract archive while retaining folder structure.
`t`               | Test (matched) contents of archive.
`l`               | List (matched) contents of archive.
`-an`             | No Archive Name matching. Recommended since we're doing a 'wildcard' archive match with `-ai!`.
`-ai`             | Use Archive Include to define the input archives.<br/> We're wrapping the (masked/wildcarded) filename in quotes to prevent shell interpretation of the exclamation (!) mark.<br/> The filename is prefixed with an exclamation (`!`) mark to allow for wildcards with the asterisk (`*`) character.
`-r`              | Recurse through the archive. Needed to match the wildcard filename patterns through the entire archive.
`-o`              | Specify Output path. Files will be extracted with this folder as their root folder.<br/> It should be directly followed by the path; no space between the flag (`-o`) and the path (`extracted/2018-11-11`).<br/> If the path does not exist yet, it will be automatically created.
`*.json`          | apply archive operation on archived files matching `*.json` (JavaScript Object Notation) filename pattern.
`*.html`          | apply archive operation on archived files matching `*.html` (HyperText Markup Language) filename pattern.
`*.csv`           | apply archive operation on archived files matching `*.csv` (Comma Separated Values) filename pattern.
`*.vcf`           | apply archive operation on archived files matching `*.vcf` (Virtual Contact File vCards) filename pattern.
`*.ics`           | apply archive operation on archived files matching `*.ics` (Internet Calendaring and Scheduling) filename pattern.

## Filtering JSON data with a jq library
One of those tools is [plexodus-tools.jq](plexodus-tools.jq), a library of filter methods for the excellent commandline JSON processor [jq](https://github.com/stedolan/jq). With the library you'll be able to chain filters and sort methods to limit your Google+ Takeout JSON files to a subset of data you can then pass on to other tools or services.
For instance, it will allow you to limit your Activity data to just public posts, or those with comments or other interactions with one or more specific users.

### Combine all the JSON activity files into a single file
It's useful to combine all the separate JSON activity files into a single JSON file:
```bash
jq -s '.' "Takeout/Google+ Stream/Posts/*.json" > combined_activities.json
```

If you run into the 'argument list too long' error, you can instead use this solution:
```bash
gfind 'Takeout/Google+ Stream/Posts/' -iname '*.json' -exec cat {} + | jq -s '.' > combined_activities.json
```
_(Using `gfind` rather than `find` to indicate I'm using GNU's `find` which I've installed through Homebrew, rather than the default BSD `find` available on macOS._

This way you can directly use this single file for your future `jq` filter commands.

### How to use the library
```bash
jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools"; . ' /path/to/combined_activities.json
```

You specify the directory in which the `plexodus-tools.jq` library is located with: `-L /path/to/Plexodus-Tools/` and then load it by specifying `include "plexodus-tools";` before your actual jq query.

#### Filter Methods:
Filter Name                         | Description
-----------------------------------:| :-----------------------------------
`not_empty`                         | Exclude empty results
`with_comments`                  | Only return Activity results that have Comments
`without_comments`            | Only return Activity results that lack any Comments
`with_image`                       | Only return Activity results that have an Image Attachment
`with_video`                       | Only return Activity results that have a Video Attachment
`with_audio`                       | Only return Activity results that have an Audio Attachment
`with_media`                       | Only return Activity results that have any kind of Media Attachment
`without_media`                 | Exclude Activity items without any kind of Media Attachment from the results 
`has_legacy_acl`               | Only return Activity results whose `postAcl` contains an `isLegacyAcl` item.
`has_collection_acl`        | Only return Activity results whose `postAcl` contains a `collectionAcl` item.
`has_community_acl`          | Only return Activity results whose `postAcl` contains a `communityAcl` item.
`has_event_acl`                  | Only return Activity results whose `postAcl` contains an `eventAcl` item.
`has_circle_acl`                | Only return Activity results whose `postAcl`.`visibleToStandardAcl` contains a `circles` item.
`has_public_circles_acl` | Only return Public Activity results; i.e. those that have `CIRCLE_TYPE_PUBLIC` as `visibleToStandardAcl` 'circle' type.
`is_public`                          | For now an alias for `has_public_circles_acl`.<br/> Note that this might not (yet) include posts that were posted to public Collections or publicly accessible Communities; this may change in the future.
`has_extended_circles_acl` | Only return Extended Circled Activity results; i.e. those that have `CIRCLE_TYPE_EXTENDED_CIRCLES` as `visibleToStandardAcl` 'circle' type. These are posts that were set to only be visible to your 'Extended Circles'.
`has_own_circles_acl`       | Only return Private Activity results; i.e. those that have `CIRCLE_TYPE_YOUR_CIRCLES` as `visibleToStandardAcl` 'circle' type. These are posts that were set to only be visible to your 'Your Circles'.
`has_your_circles_acl`     | Alias for `has_own_circles_acl`.
`with_interaction_with(displayNames)` | Only return Activity items that have some form of interaction with users whose `displayName` is an exact match for one of the specified displayNames. `displayNames` can be either a string, or an array of strings.
`with_comment_by(displayNames)`   | Only return Activity items as results when they have Comments by any of the users whose `displayName` is an exact match for one of the specified displayNames. `displayNames` can be either a string, or an array of strings.
`url_from_domain(domains)`            | Only return Activity results with url items that match any of the specified `domains`. `domains` can be either a string, or an array of strings.
`from_collection(displayNames)`| Only return Activity results that were posted to a Collection of which the `displayName` is an exact match for one of the specified displayNames. The supplied `displayNames` can be either a string, or an array of strings. Note that collections by different owners could have the same name. If you only want to match activities in a specific collection, you'll have to find its resourceName and use that with the `from_collection_with_resource_name(resourceNames)` filter instead.
`from_collection_with_resource_name(resourceNames)`| Similar to `from_collection`, but rather than compare to the `displayName` of the Collection, compares items to the unique `resourceName` instead. 
`from_collection_with_resource_id(resourceNames)`| Similar to `from_collection_with_resource_name`, but only needs a `resourceId` rather that the `resourceName`; i.e. it doesn't need the `collections/` prefix.
`sort_by_creation_time`          | Sort results by the Activity's `creationTime`.
`sort_by_update_time`              | Sort results by the Activity's `updateTime`.
`sort_by_last_modified`          | Alias for `sort_by_update_time`.
`sort_by_url`                             | Sort results by the Activity's `url` item.
`sort_activity_log_by_ts`      | Sort ActivityLog items by their `timestampMs` timestamp item.
`get_circles`                            | Get list of all unique circles items from the current results.
`get_all_circle_types`           | Get list of all unique circle types from the current results.
`get_all_circle_display_names`| Get list of all unique circle displayNames from the current results.
`get_all_circle_resource_names`| Get list of all unique circle resourceNames from the current results.
`get_all_acl_keys`                  | Get list of all unique Access Control List keys from the current results.
`get_all_community_names`     | Get list of all unique Community displayNames from the current results.
`get_all_collection_names`   | Get list of all unique Collection displayNames from the current results.
`get_all_event_resource_names` | Get list of all unique Event resourceNames from the current results.
`get_all_media_content_types`| Get list of all unique media content-types from the current results.

#### Examples
Return just the activities that are marked as 'public', and have comments by a user whose displayName is `FiXato`, and sort the results by the creation time of the Actvity:

```bash
jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools"; . | is_public | with_comment_by("FiXato") | sort_by_creation_time' combined_activities.json
```

Return just the activities that have any kind of interaction with a users whose displayName is either `FiXato` or `Filip H.F. Slagter`, have some form of media attachment, and sort the results by the last modified (updateTime) time of the Actvity:

```bash
jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools"; . | with_interaction_with(["FiXato", "Filip H.F. Slagter"]) | with_media | sort_by_last_modified' combined_activities.json
```

Return just the activities that were posted to a Collection with the name `Google Plus Revisited` and sort by their creation time:

```bash
jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools"; . | from_collection("Google Plus Revisited") | sort_by_creation_time' combined_activities.json
```

Get a list of all the unique Circle types in your JSON archive:
```bash
jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools";get_all_circle_types' combined_activities.json
```

The result of this is likely:
```json
[
  "CIRCLE_TYPE_EXTENDED_CIRCLES",
  "CIRCLE_TYPE_PUBLIC",
  "CIRCLE_TYPE_USER_CIRCLE",
  "CIRCLE_TYPE_YOUR_CIRCLES"
]
```

## Get all file extensions from archives

Just the last file extension:

```bash
7z l -an -ai'!takeout-20181111T153533Z-00*.zip' | gsed -E 's/\s+/ /g' | gcut -d' ' -f1,2,3,4,5 --complement | ggrep -E -o '\.([^.]+)$' | sort -u
```

Up to the last 3 file extensions, of which the first 2 can be at most 4 characters long, while the last (primary) file extension can be of arbitrary length:

```bash
7z l -an -ai'!takeout-20181111T153533Z-00*.zip' | gsed -E 's/\s+/ /g' | gcut -d' ' -f1,2,3,4,5 --complement | ggrep -E -o '(\.[^.]{1,4}){0,2}\.([^.]+)$' | sort -u
```

_Note: I'm using `gsed`, `gcut` and `ggrep` here to indicate I'm using the GNU versions of the utilities, rather than the BSD versions supplied by macOS. These versions can be installed (and linked with `g`-prefixes) through Homebrew on macOS. For instance with `brew install sed cut grep`. On other platforms such as Linux and Windows Cygwin, you're likely installing the GNU versions anyway._

## Export to other formats
Some of the other tools will assist in converting the (filtered) data to other formats, such as for instance HTML, or possibly Atom of json-ld, for import into other platforms.


## License
This project is [licensed under the terms of the GPLv3 license](LICENSE).

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a [copy](LICENSE) of the GNU General Public License
along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
