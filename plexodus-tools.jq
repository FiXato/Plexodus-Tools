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

def hasExtendedCirclesAcl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles[0]["type"] == "CIRCLE_TYPE_EXTENDED_CIRCLES")];

def hasOwnCirclesAcl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles[0]["type"] == "CIRCLE_TYPE_YOUR_CIRCLES")];

#FIXME: look for any of the circles, rather than the first.
def hasUserCirclesAcl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles[0]["type"] == "CIRCLE_TYPE_USER_CIRCLE")];

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

def get_all_circle_types:
  [.[].postAcl.visibleToStandardAcl.circles|not_empty|add|.type]|unique;

def get_all_circle_display_names:
  [.[].postAcl.visibleToStandardAcl.circles|not_empty|add|.displayName|not_empty]|unique;

def get_all_circle_resource_names:
  [.[].postAcl.visibleToStandardAcl.circles|not_empty|add|.resourceName|not_empty]|unique;

def get_all_acl_keys:
  [.[].postAcl|keys|not_empty]|add|unique;

def get_all_community_names:
  [.[].postAcl.communityAcl.community|not_empty|.displayName|not_empty]|unique;

def get_all_collection_names:
  [.[].postAcl.collectionAcl.collection|not_empty|.displayName|not_empty]|unique;

def get_all_event_resource_names:
  [.[].postAcl.eventAcl.event|not_empty|.resourceName|not_empty]|unique;

def has_legacy_acl:
  [.[]|select(.postAcl.isLegacyAcl)|not_empty];

def has_collection_acl:
  [.[]|select(.postAcl.collectionAcl)|not_empty];

def has_community_acl:
  [.[]|select(.postAcl.communityAcl)|not_empty];

def has_event_acl:
  [.[]|select(.postAcl.eventAcl)|not_empty];

def has_circle_acl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles)|not_empty];

# def sourceBy(displayNames):
#   [.[]];
#

  # def urlFromDomain(domains):
  # [.[]|select(..|.url?|sub("^https?://(?<domain>[^/]+).*"; .domain)? == domains)];
  # [.[]|select(..|.url?|tostring|startswith(domains))];
  # [.[]|map(..|.url?|sub("^https?://(?<domain>[^/]+).*"; .domain)?)];
