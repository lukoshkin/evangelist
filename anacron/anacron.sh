#!/usr/bin/env bash

PURGEDIR=${PURGEDIR:-$XDG_STATE_HOME/nvim/undo}
SCRIPTDIR=${SCRIPTDIR:-$EVANGELIST/anacron}

main() {
  if [[ $# -eq 0 ]]; then
    help_msg
  fi

  local job_suffix=$1
  local period=$2

  if [[ -z $period ]]; then
    period=@monthly
  else
    safecheck "$period"
  fi

  delay=15 # default delay in execution is 15 min.
  jobid=${PURGEDIR##*/}

  if [[ $job_suffix = old ]]; then
    case $period in
    @daily) days=1 ;;
    @weekly) days=7 ;;
    @monthly) days=30 ;;
    *) days=$period ;;
    esac
    cmd="find $PURGEDIR -type f -mtime +$days -delete 2> /dev/null"
  elif [[ $job_suffix = dead ]]; then
    if ! [[ -d $SCRIPTDIR ]]; then
      echo 'You must specify valid path for SCRIPTDIR'
      exit 1
    fi
    cmd="/bin/sh $SCRIPTDIR/dead-killer.sh $PURGEDIR"
  else
    echo "Wrong argument: $job_suffix"
    echo Possible values: old, dead
    exit
  fi

  if ! grep -q "$jobid.$job_suffix" /etc/anacrontab; then
    echo "$period $delay $jobid.$job_suffix $cmd" |
      sudo tee -a /etc/anacrontab >/dev/null &&
      echo 'Success! Added the entry!'
  else
    echo 'Already there!'
  fi
}

safecheck() {
  if ! [[ $1 =~ ^@(daily|weekly|monthly)$ || $1 =~ ^[0-9]+$ ]]; then
    echo "Wrong argument: $1"
    echo 'Pass any positive integer number (without sign)'
    echo 'or one of these qualifiers: @daily @weekly @monthly'
    exit
  fi
}

help_msg() {
  echo 'Usage: ./anacron.sh <which> <period>'
  echo -e '\n* <which> can be:'
  echo -e '\t- old (files older than 30 days)'
  echo -e '\t- dead (deleted files)'
  echo -e '\n* <period> can be:'
  echo -e '\t- one of: @daily @weekly @monthly'
  echo -e '\t- natural number, representing number of days'
  exit
}

main "$@"
