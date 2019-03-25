#!/usr/bin/env sh
caller_path="$(dirname "$(realpath "$0")")"
PLEXODUS_ENV_PATH=${PLEXODUS_ENV_PATH:-""}

test_path="./plexodus-tools.env"
ls "${test_path}" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}"
fi

test_path="${caller_path}/../plexodus-tools.env"
ls "${test_path}" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}"
fi

test_path="~/.config"
ls "${test_path}/" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}/plexodus-tools.env"
fi

test_path="~/.configs"
ls "${test_path}/" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}/plexodus-tools.env"
fi

test_path="~/.plexodus-tools.env"
ls "${test_path}" > /dev/null 2>&1
if [ "$PLEXODUS_ENV_PATH" != "" -a "$?" == 0 ]; then
  PLEXODUS_ENV_PATH="${test_path}"
fi

if [ "$PLEXODUS_ENV_PATH" == "" ]; then
  PLEXODUS_ENV_PATH="./plexodus-tools.env"
fi

if [ ! -f "$PLEXODUS_ENV_PATH" ]; then
  touch "$PLEXODUS_ENV_PATH"
fi

. "$PLEXODUS_ENV_PATH"
