def not_empty:
  select(length > 0);

def withComments:
  [.[]|.comments as $comments| select($comments != null and ($comments|any))];

def withImage:
  [.[]|select(.media != null and .media.contentType != null and (.media.contentType|startswith("image/")))];

def withVideo:
  [.[]|select(.media != null and .media.contentType != null and (.media.contentType|startswith("video/")))];

def withAudio:
  [.[]|select(.media != null and .media.contentType != null and (.media.contentType|startswith("audio/")))];

def withMedia:
  [.[]|select(.media != null)];

def withoutMedia:
  [.[]|select(.media == null)];

def isPublic:
  [.[]|select(.postAcl.visibleToStandardAcl.circles[0]["type"] == "CIRCLE_TYPE_PUBLIC")];

def withInteractionWith(displayNames):
  [.[]?|select(..|.displayName?, .authorDisplayName?| IN(([displayNames]|flatten)[]))]|not_empty|unique;

def withCommentBy(displayNames):
  [.[]?|select(.comments?|..|.author?.displayName?| IN(([displayNames]|flatten)[]))]|not_empty;

def fromCollection(collectionDisplayNames):
  [.[]?|select(.postAcl.collectionAcl?.collection?.displayName?| IN(([collectionDisplayNames]|flatten)[]))]|not_empty;

def fromCollectionWithResourceName(resourceNames):
  [.[]?|select(.postAcl.collectionAcl?.collection?.resourceName?| IN(([resourceNames]|flatten)[]))]|not_empty;

def fromCollectionWithResourceId(resourceIds):
  [.[]?|select(.postAcl.collectionAcl?.collection?.resourceName?| IN(([resourceIds]|flatten|map("collections/\(.)"))[]))]|not_empty;

def urlFromDomain(domains):
  [.[]|select(..|.url?|sub("^https?://(?<domain>[^/]+).*"; .domain)?| IN(([domains]|flatten)[]))];

def sort_by_creation_time:
  sort_by(.creationTime);

def sort_by_update_time:
  sort_by(.updateTime);

def sort_by_last_modified:
  sort_by_update_time;

def sort_by_url:
  sort_by(.url);

def sort_activity_log_by_ts:
  sort_by(.timestampMs);

# def sourceBy(displayNames):
#   [.[]];
#

  # def urlFromDomain(domains):
  # [.[]|select(..|.url?|sub("^https?://(?<domain>[^/]+).*"; .domain)? == domains)];
  # [.[]|select(..|.url?|tostring|startswith(domains))];
  # [.[]|map(..|.url?|sub("^https?://(?<domain>[^/]+).*"; .domain)?)];
