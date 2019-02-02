# CLI tool to archive Google+ Comments frame for Blogger blogs

This tool uses `jq`, `sed`, `curl` and Blogger API V3 (you'll need to get an API key from https://developers.google.com/blogger/docs/3.0/using#APIKey) and the web integration API of Google+ to store the frame of Google+ comments locally for a Blogger blog with Google+ comments enabled.

The scripts rely on the ENV variable BLOGGER_APIKEY to be set to your Blogger v3 API key:  
`export BLOGGER_APIKEY=aBcDEfGhIJKlMNoPQr283Z`

(This key is obviously a sample one; you need to replace it with your own actual key.)

## sed
`sed` the Stream EDitor is used for regular expression substitution. Since the BSD version of sed that comes with macOS is rather limited, you might need to install GNU sed instead with `brew install gsed` and replace calls to `sed` with `gsed`

## curl
`curl` is a CLI tool for retrieving online resources. Here I use it to send HTTP GET requests to the APIs.

## jq
`jq` is an excellent CLI tool for parsing and filtering JSON: 
https://stedolan.github.io/jq/

It can be downloaded from its website, or through your package manager.

### Get Blog ID for Blog URL
`sh ./getblogid.sh https:://your.blogger.blog.example #=> 12345`

### Get URLs for sll blog posts for Blogger blog with given id
`bash ./getposturls.sh 1234`
```
https://your.blogger.blog.example/2018/01/blog-title.html
https://your.blogger.blog.example/2019/01/second-blog-title.html
```

### Store Google+ Comments frame for blog post with given URL(s)
`echo "https://your.blogger.blog.example/2018/01/blog-title.html" |bash store_comments_frame.sh` 

Files will be stored in ./data/output/your.blogger.blog.example/ with almost all special characters replaced by dashes

### Everything combined
```bash 
bash ./getposturls.sh `sh ./getblogid.sh https://your.blogger.blog.example/`| bash store_comments_frame.sh
```