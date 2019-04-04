## Activity Posts Filenames

For each Activity resource _(the technical term the API reference uses for posts)_ a separate JSON file is created. Its filename appears to be named according to the following structure:

  `YYYYMMDD - UNIQUE_POST_TITLE.json`

or, represented as a Regular Expression:

  ```regex
  (?<year>[0-9]{4})(?<month>[0-9]{2})(?<day>[0-9]{2}) - (?<unique_post_title>.{0-42})\.json
  ```

where `YYYYMMDD` is the Activity's creation date consisting of a 4 digit year, 2 digit month and 2 digit day of month, and `UNIQUE_POST_TITLE` is a unique _(within the scope of the same day)_ Activity identifier that's at most 42 characters long.

The `UNIQUE_POST_TITLE` generally is the first 39 characters of the Activity's content. 
However, if this would cause a _duplicate filename_ within the same day, the last characters of this fragment will be replaced with a `(\d+)` suffix (e.g. `(1)`) where the number between the parentheses is an integer which starts at 1, and gets incremented by 1 till the suffixed title fragment is unique again within the scope of the day.

## Ruby Hash representation of possible Activity post structure

This structure isn't complete yet, as it's based on just a couple of example JSON files.

The data is a standard JSON file. Its structure can be visualised as a Hash or associative array as follows:

```ruby
activity_post =  {
    'url':          'https://plus.google.com/ACTIVITY_USER_ID/posts/ACTIVITY_ID',
    'creationTime': 'YYYY-mm-dd HH:MM:SS:zzzz',
    'updateTime':   'YYYY-mm-dd HH:MM:SS:zzzz',
    'author':
    {
      'displayName':    'DISPLAY_NAME_WITHOUT_NICKNAME',
      'profilePageUrl': 'https://plus.google.com/ACTIVITY_USER_ID',
      'avatarImageUrl':  'https://lh3.googleusercontent.com/-RANDOM/PATH/TO/RESOURCE/photo.jpg',
      'resourceName':    'users/ACTIVITY_USER_ID'
    },
    'album':
    {
      'media':
      [
        {
          'url':          'https://lh3.googleusercontent.com/-RANDOM/PATH/TO/RESOURCE/photo.jpg',
          'contentType':   'image/*',
          'width':        1234,
          'height':       4321,
          'resourceName': 'media/MEDIA_RESOURCE_ID',
        }
      ]
    },
    'content':          'HTML_FORMATTED_CONTENT',
    'link':
    {
      'title':   'LINK_TITLE',
      'url':     'LINK_ABSOLUTE_URL',
      'imageUrl': 'LINK_ABSOLUTE_IMAGE_URL'
    },
    'resharedPost': {
      'url': 'https://plus.google.com/+ORIGINAL_ACTIVITY_USER_ID/posts/ORIGINAL_ACTIVITY_ID',
      'author': {
        'displayName': 'ORIGINAL_ACTIVITY_USER_DISPLAY_NAME',
        'profilePageUrl': 'https://plus.google.com/+ORIGINAL_ACTIVITY_USER_ID',
        'avatarImageUrl': 'https://lh3.googleusercontent.com/-RANDOM/PATH/TO/RESOURCE/photo.jpg',
        'resourceName': 'users/ORIGINAL_ACTIVITY_NUMERIC_USER_ID'
      },
      'content': 'ORIGINAL_ACTIVITY_HTML_FORMATTED_CONTENT',
      'resourceName': 'users/ORIGINAL_ACTIVITY_NUMERIC_USER_ID/posts/ORIGINAL_ACTIVITY_ID'
    },
    'comments':
    [
      'creationTime': 'YYYY-mm-dd HH:MM:SS:zzzz',
      'author':
      {
        'displayName':    'DISPLAY_NAME_WITHOUT_NICKNAME',
        'profilePageUrl': 'https://plus.google.com/USER_ID',
        'avatarImageUrl':  'https://lh3.googleusercontent.com/-RANDOM/PATH/TO/RESOURCE/photo.jpg',
        'resourceName':    'users/USER_ID'
      },
      'content':       'HTML_FORMATTED_CONTENT',
      'postURL':      'https://plus.google.com/ACTIVITY_USER_ID/posts/ACTIVITY_ID',
      'resourceName': 'users/ACTIVITY_USER_ID/posts/THREAD_ID/comments/COMMENT_ID'
    ],
    'resourceName':    'users/ACTIVITY_USER_ID/posts/THREAD_ID',
    'plusOnes':
    [
      'plusOner':
      {
        'displayName':    'DISPLAY_NAME_WITHOUT_NICKNAME',
        'profilePageUrl': 'https://plus.google.com/USER_ID',
        'avatarImageUrl':  'https://lh3.googleusercontent.com/-RANDOM/PATH/TO/RESOURCE/photo.jpg',
        'resourceName':    'users/USER_ID'
      },
    ],
    'postAcl':
    {
      'visibleToStandardAcl':
      {
        'circles':
        [
          {
            'type': 'CIRCLE_TYPE_PUBLIC'
          },
          {
            'type': 'CIRCLE_TYPE_YOUR_CIRCLES'
          },
          {
            'type': 'CIRCLE_TYPE_EXTENDED_CIRCLES'
          },
          {
            'resourceName': 'circles/USER_ID-CIRCLE_ID',
            'type': 'CIRCLE_TYPE_USER_CIRCLE',
            'displayName': 'CIRCLE_DISPLAY_NAME'
          }
        ],
        'users':
        [
          {
            'resourceName': 'users/USER_ID',
            'displayName':  'DISPLAY_NAME_WITHOUT_NICKNAME'
          }
        ]
      },
      'communityAcl':
      {
        'community':
        {
          'resourceName': 'communities/COMMUNITY_ID',
          'displayName':  'COMMUNITY_DISPLAY_NAME'
        },
        'users':
        [
          {
            'resourceName': 'users/USER_ID',
            'displayName':  'DISPLAY_NAME_WITHOUT_NICKNAME'
          }
        ]
      },
      'eventAcl':
      {
        'event':
        {
          'resourceName': 'events/EVENT_ID'
        }
      },
      'collectionAcl':
      {
        'collection':
        {
          'resourceName': 'collections/COLLECTION_ID',
          'displayName':  'COLLECTION_DISPLAY_NAME'
        }
      }
    }
  }
```

*(NOTE: This Ruby structure has not been kept up to date; for now it's merely still here as illustration/clarification)*

## Flat Representation of all possible JSON keys for Activity posts

What follows is a list of all _*possible*_ JSON keys encountered after analysing a complete archive of 2145 Google+ Stream posts from 2011-06-30 till 2019-03-07:

```

activityId
album
album.media
album.media[]
album.media[].contentType
album.media[].description
album.media[].height
album.media[].localFilePath
album.media[].resourceName
album.media[].url
album.media[].width
author
author.avatarImageUrl
author.displayName
author.profilePageUrl
author.resourceName
collectionAttachment
collectionAttachment.coverPhotoUrl
collectionAttachment.displayName
collectionAttachment.owner
collectionAttachment.owner.avatarImageUrl
collectionAttachment.owner.displayName
collectionAttachment.owner.profilePageUrl
collectionAttachment.owner.resourceName
collectionAttachment.permalink
collectionAttachment.resourceName
comments
comments[]
comments[].author
comments[].author.avatarImageUrl
comments[].author.displayName
comments[].author.profilePageUrl
comments[].author.resourceName
comments[].commentActivityId
comments[].content
comments[].creationTime
comments[].link
comments[].link.imageUrl
comments[].link.title
comments[].link.url
comments[].media
comments[].media.contentType
comments[].media.height
comments[].media.localFilePath
comments[].media.resourceName
comments[].media.url
comments[].media.width
comments[].postUrl
comments[].resourceName
comments[].updateTime
communityAttachment
communityAttachment.coverPhotoUrl
communityAttachment.displayName
communityAttachment.resourceName
content
creationTime
link
link.imageUrl
link.title
link.url
location
location.displayName
location.latitude
location.longitude
location.physicalAddress
media
media.contentType
media.description
media.height
media.localFilePath
media.resourceName
media.url
media.width
plusOnes
plusOnes[]
plusOnes[].plusOner
plusOnes[].plusOner.avatarImageUrl
plusOnes[].plusOner.displayName
plusOnes[].plusOner.profilePageUrl
plusOnes[].plusOner.resourceName
poll
poll.choices
poll.choices[]
poll.choices[].description
poll.choices[].imageLocalFilePath
poll.choices[].imageUrl
poll.choices[].resourceName
poll.choices[].voteCount
poll.choices[].votes
poll.choices[].votes[]
poll.choices[].votes[].voter
poll.choices[].votes[].voter.avatarImageUrl
poll.choices[].votes[].voter.displayName
poll.choices[].votes[].voter.profilePageUrl
poll.choices[].votes[].voter.resourceName
poll.imageLocalFilePath
poll.imageUrl
poll.totalVotes
poll.viewerPollChoiceResourceName
postAcl
postAcl.collectionAcl
postAcl.collectionAcl.collection
postAcl.collectionAcl.collection.displayName
postAcl.collectionAcl.collection.resourceName
postAcl.collectionAcl.users
postAcl.collectionAcl.users[]
postAcl.collectionAcl.users[].displayName
postAcl.collectionAcl.users[].resourceName
postAcl.communityAcl
postAcl.communityAcl.community
postAcl.communityAcl.community.displayName
postAcl.communityAcl.community.resourceName
postAcl.communityAcl.users
postAcl.communityAcl.users[]
postAcl.communityAcl.users[].displayName
postAcl.communityAcl.users[].resourceName
postAcl.eventAcl
postAcl.eventAcl.event
postAcl.eventAcl.event.displayName
postAcl.eventAcl.event.resourceName
postAcl.isDomainRestricted
postAcl.isLegacyAcl
postAcl.isPublic
postAcl.visibleToStandardAcl
postAcl.visibleToStandardAcl.circles
postAcl.visibleToStandardAcl.circles[]
postAcl.visibleToStandardAcl.circles[].displayName
postAcl.visibleToStandardAcl.circles[].resourceName
postAcl.visibleToStandardAcl.circles[].type
postAcl.visibleToStandardAcl.users
postAcl.visibleToStandardAcl.users[]
postAcl.visibleToStandardAcl.users[].displayName
postAcl.visibleToStandardAcl.users[].resourceName
postKind
resharedPost
resharedPost.album
resharedPost.album.media
resharedPost.album.media[]
resharedPost.album.media[].contentType
resharedPost.album.media[].description
resharedPost.album.media[].height
resharedPost.album.media[].resourceName
resharedPost.album.media[].url
resharedPost.album.media[].width
resharedPost.author
resharedPost.author.avatarImageUrl
resharedPost.author.displayName
resharedPost.author.profilePageUrl
resharedPost.author.resourceName
resharedPost.communityAttachment
resharedPost.communityAttachment.coverPhotoUrl
resharedPost.communityAttachment.displayName
resharedPost.communityAttachment.resourceName
resharedPost.content
resharedPost.link
resharedPost.link.imageUrl
resharedPost.link.title
resharedPost.link.url
resharedPost.media
resharedPost.media.contentType
resharedPost.media.description
resharedPost.media.height
resharedPost.media.resourceName
resharedPost.media.url
resharedPost.media.width
resharedPost.resourceName
resharedPost.url
reshares
reshares[]
reshares[].resharer
reshares[].resharer.avatarImageUrl
reshares[].resharer.displayName
reshares[].resharer.profilePageUrl
reshares[].resharer.resourceName
resourceName
updateTime
url
```

This list was generated with the following command:

  ```bash
  jq -s 'map(.)' takeout_archive_2018/*.json | jq -r 'paths|map(.|tostring)|join(".")' |gsed -r 's/^[0-9]+(\.|$)//'|gsed -r 's/\.[0-9]+/[]/g'|sort -u > unique_keys.txt
  ```

I used `gsed` instead of `sed` to indicate it's GNU sed, rather than for instance the default sed that comes with for example macOS; though the regular expression is probably simple enough to work regardless.

A `.` (period) indicates that the following key is a child, and `[]` (square brackets) indicate that the preceding parent key is an array.
So, `reshares` is an array of which the child members contain the hash key `resharer`, which contain the keys `avatarImageUrl`, `displayName`, `profilePageUrl` and `resourceName`.

In JSON this would be equivalent to:
```json
  'reshares': [
    {
      'resharer': {
        'avatarImageUrl': 'some url',
        'displayName': 'some display name',
        'profilePageUrl': 'some url',
        'resourceName': 'some/resource/path'
      }
    }
  ]
```

## Legend

* `ACTIVITY_USER_ID` is the numeric Person ID of the user who posts the Activity;
* `ACTIVITY_ID` a unique identifier consisting of alpha-numeric characters (`[a-zA-Z0-9]`); do note that this id is not the same as the `Activity#id` used by the [Google+ REST API](https://developers.google.com/+/web/api/rest/latest/activities). In fact, none of the `id`s and `resourceName`s supplied in the JSON file seem to be usable through the API.
* `USER_ID` is the numeric Person ID of the user within the scope of the current content. For instance, within the scope of 'comments', it is the Person ID of the user who posted the comment;
* `DISPLAY_NAME_WITHOUT_NICKNAME` is the display name of the profile, however the nickname does not seem to be included, even if the user had set his nickname to be included within his display name. 
* `HTML_FORMATTED_CONTENT` is the content (post's or comment's body) formatted using HTML, rather than containing Google's own markdown-like markup/formatting language.
* `LINK_TITLE` is the title of the linked (external) webpage, likely extracted from the webpage's `<title>` HTML tag.
* `LINK_ABSOLUTE_URL` is the absolute URL of the linked (external) webpage (e.g. `https://somesite.example/path/to/some/page`).
* `LINK_ABSOLUTE_IMAGE_URL` is the absolute URL of the linked (external) image resource (e.g. `https://somesite.example/path/to/some/image.jpg`).
* `THREAD_ID` appears to be a unique identifier for a comment thread for an activity. Though it also seems to be a secondary Activity ID (perhaps used internally?) as it is not only used within comment threads, it also is used in the Activity's resourceName.
* `COMMENT_ID` appears to be a unique identifier for a comment within a comment thread for an activity. It appears to consist of two sub-fragments, delimited by a hyphen (-). The first fragments appears to be the same for all comments within the same thread, and the last (shortest) fragment seems to be unique within that thread.
* `COMMUNITY_ID` unique numeric identifier for the community in which the Activity was posted.
* `COMMUNITY_DISPLAY_NAME` string, display name for the community in which the Activity was posted.
* `EVENT_ID` unique alpha-numeric identifier for the Event Activity that was posted.
* `MEDIA_RESOURCE_ID` an alpha-numeric URL-encoded identifier, or possibly a URL-encoded BASE64 content string.
* `COLLECTION_ID` an alpha-numeric identifier for the Collection the Activity is in.
* `COLLECTION_DISPLAY_NAME` the display name of the Collection.
* `media`.`width` and `media`.`height` are *integer* values representing their dimensions in pixels.
* `ORIGINAL_ACTIVITY_HTML_FORMATTED_CONTENT` like `HTML_FORMATTED_CONTENT` but then for the Original Activity item rather than the reshared item.
* `ORIGINAL_ACTIVITY_NUMERIC_USER_ID` like `ACTIVITY_USER_ID` but then belonging to the user who originally posted the Activity item, rather than the reshared Activity item. Is an Integer represented as a String.
* `ORIGINAL_ACTIVITY_USER_ID` like `ACTIVITY_USER_ID`, but will be in +UserAliasID format if the user has set a user alias. If no alias was set, it'll be a numeric id instead.
* `ORIGINAL_ACTIVITY_USER_DISPLAY_NAME` like `DISPLAY_NAME_WITHOUT_NICKNAME`, but then for the User who originally posted the Activity, rather than the reshared Activity item.
* `ORIGINAL_ACTIVITY_ID` like `ACTIVITY_ID` but then for the original Activity item, rather than the reshared item.


Within datetime strings:

* `YYYY` is a 4 digit year,
* `mm` a 2 digit month (01-12),
* `dd` a 2 digit day of the month (01-31),
* `HH` a 2 digit hour (00-23),
* `MM` a 2 digit minute of the hour (00-59),
* `SS` 2 digits indicating the seconds of the minute (00-59) and
* `zzzz` 2x2 digits indicating the hours and minutes offset of UTC.

### Notes about Access Control List data

For the `postAcl` (Access Control List) data, there is some exclusivity regarding the items, but for completeness/overview sake all *possible* items are listed.

It's likely that you can have either a `visibleToStandardAcl` item, an `eventAcl` item, a `communityAcl` item, or a `collectionAcl` item and none of them combined with each other. 

Furthermore, within `visibleToStandardAcl`.`circles`, the `CIRCLE_TYPE_PUBLIC`-, `CIRCLE_TYPE_YOUR_CIRCLES`- and `CIRCLE_TYPE_EXTENDED_CIRCLES`-type circle items are likely mutually-exclusive, which means you can't combine one or more of them with each other. You can likely find one of them combined with zero, one or more `CIRCLE_TYPE_USER_CIRCLE`-type circle item though.

Finally, within `communityAcl` the `users` item is optional.
