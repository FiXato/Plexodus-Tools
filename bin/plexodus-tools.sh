#!/usr/bin/env sh
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"
formatting_filepath="$caller_path/../lib/formatting.sh"
if [ -f "$formatting_filepath" ]; then
  . "$formatting_filepath"
fi

if ! hash tput 2>/dev/null; then
  tput() {
    printf ""
  }
fi

setup() {
  if hash pkg 2>/dev/null; then
    pkg install gawk findutils sed grep coreutils attr bash git ncurses-utils
  elif hash brew 2>/dev/null; then
    brew install gawk findutils gnu-sed grep coreutils moreutils bash git
  elif hash apt-get 2>/dev/null; then
    sudo apt-get install gawk findutils sed grep coreutils moreutils bash git python-xattr
  fi
  
  if hash git 2>/dev/null; then
    git status > /dev/null
    if [ "$?" != "0" ]; then
      echo "Replacing this script with the full git repository"
      git clone https://github.com/FiXato/Plexodus-Tools && rm plexodus-tools.sh && cd Plexodus-Tools && ln -s bin/plexodus-tools.sh ./
    fi
  fi
}

save_screen() {
  tput smcup
}

restore_screen() {
  tput rmcup
}

menu() {
  BG_FORMAT="${TP_RESET}${BG_BLUE}${FG_WHITE}"
  while [ "$REPLY"  != "Q" ]; do
    printf "%s" ${BG_FORMAT}""
    clear
    cat <<- _EOF_
      ${TP_BOLD}${BG_BLUE}${FG_WHITE}Please Select:${BG_FORMAT}

      1. Install required packages
      Q. Quit

_EOF_

    read -p "Enter selection [1, Q] > " selection
    # Clear area beneath menu
    tput cup 10 0
    printf "%s" "${BG_BLACK}${FG_GREEN}"
    tput ed
    tput cup 11 0

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
    printf "\n"
    read -p "Hit enter to continue." input
  done
}

# Save screen
save_screen

# Display menu until selection == 0
menu

# Restore screen
restore_screen