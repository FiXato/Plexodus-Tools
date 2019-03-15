#!/usr/bin/env bash
# encoding: utf-8
usage="Usage; export GOOGLE_OAUTH_ACCESS_TOKEN=\$(\"$0\" \"path/to/oauth2/client_secret.json\")"

oauth_json_credentials_file="$1"
if hash oauth2l 2>/dev/null; then
  if [ "$1" == "" ]; then
    echo "Please pass the path to the OAuth2 JSON file you downloaded from your Google APIs Console: https://console.developers.google.com/apis/credentials" 1>&2
    echo "$usage" 1>&2
  else
    scopes=("contacts.readonly" "plus.login" "user.addresses.read" "user.birthday.read" "user.emails.read" "user.phonenumbers.read" "userinfo.email" "userinfo.profile")
    echo "Fetching OAuth2 Token for scopes needed for complete profile information from the People API: ${scopes[@]/##/ }" 1>&2
    oauth_token="$(oauth2l fetch --json "$oauth_json_credentials_file" ${scopes[@]/##/ } | tee /dev/tty)"
    exit_code="$?"
    if (( $exit_code > 0 )); then
      echo "Error while fetching OAuth2 Token. Exited with code $exit_code" 1>&2
      exit $exit_code
    fi
    oauth_token="${oauth_token##*$'\n'}"
    printf '%s' "${oauth_token}"
  fi
else
  echo "Cannot find OAuth2 tool 'oauth2l'. Installation instructions can be found on https://github.com/google/oauth2l" 1>&2
fi
