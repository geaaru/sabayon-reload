#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

sabayon_builder_init () {

  if [[ -z "${SABAYON_SKIP_SYNC}" || "${SABAYON_SKIP_SYNC}" == "0" ]] ; then
    equo up && equo u || return 1
  fi

}

case $1 in
  init)
    sabayon_builder_init
    ;;
  phase1)
    sabayon_builder_phase1
    ;;
  *)
  echo "Use init|phase1"
  exit 1
esac

exit $?

# vim: ts=2 sw=2 expandtab
