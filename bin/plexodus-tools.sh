#!/usr/bin/env sh
# encoding: utf-8
tput() {
  if hash tput 2>/dev/null; then
    tput "$@"
  fi
}

caller_path="$(dirname "$(realpath "$0")")"
formatting_filepath="$caller_path/../lib/formatting.sh"
if [ -f "$formatting_filepath" ]; then
  . "$formatting_filepath"
fi

setup() {
  if hash pkg 2>/dev/null; then
    pkg install gawk findutils gnu-sed grep coreutils moreutils bash git
  elif hash brew 2>/dev/null; then
    brew install gawk findutils gnu-sed grep coreutils moreutils bash git
  elif hash apt-get 2>/dev/null; then
    sudo apt-get install gawk findutils sed grep coreutils moreutils bash git
  fi
}

menu() {
  BG_FORMAT="${TP_RESET}${BG_BLUE}${FG_WHITE}"
  while true; do
    printf "%s" ${BG_FORMAT}""
    clear
    cat <<- _EOF_
      ${TP_BOLD}${BG_BLUE}${FG_WHITE}Please Select:${BG_FORMAT}

      1. Install required packages
      Q. Quit

_EOF_

    read -p "Enter selection [1, Q] > " selection
    printf "\n%s" "${BG_BLACK}${FG_GREEN}"

    # Act on selection
    case $selection in
      1)  setup
          ;;
      q)  break
          ;;
      Q)  break
          ;;
      *)  printf "%s" "Invalid entry." 1>&2
          ;;
    esac
    printf "\n\nPress any key to continue."
    read -n 1
  done
}

# Display menu until selection == 0
menu
