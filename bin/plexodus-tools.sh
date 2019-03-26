#!/usr/bin/env bash
# encoding: utf-8
caller_path="$(dirname "$(realpath "$0")")"

functions_lib_filepath="$caller_path/../lib/functions.sh"
if [ -f "$functions_lib_filepath" ]; then
  . "$functions_lib_filepath"
fi

if ! hash tput 2>/dev/null; then
  tput() {
    printf ""
  }
fi

setup() {
  if hash pkg 2>/dev/null; then
    pkg install gawk findutils sed grep coreutils attr bash git ncurses-utils curl p7zip termux-tools
    printf "%s\n" "Running termux-setup-storage, so you can access your Downloads directory from within Termux. This might request for storage permissions on Android 6 and newer." && termux-setup-storage
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
  else
    update_env_file "DEBUG" "1"
  fi
  unset DEBUG # unset, or else the reload won't have any effect, as it won't use the new default.
  reload_env
  printf "%s\n" "DEBUG $([ "$DEBUG" == "1" ] && echo "Enabled" || echo "Disabled") DEBUG"
}

set_extracted_takeout_path() {
  local input
  read -e -p "Please enter the path to the parent directory of where the Takeout folder is/will be extracted: " input
  if [ "$input" == "" ]; then
    echo "${FG_RED}PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH cannot be empty" 1>&2
    return 255
  else
    ls "${input}/"  > /dev/null 2>&1
    if (( $? > 0 )); then
      echo "${FG_RED}'$input' is not an accessible directory." 1>&2
      read -p "Want to create it? [y/n]" response
      if [ "$response" == 'y' -o "$response" == "Y" -o "$response" == "yes" ]; then
        mkdir -p "$input"
      else
        return 255
      fi
    fi
    update_env_file "PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH" "$input"
    unset PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH
    reload_env
  fi
  printf "%s\n" "PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH is set to '$PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH'"
  return 0
}

menu_items_ohash_name() {
  printf "%s" "menu_items_${1}"
}

menu_items_formatted() {
  printf_ohash "$(menu_items_ohash_name "$1")" "${FORMAT_MENU_ITEM_PREFIX}[%s] ${FORMAT_MENU_ITEM}%s${FORMAT_MENU_DEFAULT}\n"
}

menu_items_keys() {
  printf_ohash_keys "$(menu_items_ohash_name "$1")"
}

menu_item_add() {
  ohash_add "$(menu_items_ohash_name "$1")" "$2" "${3//$'\n'/$'\n    '}"
}

menu_items_clear() {
  ohash_clear "$(menu_items_ohash_name "$1")"
}

menu_text_main()
{
  menu_items_clear 'main'
  menu_item_add 'main' '1' 'Install required packages'
  menu_item_add 'main' '2' 'Update Plexodus-Tools'
  menu_item_add 'main' '3' "Extract data files from takeout-*.zip into $PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH/Takeout/"$'\n'"It looks in the current directory, and ~/storage/downloads"$'\n'"(which on Android is your Downloads folder)."
  menu_item_add 'main' '4' "Extract all relevant URLs from $PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH data files"
  menu_item_add 'main' 'S' 'Settings'
  menu_item_add 'main' 'Q' 'Quit'
}

menu_text_settings()
{
  menu_items_clear 'settings'
  menu_item_add 'settings' '1' "$([ "$DEBUG" == "1" ] && echo "Disable" || echo "Enable") DEBUG"
  menu_item_add 'settings' '2' "Change PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH (current: $PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH)"
  menu_item_add 'settings' 'Q' 'Return to main menu'
}

handle_settings_menu() {
  declare -n _selection="$1"
  local output=""
  # Act on selection
  case $_selection in
    1)  output="$(toggle_debug)" && unset DEBUG && reload_env || read -p "Hit enter to continue" && return 0 # unset, or else reloading will not just use the current setting
        ;;
    2)  output="$(set_extracted_takeout_path)" && unset PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH && reload_env || read -p "Hit enter to continue" && return 0
        ;;
    [qQ])  return 255
        ;;
    *)  output="${TP_BOLD}${FG_RED}Invalid entry.${FORMAT_MENU_DEFAULT}"
        ;;
  esac

  printf "\n\n"
  align_block "$output" display_center "${FORMAT_MENU_DEFAULT}%s\n"
  printf "\n"
  display_center "${TP_BOLD}Hit enter to continue.${FORMAT_MENU_DEFAULT}"
  read input
  printf "\n"
  return 0
}

extract_data_from_takeout_archives() {
  gnufind {.,~/storage/downloads/} -maxdepth 1 -iname 'takeout-*.zip' -exec 7z x "{}" '*.json' '*.html' '*.csv' '*.vcf' '*.ics' -r -o${PLEXODUS_EXTRACTED_TAKEOUT_PARENT_PATH}/ \; 2>/dev/null
}

handle_main_menu() {
  declare -n _selection="$1"
  local output=""
  # Act on selection
  case $_selection in
    1)  output="$(setup)"
        ;;
    2)  output="$(git pull && printf "%s\n" "If new code was fetched, please exit and restart Plexodus-Tools to apply the updates.")"
        ;;
    3)  extract_data_from_takeout_archives | tee "$LAST_COMMAND_OUTPUT_LOGPATH" && output="$(cat "$LAST_COMMAND_OUTPUT_LOGPATH")" || read -p "Error while trying to extract takeout archive. Maybe none could be found?" && return 0
        ;;
    4) output="$("${caller_path}/../bin/get_all_unique_urls_from_takeout.sh")"
        ;;
    [sS]) menu 'SETTINGS MENU' 'settings' && return 0
        ;;
    [qQ])  return 255
        ;;
    *)  output="${TP_BOLD}${FG_RED}Invalid entry.${FORMAT_MENU_DEFAULT}"
        ;;
  esac

  printf "\n\n"
  align_block "$output" display_center "${FORMAT_MENU_DEFAULT}%s\n"
  printf "\n"
  display_center "${TP_BOLD}Hit enter to continue.${FORMAT_MENU_DEFAULT}"
  read input
  printf "\n"
  return 0
}

menu() {
  while [ "$REPLY"  != "Q" ]; do
    # Initialize menu
    "menu_text_$2"

    printf "%s" "${FORMAT_MENU_DEFAULT}"
    clear

    display_center "${FORMAT_MENU_HEADER}${1}${FORMAT_MENU_DEFAULT}"
    printf "\n\n"


    local menu_text="$(menu_items_formatted "$2")"
    local prompt_title="Enter selection [$(menu_items_keys "$2")] > "
    
    align_block "$menu_text" display_center
    printf "\n\n"

    local menu_selections_prompt="$(display_center "${FORMAT_MENU_SELECTIONS_PROMPT}${prompt_title}${FORMAT_MENU_DEFAULT}")"
    read -p "$menu_selections_prompt" selection
    
    printf "%s" "${BG_BLACK}${FG_GREEN}"

    "handle_$2_menu" selection || break

    printf "\n"
  done
}

# Save screen
save_screen

menu "MAIN MENU" "main"

# Restore screen
restore_screen