#!/usr/bin/env sh
# encoding: utf-8

FG_BLACK=$(tput setaf 0)
FG_RED=$(tput setaf 1)
FG_GREEN=$(tput setaf 2)
FG_YELLOW=$(tput setaf 3)
FG_BLUE=$(tput setaf 4)
FG_MAGENTA=$(tput setaf 5)
FG_CYAN=$(tput setaf 6)
FG_WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

TP_BOLD="$(tput bold)"
TP_DIM="$(tput dim)"
TP_UON="$(tput smul)"
TP_UOFF="$(tput rmul)"
TP_INV="$(tput rev)"
TP_REV="$TP_INV"
TP_SOON="$(tput smso)"
TP_SOOFF="$(tput rmso)"
TP_RESET="$(tput sgr0)"

FORMAT_MENU_DEFAULT="${TP_RESET}${BG_BLUE}${FG_WHITE}"
FORMAT_MENU_HEADER="${TP_BOLD}${BG_BLUE}${FG_WHITE}"
FORMAT_MENU_SELECTIONS_PROMPT="${TP_BOLD}"
FORMAT_MENU_ITEM_PREFIX="${TP_BOLD}"
FORMAT_MENU_ITEM="${FORMAT_MENU_DEFAULT}"


save_screen() {
  tput smcup
}

restore_screen() {
  tput rmcup
}


max_width() {
  local text
  local max_width=0
  local line

  if [ "$1" != "" ]; then
    text="$1"
  else
    text="$(cat --)"
  fi

  while IFS= read -r line; do
    if [ $max_width -lt ${#line} ]; then
      max_width=${#line}
    fi
  done <<< "$text"
  printf $max_width
}

align_block() {
  local text
  local line
  local format_function_name="$2"
  local max_width
  local format=${3:-"%s\n"}
  
  text="$1"
  if [ "$text" == "" ]; then
    text="$(cat --)"
  fi
  
  max_width=$(max_width "$text")
  while IFS= read -r line || [ -n "$line" ]; do
    printf "$format" "$("$format_function_name" "$line" $max_width)"
  done <<< "$text"
}

display_center() {
  local columns="$(tput cols)"
  local line_width
  local string_width
  local text
  local indent

  if [ "$1" != "" ]; then
    text="$1"
  else
    text="$(cat --)"
  fi

  string_width=${#text}
  line_width=${2:-$string_width}
  indent=$(( $columns - ($columns - $string_width)/2 - ($line_width - $string_width)/2 ))
  printf "%*s" $indent "$text"
}