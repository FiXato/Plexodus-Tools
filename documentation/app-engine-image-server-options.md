List of all the English variable names and their types, taken from this [StackOverflow comment by chocolatkey](https://stackoverflow.com/a/49991848):

  ```
  int:  s   ==> Size
  int:  w   ==> Width
  bool: c   ==> Crop
  hex:  c   ==> BorderColor
  bool: d   ==> Download
  int:  h   ==> Height
  bool: s   ==> Stretch
  bool: h   ==> Html
  bool: p   ==> SmartCrop
  bool: pa  ==> PreserveAspectRatio
  bool: pd  ==> Pad
  bool: pp  ==> SmartCropNoClip
  bool: pf  ==> SmartCropUseFace
  int:  p   ==> FocalPlane
  bool: n   ==> CenterCrop
  int:  r   ==> Rotate
  bool: r   ==> SkipRefererCheck
  bool: fh  ==> HorizontalFlip
  bool: fv  ==> VerticalFlip
  bool: cc  ==> CircleCrop
  bool: ci  ==> ImageCrop
  bool: o   ==> Overlay
  str:  o   ==> EncodedObjectId
  str:  j   ==> EncodedFrameId
  int:  x   ==> TileX
  int:  y   ==> TileY
  int:  z   ==> TileZoom
  bool: g   ==> TileGeneration
  bool: fg  ==> ForceTileGeneration
  bool: ft  ==> ForceTransformation
  int:  e   ==> ExpirationTime
  str:  f   ==> ImageFilter
  bool: k   ==> KillAnimation
  int:  k   ==> FocusBlur
  bool: u   ==> Unfiltered
  bool: ut  ==> UnfilteredWithTransforms
  bool: i   ==> IncludeMetadata
  bool: ip  ==> IncludePublicMetadata
  bool: a   ==> EsPortraitApprovedOnly
  int:  a   ==> SelectFrameint
  int:  m   ==> VideoFormat
  int:  vb  ==> VideoBegin
  int:  vl  ==> VideoLength
  bool: lf  ==> LooseFaceCrop
  bool: mv  ==> MatchVersion
  bool: id  ==> ImageDigest
  int:  ic  ==> InternalClient
  bool: b   ==> BypassTakedown
  int:  b   ==> BorderSize
  str:  t   ==> Token
  str:  nt0 ==> VersionedToken
  bool: rw  ==> RequestWebp
  bool: rwu ==> RequestWebpUnlessMaybeTransparent
  bool: rwa ==> RequestAnimatedWebp
  bool: nw  ==> NoWebp
  bool: rh  ==> RequestH264
  bool: nc  ==> NoCorrectExifOrientation
  bool: nd  ==> NoDefaultImage
  bool: no  ==> NoOverlay
  str:  q   ==> QueryString
  bool: ns  ==> NoSilhouette
  int:  l   ==> QualityLevel
  int:  v   ==> QualityBucket
  bool: nu  ==> NoUpscale
  bool: rj  ==> RequestJpeg
  bool: rp  ==> RequestPng
  bool: rg  ==> RequestGif
  bool: pg  ==> TilePyramidAsProto
  bool: mo  ==> Monogram
  bool: al  ==> Autoloop
  int:  iv  ==> ImageVersion
  int:  pi  ==> PitchDegrees
  int:  ya  ==> YawDegrees
  int:  ro  ==> RollDegrees
  int:  fo  ==> FovDegrees
  bool: df  ==> DetectFaces
  str:  mm  ==> VideoMultiFormat
  bool: sg  ==> StripGoogleData
  bool: gd  ==> PreserveGoogleData
  bool: fm  ==> ForceMonogram
  int:  ba  ==> Badge
  int:  br  ==> BorderRadius
  hex:  bc  ==> BackgroundColor
  hex:  pc  ==> PadColor
  hex:  sc  ==> SubstitutionColor
  bool: dv  ==> DownloadVideo
  bool: md  ==> MonogramDogfood
  int:  cp  ==> ColorProfile
  bool: sm  ==> StripMetadata
  int:  cv  ==> FaceCropVersion
  ```

  ---

Taken from this [StackOverflow comment by taylor-hughes](https://stackoverflow.com/a/25438197):
  
  We can effect various image transformations by tacking strings onto the end of an App Engine blob-based image URL, following an = character. Options can be combined by separating them with hyphens, eg.:

  `http://[image-url]=s200-fh-p-b10-c0xFFFF0000`

  or:

  `http://[image-url]=s200-r90-cc-c0xFF00FF00-fSoften=1,20,0:`
  
  ## SIZE / CROP

  - `s640` &mdash; generates image `640` pixels on largest dimension
  - `s0` &mdash; original size image
  - `w100` &mdash; generates image `100` pixels wide
  - `h100` &mdash; generates image `100` pixels tall
  - `s` (without a value) &mdash; stretches image to fit dimensions
  - `c` &mdash; crops image to provided dimensions
  - `n` &mdash; same as `c`, but crops from the center
  - `p` &mdash; smart square crop, attempts cropping to faces
  - `pp` &mdash; alternate smart square crop, does not cut off faces (?)
  - `cc` &mdash; generates a circularly cropped image
  - `ci` &mdash; square crop to smallest of: width, height, or specified `=s` parameter
  - `nu` &mdash; no-upscaling. Disables resizing an image to larger than its original resolution.

  ## PAN AND ZOOM

  - `x, y, z:` &mdash; pan and zoom a tiled image. These have no effect on an untiled image or without an authorization parameter of some form (see googleartproject.com).


  ## ROTATION

  - `fv` &mdash; flip vertically
  - `fh` &mdash; flip horizontally
  - `r{90, 180, 270}` &mdash; rotates image `90`, `180`, or `270` degrees clockwise

  ## IMAGE FORMAT

  - `rj` — forces the resulting image to be `JPG`
  - `rp` — forces the resulting image to be `PNG`
  - `rw` — forces the resulting image to be `WebP`
  - `rg` — forces the resulting image to be `GIF`

  - `v{0,1,2,3}` — sets image to a different format option _(`Baseline Standard`, `Baseline Optimized`, and `Progressive`)_ (works with JPG and WebP)

  Forcing PNG, WebP and GIF outputs can work in combination with circular crops for a transparent background. Forcing JPG can be combined with border color to fill in backgrounds in transparent images.

  ## ANIMATED GIFs

  - `rh` &mdash; generates an MP4 from the input image
  - `k` &mdash; kill animation (generates static image)

  ## MISC.

  - `b10` &mdash; add a 10px border to image
  - `c0xAARRGGBB` &mdash; set border color, eg. `=c0xffff0000` for red
  - `d` &mdash; adds header to cause browser download
  - `e7` &mdash; set cache-control max-age header on response to 7 days
  - `l100` &mdash; sets JPEG quality to 100% (1-100)
  - `h` &mdash; responds with an HTML page containing the image
  - `g` &mdash; responds with XML used by Google's pan/zoom

  ## Filters

  - `fSoften=1,100,0:` - where `100` can go from `0` to `100` to blur the image
  - `fVignette=1,100,1.4,0,000000` where `100` controls the size of the gradient and `000000` is `RRGGBB` of the color of the border shadow
  - `fInvert=0,1` inverts the image regardless of the value provided
  - `fbw=0,1` makes the image black and white regardless of the value provided

  ## Unknown Parameters

  These parameters have been seen in use, but their effect is unknown: `no`, `nd`, `mv`

  ## Caveats

  Some options (like `=l` for JPEG quality) do not seem to generate new images. If you change another option (size, etc.) and change the `l` value, the quality change should be visible. Some options also don't work well together. This is all undocumented by Google, probably with good reason.

  Moreover, it's probably not a good idea to depend on any of these options existing forever.
  
  **Google could remove most of them without notice at any time.**
  
  ---