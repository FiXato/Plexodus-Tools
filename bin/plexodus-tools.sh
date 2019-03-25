#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"

env_lib_filepath="$caller_path/../lib/env.sh"
if [ -f "$env_lib_filepath" ]; then
  . "$env_lib_filepath"
fi

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
    pkg install gawk findutils sed grep coreutils attr bash git ncurses-utils curl p7zip
  elif hash brew 2>/dev/null; then
    brew install gawk findutils gnu-sed grep coreutils moreutils bash git curl p7zip
  elif hash apt-get 2>/dev/null; then
    sudo apt-get install gawk findutils sed grep coreutils moreutils bash git python-xattr curl p7zip-full
  else
    printf "%s\n" "Unsupported package manager. Please install the following packages via your platform's package manager:\ngawk findutils sed grep coreutils moreutils bash git python-xattr curl p7zip-full" 1>&2
  fi
  
  if hash git 2>/dev/null; then
    git status > /dev/null
    if [ "$?" != "0" ]; then
      printf "%s\n" "Replacing this script with the full git repository"
      git clone https://github.com/FiXato/Plexodus-Tools && rm plexodus-tools.sh && ln -s Plexodus-Tools/bin/plexodus-tools.sh ./ && printf "%s\n" 'Repository cloned. You can now `cd Plexodus-Tools && ./bin/plexodus-tools.sh`'
    fi
  fi
}

toggle_debug() {
  if [ "$DEBUG" == "1" ]; then
    update_env_file "DEBUG" "0"
    printf "%s\n" "DEBUG disabled"
  else
    update_env_file "DEBUG" "1"
    printf "%s\n" "DEBUG enabled"
  fi
  reload_env
  printf "%s\n" "ENVironment file reloaded"  
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
      2. Update Plexodus-Tools
      3. $([ "$DEBUG" == "1" ] && echo "Disable" || echo "Enable") DEBUG
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
      2)  git pull
          ;;
      3)  toggle_debug
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