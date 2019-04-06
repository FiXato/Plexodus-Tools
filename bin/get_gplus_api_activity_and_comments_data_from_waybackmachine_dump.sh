#!/usr/bin/env sh
# encoding: utf-8
SED_CMD="${SED_CMD:-"$(hash gsed 2>/dev/null && echo 'gsed' || echo 'sed')"}"
"${PUP_CMD:-"pup"}" --charset utf-8 $'script[nonce]:contains("key: \'ds:3\'") text{}' | "${SED_CMD}" -E 's/^AF_initDataCallback\(.+data:[^\[]+//' | "${SED_CMD}" -E 's/^}}\);$//' || echo ""