#!/usr/bin/env bash
# encoding: utf-8
function gnused() {
  if hash gsed 2>/dev/null; then
      gsed -E "$@"
  else
      sed -E "$@"
  fi
}
#export -f gnused

function gnugrep() {
  if hash ggrep 2>/dev/null; then
      ggrep "$@"
  else
      grep "$@"
  fi
}
#export -f gnugrep

function sanitise_filename() {
  gnused 's/[^-a-zA-Z0-9_.]/-/g'
}
