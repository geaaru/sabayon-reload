#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh
. $(dirname $(readlink -f $BASH_SOURCE))/overlay_commons.sh

DEFAULT_OVERLAYS=(
  "sabayon-distro"
  "sabayon"
)

SABAYON_CHECK_RESULTDIR=${SABAYON_CHECK_RESULTDIR:-/tmp/overlay_checks}
SABAYON_OVERLAYDIR=${SABAYON_OVERLAYDIR:-/var/lib/layman}
SABAYON_OVERLAYS2CHECK=${SABAYON_OVERLAYS2CHECK:-${DEFAULT_OVERLAYS}}

overlays_info () {

  echo "
SABAYON_CHECK_RESULTDIR   = ${SABAYON_CHECK_RESULTDIR}
SABAYON_OVERLAYDIR        = ${SABAYON_OVERLAYDIR}
SABAYON_OVERLAYS2CHECK    = ${SABAYON_OVERLAYS2CHECK[@]}

"

  return 0
}

main () {

  local i=0

  overlays_info

  echo "Sync overlays..."

  layman -S


  echo "Starting check of overlays ${SABAYON_OVERLAYS2CHECK[@]}..."

  for ((i = 0; i < ${#SABAYON_OVERLAYS2CHECK[@]} ; i++)) ; do

    sabayon_overlay_check_uris "${SABAYON_OVERLAYS2CHECK[${i}]}" \
      "${SABAYON_OVERLAYDIR}" "${SABAYON_CHECK_RESULTDIR}" || return 1

  done

  echo "All done. Have you a good day."

  return 0
}

main
exit $?

# vim: ts=2 sw=2 expandtab
