# CLI tool to archive Google+ Comments frame for Blogger blogs

This tool uses `jq`, `sed`, `curl`, Blogger API V3 (you'll need to get an API key from https://developers.google.com/blogger/docs/3.0/using#APIKey), Google Plus API (you'll need an API key from https://developers.google.com/+/web/api/rest/oauth#apikey) and the Google+ web integration API to store the frame of Google+ comments locally for a Blogger blog with Google+ comments enabled.

The scripts rely on the following ENV variables to be set:

* `BLOGGER_APIKEY` for your Blogger v3 API key:  `export BLOGGER_APIKEY=aBcDEfGhIJKlMNoPQr283Z`
* `GPLUS_APIKEY` for your Google Plus API key:  `export GPLUS_APIKEY=Z382rQPoNMlKJIhGfEDc_Ba`

(These above key values are obviously a example one; you need to replace them with your own actual keys.)

## sed
`sed` the Stream EDitor is used for regular expression substitution. Since the BSD version of sed that comes with macOS is rather limited, you might need to install GNU sed instead with `brew install gsed` and replace calls to `sed` with `gsed`

## curl
`curl` is a CLI tool for retrieving online resources. Here I use it to send HTTP GET requests to the APIs.

## jq
`jq` is an excellent CLI tool for parsing and filtering JSON: 
https://stedolan.github.io/jq/

It can be downloaded from its website, or through your package manager.

## Usage:

### Get a complete archive:
While you can manually pipe results into the fairly self-contained CLI scripts, it's easiest to just use the `export_blog.sh` script which does everything for you:

`DEBUG=1 REQUEST_THROTTLE=1 PER_PAGE=500 ./export_blog.sh https://your.blogger.blog.example`

* `DEBUG=1` enables the new debug messages on stderr
* `REQUEST_THROTTLE=1` will sleep in some cases for a single second, to throttle the API requests. Could probably be reduced to `0.5` or even just `0` to disable it.
* `PER_PAGE=500` will request 500 blog posts per API request. Not yet implemented for Comments, though I figured it was easiest to hardcode that to 500 since that's the max for an Activity anyway. Saves me paginations

The script tries to cache queries for a day to reduce needless re-querying of the APIs.

### Get Blog ID for Blog URL
`./getblogid.sh https://your.blogger.blog.example #=> 12345`

This will also store the blog_id in `data/blog_ids/${domain}.txt`.

### Get URLs for all blog posts for Blogger blog with given id
`./getposturls.sh 1234`
```
https://your.blogger.blog.example/2018/01/blog-title.html
https://your.blogger.blog.example/2019/01/second-blog-title.html
```

This will also store the Blogger.posts JSON responses  in `data/blog_post_urls/${blog_id}-${per_page}(|-$page_token)-${year}-${month}-${day}.json` and the list of post URLs in `data/blog_post_urls/${blog_id}-${per_page}-${year}-${month}-${day}.txt`.

### Store Google+ Comments widget for blog post with given URL(s)
```bash
echo -e "https://your.blogger.blog.example/2018/01/blog-title.html\nhttps://your.blogger.blog.example/2018/01/another-blog-title.html" | ./store_comments_frame.sh
``` 

Google+ Comments Widget responses will be stored in ./data/comments_frames/your.blogger.blog.example/ with almost all special characters replaced by dashes

### List Google+ ActivityIDs from Google+ Comments widget files/dumps
This tries to list all Activity IDs it can find in the Google+ Comments widget result.

```bash
echo -e "data/comments_frames/your.blogger.blog.example/2018-01-blog-title.html\ndata/comments_frames/your.blogger.blog.example/2018-01-another-blog-title.html" | ./get_activity_ids_from_comments_frame.sh
``` 

This will return a list of newline-separated Google+ Activity#id results you can use to look up Google+ Posts (Activities) through the Google Plus API (for as long as it's still available).

### Get the Activity and its Comments for a given activity id (and convert to HTML)
This will look up the Google+ Activity JSON resource through the Google+ API's Activity.get endpoint, as well as its associated Google+ Comments JSON resources through the Google+ API's Comments.list endpoint.

```bash
echo -e "asdDSAmKEKAWkmcda3o01DMoame3" | ./get_comments_from_google_plus_api_by_activity_id.sh
```

For now it also tries to do conversion from JSON to very limited and ugly HTML, but that will likely be split off to its own script.

The JSON resources are stored at:

* `data/gplus/activities/$activity_id.json`
* `data/gplus/activities/$activity_id/comments.json`

The HTML output for now is stored at:

* `data/output/$domain/html/sanitised-blog-url-path.html`
* `data/output/$domain/html/all-activities.html`

### Example of combining commands
By piping the results of the commands in the right order, you can let the scripts do the hard work.

```bash 
./getposturls.sh `sh ./getblogid.sh https://your.blogger.blog.example/`| store_comments_frame.sh
```

## Notice
This set of scripts was coded over the past couple of days, since the January 30th announcement from Google made it clear that Blogger owners were running out of time quickly. As such, it has not been rigourously tested yet. 

I have been able to make archives of 2 blogs so far, which seem to have been successful as of Feb 3rd.


## Thanks

* Michael Prescott for having a need for this script, and for bouncing ideas back and forth with me. 
* Abdelghafour Elkaaba, for giving some ideas on how to import this back into Blogger's native comments
* Edward Morbius, for moderating the [Google+ Mass Migration community](https://plus.google.com/communities/112164273001338979772) on Google+
* Peggy K, for signal boosting and being a soundboard

## Relevant Links

You can follow related discussions here:
* [Google+ Exodus Collection](https://plus.google.com/collection/wakeQF)
* [G+ Exodus: PSA: Google+ Comments for Blogger owners have 3 days to manually archive the comments on all their blog posts](https://plus.google.com/112064652966583500522/posts/EJukQAAfFrV)
* [G+MM: You have only till February 4th to archive all the comments on your Blogger blogs](https://plus.google.com/112064652966583500522/posts/L6HxBe48kQs)
* [G+ Comment on Blogger's official GoogleBlog: Lack of Migration Path](https://plus.google.com/112064652966583500522/posts/aoGutBGaZ51)
* [Google+ Help Community: Where are the Google+ Comments on my Blogger blog located?](https://plus.google.com/112064652966583500522/posts/Hx3buXXfjFb)
