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