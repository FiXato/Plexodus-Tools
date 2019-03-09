# Data from the JSON embedded near the bottom of each post's HTML on plus.google.com
JSON extracted with the following oneliner:
```bash
curl -H "Content-Type: text/html; charset=UTF-8" | pup --charset utf-8 $'script[nonce]:contains("key: \'ds:3\'") text{}' | gsed -E 's/^AF_initDataCallback\(.+data:[^\[]+//' | gsed -E 's/^}}\);$//' | jq
```

## activityID
`jq '.[1]'`

## Activity Comments
`jq '.[0][0][]'`

### Some kind of numeric ID, 9 characters, the same for each comment
'.[0][0][0][0]'

### activityID#commentID
'.[0][0][0][1]'

### Activity Comment data
'.[0][0][0][2]'
'.[0][0][0][2]|keys' #=> same key as used as value for '.[0][0][0][1]'

'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring]' #=> gets all comment data

#### Activity Comment data details
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][0,5,10,13,16,17,18,19,20,21,22,24,28,29,32]' # null
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][8,9,11,12,23]' # false

'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][1]' #displayName (badly encoded?)
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][2]' # "" (empty string)
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][3]' # 1548139667163 (numeric id, different for every comment)
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][4]' # "z12zxjm4cuioxt3bz04cdhjoixeixfyzjso0k#1548139667163776" (activityId#commentId?)  the commentid part after the hash is the same as the previous numeric id, plus 3 extra digits. The entire values appears to be the same as Same as '.[0][0][0][1]'
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][6]' # commenter's UserID
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][7]' # ActivityID ("z12zxjm4cuioxt3bz04cdhjoixeixfyzjso0k" )
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][14]' # 0

#### Activity Comment unknown Data Array
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][15]' # some array:
```json
[
  "5/jcsn4ynshdqncsvph5rrkx1ngdx30h33gloaovvdj1mqmy3aj5xaowvja1pmagdpakw32i1nawu3eidka0uneic/asbe#comment#1548183745900559",
  5,
  null,
  null,
  null,
  null,
  0,
  null,
  null,
  null,
  null,
  null,
  null,
  false,
  null,
  null,
  2,
  null,
  false
]
```
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][15][0] # some kind of long id/path; possibly a resourceName?
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][15][1] # 5; Seems to be the same for all the comments in this activity. Number is the same as the digit preceding the resource path in [0]
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][15][6] # 0; so far the same for all comments
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][15][16]' # Number of +1's on Comment
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][15][2,3,4,5,7,8,9,10,11,12,14,15,17] # null
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][15][13,18] # false


#### Activity Comment Author data
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25]' # author array?:
```json
[
  "Filip H.F. ”FiXato” Slagter",
  "112064652966583500522",
  false,
  false,
  "https://lh3.googleusercontent.com/a-/AAuE7mD1PExkBUK3YWLqyPJ4O-kY1dKqBL_NXBU2IjjpoAE=il",
  "./112064652966583500522",
  null,
  null,
  null,
  true
]
```
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25][0]' # DisplayName
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25][1]' # Numeric UserID
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25][4]' # Profile Picture URL
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25][5]' # Relative Path to Profile page (can be a +CustomUserName): "./112064652966583500522"
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25][6,7,8]' # null
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25][2,3]' # false
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][25][9]' # true

#### Activity Comment Language data?
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][26]' # Comment language array?
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][26][0]' # 'en' (language code?)
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][26][1]' # false

#### Activity Comment Body data
'.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][27][0]' # Comment body array:
Simple example
```json
[
  [
    0,
    "Now "
  ],
  [
    0,
    "this",
    [
      null,
      true
    ]
  ],
  [
    0,
    " is how to write a signalflare :)"
  ]
]
```
More complex example with a link to a Twitter account
```json
[
  [
    0,
    "A nice little company:"
  ],
  [
    1
  ],
  [
    2,
    "twitter.com - (@aboutdotme) | Twitter",
    null,
    [
      "https://twitter.com/aboutDOTme",
      null,
      [
        [
          [
            335,
            0
          ],
          "https://twitter.com/aboutDOTme#__sid=rd0",
          null,
          null,
          null,
          null,
          [
            1548182995693,
            "https://twitter.com/aboutDOTme",
            "https://twitter.com/aboutDOTme"
          ],
          "https://twitter.com/aboutDOTme#__sid=rd0",
          {
            "39748951": [
              "https://twitter.com/aboutDOTme",
              "https://pbs.twimg.com/profile_images/946117419444998144/ONS6ZohG_400x400.jpg",
              "(@aboutdotme) | Twitter",
              null,
              null,
              [
                "//lh3.googleusercontent.com/proxy/_BiWIxyTfAT-iOZspSnjF_H3k3_30NVTEKkZfT8EmqATa4YCh4OOq1xWHPfiS00zEVhihpaFDNFnZ6sBNroZC6tnptA0KdFzTfmBY5lQjEqz3o9EI8KBMHG7cer-z4A=w506-h910",
                506,
                910,
                true,
                null,
                null,
                null,
                506,
                [
                  2,
                  "https://lh3.googleusercontent.com/proxy/_BiWIxyTfAT-iOZspSnjF_H3k3_30NVTEKkZfT8EmqATa4YCh4OOq1xWHPfiS00zEVhihpaFDNFnZ6sBNroZC6tnptA0KdFzTfmBY5lQjEqz3o9EI8KBMHG7cer-z4A=w800-h800"
                ]
              ],
              "//s2.googleusercontent.com/s2/favicons?domain=twitter.com",
              null,
              null,
              null,
              null,
              "twitter.com",
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              [
                [
                  339,
                  338,
                  336,
                  335,
                  0
                ],
                "https://pbs.twimg.com/profile_images/946117419444998144/ONS6ZohG_400x400.jpg",
                {
                  "40265033": [
                    "https://pbs.twimg.com/profile_images/946117419444998144/ONS6ZohG_400x400.jpg",
                    "https://pbs.twimg.com/profile_images/946117419444998144/ONS6ZohG_400x400.jpg",
                    null,
                    null,
                    null,
                    [
                      "//lh3.googleusercontent.com/proxy/_BiWIxyTfAT-iOZspSnjF_H3k3_30NVTEKkZfT8EmqATa4YCh4OOq1xWHPfiS00zEVhihpaFDNFnZ6sBNroZC6tnptA0KdFzTfmBY5lQjEqz3o9EI8KBMHG7cer-z4A=w506-h910",
                      506,
                      910,
                      true,
                      null,
                      null,
                      null,
                      506,
                      [
                        2,
                        "https://lh3.googleusercontent.com/proxy/_BiWIxyTfAT-iOZspSnjF_H3k3_30NVTEKkZfT8EmqATa4YCh4OOq1xWHPfiS00zEVhihpaFDNFnZ6sBNroZC6tnptA0KdFzTfmBY5lQjEqz3o9EI8KBMHG7cer-z4A=w800-h800"
                      ]
                    ],
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    400,
                    400
                  ]
                }
              ],
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              "https://twitter.com/aboutDOTme"
            ]
          }
        ]
      ],
      null,
      1
    ]
  ],
  [
    1
  ],
  [
    1
  ],
  [
    0,
    "(Not sure why but Morbius' posts don't allow me to comment.)"
  ]
]
```

Now this is an interesting one. Each array item seems to be a section of the comment body, also formatted in an array, where the sub-array's first item is a digit, the second in the text, followed by an optional options/settings? array. 
Seems to follow the following structure:
`jq '.[0][0][0][0] as $id | .[0][0][0][2][$id|tostring][27][0] as $commentBody'`
`$commentBody[$commentSection][$commentSectionType{,$commentSectionText{,$commentSectionOptions{,$commentSectionData}}}]`
(Where optional items are enclosed in {curly braces})

`$commentSectionType` ($commentBody[$commentSection][0])
`0`: Normal text, applies to `$commentSectionText`. `$commentOptions` is an array that seems to contain the formatting details. [null, true] would give italic text.
`1`: Newline; has no `$commentSectionText`
`2`: Link item; `$commentSectionText` is the link text, `$commentOptions`is empty, `$commentSectionData` is a big array with metadata from the link.
