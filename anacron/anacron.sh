#!/usr/bin/env bash


main () {
  if [[ $# -eq 0 ]]
  then
    help_msg
  fi

  if [[ -z $2 ]]
  then
    period=@monthly
  else
    safecheck "$2"
    period=$2
  fi

  delay=15
  jobid='purgeVimUndo'

  if [[ $1 = old ]]
  then
    case $period in
      @daily) days=1 ;;
      @weekly) days=7 ;;
      @monthly) days=30 ;;
      *) days=$period ;;
    esac
    cmd="find $XDG_DATA_HOME/nvim/site/undo -type f -mtime +$days -delete"
  elif [[ $1 = dead ]]
  then
    cmd='/bin/sh '
    parent=$(dirname "${BASH_SOURCE:-$0}")
    cp "$parent/$jobid.sh" "$XDG_DATA_HOME/nvim/site/" \
      || { echo "Check that 'evangelist' is installed"; exit; }
    cmd+="$XDG_DATA_HOME/nvim/site/$jobid.sh $XDG_DATA_HOME/nvim/site/undo"
  else
    echo "Wrong argument: $1"
    echo Possible values: old, dead
    exit
  fi

  if ! grep -q "$jobid.$1" /etc/anacrontab
  then
    echo -e "$period $delay $jobid.$1 $cmd\n" \
      | sudo tee -a /etc/anacrontab > /dev/null \
      && echo Success! Added the entry!
  else
    echo Already there!
  fi
}


safecheck () {
  if ! [[ $1 =~ ^@(daily|weekly|monthly)$ || $1 =~ ^[0-9]+$ ]]
  then
    echo "Wrong argument: $1"
    echo 'Pass any positive integer number (without sign)'
    echo or one of these qualifiers: @daily @weekly @monthly
    exit
  fi
}


help_msg () {
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

