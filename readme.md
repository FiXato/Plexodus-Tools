## CLI tool to archive Google+ Comments frame for Blogger blogs

This tool uses `jq`, `sed`, `curl` and Blogger API V3 (you'll need to get an API key from https://developers.google.com/blogger/docs/3.0/using#APIKey) and the web integration API of Google+ to store the frame of Goofle+ comments locally for a Blogger blog with Google+ comments enabled.

The scripts rely on the ENV variable BLOGGER_APIKEY to be set to your Blogger v3 API key:  
`export BLOGGER_APIKEY=aBcDEfGhIJKlMNoPQr283Z`

(This key is obviously a sample one; you need to replace it with your own actual key.)

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