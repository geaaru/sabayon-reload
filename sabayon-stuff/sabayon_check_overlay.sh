#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh
. $(dirname $(readlink -f $BASH_SOURCE))/overlay-commons.sh

PACKAGES_TO_REMOVE=(
  "dev-ruby/rake"
  "dev-ruby/test-unit"
  "dev-ruby/power_assert"
  "dev-ruby/net-telnet"
  "dev-ruby/minitest"
  "dev-ruby/rdoc"
  "dev-ruby/json"
  "dev-ruby/did_you_mean"
  "virtual/rubygems"
  "dev-ruby/rubygems"
  "dev-util/cmake"
  "dev-libs/libusb"
)

DEFAULT_OVERLAYS=(
  "sabayon-distro"
  "sabayon"
)

FILES_TO_REMOVE=(
  "/etc/make.profile"
)

SABAYON_CHECK_RESULTDIR=${SABAYON_CHECK_RESULTDIR:-/tmp/overlay_checks}
SABAYON_OVERLAYDIR=${SABAYON_OVERLAYDIR:-/var/lib/layman}
SABAYON_OVERLAYS2CHECK=${SABAYON_OVERLAYS2CHECK:-${DEFAULT_OVERLAYS[@]}}
SABAYON_SYNC_OVERLAY=${SABAYON_SYNC_OVERLAY:-0}
SABAYON_TMP_DISTDIR=${SABAYON_TMP_DISTDIR:-/tmp/distfiles}
SABAYON_DEBUG=${SABAYON_DEBUG:-0}

overlays_info () {

  echo "
SABAYON_CHECK_RESULTDIR   = ${SABAYON_CHECK_RESULTDIR}
SABAYON_OVERLAYDIR        = ${SABAYON_OVERLAYDIR}
SABAYON_OVERLAYS2CHECK    = ${SABAYON_OVERLAYS2CHECK[@]}
SABAYON_SYNC_OVERLAY      = ${SABAYON_SYNC_OVERLAY}
SABAYON_TMP_DISTDIR       = ${SABAYON_TMP_DISTDIR}

"

  return 0
}

overlays_init () {

  local i=0
  local overlay=""
  local exists=""

  for ((i = 0; i < ${#SABAYON_OVERLAYS2CHECK[@]} ; i++)) ; do

    overlay="${SABAYON_OVERLAYS2CHECK[${i}]}"

    exists=$(layman -l | cut -d' ' -f 3 | grep "^${overlay}$" | wc -l)

    if [ "${exists}" != "1" ] ; then
      sabayon_install_overlay "${overlay}" 1 || return 1
    fi

  done

  return 0
}

build () {

  sabayon_config_portage_empty 0 1 0 "-name '*eclass'" || return 1

  equo up || return 1

  # Cleanup
  equo rm --deep --configfiles \
    --force-system "${PACKAGES_TO_REMOVE[@]}" || return 1

  echo 3 | equo i layman git || return 1

  echo -9 | equo conf update || return 1

  equo cleanup || return 1

  # Cleanup
  rm -rf "${FILES_TO_REMOVE[@]}" || return 1

  return 0
}

main () {

  local i=0

  overlays_info

  overlays_init || return 1

  if [ ${SABAYON_SYNC_OVERLAY} == "1" ] ; then
    echo "Sync overlays..."

    layman -S

  fi

  if [ ! -e ${SABAYON_CHECK_RESULTDIR} ] ; then
    mkdir -p ${SABAYON_CHECK_RESULTDIR} || return 1
  fi

  if [ ! -e ${SABAYON_TMP_DISTDIR} ] ; then
    echo "CREATE DIR ${SABAYON_TMP_DISTDIR}"
    mkdir -p ${SABAYON_TMP_DISTDIR} || return 1
  fi

  echo "Starting check of overlays ${SABAYON_OVERLAYS2CHECK[@]}..."

  for ((i = 0; i < ${#SABAYON_OVERLAYS2CHECK[@]} ; i++)) ; do

    sabayon_overlay_check_uris "${SABAYON_OVERLAYS2CHECK[${i}]}" \
      "${SABAYON_OVERLAYDIR}" || return 1

  done

  echo "All done. Have you a good day."

  return 0
}


case $1 in
  build)
    build
    ;;
  *)
    main
    ;;
esac

exit $?
# vim: ts=2 sw=2 expandtab
