# Plexodus-Tools
A collection of tools to process the Google Plus-related data from Google Takeout.

## Google+ Shutting down August 2019
With the [announcement of Google+ shutting its doors for consumers](https://www.blog.google/technology/safety-security/project-strobe/), those of us who've accumulated a large collection of posts and other data over the lifetime of the platform, are in need of tools to process the data archives that Google are providing us through Google Takeout, and possibly live data through the Google+ API.
This repository will hopefully provide some of those tools.

## Filtering JSON data with a jq library
One of those tools will be a library of filter methods for the excellent commandline JSON processor [jq](https://github.com/stedolan/jq). With the library you'll be able to chain filters and sort methods to limit your Google+ Takeout JSON files to a subset of data you can then pass on to other tools or services.
For instance, it will allow you to limit your Activity data to just public posts, or those with comments or other interactions with one or more specific users.

## Export to other formats
Some of the other tools will assist in converting the (filtered) data to other formats, such as for instance HTML, or possibly Atom of json-ld, for import into other platforms.
