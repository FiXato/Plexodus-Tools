# Plexodus-Tools
A collection of tools to process the Google Plus-related data from Google Takeout.

Copyright (C) 2018 Filip H.F. "FiXato" Slagter

## Google+ Shutting down August 2019
With the [announcement of Google+ shutting its doors for consumers](https://www.blog.google/technology/safety-security/project-strobe/), those of us who've accumulated a large collection of posts and other data over the lifetime of the platform, are in need of tools to process the data archives that Google are providing us through [Google Takeout](https://takeout.google.com), and possibly live data through the Google+ API.
This repository will hopefully provide some of those tools.

## Extract files from a Zip/Zip64 archive
If your Zip-archive is greater than 2GB, and has to be extracted on a platform that doesn't support extracting zip64 files natively, I suggest you install [p7zip](http://p7zip.sourceforge.net/), a port of [7-Zip](https://www.7-zip.org/) for POSIX systems. On macOS the easiest would be to install it through [Homebrew](https://brew.sh) with `brew install p7zip`. Once (p)7-Zip has been installed, you can extract all files while retaining their directory structure with:

`7z x takeout-20181025T124927Z-001.zip`

If you want to just extract the JSON files, you can use this instead:

`7z x takeout-20181025T124927Z-001.zip *.json -r`

To extract them to a different directory (while retaining their directory structure):

`7z x takeout-20181025T124927Z-001.zip *.json -r -o/path/to/output/dir/`

To extract them to a different directory (without creating sub-directories):

`7z e takeout-20181025T124927Z-001.zip *.json -r -o/path/to/output/dir/`

## Filtering JSON data with a jq library
One of those tools is [plexodus-tools.jq](plexodus-tools.jq), a library of filter methods for the excellent commandline JSON processor [jq](https://github.com/stedolan/jq). With the library you'll be able to chain filters and sort methods to limit your Google+ Takeout JSON files to a subset of data you can then pass on to other tools or services.
For instance, it will allow you to limit your Activity data to just public posts, or those with comments or other interactions with one or more specific users.

### Combine all the JSON activity files into a single file
It's useful to combine all the separate JSON activity files into a single JSON file:

`jq -s '.' "Takeout/Google+ Stream/Posts/*.json" > combined_activities.json`

This way you can directly use this single file for your future `jq` filter commands.

### How to use the library
`jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools";.' /path/to/combined_activities.json`

You specify the directory in which the `plexodus-tools.jq` library is located with: `-L /path/to/Plexodus-Tools/` and then load it by specifying `include "plexodus-tools";` before your actual jq query.

#### Filter Methods:
Filter Name | Description
----------- | -----------
`not_empty` | Exclude empty results
`withComments` | Only return Activity results that have Comments
`withImage` | Only return Activity results that have an Image Attachment
`withVideo` | Only return Activity results that have a Video Attachment
`withAudio` | Only return Activity results that have an Audio Attachment
`withMedia` | Only return Activity results that have any kind of Media Attachment
`withoutMedia` | Exclude Activity items without any kind of Media Attachment from the results 
`isPublic` | Only return Public Activity results; i.e. those that have `CIRCLE_TYPE_PUBLIC` as `visibleToStandardAcl` 'circle' type.` `withInteractionWith(displayNames)` | Only return Activity items that have some form of interaction with users whose `displayName` is an exact match for one of the specified displayNames. `displayNames` can be either a string, or an array of strings.
`withCommentBy(displayNames)` | Only return Activity items as results when they have Comments by any of the users whose `displayName` is an exact match for one of the specified displayNames. `displayNames` can be either a string, or an array of strings.
`urlFromDomain(domains)` | Only return Activity results with url items that match any of the specified `domains`. `domains` can be either a string, or an array of strings.
`sort_by_creation_time` | Sort results by the Activity's `creationTime`.
`sort_by_update_time` | Sort results by the Activity's `updateTime`.
`sort_by_last_modified` | Alias for `sort_by_update_time`.
`sort_by_url` | Sort results by the Activity's `url` item.
`sort_activity_log_by_ts` | Sort ActivityLog items by their `timestampMs` timestamp item.

#### Examples
Return just the activities that are marked as 'public', and have comments by a user whose displayName is "FiXato", and sort the results by the creation time of the Actvity:

`jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools";.|isPublic|withCommentBy("FiXato")|sort_by_creation_time' combined_activities.json`

Return just the activities that have any kind of interaction with a users whose displayName is either "FiXato" or "Filip H.F. Slagter", have some form of media attachment, and sort the results by the last modified (updateTime) time of the Actvity:

`jq -L /path/to/Plexodus-Tools/ 'include "plexodus-tools";.|withInteractionWith(["FiXato", "Filip H.F. Slagter"])|with_media|sort_by_last_modified' combined_activities.json`

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