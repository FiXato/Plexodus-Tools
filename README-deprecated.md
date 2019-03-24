# Plexodus-Tools
A collection of tools to process the Google Plus-related data. This document contains documentation related to the tools that is now deprecated due to APIs no longer being available.

Copyright (C) 2018-2019 Filip H.F. "FiXato" Slagter

## Google+ Shutting down April 2019
With the [announcement of Google+ shutting its doors for consumers](https://www.blog.google/technology/safety-security/project-strobe/), and the [second announcement of Google+ expediting its shutdown](https://www.blog.google/technology/safety-security/expediting-changes-google-plus/), those of us who've accumulated a large collection of posts and other data over the lifetime of the platform, are in need of tools to process the data archives that Google are providing us through [Google Takeout](https://takeout.google.com), and possibly live data through the [Google+ API](https://developers.google.com/+/web/api/rest/).
With the shutdown originally being scheduled for August 2019, but following the second announcement, expedited to April 2nd, 2019, and the Google+ APIs being turned off, on Sunday March 7th, 2019 at the latest, time is quickly running out.

This repository will hopefully provide some of those tools.


_Note: I'm using `gsed`, `gcut` and `ggrep` here to indicate I'm using the GNU versions of the utilities, rather than the BSD versions supplied by macOS. These versions can be installed (and linked with `g`-prefixes) through Homebrew on macOS. For instance with `brew install sed cut grep`. On other platforms such as Linux and Windows Cygwin, you're likely installing the GNU versions anyway._

## Bash scripts

Aside the various Ruby scripts, this toolset also contains some self-contained Bash scripts for data retrieval and processing:

## Google+ Comments on Blogger Blogs Exporter

### Requirements
The Bash scripts for exporting Google+ Comments on Blogger Blogs rely heavily on a variety of CLI utilities, and services.

For instance, this tool uses `jq`, `(g)sed`, `(g)grep`, `curl`, and various APIs to store the Google+ posts and comments locally for Blogger blogs with Google+ comments enabled. Obviously you also need a Bourne Again SHell compatible shell for executing the scripts.

#### API access

_(While the Blogger APIs are still available, I'll leave this in this document too, for completeness sake.)_

##### Blogger API V3
I use Blogger's official API to retrieve the `Blog#id` based on the Blog's URL, as well as to retrieve all blog post URLs based on the `Blog#id`.

* Blogger API V3 requires an API key.  You can find [official developers.google.com instructions](https://developers.google.com/blogger/docs/3.0/using#APIKey) on how to request an API key from: https://developers.google.com/blogger/docs/3.0/using#APIKey
* You also need to set the `BLOGGER_APIKEY` ENVironment variable for your Blogger v3 API key:  `export BLOGGER_APIKEY=aBcDEfGhIJKlMNoPQr283Z`

##### Google+ API
I use the official Google Plus API to retrieve the top level posts (`Activities`, as they are called in the API) used in the Google+ Comments for Blogger widget, as well as their `Comments` resources.

* Google+ `Activities` and `Comments` API endpoints require an API key (or OAuth workflow).  You can find [official developers.google.com instructions](https://developers.google.com/+/web/api/rest/oauth#apikey) on how to request an API key from: https://developers.google.com/+/web/api/rest/oauth#apikey
* You also need to set the `GPLUS_APIKEY` ENVironment variable for your Google Plus API key:  `export GPLUS_APIKEY=Z382rQPoNMlKJIhGfEDc_Ba`

(These above key values are obviously example ones; you'll need to replace them with your own actual keys.)

##### Google+ web integration API
I use the G+ Comments Widget from Google+'s Web Integrations API to get a list of `Activity#id`'s associated with the Blogger blog post, based on its URL.

#### grep
`grep` is a CLI tool for regular expression-based filtering of files and data. Since the BSD version of grep that comes with macOS is rather limited, please install GNU grep instead. Not sure if it's through `brew install grep` or `brew install gnu-grep`.

Once installed on macOS, you should have access to GNU's version of grep via the `g`-prefix: `ggrep`. The Bash scripts in this repository will automatically use `ggrep` rather than `grep` if they find it available on your system.

#### sed
`sed` the Stream EDitor is used for regular expression substitution. Since the BSD version of sed that comes with macOS is rather limited, you will likely need to install GNU sed instead with `brew install gsed` and replace calls to `sed` with `gsed`

Once installed on macOS, you should have access to GNU's version of sed via the `g`-prefix: `gsed`. The scripts in this repository will automatically use `gsed` rather than `sed` if they find it available on your system.

#### curl
`curl` is a CLI tool for retrieving online resources. For the tools in this project, I use it to send HTTP GET requests to the APIs.

#### jq
`jq` is an excellent CLI tool for parsing and filtering JSON:
https://stedolan.github.io/jq/

It can be downloaded from its [website](https://stedolan.github.io/jq/), or through your package manager (for instance on macOS through `brew install jq`).

### Usage:

#### Get a complete archive:
While you can manually pipe results into the fairly self-contained CLI scripts, it's easiest to just use the `export_blogger_comments.sh` script which does everything for you:

```bash
DEBUG=1 REQUEST_THROTTLE=1 PER_PAGE=500 ./bin/export_blogger_comments.sh https://your.blogger.blog.example
```

* `DEBUG=1` enables the new debug messages on stderr
* `REQUEST_THROTTLE=1` will sleep in some cases for a single second, to throttle the API requests. Could probably be reduced to `0.5` or even just `0` to disable it.
* `PER_PAGE=500` will request 500 blog posts per API request. Not yet implemented for Comments, though I figured it was easiest to hardcode that to 500 since that's the max for an Activity anyway. Saves me paginations

The script tries to cache queries for a day to reduce needless re-querying of the APIs.

#### Get Blog ID for Blog URL
```bash
./bin/get_blogger_id.sh https://your.blogger.blog.example
#=> 12345
```

This will also store the `$blog_id` in `data/blog_ids/${domain}.txt`.

#### Get URLs for all blog posts for Blogger blog with given id
```bash
./bin/get_blogger_post_urls.sh 1234
```

Which will output a newline-separated list of Blogger blog post URLs:

```
https://your.blogger.blog.example/2018/01/blog-title.html
https://your.blogger.blog.example/2019/01/second-blog-title.html
```

This will also store the Blogger.posts JSON responses  in `data/blog_post_urls/${blog_id}-${per_page}(-${page_token})-${year}-${month}-${day}.json` and the list of post URLs in `data/blog_post_urls/${blog_id}-${per_page}-${year}-${month}-${day}.txt`.

#### Store Google+ Comments widget for blog post with given URL(s)

Single URL example:

```bash
./bin/request_gplus_comments_widget_for_url.sh https://your.blogger.blog.example/2018/01/blog-title.html
```

Newline-delimited example:

```bash
echo -e "https://your.blogger.blog.example/2018/01/blog-title.html\nhttps://your.blogger.blog.example/2018/01/another-blog-title.html" | xargs -L 1 ./bin/request_gplus_comments_widget_for_url.sh
```

Google+ Comments Widget responses will be stored in `./data/gplus_comments_widgets/your.blogger.blog.example/` with almost all special characters replaced by dashes. E.g. `./data/gplus_comments_widgets/your.blogger.blog.example/2018-01-blog-title.html`

#### List Google+ ActivityIDs from Google+ Comments widget files/dumps
This tries to list all Activity IDs it can find in the Google+ Comments widget result.

Single URL example:

```bash
./bin/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh ./data/gplus_comments_widgets/your.blogger.blog.example/2018-01-blog-title.html
```

Newline-delimited example:

```bash
echo -e "data/gplus_comments_widgets/your.blogger.blog.example/2018-01-blog-title.html\ndata/gplus_comments_widgets/your.blogger.blog.example/2018-01-another-blog-title.html" | xargs -L 1 ./bin/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh
```

This will return a list of newline-separated Google+ Activity#id results you can use to look up Google+ Posts (Activities) through the Google Plus API (for as long as it's still available).

#### Get the Activity and its Comments for a given activity id (and convert to HTML)
These scripts will look up the Google+ Activity JSON resource through the Google+ API's Activity.get endpoint, as well as its associated Google+ Comments JSON resources through the Google+ API's Comments.list endpoint.

```bash
ACTIVITY_ID="asdDSAmKEKAWkmcda3o01DMoame3"
./bin/get_gplus_api_activity_by_gplus_activity_id.sh "$ACTIVITY_ID"
./bin/get_gplus_api_comments_by_gplus_activity_id.sh "$ACTIVITY_ID"
```

Alternatively you can pass the activity from from the former script to the `get_gplus_api_comments_by_gplus_activity_file.sh` script, which will only try to retrieve comments if the Activity actually has replies:

```bash
./bin/get_gplus_api_comments_by_gplus_activity_file.sh $(./bin/get_gplus_api_activity_by_gplus_activity_id.sh "$ACTIVITY_ID")
```


The JSON resources are stored at:

* `data/gplus/activities/$activity_id.json`
* `data/gplus/activities/$activity_id/comments_for_$activity_id.json`

#### Examples of combining commands
By piping the results of the commands in the right order, with the use of xargs and/or command substitution, you can let the scripts do the hard work.

```bash
./bin/get_blogger_post_urls.sh "$(./bin/get_blogger_id.sh "https://your.blogger.blog.example/")" | xargs -L 1 ./bin/request_gplus_comments_widget_for_url.sh | xargs -L 1 ./bin/get_gplus_api_activity_ids_from_gplus_comments_widget_file.sh | xargs -L 1 ./bin/get_gplus_api_activity_by_gplus_activity_id.sh | xargs -L 1 ./bin/get_gplus_api_comments_by_gplus_activity_file.sh
```

Or just have a look at the [export_blogger_comments.sh](bin/export_blogger_comments.sh) script, which basically serves this default workflow.

### Thanks

* Michael Prescott for having a need for this script, and for bouncing ideas back and forth with me. 
* Abdelghafour Elkaaba, for giving some ideas on how to import this back into Blogger's native comments
* Edward Morbius, for moderating the [Google+ Mass Migration community](https://plus.google.com/communities/112164273001338979772) on Google+
* Peggy K, for signal boosting and being a soundboard

### Relevant Links

You can follow related discussions here:
* [Google+ Exodus Collection](https://plus.google.com/collection/wakeQF)
* [G+ Exodus: PSA: Google+ Comments for Blogger owners have 3 days to manually archive the comments on all their blog posts](https://plus.google.com/112064652966583500522/posts/EJukQAAfFrV)
* [G+MM: You have only till February 4th to archive all the comments on your Blogger blogs](https://plus.google.com/112064652966583500522/posts/L6HxBe48kQs)
* [G+ Comment on Blogger's official GoogleBlog: Lack of Migration Path](https://plus.google.com/112064652966583500522/posts/aoGutBGaZ51)
* [Google+ Help Community: Where are the Google+ Comments on my Blogger blog located?](https://plus.google.com/112064652966583500522/posts/Hx3buXXfjFb)

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
