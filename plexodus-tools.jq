def not_empty:
  select(length > 0);

def with_comments:
  [.[]|select(.comments|not_empty)];

def without_comments:
  [.[]|select(.comments|length == 0)];

def with_image:
  [.[]|select((.media|length > 0) and (.media.contentType|startswith("image/")))];

def with_video:
  [.[]|select((.media|length > 0) and (.media.contentType|startswith("video/")))];

# Don't think Google+ ever supported audio attachments, but I've added it for completeness sake.
def with_audio:
  [.[]|select((.media|length > 0) and (.media.contentType|startswith("audio/")))];

def with_media:
  [.[]|select(.media|not_empty)];

def without_media:
  [.[]|select(.media|length == 0)];

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

def has_public_circles_acl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles|not_empty|any(.type == "CIRCLE_TYPE_PUBLIC"))];

# TODO: `is_public` for now is an alias for `has_public_circles_acl`, but might at a later point also support posts that have collectionAcl or communityAcl for Collections and Communities that have public access.
def is_public:
  has_public_circles_acl;

def has_extended_circles_acl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles|not_empty|any(.type == "CIRCLE_TYPE_EXTENDED_CIRCLES"))];

def has_own_circles_acl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles|not_empty|any(.type == "CIRCLE_TYPE_YOUR_CIRCLES"))];

def has_your_circles_acl:
  has_own_circles_acl;

def has_user_circles_acl:
  [.[]|select(.postAcl.visibleToStandardAcl.circles|not_empty|any(.type == "CIRCLE_TYPE_USER_CIRCLE"))];

# FIXME: this could theoretically also return matches for Collections or Communities with a matching name...
def with_interaction_with(displayNames):
  [.[]?|select(..|.displayName?, .authorDisplayName?| IN(([displayNames]|flatten)[]))]|not_empty|unique;

def with_comment_by(displayNames):
  [.[]?|select(.comments?|..|.author?.displayName?| IN(([displayNames]|flatten)[]))]|not_empty;

def from_collection(collectionDisplayNames):
  [.[]?|select(.postAcl.collectionAcl?.collection?.displayName?| IN(([collectionDisplayNames]|flatten)[]))]|not_empty;

def from_collection_with_resourceName(resourceNames):
  [.[]?|select(.postAcl.collectionAcl?.collection?.resourceName?| IN(([resourceNames]|flatten)[]))]|not_empty;

def from_collection_with_resource_id(resourceIds):
  [.[]?|select(.postAcl.collectionAcl?.collection?.resourceName?| IN(([resourceIds]|flatten|map("collections/\(.)"))[]))]|not_empty;

def url_from_domain(domains):
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

def get_circles:
  [.[].postAcl.visibleToStandardAcl.circles|not_empty|add]|unique;

def get_all_circle_types:
  [get_circles[]|.type]|unique;

def get_all_circle_display_names:
  [get_circles[]|.displayName|not_empty]|unique;

def get_all_circle_resource_names:
  [get_circles[]|.resourceName|not_empty]|unique;

def get_all_acl_keys:
  [.[].postAcl|keys|not_empty]|add|unique;

def get_all_community_names:
  [.[].postAcl.communityAcl.community|not_empty|.displayName|not_empty]|unique;

def get_all_collection_names:
  [.[].postAcl.collectionAcl.collection|not_empty|.displayName|not_empty]|unique;

def get_all_event_resource_names:
  [.[].postAcl.eventAcl.event|not_empty|.resourceName|not_empty]|unique;

def get_all_media_content_types:
  [.[]|.media.contentType|not_empty]|unique;

# def sourceBy(displayNames):
#   [.[]];
#

  # def urlFromDomain(domains):
  # [.[]|select(..|.url?|sub("^https?://(?<domain>[^/]+).*"; .domain)? == domains)];
  # [.[]|select(..|.url?|tostring|startswith(domains))];
  # [.[]|map(..|.url?|sub("^https?://(?<domain>[^/]+).*"; .domain)?)];
